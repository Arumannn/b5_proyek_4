import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../constants/app_constants.dart';

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
  static final MongoService instance = MongoService._internal();
  MongoService._internal();

  // ─── State ─────────────────────────────────────────────────────
  Db? _db;
  bool _initialized = false;
  bool _isConnecting = false;

  // ─── Env Config ────────────────────────────────────────────────
  String get _uri => dotenv.env['MONGO_URI'] ?? '';
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
      debugPrint('   Pastikan format: mongodb+srv://user:password@cluster.xxx.mongodb.net/');
      return false;
    }

    _isConnecting = true;

    try {
      debugPrint('🔄 MongoService: Menghubungkan ke MongoDB Atlas...');
      debugPrint('   Database: $_databaseName');

      _db = await Db.create(_uri);
      await _db!.open();

      if (_db!.isConnected) {
        _initialized = true;
        _isConnecting = false;
        debugPrint('✅ MongoService: Terhubung ke MongoDB Atlas!');
        debugPrint('   Database: $_databaseName');
        debugPrint('   State: ${_db!.state}');
        return true;
      } else {
        _isConnecting = false;
        debugPrint('❌ MongoService: open() dipanggil tapi tidak connected.');
        return false;
      }
    } catch (e) {
      _isConnecting = false;
      _initialized = false;
      debugPrint('❌ MongoService: Gagal terhubung ke Atlas!');
      debugPrint('   Error: $e');
      debugPrint('   Tips troubleshooting:');
      debugPrint('   1. Cek MONGO_URI di .env — pastikan username & password benar');
      debugPrint('   2. Pastikan IP 0.0.0.0/0 sudah di-allow di Atlas Network Access');
      debugPrint('   3. Pastikan cluster aktif (bukan paused)');
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
  // Selalu pastikan isConnected sebelum memanggil operasi ini.
  // ════════════════════════════════════════════════════════════════

  // ─── INSERT ONE ─────────────────────────────────────────────────
  /// Insert satu dokumen ke collection.
  ///
  /// Return: WriteResult — cek .hasWriteErrors untuk error handling.
  /// Throws: MongoDartError jika duplicate key (kode 11000).
  Future<WriteResult> insertOne({
    required String collectionName,
    required Map<String, dynamic> document,
  }) async {
    await ensureConnected();
    return await collection(collectionName).insertOne(document);
  }

  // ─── INSERT MANY ────────────────────────────────────────────────
  /// Insert banyak dokumen sekaligus (batch sync di SyncManager).
  Future<BulkWriteResult> insertMany({
    required String collectionName,
    required List<Map<String, dynamic>> documents,
  }) async {
    await ensureConnected();
    return await collection(collectionName).insertMany(documents);
  }

  // ─── FIND ONE ───────────────────────────────────────────────────
  /// Ambil satu dokumen berdasarkan filter.
  /// Return null jika tidak ditemukan.
  Future<Map<String, dynamic>?> findOne({
    required String collectionName,
    required Map<String, dynamic> filter,
  }) async {
    await ensureConnected();
    return await collection(collectionName).findOne(filter);
  }

  // ─── FIND MANY ──────────────────────────────────────────────────
  /// Ambil semua dokumen yang cocok dengan filter.
  Future<List<Map<String, dynamic>>> findMany({
    required String collectionName,
    Map<String, dynamic>? filter,
    Map<String, dynamic>? sort,
    int? limit,
  }) async {
    await ensureConnected();
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
  }

  // ─── UPDATE ONE ─────────────────────────────────────────────────
  /// Update field tertentu pada satu dokumen (\$set).
  /// Return jumlah dokumen yang dimodifikasi.
  Future<int> updateOne({
    required String collectionName,
    required Map<String, dynamic> filter,
    required Map<String, dynamic> updateFields,
  }) async {
    await ensureConnected();
    final result = await collection(collectionName).updateOne(
      filter,
      modify.set(updateFields.keys.first, updateFields.values.first)
          .let((m) {
        var builder = m;
        final entries = updateFields.entries.skip(1);
        for (final entry in entries) {
          builder = builder.set(entry.key, entry.value);
        }
        return builder;
      }),
    );
    return result.nModified ?? 0;
  }

  // ─── DELETE ONE ─────────────────────────────────────────────────
  /// Hapus satu dokumen berdasarkan filter.
  Future<int> deleteOne({
    required String collectionName,
    required Map<String, dynamic> filter,
  }) async {
    await ensureConnected();
    final result =
        await collection(collectionName).deleteOne(filter);
    return result.nRemoved;
  }

  // ─── COUNT ──────────────────────────────────────────────────────
  /// Hitung jumlah dokumen yang cocok dengan filter.
  Future<int> count({
    required String collectionName,
    Map<String, dynamic>? filter,
  }) async {
    await ensureConnected();
    return await collection(collectionName).count(filter);
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

// ─── Extension Helper ───────────────────────────────────────────
extension _ModifyBuilderExt on ModifierBuilder {
  ModifierBuilder let(ModifierBuilder Function(ModifierBuilder) fn) => fn(this);
}