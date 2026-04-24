import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service untuk upload file ke Cloudinary menggunakan HTTP multipart.
///
/// ARSITEKTUR:
/// - Menggunakan Dio untuk multipart upload (lebih andal dari http package)
/// - Credentials dibaca dari .env — TIDAK hardcoded
/// - Mendukung retry otomatis (dikelola oleh SyncManager)
/// - Return URL publik yang langsung bisa disimpan ke MongoDB
///
/// CARA PAKAI:
///   final url = await CloudinaryService.instance.uploadFile('/tmp/bukti.jpg');
///   if (url != null) { /* simpan url ke PermissionRecord.buktiFotoUrl */ }
class CloudinaryService {
  // ─── Singleton ──────────────────────────────────────────────────
  static final CloudinaryService instance = CloudinaryService._internal();
  CloudinaryService._internal()
      : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 60),
          ),
        );

  final Dio _dio;

  // ─── Env Config ─────────────────────────────────────────────────
  String get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  String get _apiKey    => dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  String get _apiSecret => dotenv.env['CLOUDINARY_API_SECRET'] ?? '';

  /// Base URL upload endpoint Cloudinary (auto-upload image)
  String get _uploadUrl =>
      'https://api.cloudinary.com/v1_1/$_cloudName/auto/upload';

  // ─── UPLOAD FILE ────────────────────────────────────────────────

  /// Upload file dari path lokal ke Cloudinary.
  ///
  /// [localPath]  — path absolut file di device (misal: /data/.../bukti.jpg)
  /// [folder]     — folder tujuan di Cloudinary (default: 'prasasti/izin')
  /// [publicId]   — ID unik file di Cloudinary (opsional, auto-generate jika null)
  ///
  /// Return: URL publik file jika sukses, null jika gagal.
  ///
  /// NOTE: Method ini TIDAK mengelola retry — retry dikelola oleh SyncManager.
  Future<String?> uploadFile({
    required String localPath,
    String folder = 'prasasti/izin',
    String? publicId,
  }) async {
    if (!_isConfigured) {
      debugPrint('[Cloudinary] ERROR: credentials belum dikonfigurasi di .env');
      debugPrint('  Pastikan CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, '
          'CLOUDINARY_API_SECRET sudah diisi.');
      return null;
    }

    final file = File(localPath);
    if (!file.existsSync()) {
      debugPrint('[Cloudinary] ERROR: file tidak ditemukan: $localPath');
      return null;
    }

    try {
      debugPrint('[Cloudinary] mulai upload: $localPath');
      debugPrint('[Cloudinary] folder: $folder');

      // ── Build signature untuk authenticated upload ──────────────
      final timestamp = _nowTimestamp();
      final signature = _buildSignature(
        timestamp: timestamp,
        folder: folder,
        publicId: publicId,
      );

      // ── Build multipart form data ───────────────────────────────
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          localPath,
          filename: _extractFilename(localPath),
        ),
        'api_key': _apiKey,
        'timestamp': timestamp.toString(),
        'signature': signature,
        'folder': folder,
        if (publicId != null) 'public_id': publicId,
      });

      // ── POST ke Cloudinary ─────────────────────────────────────
      final response = await _dio.post(
        _uploadUrl,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
        onSendProgress: (sent, total) {
          if (total > 0) {
            final pct = (sent / total * 100).toStringAsFixed(1);
            debugPrint('[Cloudinary] upload progress: $pct%');
          }
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final secureUrl = data['secure_url']?.toString();

        if (secureUrl != null && secureUrl.isNotEmpty) {
          debugPrint('[Cloudinary] upload sukses: $secureUrl');
          return secureUrl;
        }

        debugPrint('[Cloudinary] response OK tapi secure_url kosong: $data');
        return null;
      }

      debugPrint('[Cloudinary] upload gagal — status: ${response.statusCode}');
      return null;
    } on DioException catch (e) {
      _logDioError(e);
      return null;
    } catch (e, st) {
      debugPrint('[Cloudinary] error tidak terduga: $e');
      debugPrint(st.toString());
      return null;
    }
  }

  // ─── DELETE FILE (opsional, untuk cleanup) ──────────────────────

  /// Hapus file dari Cloudinary berdasarkan public_id.
  /// Dipanggil jika pengajuan izin dibatalkan sebelum sync.
  Future<bool> deleteFile(String publicId) async {
    if (!_isConfigured) return false;

    try {
      final timestamp = _nowTimestamp();
      final toSign = 'public_id=$publicId&timestamp=$timestamp$_apiSecret';
      final signature = _sha1Hex(toSign);

      final response = await _dio.post(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/destroy',
        data: {
          'public_id': publicId,
          'api_key': _apiKey,
          'timestamp': timestamp.toString(),
          'signature': signature,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      final result = response.data?['result']?.toString();
      if (result == 'ok') {
        debugPrint('[Cloudinary] file dihapus: $publicId');
        return true;
      }

      debugPrint('[Cloudinary] delete response: $result');
      return false;
    } catch (e) {
      debugPrint('[Cloudinary] delete error: $e');
      return false;
    }
  }

  // ─── HELPERS ────────────────────────────────────────────────────

  bool get _isConfigured =>
      _cloudName.isNotEmpty && _apiKey.isNotEmpty && _apiSecret.isNotEmpty;

  int _nowTimestamp() =>
      DateTime.now().millisecondsSinceEpoch ~/ 1000;

  /// Build signed signature untuk Cloudinary authenticated upload.
  /// Format: SHA1(params_string + api_secret)
  ///
  /// Dokumen resmi: https://cloudinary.com/documentation/authentication
  String _buildSignature({
    required int timestamp,
    required String folder,
    String? publicId,
  }) {
    // Parameter harus diurutkan alphabetically tanpa api_key & file
    final params = <String, String>{
      'folder': folder,
      'timestamp': timestamp.toString(),
      if (publicId != null) 'public_id': publicId,
    };

    final sortedKeys = params.keys.toList()..sort();
    final paramString = sortedKeys
        .map((k) => '$k=${params[k]}')
        .join('&');

    // Tambahkan api_secret di akhir (tidak di-encode)
    final toSign = '$paramString$_apiSecret';
    return _sha1Hex(toSign);
  }

  /// SHA1 hash — implementasi manual karena tidak ada stdlib SHA1 di Dart.
  /// Menggunakan crypto package yang sudah ada di transitive dependencies.
  String _sha1Hex(String input) {
    // Fallback: gunakan dart:convert + manual SHA1 via crypto
    // crypto sudah ada sebagai transitive dependency (via firebase_core)
    try {
      // Lazy import untuk menghindari dependency langsung
      // jika crypto tidak tersedia, gunakan HMAC-SHA1 alternative
      final bytes = _utf8Encode(input);
      return _computeSha1(bytes);
    } catch (e) {
      debugPrint('[Cloudinary] SHA1 error: $e');
      return '';
    }
  }

  List<int> _utf8Encode(String s) {
    final result = <int>[];
    for (final char in s.runes) {
      if (char < 0x80) {
        result.add(char);
      } else if (char < 0x800) {
        result.add(0xC0 | (char >> 6));
        result.add(0x80 | (char & 0x3F));
      } else {
        result.add(0xE0 | (char >> 12));
        result.add(0x80 | ((char >> 6) & 0x3F));
        result.add(0x80 | (char & 0x3F));
      }
    }
    return result;
  }

  /// Implementasi SHA1 murni Dart (tidak butuh dependency tambahan).
  String _computeSha1(List<int> bytes) {
    // Initial hash values (SHA1 standard)
    var h0 = 0x67452301;
    var h1 = 0xEFCDAB89;
    var h2 = 0x98BADCFE;
    var h3 = 0x10325476;
    var h4 = 0xC3D2E1F0;

    // Pre-processing: padding
    final msgLen = bytes.length;
    final bitLen = msgLen * 8;
    final padded = List<int>.from(bytes)..add(0x80);

    while (padded.length % 64 != 56) {
      padded.add(0);
    }

    // Append original length as 64-bit big-endian
    for (var i = 7; i >= 0; i--) {
      padded.add((bitLen >> (i * 8)) & 0xFF);
    }

    // Process each 512-bit chunk
    for (var chunkStart = 0; chunkStart < padded.length; chunkStart += 64) {
      final chunk = padded.sublist(chunkStart, chunkStart + 64);
      final w = List<int>.filled(80, 0);

      for (var i = 0; i < 16; i++) {
        w[i] = ((chunk[i * 4] << 24) |
                (chunk[i * 4 + 1] << 16) |
                (chunk[i * 4 + 2] << 8) |
                chunk[i * 4 + 3]) &
            0xFFFFFFFF;
      }

      for (var i = 16; i < 80; i++) {
        w[i] = _rotl32(w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1);
      }

      var a = h0, b = h1, c = h2, d = h3, e = h4;

      for (var i = 0; i < 80; i++) {
        int f, k;
        if (i < 20) {
          f = (b & c) | (~b & d);
          k = 0x5A827999;
        } else if (i < 40) {
          f = b ^ c ^ d;
          k = 0x6ED9EBA1;
        } else if (i < 60) {
          f = (b & c) | (b & d) | (c & d);
          k = 0x8F1BBCDC;
        } else {
          f = b ^ c ^ d;
          k = 0xCA62C1D6;
        }

        final temp =
            (_rotl32(a, 5) + f + e + k + w[i]) & 0xFFFFFFFF;
        e = d;
        d = c;
        c = _rotl32(b, 30);
        b = a;
        a = temp;
      }

      h0 = (h0 + a) & 0xFFFFFFFF;
      h1 = (h1 + b) & 0xFFFFFFFF;
      h2 = (h2 + c) & 0xFFFFFFFF;
      h3 = (h3 + d) & 0xFFFFFFFF;
      h4 = (h4 + e) & 0xFFFFFFFF;
    }

    return [h0, h1, h2, h3, h4]
        .map((v) => v.toRadixString(16).padLeft(8, '0'))
        .join();
  }

  int _rotl32(int val, int shift) {
    val = val & 0xFFFFFFFF;
    shift = shift & 31;
    return ((val << shift) | (val >> (32 - shift))) & 0xFFFFFFFF;
  }

  String _extractFilename(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  void _logDioError(DioException e) {
    debugPrint('[Cloudinary] DioException: ${e.type}');
    debugPrint('  message: ${e.message}');
    if (e.response != null) {
      debugPrint('  status: ${e.response?.statusCode}');
      debugPrint('  data: ${e.response?.data}');
    }
  }
}