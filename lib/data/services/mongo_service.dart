import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart';

/// Singleton service untuk berkomunikasi dengan MongoDB Atlas.
///
/// ARSITEKTUR:
/// - Menggunakan mongo_dart driver (bukan REST API yang sudah deprecated)
/// - Koneksi dibuat sekali, dipakai sepanjang lifecycle app
/// - Connection string tersimpan di .env — TIDAK hardcoded di kode
/// - Semua operasi berjalan async — tidak pernah block UI thread
///
/// LIFECYCLE:
///   main() → MongoService.instance.init() → gunakan sepanjang app
///   (tidak perlu connect/disconnect berulang)
class MongoService {
  // ─── Singleton ─────────────────────────────────────────────────
  static MongoService _instance = MongoService._internal();
  static MongoService get instance => _instance;

  @visibleForTesting
  static set instance(MongoService newInstance) {
    _instance = newInstance;
  }

  MongoService._internal();

  // ─── State ─────────────────────────────────────────────────────
  Db? _db;
  bool _initialized = false;
  bool _isConnecting = false;

  // ─── Env Config ────────────────────────────────────────────────
  String get _uri => dotenv.env['MONGO_URI'] ?? '';
  String get _fallbackUri => dotenv.env['MONGO_URI_FALLBACK'] ?? '';
  String get _databaseName => dotenv.env['MONGO_DATABASE'] ?? 'prasasti_db';

  // ─── Getter Collection ─────────────────────────────────────────
  /// Akses collection. Gunakan AppConstants.xxxCollection untuk nama.
  DbCollection collection(String collectionName) {
    if (_db == null || !_db!.isConnected) {
      throw StateError(
        'MongoService belum terkoneksi! '
        'Panggil await MongoService.instance.init() di main() dulu.',
      );
    }
    return _db!.collection(collectionName);
  }

  // ─── INISIALISASI ───────────────────────────────────────────────
  /// Buat koneksi ke MongoDB Atlas.
  /// Dipanggil SEKALI di main() — menunggu koneksi benar-benar terbuka.
  ///
  /// PENTING: Koneksi bersifat persistent — tidak perlu connect ulang
  /// untuk setiap operasi CRUD. Driver akan otomatis mengelola connection pool.
  Future<bool> init() async {
    if (_initialized && _db != null && _db!.isConnected) {
      debugPrint('ℹ️ MongoService: sudah terkoneksi, skip init.');
      return true;
    }

    if (_isConnecting) {
      debugPrint('ℹ️ MongoService: sedang dalam proses koneksi...');
      return false;
    }

    if (_uri.isEmpty || _uri.contains('<')) {
      debugPrint('❌ MongoService: MONGO_URI di .env belum diisi dengan benar!');
      debugPrint(
        '   Pastikan format: mongodb+srv://user:password@cluster.xxx.mongodb.net/',
      );
      return false;
    }

    _isConnecting = true;

    final urisToTry = <String>[_uri];
    if (_fallbackUri.isNotEmpty && _fallbackUri != _uri) {
      urisToTry.add(_fallbackUri);
    }

    Object? lastError;

    for (var i = 0; i < urisToTry.length; i++) {
      final currentUri = urisToTry[i];
      final isFallback = i > 0;

      try {
        debugPrint('🔄 MongoService: Menghubungkan ke MongoDB Atlas...');
        debugPrint('   Database: $_databaseName');
        debugPrint('   URI mode: ${isFallback ? 'fallback' : 'primary'}');

        _db = await Db.create(currentUri);
        await _db!.open();

        if (_db!.isConnected) {
          _initialized = true;
          _isConnecting = false;
          debugPrint('✅ MongoService: Terhubung ke MongoDB Atlas!');
          debugPrint('   Database: $_databaseName');
          debugPrint('   State: ${_db!.state}');
          return true;
        }

        debugPrint('❌ MongoService: open() dipanggil tapi tidak connected.');
        await _db?.close();
        _db = null;
      } catch (e) {
        lastError = e;
        debugPrint('⚠️ MongoService: koneksi ${isFallback ? 'fallback' : 'primary'} gagal: $e');
        try {
          await _db?.close();
        } catch (_) {}
        _db = null;

        final usesSrv = currentUri.trim().toLowerCase().startsWith('mongodb+srv://');
        final looksLikeDnsOverHttpsFailure = e.toString().contains('dns.google.com/resolve') ||
            e.toString().contains('Connection closed before full header was received');
        if (usesSrv && looksLikeDnsOverHttpsFailure) {
          debugPrint('ℹ️ MongoService: SRV lookup gagal (DNS over HTTPS diblokir jaringan).');
          debugPrint('   Solusi: isi MONGO_URI_FALLBACK dengan URI non-SRV dari Atlas (mongodb://...).');
        }
      }
    }

    try {
      throw lastError ?? StateError('Koneksi gagal tanpa detail error.');
    } catch (e) {
      _isConnecting = false;
      _initialized = false;
      debugPrint('❌ MongoService: Gagal terhubung ke Atlas!');
      debugPrint('   Error: $e');
      debugPrint('   Tips troubleshooting:');
      debugPrint(
        '   1. Cek MONGO_URI di .env — pastikan username & password benar',
      );
      debugPrint(
        '   2. Pastikan IP 0.0.0.0/0 sudah di-allow di Atlas Network Access',
      );
      debugPrint('   3. Pastikan cluster aktif (bukan paused)');
      debugPrint('   4. Jika jaringan memblokir DNS over HTTPS, tambahkan MONGO_URI_FALLBACK (mongodb://...)');
      return false;
    }
  }

