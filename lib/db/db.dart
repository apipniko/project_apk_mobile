import '../data_dummy.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart' as p;

/// Database lokal (SQLite): karyawan, users (login), presensi, pengajuan.
class Db {
  static Database? _db;

  static Future<Database> get instance async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    if (kIsWeb) {
      // Chrome/web: pakai sqlite3.wasm (sqflite_common_ffi_web)
      databaseFactory = databaseFactoryFfiWeb;
    }
    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, 'project50jt.db'),
      version: 2,
      onCreate: (db, v) => _migrate(db, 0, v),
      onUpgrade: _migrate,
      onDowngrade: onDatabaseDowngradeDelete,
    );
  }

  /// Buat semua tabel bila belum ada; aman untuk create maupun upgrade.
  static Future<void> _migrate(Database db, int from, int to) async {
    await db.execute("""
      CREATE TABLE IF NOT EXISTS karyawan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        nip TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL,
        departemen TEXT NOT NULL,
        jabatan TEXT NOT NULL,
        jadwal TEXT NOT NULL,
        mulaiBekerja TEXT NOT NULL,
        peran TEXT NOT NULL,
        alokasiCuti INTEGER NOT NULL DEFAULT 0,
        wajahLengkap INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    """);
    await db.execute("""
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nip TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        peran TEXT NOT NULL,
        karyawanId INTEGER
      )
    """);
    await db.execute("""
      CREATE TABLE IF NOT EXISTS presensi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nip TEXT NOT NULL,
        tanggal TEXT NOT NULL,
        jamMasuk TEXT,
        jamKeluar TEXT,
        status TEXT NOT NULL,
        UNIQUE (nip, tanggal)
      )
    """);
    await db.execute("""
      CREATE TABLE IF NOT EXISTS pengajuan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nip TEXT NOT NULL,
        kategori TEXT NOT NULL,
        tanggalMulai TEXT NOT NULL,
        tanggalSelesai TEXT NOT NULL,
        keterangan TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'Menunggu Manager',
        createdAt TEXT NOT NULL
      )
    """);
    // Akun awal (abaikan kalau sudah ada)
    await db.insert('users', {'nip': 'admin', 'password': 'admin123', 'peran': 'Admin'},
        conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('users', {'nip': '96820', 'password': 'karyawan123', 'peran': 'Karyawan'},
        conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('karyawan', {
      'nama': 'Bintanx',
      'nip': '96820',
      'email': 'bintanx@project50jt.id',
      'departemen': 'Design',
      'jabatan': 'UI/UX Design',
      'jadwal': 'Regular - Senin-Jumat',
      'mulaiBekerja': '24 Okt 2024',
      'peran': 'Karyawan',
      'alokasiCuti': 12,
      'wajahLengkap': 1,
      'createdAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // ---------- AUTH ----------
  /// Return baris user (nip, peran) kalau cocok; null kalau salah.
  static Future<Map<String, Object?>?> login(String nipOrEmail, String pass) async {
    final db = await instance;
    final cleanInput = nipOrEmail.trim();
    // 1. Cek langsung nip di tabel users
    final rows = await db.query('users',
        where: 'nip = ? AND password = ?',
        whereArgs: [cleanInput, pass],
        limit: 1);
    if (rows.isNotEmpty) return rows.first;

    // 2. Cek email di tabel karyawan
    final kar = await db.query('karyawan',
        where: 'email = ?',
        whereArgs: [cleanInput],
        limit: 1);
    if (kar.isNotEmpty) {
      final actualNip = kar.first['nip'] as String;
      final rows2 = await db.query('users',
          where: 'nip = ? AND password = ?',
          whereArgs: [actualNip, pass],
          limit: 1);
      if (rows2.isNotEmpty) return rows2.first;
    }
    return null;
  }

  /// Sesi disimpan sebagai baris khusus di tabel users (nip = '\u2014session\u2014').
  static Future<void> saveSession(String nip, String peran) async {
    final db = await instance;
    await db.delete('users', where: "nip = '-session-'");
    await db
        .insert('users', {'nip': '-session-', 'password': nip, 'peran': peran});
  }

  static Future<Map<String, Object?>?> currentSession() async {
    final db = await instance;
    final rows = await db.query('users', where: "nip = '-session-'", limit: 1);
    if (rows.isEmpty) return null;
    return {
      'nip': rows.first['password'] as String,
      'peran': rows.first['peran'] as String,
    };
  }

  static Future<void> logout() async {
    final db = await instance;
    await db.delete('users', where: "nip = '-session-'");
  }

  static Future<void> registerUser(String nip, String pass, String peran) async {
    final db = await instance;
    await db.insert('users', {'nip': nip, 'password': pass, 'peran': peran},
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  // ---------- KARYAWAN ----------
  static Future<int> insertKaryawan(Map<String, Object?> k) async {
    final db = await instance;
    return db.insert('karyawan', k, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  static Future<List<Map<String, Object?>>> allKaryawan() async {
    final db = await instance;
    return db.query('karyawan', orderBy: 'nama COLLATE NOCASE');
  }

  static Future<int> deleteKaryawan(int id) async {
    final db = await instance;
    return db.delete('karyawan', where: 'id = ?', whereArgs: [id]);
  }

  static Future<bool> nipExists(String nip) async {
    final db = await instance;
    final rows = await db.query('karyawan',
        columns: ['id'], where: 'nip = ?', whereArgs: [nip], limit: 1);
    return rows.isNotEmpty;
  }

  static Future<String> namaDariNip(String nip) async {
    final db = await instance;
    final rows = await db
        .query('karyawan', columns: ['nama'], where: 'nip = ?', whereArgs: [nip], limit: 1);
    if (rows.isNotEmpty) return rows.first['nama'] as String;
    for (final k in karyawanList) {
      if (k.nip == nip) return k.nama;
    }
    return nip;
  }

  // ---------- PRESENSI ----------
  static Future<int> catatPresensi({
    required String nip,
    required String tanggal,
    required String jam,
    required bool isMasuk,
  }) async {
    final db = await instance;
    final existing = await db.query('presensi',
        where: 'nip = ? AND tanggal = ?', whereArgs: [nip, tanggal], limit: 1);
    if (existing.isEmpty) {
      if (!isMasuk) return 0;
      return db.insert('presensi', {
        'nip': nip,
        'tanggal': tanggal,
        'jamMasuk': jam,
        'status': _statusDariJam(jam),
      });
    }
    if (isMasuk) return 0;
    return db.update('presensi', {'jamKeluar': jam},
        where: 'nip = ? AND tanggal = ?', whereArgs: [nip, tanggal]);
  }

  static String _statusDariJam(String jam) {
    final parts = jam.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    return (h > 8 || (h == 8 && m > 0)) ? 'Terlambat' : 'Tepat Waktu';
  }

  static Future<List<Map<String, Object?>>> riwayatPresensi(String nip) async {
    final db = await instance;
    return db.query('presensi',
        where: 'nip = ?', whereArgs: [nip], orderBy: 'tanggal DESC');
  }

  // ---------- PENGAJUAN ----------
  static Future<int> buatPengajuan({
    required String nip,
    required String kategori,
    required String tanggalMulai,
    required String tanggalSelesai,
    required String keterangan,
  }) async {
    final db = await instance;
    return db.insert('pengajuan', {
      'nip': nip,
      'kategori': kategori,
      'tanggalMulai': tanggalMulai,
      'tanggalSelesai': tanggalSelesai,
      'keterangan': keterangan,
      'status': 'Menunggu Manager',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, Object?>>> pengajuanSaya(String nip) async {
    final db = await instance;
    return db.query('pengajuan',
        where: 'nip = ?', whereArgs: [nip], orderBy: 'createdAt DESC');
  }
}
