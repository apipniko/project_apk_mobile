import 'package:flutter/material.dart';

import 'db/db.dart';
import 'admin/beranda_admin.dart';
import 'admin/kelola_karyawan.dart';
import 'admin/pengajuan.dart';
import 'admin/laporan.dart';
import 'admin/tambah_karyawan.dart';
import 'login.dart';
import 'karyawan/shell_karyawan.dart';
import 'theme.dart';

/// PROJECT-50JT — Aplikasi presensi karyawan (admin + karyawan).
/// Transisi cepat tanpa query ganda/reload session berulang.
void main() {
  runApp(const Project50jtApp());
}

class Project50jtApp extends StatelessWidget {
  const Project50jtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RAWAN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const RootGate(),
    );
  }
}

/// Cek sesi tersimpan saat pertama kali buka app.
class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  Map<String, Object?>? _session;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkSavedSession();
  }

  Future<void> _checkSavedSession() async {
    try {
      await Db.instance;
      final session = await Db.currentSession();
      var validSession = session;
      if (session != null) {
        final nip = session['nip'] as String;
        final employee = await Db.karyawanByNip(nip);
        if (employee != null) {
          if (employee['statusKaryawan'] != 'Aktif') {
            await Db.logout();
            validSession = null;
          } else {
            session['nama'] = employee['nama'];
          }
        } else if (session['peran'] != 'Admin') {
          await Db.logout();
          validSession = null;
        } else {
          session['nama'] = await Db.namaDariNip(nip);
        }
      }
      if (mounted) {
        setState(() {
          _session = validSession;
          _error = null;
          _ready = true;
        });
      }
    } on Exception catch (error) {
      if (mounted) {
        setState(() {
          _error = 'Data aplikasi gagal dibuka: $error';
          _ready = true;
        });
      }
    }
  }

  void _onLogin(String nip, String peran, String nama) {
    setState(() {
      _session = {'nip': nip, 'peran': peran, 'nama': nama};
    });
  }

  Future<void> _onLogout() async {
    try {
      await Db.logout();
      if (mounted) setState(() => _session = null);
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Tidak dapat keluar: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.red, size: 36),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _ready = false;
                      _error = null;
                    });
                    _checkSavedSession();
                  },
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_session == null) {
      return LoginScreen(onLogin: _onLogin);
    }

    final peran = _session!['peran'] as String;
    final nip = _session!['nip'] as String;
    final nama = (_session!['nama'] as String?) ?? nip;

    if (peran != 'Karyawan') {
      return AdminShell(onLogout: _onLogout, actorRole: peran, actorNip: nip);
    }
    return UserShell(nip: nip, nama: nama, onLogout: _onLogout);
  }
}

/// Shell admin: Beranda / Presensi (Kelola Karyawan) / Pengajuan + FAB Tambah Karyawan + Logout.
class AdminShell extends StatefulWidget {
  final VoidCallback onLogout;
  final String actorRole;
  final String actorNip;

  const AdminShell({
    super.key,
    required this.onLogout,
    this.actorRole = 'Admin',
    this.actorNip = 'admin',
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;
  int _refreshEpoch = 0;

  void _openTambah() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const TambahKaryawanScreen()));
    if (mounted) {
      setState(() => _refreshEpoch++);
    }
  }

  void _openLaporan() {
    setState(() => _index = 3);
  }

  @override
  Widget build(BuildContext context) {
    final canViewReports = widget.actorRole != 'Manager Divisi';
    final screens = [
      BerandaAdminScreen(
        key: ValueKey('beranda_$_refreshEpoch'),
        onOpenLaporan: widget.actorRole == 'Manager Divisi'
            ? null
            : _openLaporan,
        onOpenPengajuan: () => setState(() => _index = 2),
        actorNip: widget.actorNip,
        actorRole: widget.actorRole,
      ),
      KelolaKaryawanScreen(
        key: ValueKey('karyawan_$_refreshEpoch'),
        canDelete: widget.actorRole == 'Admin' || widget.actorRole == 'HR',
        canEdit: widget.actorRole == 'Admin' || widget.actorRole == 'HR',
        currentActorNip: widget.actorNip,
        managerNip: widget.actorRole == 'Manager Divisi'
            ? widget.actorNip
            : null,
      ),
      PengajuanScreen(
        key: ValueKey('pengajuan_$_refreshEpoch'),
        actorNip: widget.actorNip,
        actorRole: widget.actorRole,
      ),
      canViewReports
          ? const LaporanScreen(showAppBar: false)
          : const SizedBox.shrink(),
    ];
    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
        label: 'Beranda',
      ),
      const NavigationDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people_rounded, color: AppColors.primary),
        label: 'Karyawan',
      ),
      const NavigationDestination(
        icon: Icon(Icons.description_outlined),
        selectedIcon: Icon(Icons.description_rounded, color: AppColors.primary),
        label: 'Pengajuan',
      ),
      if (canViewReports)
        const NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart_rounded, color: AppColors.primary),
          label: 'Laporan',
        ),
    ];

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            [
              widget.actorRole == 'HR' ? 'Beranda HR' : 'Beranda Admin',
              'Kelola Karyawan',
              'Pengajuan Izin & Cuti',
              'Laporan Kehadiran',
            ][_index],
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          actions: [
            IconButton(
              tooltip: 'Keluar',
              icon: const Icon(Icons.logout),
              onPressed: widget.onLogout,
            ),
          ],
        ),
        body: IndexedStack(index: _index, children: screens),
        floatingActionButton:
            (widget.actorRole == 'Admin' || widget.actorRole == 'HR') &&
                (_index == 0 || _index == 1)
            ? FloatingActionButton.extended(
                heroTag: 'tambah_admin',
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                onPressed: _openTambah,
                icon: const Icon(Icons.person_add_alt_1, size: 20),
                label: const Text(
                  'Tambah karyawan',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          backgroundColor: Colors.white,
          indicatorColor: AppColors.mintChip,
          destinations: destinations,
        ),
      ),
    );
  }
}
