import '../data_dummy.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart' as p;

class DbException implements Exception {
  const DbException(this.message);

  final String message;

  @override
  String toString() => message;
}

class Db {
  static Database? _db;
  static const _schemaVersion = 5;
  static const _sessionNip = '-session-';

  static Future<Database> get instance async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    if (kIsWeb) databaseFactory = databaseFactoryFfiWeb;
    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, 'project50jt.db'),
      version: _schemaVersion,
      onCreate: (db, version) => _migrate(db, 0, version),
      onUpgrade: _migrate,
      onDowngrade: onDatabaseDowngradeDelete,
    );
  }

  static Future<void> _migrate(Database db, int from, int to) async {
    await db.execute('''
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
        statusKaryawan TEXT NOT NULL DEFAULT 'Aktif',
        wajahLengkap INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nip TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        peran TEXT NOT NULL,
        karyawanId INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS presensi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nip TEXT NOT NULL,
        tanggal TEXT NOT NULL,
        jamMasuk TEXT,
        jamKeluar TEXT,
        status TEXT NOT NULL,
        latitudeMasuk REAL,
        longitudeMasuk REAL,
        akurasiMasuk REAL,
        latitudePulang REAL,
        longitudePulang REAL,
        akurasiPulang REAL,
        UNIQUE (nip, tanggal)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pengajuan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nip TEXT NOT NULL,
        kategori TEXT NOT NULL,
        tanggalMulai TEXT NOT NULL,
        tanggalSelesai TEXT NOT NULL,
        keterangan TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'Menunggu Manager',
        createdAt TEXT NOT NULL,
        catatanKeputusan TEXT NOT NULL DEFAULT '',
        diputuskanOleh TEXT,
        managerAt TEXT,
        hrAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sessions (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        nip TEXT NOT NULL,
        peran TEXT NOT NULL
      )
    ''');

    if (from > 0 && from < 3) {
      await db.execute(
        "ALTER TABLE pengajuan ADD COLUMN catatanKeputusan TEXT NOT NULL DEFAULT ''",
      );
      await db.execute('ALTER TABLE pengajuan ADD COLUMN diputuskanOleh TEXT');
      await db.execute('ALTER TABLE pengajuan ADD COLUMN managerAt TEXT');
      await db.execute('ALTER TABLE pengajuan ADD COLUMN hrAt TEXT');
      final oldSession = await db.query(
        'users',
        where: 'nip = ?',
        whereArgs: [_sessionNip],
        limit: 1,
      );
      if (oldSession.isNotEmpty) {
        await db.insert('sessions', {
          'id': 1,
          'nip': oldSession.first['password'],
          'peran': oldSession.first['peran'],
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        await db.delete('users', where: 'nip = ?', whereArgs: [_sessionNip]);
      }
      await _normalizeLegacyDates(db);
    }
    if (from > 0 && from < 4) {
      await db.execute(
        "ALTER TABLE karyawan ADD COLUMN statusKaryawan TEXT NOT NULL DEFAULT 'Aktif'",
      );
    }
    if (from > 0 && from < 5) {
      await db.execute('ALTER TABLE presensi ADD COLUMN latitudeMasuk REAL');
      await db.execute('ALTER TABLE presensi ADD COLUMN longitudeMasuk REAL');
      await db.execute('ALTER TABLE presensi ADD COLUMN akurasiMasuk REAL');
      await db.execute('ALTER TABLE presensi ADD COLUMN latitudePulang REAL');
      await db.execute('ALTER TABLE presensi ADD COLUMN longitudePulang REAL');
      await db.execute('ALTER TABLE presensi ADD COLUMN akurasiPulang REAL');
    }

    await db.insert('users', {
      'nip': 'admin',
      'password': 'admin123',
      'peran': 'Admin',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    for (final employee in karyawanList) {
      await db.insert('karyawan', {
        'nama': employee.nama,
        'nip': employee.nip,
        'email': '${employee.nip}@rawan.id',
        'departemen': employee.departemen,
        'jabatan': employee.jabatan,
        'jadwal': 'Regular - Senin-Jumat',
        'mulaiBekerja': '24 Okt 2024',
        'peran': 'Karyawan',
        'alokasiCuti': 12,
        'wajahLengkap': employee.wajahLengkap ? 1 : 0,
        'createdAt': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.insert('users', {
        'nip': employee.nip,
        'password': 'karyawan123',
        'peran': 'Karyawan',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  static Future<void> _normalizeLegacyDates(DatabaseExecutor db) async {
    for (final table in ['presensi']) {
      final rows = await db.query(table, columns: ['id', 'tanggal']);
      for (final row in rows) {
        final value = row['tanggal'] as String;
        final normalized = _legacyDateKey(value);
        if (normalized != null && normalized != value) {
          await db.update(
            table,
            {'tanggal': normalized},
            where: 'id = ?',
            whereArgs: [row['id']],
          );
        }
      }
    }
    final rows = await db.query('pengajuan');
    for (final row in rows) {
      final mulai = _legacyDateKey(row['tanggalMulai'] as String);
      final selesai = _legacyDateKey(row['tanggalSelesai'] as String);
      if (mulai != null || selesai != null) {
        await db.update(
          'pengajuan',
          {
            'tanggalMulai': mulai ?? row['tanggalMulai'],
            'tanggalSelesai': selesai ?? row['tanggalSelesai'],
          },
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      }
    }
  }

  static String? _legacyDateKey(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return dateKey(parsed);
    final numeric = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(value);
    if (numeric != null) {
      final date = DateTime(
        int.parse(numeric[3]!),
        int.parse(numeric[2]!),
        int.parse(numeric[1]!),
      );
      return dateKey(date);
    }
    final named = RegExp(r'^(\d{1,2}) ([A-Za-z]{3}) (\d{4})$')
        .firstMatch(value);
    if (named != null) {
      const months = {
        'jan': 1,
        'feb': 2,
        'mar': 3,
        'apr': 4,
        'mei': 5,
        'may': 5,
        'jun': 6,
        'jul': 7,
        'agu': 8,
        'aug': 8,
        'sep': 9,
        'okt': 10,
        'oct': 10,
        'nov': 11,
        'des': 12,
        'dec': 12,
      };
      final month = months[named[2]!.toLowerCase()];
      if (month != null) {
        return dateKey(
          DateTime(int.parse(named[3]!), month, int.parse(named[1]!)),
        );
      }
    }
    return null;
  }

  static String dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String displayDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static DateTime? _parseDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null || dateKey(date) != value) return null;
    return date;
  }

  static int _minutes(String value) {
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value);
    if (match == null) return -1;
    final hour = int.parse(match[1]!);
    final minute = int.parse(match[2]!);
    if (hour > 23 || minute > 59) return -1;
    return hour * 60 + minute;
  }

  static String _statusDariJam(String jam) =>
      _minutes(jam) > 8 * 60 ? 'Terlambat' : 'Tepat Waktu';

  static Future<Map<String, Object?>?> login(
    String nipOrEmail,
    String pass,
  ) async {
    final db = await instance;
    final input = nipOrEmail.trim();
    final direct = await db.query(
      'users',
      where: 'nip = ? AND password = ?',
      whereArgs: [input, pass],
      limit: 1,
    );
    if (direct.isNotEmpty) {
      final user = direct.first;
      final employee = await karyawanByNip(user['nip'] as String);
      if (employee != null && employee['statusKaryawan'] != 'Aktif') {
        throw const DbException('Akun karyawan tidak aktif. Hubungi HR.');
      }
      if (employee == null && user['peran'] != 'Admin') {
        return null;
      }
      return user;
    }

    final employee = await db.query(
      'karyawan',
      columns: ['nip'],
      where: 'LOWER(email) = LOWER(?)',
      whereArgs: [input],
      limit: 1,
    );
    if (employee.isEmpty) return null;
    final rows = await db.query(
      'users',
      where: 'nip = ? AND password = ?',
      whereArgs: [employee.first['nip'], pass],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final employeeData = await karyawanByNip(employee.first['nip'] as String);
    if (employeeData?['statusKaryawan'] != 'Aktif') {
      throw const DbException('Akun karyawan tidak aktif. Hubungi HR.');
    }
    return rows.first;
  }

  static Future<void> saveSession(String nip, String peran) async {
    final db = await instance;
    await db.insert('sessions', {
      'id': 1,
      'nip': nip,
      'peran': peran,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Map<String, Object?>?> currentSession() async {
    final db = await instance;
    final rows = await db.query('sessions', where: 'id = 1', limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  static Future<void> logout() async {
    final db = await instance;
    await db.delete('sessions', where: 'id = 1');
  }

  static Future<void> registerUser(
    String nip,
    String pass,
    String peran,
  ) async {
    final db = await instance;
    await db.insert('users', {
      'nip': nip.trim(),
      'password': pass,
      'peran': peran,
    }, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  static Future<int> buatKaryawan({
    required Map<String, Object?> karyawan,
    required String password,
  }) async {
    final db = await instance;
    return db.transaction((txn) async {
      final duplicateEmail = await txn.query(
        'karyawan',
        columns: ['id'],
        where: 'LOWER(email) = LOWER(?)',
        whereArgs: [karyawan['email']],
        limit: 1,
      );
      if (duplicateEmail.isNotEmpty) {
        throw const DbException('Email sudah digunakan oleh karyawan lain.');
      }
      final employeeId = await txn.insert('karyawan', karyawan);
      await txn.insert('users', {
        'nip': karyawan['nip'],
        'password': password,
        'peran': karyawan['peran'],
        'karyawanId': employeeId,
      });
      return employeeId;
    });
  }

  static Future<int> updateKaryawan({
    required String nip,
    required Map<String, Object?> data,
  }) async {
    final db = await instance;
    return db.transaction((txn) async {
      final duplicateEmail = await txn.query(
        'karyawan',
        columns: ['id'],
        where: 'LOWER(email) = LOWER(?) AND nip != ?',
        whereArgs: [data['email'], nip],
        limit: 1,
      );
      if (duplicateEmail.isNotEmpty) {
        throw const DbException('Email sudah digunakan oleh karyawan lain.');
      }
      final changed = await txn.update(
        'karyawan',
        data,
        where: 'nip = ?',
        whereArgs: [nip],
      );
      if (changed != 1) throw const DbException('Karyawan tidak ditemukan.');
      await txn.update(
        'users',
        {'peran': data['peran']},
        where: 'nip = ?',
        whereArgs: [nip],
      );
      return changed;
    });
  }

  static Future<void> resetPassword(String nip) async {
    final db = await instance;
    final changed = await db.update(
      'users',
      {'password': 'karyawan123'},
      where: 'nip = ?',
      whereArgs: [nip],
    );
    if (changed != 1) throw const DbException('Akun karyawan tidak ditemukan.');
  }

  static Future<void> setEmployeeStatus({
    required String nip,
    required String status,
  }) async {
    if (status != 'Aktif' && status != 'Nonaktif') {
      throw const DbException('Status karyawan tidak valid.');
    }
    final db = await instance;
    final changed = await db.update(
      'karyawan',
      {'statusKaryawan': status},
      where: 'nip = ?',
      whereArgs: [nip],
    );
    if (changed != 1) throw const DbException('Karyawan tidak ditemukan.');
  }

  static Future<List<Map<String, Object?>>> allKaryawan({
    DateTime? tanggal,
    bool hanyaAktif = false,
  }) async {
    final db = await instance;
    final selectedDate = tanggal ?? DateTime.now();
    final day = dateKey(selectedDate);
    final employees = await db.rawQuery(
      '''
      SELECT k.*, p.jamMasuk, p.jamKeluar, p.status AS statusPresensi
      FROM karyawan k
      LEFT JOIN presensi p ON p.nip = k.nip AND p.tanggal = ?
      ${hanyaAktif ? "WHERE k.statusKaryawan = 'Aktif'" : ''}
      ORDER BY k.nama COLLATE NOCASE
      ''',
      [day],
    );
    final approvedLeaves = await db.query(
      'pengajuan',
      columns: ['nip'],
      where: "status = 'Disetujui HR' AND tanggalMulai <= ? AND tanggalSelesai >= ?",
      whereArgs: [day, day],
    );
    final leaveNips = approvedLeaves.map((row) => row['nip']).toSet();
    final today = DateTime.now();
    final selectedDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final todayDay = DateTime(today.year, today.month, today.day);
    final isDayComplete =
        selectedDay.isBefore(todayDay) ||
        (selectedDay == todayDay && today.hour >= 18);
    return employees.map((row) {
      final item = Map<String, Object?>.from(row);
      if (item['statusPresensi'] == null) {
        item['statusPresensi'] = leaveNips.contains(item['nip'])
            ? 'Izin'
            : selectedDay.weekday > DateTime.friday
            ? 'Tidak dijadwalkan'
            : isDayComplete
            ? 'Alpha'
            : 'Belum presensi';
      }
      return item;
    }).toList();
  }

  static Future<List<Map<String, Object?>>> availableDepartments() async {
    final db = await instance;
    return db.rawQuery(
      "SELECT DISTINCT departemen FROM karyawan WHERE departemen != '' "
      "ORDER BY departemen COLLATE NOCASE",
    );
  }

  static Future<Map<String, Object?>?> karyawanByNip(String nip) async {
    final db = await instance;
    final rows = await db.query(
      'karyawan',
      where: 'nip = ?',
      whereArgs: [nip],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  static Future<void> updateProfile({
    required String nip,
    required String nama,
    required String email,
  }) async {
    final db = await instance;
    final changed = await db.update(
      'karyawan',
      {'nama': nama.trim(), 'email': email.trim()},
      where: 'nip = ?',
      whereArgs: [nip],
    );
    if (changed != 1) {
      throw const DbException('Profil karyawan tidak ditemukan.');
    }
  }

  static Future<void> changePassword({
    required String nip,
    required String currentPassword,
    required String newPassword,
  }) async {
    if (newPassword.trim().length < 8) {
      throw const DbException('Kata sandi baru minimal 8 karakter.');
    }
    final db = await instance;
    final changed = await db.update(
      'users',
      {'password': newPassword.trim()},
      where: 'nip = ? AND password = ?',
      whereArgs: [nip, currentPassword],
    );
    if (changed != 1) {
      throw const DbException('Kata sandi saat ini tidak sesuai.');
    }
  }

  static Future<int> deleteKaryawan(int id) async {
    final db = await instance;
    return db.transaction((txn) async {
      final rows = await txn.query(
        'karyawan',
        columns: ['nip'],
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rows.isEmpty) return 0;
      final nip = rows.first['nip'] as String;
      await txn.delete('presensi', where: 'nip = ?', whereArgs: [nip]);
      await txn.delete('pengajuan', where: 'nip = ?', whereArgs: [nip]);
      await txn.delete('users', where: 'nip = ?', whereArgs: [nip]);
      return txn.delete('karyawan', where: 'id = ?', whereArgs: [id]);
    });
  }

  static Future<bool> nipExists(String nip) async {
    final db = await instance;
    final rows = await db.query(
      'karyawan',
      columns: ['id'],
      where: 'nip = ?',
      whereArgs: [nip.trim()],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  static Future<bool> emailExists(String email) async {
    final db = await instance;
    final rows = await db.query(
      'karyawan',
      columns: ['id'],
      where: 'LOWER(email) = LOWER(?)',
      whereArgs: [email.trim()],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  static Future<String> namaDariNip(String nip) async {
    final employee = await karyawanByNip(nip);
    return employee?['nama'] as String? ?? nip;
  }

  static Future<int> catatPresensi({
    required String nip,
    required String tanggal,
    required String jam,
    required bool isMasuk,
    required double latitude,
    required double longitude,
    required double akurasi,
  }) async {
    if (_parseDate(tanggal) == null) {
      throw const DbException(
        'Tanggal presensi harus menggunakan format YYYY-MM-DD.',
      );
    }
    final currentMinutes = _minutes(jam);
    if (currentMinutes < 0) {
      throw const DbException(
        'Jam presensi harus menggunakan format HH:mm yang valid.',
      );
    }
    if (!latitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        !longitude.isFinite ||
        longitude < -180 ||
        longitude > 180 ||
        !akurasi.isFinite ||
        akurasi < 0) {
      throw const DbException('Koordinat lokasi presensi tidak valid.');
    }
    final db = await instance;
    return db.transaction((txn) async {
      final employee = await txn.query(
        'karyawan',
        columns: ['nip', 'statusKaryawan'],
        where: 'nip = ?',
        whereArgs: [nip],
        limit: 1,
      );
      if (employee.isEmpty) {
        throw const DbException('Karyawan tidak ditemukan.');
      }
      if (employee.first['statusKaryawan'] != 'Aktif') {
        throw const DbException('Akun karyawan tidak aktif.');
      }
      final existing = await txn.query(
        'presensi',
        where: 'nip = ? AND tanggal = ?',
        whereArgs: [nip, tanggal],
        limit: 1,
      );
      if (existing.isEmpty) {
        if (!isMasuk) return 0;
        return txn.insert('presensi', {
          'nip': nip,
          'tanggal': tanggal,
          'jamMasuk': jam,
          'status': _statusDariJam(jam),
          'latitudeMasuk': latitude,
          'longitudeMasuk': longitude,
          'akurasiMasuk': akurasi,
        });
      }
      if (isMasuk || existing.first['jamKeluar'] != null) return 0;
      final checkIn = _minutes(existing.first['jamMasuk'] as String);
      if (checkIn < 0 || currentMinutes < checkIn) return 0;
      return txn.update(
        'presensi',
        {
          'jamKeluar': jam,
          'latitudePulang': latitude,
          'longitudePulang': longitude,
          'akurasiPulang': akurasi,
        },
        where: 'nip = ? AND tanggal = ? AND jamKeluar IS NULL',
        whereArgs: [nip, tanggal],
      );
    });
  }

  static Future<List<Map<String, Object?>>> riwayatPresensi(String nip) async {
    final db = await instance;
    return db.query(
      'presensi',
      where: 'nip = ?',
      whereArgs: [nip],
      orderBy: 'tanggal DESC',
    );
  }

  static Future<Map<String, int>> ringkasanPresensi({DateTime? tanggal}) async {
    final employees = await allKaryawan(tanggal: tanggal, hanyaAktif: true);
    final hadir = employees.where((row) => row['jamMasuk'] != null).length;
    final terlambat = employees
        .where((row) => row['statusPresensi'] == 'Terlambat')
        .length;
    final izin = employees
        .where((row) => row['statusPresensi'] == 'Izin')
        .length;
    return {
      'total': employees.length,
      'hadir': hadir,
      'tepatWaktu': hadir - terlambat,
      'terlambat': terlambat,
      'izin': izin,
      'alpha': employees
          .where((row) => row['statusPresensi'] == 'Alpha')
          .length,
    };
  }

  static Future<List<Map<String, Object?>>> laporanPresensi({
    required DateTime mulai,
    required DateTime selesai,
    String? departemen,
  }) async {
    if (selesai.isBefore(mulai)) {
      throw const DbException(
        'Tanggal akhir laporan tidak boleh sebelum tanggal mulai.',
      );
    }
    final db = await instance;
    final beginning = DateTime(mulai.year, mulai.month, mulai.day);
    final requestedEnd = DateTime(selesai.year, selesai.month, selesai.day);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final end = requestedEnd.isAfter(todayDate) ? todayDate : requestedEnd;
    final from = dateKey(beginning);
    final to = dateKey(end);
    final employees = await db.query(
      'karyawan',
      where: departemen == null || departemen.isEmpty
          ? "statusKaryawan = 'Aktif'"
          : "statusKaryawan = 'Aktif' AND departemen = ?",
      whereArgs: departemen == null || departemen.isEmpty ? null : [departemen],
      orderBy: 'nama COLLATE NOCASE',
    );
    final entries = await db.query(
      'presensi',
      where: 'tanggal >= ? AND tanggal <= ?',
      whereArgs: [from, to],
    );
    final leaves = await db.query(
      'pengajuan',
      where: "status = 'Disetujui HR' AND tanggalMulai <= ? AND tanggalSelesai >= ?",
      whereArgs: [to, from],
    );
    final entriesByNip = <String, Map<String, Map<String, Object?>>>{};
    for (final entry in entries) {
      entriesByNip.putIfAbsent(
        entry['nip'] as String,
        () => {},
      )[entry['tanggal'] as String] = entry;
    }
    final leavesByNip = <String, List<Map<String, Object?>>>{};
    for (final leave in leaves) {
      leavesByNip.putIfAbsent(leave['nip'] as String, () => []).add(leave);
    }
    return employees.map((employee) {
      final nip = employee['nip'] as String;
      final attendance =
          entriesByNip[nip] ?? const <String, Map<String, Object?>>{};
      final leaveRequests = leavesByNip[nip] ?? const [];
      var onTime = 0;
      var late = 0;
      var leave = 0;
      var alpha = 0;
      for (
        var day = beginning;
        !day.isAfter(end);
        day = day.add(const Duration(days: 1))
      ) {
        if (day.weekday > DateTime.friday) continue;
        final dayKey = dateKey(day);
        final record = attendance[dayKey];
        if (record != null) {
          if (record['status'] == 'Terlambat') {
            late++;
          } else {
            onTime++;
          }
          continue;
        }
        final hasApprovedLeave = leaveRequests.any((request) {
          final start = request['tanggalMulai'] as String;
          final finish = request['tanggalSelesai'] as String;
          return start.compareTo(dayKey) <= 0 && finish.compareTo(dayKey) >= 0;
        });
        if (hasApprovedLeave) {
          leave++;
        } else if (day.isBefore(todayDate) ||
            (day == todayDate && today.hour >= 18)) {
          alpha++;
        }
      }
      return <String, Object?>{
        ...employee,
        'tepatWaktu': onTime,
        'terlambat': late,
        'izin': leave,
        'alpha': alpha,
      };
    }).toList();
  }

  static Future<int> buatPengajuan({
    required String nip,
    required String kategori,
    required String tanggalMulai,
    required String tanggalSelesai,
    required String keterangan,
  }) async {
    const categories = {
      'Izin sakit (SKD)',
      'Cuti Tahunan',
      'Izin keperluan keluarga',
    };
    final start = _parseDate(tanggalMulai);
    final end = _parseDate(tanggalSelesai);
    if (start == null || end == null || end.isBefore(start)) {
      throw const DbException('Rentang tanggal pengajuan tidak valid.');
    }
    if (!categories.contains(kategori) || keterangan.trim().isEmpty) {
      throw const DbException('Kategori dan keterangan wajib diisi.');
    }
    final db = await instance;
    return db.transaction((txn) async {
      final employees = await txn.query(
        'karyawan',
        columns: ['alokasiCuti', 'statusKaryawan'],
        where: 'nip = ?',
        whereArgs: [nip],
        limit: 1,
      );
      if (employees.isEmpty) {
        throw const DbException('Karyawan tidak ditemukan.');
      }
      if (employees.first['statusKaryawan'] != 'Aktif') {
        throw const DbException('Akun karyawan tidak aktif.');
      }
      final overlapping = await txn.query(
        'pengajuan',
        columns: ['id'],
        where:
            "nip = ? AND status NOT LIKE 'Ditolak%' AND "
            'tanggalMulai <= ? AND tanggalSelesai >= ?',
        whereArgs: [nip, tanggalSelesai, tanggalMulai],
        limit: 1,
      );
      if (overlapping.isNotEmpty) {
        throw const DbException(
          'Tanggal tersebut sudah tercakup pengajuan lain.',
        );
      }

      if (kategori == 'Cuti Tahunan') {
        final existingRequests = await txn.query(
          'pengajuan',
          columns: ['tanggalMulai', 'tanggalSelesai'],
          where: "nip = ? AND kategori = ? AND status NOT LIKE 'Ditolak%'",
          whereArgs: [nip, kategori],
        );
        final used = existingRequests.fold<int>(
          0,
          (sum, request) =>
              sum +
              _workingDays(
                _parseDate(request['tanggalMulai'] as String)!,
                _parseDate(request['tanggalSelesai'] as String)!,
              ),
        );
        final balance = employees.first['alokasiCuti'] as int;
        final requested = _workingDays(start, end);
        if (requested > balance - used) {
          throw DbException(
            'Sisa cuti tahunan tidak mencukupi (${(balance - used).clamp(0, balance)} hari).',
          );
        }
      }

      return txn.insert('pengajuan', {
        'nip': nip,
        'kategori': kategori,
        'tanggalMulai': tanggalMulai,
        'tanggalSelesai': tanggalSelesai,
        'keterangan': keterangan.trim(),
        'status': 'Menunggu Manager',
        'createdAt': DateTime.now().toIso8601String(),
      });
    });
  }

  static int _workingDays(DateTime start, DateTime end) {
    var days = 0;
    for (
      var date = start;
      !date.isAfter(end);
      date = date.add(const Duration(days: 1))
    ) {
      if (date.weekday <= DateTime.friday) days++;
    }
    return days;
  }

  static Future<int> sisaCutiTahunan(String nip) async {
    final db = await instance;
    final employees = await db.query(
      'karyawan',
      columns: ['alokasiCuti'],
      where: 'nip = ?',
      whereArgs: [nip],
      limit: 1,
    );
    if (employees.isEmpty) throw const DbException('Karyawan tidak ditemukan.');
    final requests = await db.query(
      'pengajuan',
      columns: ['tanggalMulai', 'tanggalSelesai'],
      where: "nip = ? AND kategori = 'Cuti Tahunan' AND status NOT LIKE 'Ditolak%'",
      whereArgs: [nip],
    );
    final used = requests.fold<int>(
      0,
      (sum, request) =>
          sum +
          _workingDays(
            _parseDate(request['tanggalMulai'] as String)!,
            _parseDate(request['tanggalSelesai'] as String)!,
          ),
    );
    return ((employees.first['alokasiCuti'] as int) - used)
        .clamp(0, employees.first['alokasiCuti'] as int)
        .toInt();
  }

  static Future<List<Map<String, Object?>>> pengajuanSaya(String nip) async {
    final db = await instance;
    return db.query(
      'pengajuan',
      where: 'nip = ?',
      whereArgs: [nip],
      orderBy: 'createdAt DESC',
    );
  }

  static Future<List<Map<String, Object?>>> semuaPengajuan() async {
    final db = await instance;
    return db.rawQuery('''
      SELECT p.*, k.nama, k.jabatan, k.departemen
      FROM pengajuan p
      LEFT JOIN karyawan k ON k.nip = p.nip
      ORDER BY p.createdAt DESC
    ''');
  }

  static Future<int> putuskanPengajuan({
    required int id,
    required String actorNip,
    required String actorRole,
    required bool disetujui,
    String catatan = '',
  }) async {
    final db = await instance;
    return db.transaction((txn) async {
      final requests = await txn.query(
        'pengajuan',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (requests.isEmpty) {
        throw const DbException('Pengajuan tidak ditemukan.');
      }
      final request = requests.first;
      final status = request['status'] as String;
      final isManager = actorRole == 'Manager Divisi';
      final isHr = actorRole == 'HR';
      final isAdmin = actorRole == 'Admin';
      if (isManager || isHr) {
        final actor = await txn.query(
          'karyawan',
          columns: ['statusKaryawan'],
          where: 'nip = ?',
          whereArgs: [actorNip],
          limit: 1,
        );
        if (actor.isEmpty || actor.first['statusKaryawan'] != 'Aktif') {
          throw const DbException('Akun peninjau tidak aktif.');
        }
      }

      if (status == 'Menunggu Manager') {
        if (!isManager && !isAdmin) {
          throw const DbException(
            'Hanya manager divisi atau Admin yang dapat meninjau tahap ini.',
          );
        }
        if (isManager) {
          final departments = await txn.rawQuery(
            '''
            SELECT pemohon.departemen AS pemohon, manager.departemen AS manager
            FROM karyawan pemohon, karyawan manager
            WHERE pemohon.nip = ? AND manager.nip = ?
            ''',
            [request['nip'], actorNip],
          );
          if (departments.isEmpty ||
              departments.first['pemohon'] != departments.first['manager']) {
            throw const DbException(
              'Manager hanya dapat meninjau pengajuan dari departemennya.',
            );
          }
        }
      } else if (status == 'Siap ditinjau HR') {
        if (!isHr && !isAdmin) {
          throw const DbException(
            'Hanya HR atau Admin yang dapat meninjau tahap ini.',
          );
        }
      } else {
        throw const DbException(
          'Pengajuan ini sudah diputuskan atau tidak dapat diproses.',
        );
      }

      final now = DateTime.now().toIso8601String();
      final nextStatus = status == 'Menunggu Manager'
          ? (disetujui ? 'Siap ditinjau HR' : 'Ditolak Manager')
          : (disetujui ? 'Disetujui HR' : 'Ditolak HR');
      final changed = await txn.update(
        'pengajuan',
        {
          'status': nextStatus,
          'catatanKeputusan': catatan.trim(),
          'diputuskanOleh': actorNip,
          if (status == 'Menunggu Manager') 'managerAt': now else 'hrAt': now,
        },
        where: 'id = ? AND status = ?',
        whereArgs: [id, status],
      );
      if (changed != 1) {
        throw const DbException('Status pengajuan berubah. Muat ulang data.');
      }
      return changed;
    });
  }
}