  // ─── STATUS CHECK ───────────────────────────────────────────────
  /// Cek apakah koneksi ke Atlas aktif.
  bool get isConnected => _db != null && _db!.isConnected;

  /// Uji koneksi — untuk tombol "Test Koneksi" di Week 7 verifier.
  Future<bool> testConnection() async {
    try {
      if (!isConnected) {
        final connected = await init();
        if (!connected) return false;
      }
      // Ping dengan operasi ringan: list collection names
      await _db!.getCollectionNames();
      debugPrint('✅ MongoService testConnection: BERHASIL');
      return true;
    } catch (e) {
      debugPrint('❌ MongoService testConnection: GAGAL — $e');
      return false;
    }
  }

  // ─── RECONNECT ──────────────────────────────────────────────────
  /// Coba reconnect jika koneksi terputus.
  /// Dipanggil otomatis oleh SyncManager sebelum sync (Week 11).
  Future<bool> ensureConnected() async {
    if (isConnected) return true;
    debugPrint('🔄 MongoService: Koneksi terputus, mencoba reconnect...');
    return await init();
  }

  // ════════════════════════════════════════════════════════════════
  // CRUD OPERATIONS
  // Semua method di bawah ini dipakai oleh Controller & SyncManager.
  // Dilengkapi mekanisme auto-retry jika Atlas mereset koneksi.
  // ════════════════════════════════════════════════════════════════

  /// Wrapper untuk menangani ConnectionException / No master connection dari Atlas
  Future<T> _withRetry<T>(Future<T> Function() operation) async {
    try {
      await ensureConnected();
      return await operation();
    } catch (e) {
      final eStr = e.toString().toLowerCase();
      if (eStr.contains('connection closed') || 
          eStr.contains('no master connection') || 
          eStr.contains('socket') || 
          eStr.contains('connectionexception')) {
        debugPrint('⚠️ MongoService: Connection reset detected. Reconnecting and retrying...');
        try {
          await _db?.close();
        } catch (_) {}
        _db = null;
        _initialized = false;
        
        final connected = await ensureConnected();
        if (connected) {
          return await operation();
        } else {
          throw StateError('Gagal menyambung ulang ke database.');
        }
      }
      rethrow;
    }
  }

