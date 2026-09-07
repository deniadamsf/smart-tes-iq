import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Membuat instance singleton agar koneksi database hanya dibuka sekali
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smart_tes_iq.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Buka database. onUpgrade WAJIB ada bersama kenaikan version:
    // menaikkan version tanpa onUpgrade membuat database GAGAL DIBUKA untuk
    // user lama, dan seluruh riwayat tes mereka jadi tidak terbaca.
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  // Membuat struktur tabel saat database pertama kali dibuat
  Future _createDB(Database db, int version) async {
    // 1. Tabel Profil Lokal (Tamu)
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        is_guest INTEGER NOT NULL DEFAULT 1, -- 1 = Tamu, 0 = Login
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 2. Tabel Riwayat Hasil Tes
    await db.execute('''
      CREATE TABLE test_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        test_name TEXT NOT NULL, -- Contoh: 'Analogi Verbal', 'Spasial'
        score INTEGER NOT NULL,
        total_questions INTEGER NOT NULL,
        ai_analysis TEXT, -- Menyimpan ringkasan analisa AI
        is_synced INTEGER NOT NULL DEFAULT 0, -- 0 = Belum dikirim ke Laravel, 1 = Sudah
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 3. Tabel Riwayat Obrolan AI (BARU)
    await db.execute('''
      CREATE TABLE chat_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sender TEXT NOT NULL, -- 'user' atau 'ai'
        message TEXT NOT NULL,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        is_synced INTEGER NOT NULL DEFAULT 0 -- 0 = Belum dikirim ke Laravel, 1 = Sudah
      )
    ''');

    // 4. Tabel Tantangan Harian (v2)
    await _createDailyChallengeTable(db);
  }

  // ==========================================
  // MIGRASI SKEMA
  // ==========================================

  // Dipanggil saat user LAMA membuka aplikasi dengan versi database lebih baru.
  // HANYA BOLEH MENAMBAH. Jangan pernah DROP atau ALTER tabel lama di sini —
  // riwayat tes user tersimpan di sana dan tidak punya cadangan.
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createDailyChallengeTable(db);
    }
  }

  // Dipanggil dari DUA tempat: _createDB (instalasi baru) dan _upgradeDB
  // (user lama yang update). Kalau hanya dipasang di salah satunya, separuh
  // user tidak akan punya tabel ini.
  Future _createDailyChallengeTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_challenge (
        challenge_date TEXT PRIMARY KEY,   -- 'YYYY-MM-DD', tanggal dari SERVER
        correct        INTEGER NOT NULL,
        total          INTEGER NOT NULL,
        duration_ms    INTEGER NOT NULL,
        iq_harian      INTEGER NOT NULL,
        rank_today     INTEGER,            -- null kalau peringkat belum diambil
        synced_at      TEXT
      )
    ''');
  }

  // ==========================================
  // FUNGSI UNTUK MENYIMPAN & MENGAMBIL DATA TES
  // ==========================================

  Future<int> insertTestResult(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('test_results', row);
  }

  Future<List<Map<String, dynamic>>> getAllTestResults() async {
    final db = await instance.database;
    return await db.query('test_results', orderBy: 'created_at DESC');
  }

  Future<int> getCompletedTestsCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(DISTINCT test_name) as count FROM test_results');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getUnsyncedResults() async {
    final db = await instance.database;
    return await db.query('test_results', where: 'is_synced = ?', whereArgs: [0]);
  }

  Future<int> markAsSynced(int id) async {
    final db = await instance.database;
    return await db.update(
      'test_results',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================
  // FUNGSI UNTUK DATABASE OBROLAN AI (BARU)
  // ==========================================

  // Menyimpan pesan baru ke lokal
  Future<int> insertChatMessage(String sender, String message) async {
    final db = await instance.database;
    return await db.insert('chat_history', {
      'sender': sender,
      'message': message,
      'is_synced': 0, // Default belum dikirim ke Laravel
    });
  }

  // Mengambil semua riwayat obrolan untuk ditampilkan di layar
  Future<List<Map<String, dynamic>>> getChatHistory() async {
    final db = await instance.database;
    return await db.query('chat_history', orderBy: 'id ASC');
  }

  // Menghapus semua riwayat obrolan (Fitur Hapus Chat untuk User)
  Future<void> clearChatHistory() async {
    final db = await instance.database;
    await db.delete('chat_history');
  }

  // Mengambil chat yang belum tersinkronisasi ke Laravel
  Future<List<Map<String, dynamic>>> getUnsyncedChats() async {
    final db = await instance.database;
    return await db.query('chat_history', where: 'is_synced = ?', whereArgs: [0]);
  }

  // Update status sinkronisasi chat setelah berhasil dikirim ke Laravel
  Future<int> markChatAsSynced(int id) async {
    final db = await instance.database;
    return await db.update(
      'chat_history',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  // FUNGSI BARU: Menyimpan Teks AI ke tes yang Paling Terakhir dikerjakan
  Future<void> updateLatestTestAnalysis(String testName, String aiAnalysis) async {
    final db = await database;

    // 1. Cari 1 tes terakhir yang dikerjakan berdasarkan namanya
    final List<Map<String, dynamic>> maps = await db.query(
      'test_results',
      where: 'test_name = ?',
      whereArgs: [testName],
      orderBy: 'id DESC', // Urutkan dari yang terbaru
      limit: 1,
    );

    if (maps.isNotEmpty) {
      // 2. Timpa teks "Menunggu sinkronisasi..." dengan teks asli dari AI
      await db.update(
        'test_results',
        {
          'ai_analysis': aiAnalysis,
          'is_synced': 0 // Set 0 agar otomatis ter-backup ke Laravel lagi
        },
        where: 'id = ?',
        whereArgs: [maps.first['id']],
      );
    }
  }

  // ==========================================
  // TANTANGAN HARIAN (v2)
  // ==========================================
  // Cache lokal hasil sendiri supaya tetap terbaca offline.
  // Sumber kebenaran tetap di server — peringkat dan tanggal dihitung
  // di sana, bukan di sini.

  Future<void> saveDailyChallenge(Map<String, dynamic> row) async {
    final db = await instance.database;
    await db.insert(
      'daily_challenge',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getDailyChallenge(String date) async {
    final db = await instance.database;
    final rows = await db.query(
      'daily_challenge',
      where: 'challenge_date = ?',
      whereArgs: [date],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> getDailyChallengeHistory({int limit = 30}) async {
    final db = await instance.database;
    return await db.query(
      'daily_challenge',
      orderBy: 'challenge_date DESC',
      limit: limit,
    );
  }
}