  // ─── INSERT ONE ─────────────────────────────────────────────────
  /// Insert satu dokumen ke collection.
  ///
  /// Return: WriteResult — cek .hasWriteErrors untuk error handling.
  /// Throws: MongoDartError jika duplicate key (kode 11000).
  Future<WriteResult> insertOne({
    required String collectionName,
    required Map<String, dynamic> document,
  }) async {
    return await _withRetry(() async {
      return await collection(collectionName).insertOne(document);
    });
  }

  // ─── INSERT MANY ────────────────────────────────────────────────
  /// Insert banyak dokumen sekaligus (batch sync di SyncManager).
  Future<BulkWriteResult> insertMany({
    required String collectionName,
    required List<Map<String, dynamic>> documents,
  }) async {
    return await _withRetry(() async {
      return await collection(collectionName).insertMany(documents);
    });
  }

  // ─── FIND ONE ───────────────────────────────────────────────────
  /// Ambil satu dokumen berdasarkan filter.
  /// Return null jika tidak ditemukan.
  Future<Map<String, dynamic>?> findOne({
    required String collectionName,
    required Map<String, dynamic> filter,
  }) async {
    return await _withRetry(() async {
      return await collection(collectionName).findOne(filter);
    });
  }

  // ─── FIND MANY ──────────────────────────────────────────────────
  /// Ambil semua dokumen yang cocok dengan filter.
  Future<List<Map<String, dynamic>>> findMany({
    required String collectionName,
    Map<String, dynamic>? filter,
    Map<String, dynamic>? sort,
    int? limit,
  }) async {
    return await _withRetry(() async {
      SelectorBuilder selector = where;

      if (filter != null && filter.isNotEmpty) {
        filter.forEach((key, value) {
          selector = selector.eq(key, value);
        });
      }
      if (sort != null && sort.isNotEmpty) {
        sort.forEach((key, value) {
          selector = selector.sortBy(key, descending: value == -1);
        });
      }
      if (limit != null) {
        selector = selector.limit(limit);
      }

      return await collection(collectionName).find(selector).toList();
    });
  }

  // ─── UPDATE ONE ─────────────────────────────────────────────────
  /// Update field tertentu pada satu dokumen (\$set).
  /// Return jumlah dokumen yang dimodifikasi.
  Future<int> updateOne({
    required String collectionName,
    required Map<String, dynamic> filter,
    required Map<String, dynamic> updateFields,
  }) async {
    return await _withRetry(() async {
      // Build ModifierBuilder dari semua field yang ingin di-update
      ModifierBuilder modifier = modify;
      for (final entry in updateFields.entries) {
        modifier = modifier.set(entry.key, entry.value);
      }

      final result = await collection(collectionName).updateOne(filter, modifier);
      return result.nModified;
    });
  }

  // ─── DELETE ONE ─────────────────────────────────────────────────
  /// Hapus satu dokumen berdasarkan filter.
  Future<int> deleteOne({
    required String collectionName,
    required Map<String, dynamic> filter,
  }) async {
    return await _withRetry(() async {
      final result = await collection(collectionName).deleteOne(filter);
      return result.nRemoved;
    });
  }

  // ─── COUNT ──────────────────────────────────────────────────────
  /// Hitung jumlah dokumen yang cocok dengan filter.
  Future<int> count({
    required String collectionName,
    Map<String, dynamic>? filter,
  }) async {
    return await _withRetry(() async {
      return await collection(collectionName).count(filter);
    });
  }

  // ─── CHECK DUPLICATE KEY ────────────────────────────────────────
  /// Cek apakah exception disebabkan oleh duplicate key (error 11000).
  /// Digunakan SyncManager untuk handle duplikasi data antar perangkat.
  static bool isDuplicateKeyError(dynamic error) {
    final errorStr = error.toString();
    return errorStr.contains('11000') ||
        errorStr.contains('duplicate key') ||
        errorStr.contains('E11000');
  }

  // ─── CLOSE ──────────────────────────────────────────────────────
  /// Tutup koneksi (panggil saat app benar-benar ditutup jika perlu).
  Future<void> close() async {
    if (_db != null && _db!.isConnected) {
      await _db!.close();
      _initialized = false;
      debugPrint('🔒 MongoService: Koneksi ditutup');
    }
  }
}
