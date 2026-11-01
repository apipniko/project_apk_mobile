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
      title: 'PROJECT-50JT',
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

  @override
  void initState() {
    super.initState();
    _checkSavedSession();
  }

  Future<void> _checkSavedSession() async {
    await Db.instance;
    final s = await Db.currentSession();
    if (s != null) {
      final nama = await Db.namaDariNip(s['nip'] as String);
      s['nama'] = nama;
    }
    if (mounted) {
      setState(() {
        _session = s;
        _ready = true;
      });
    }
  }

  void _onLogin(String nip, String peran, String nama) {
    setState(() {
      _session = {'nip': nip, 'peran': peran, 'nama': nama};
    });
  }

  void _onLogout() async {
    await Db.logout();
    if (mounted) {
      setState(() => _session = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_session == null) {
      return LoginScreen(onLogin: _onLogin);
    }

    final peran = _session!['peran'] as String;
    final nip = _session!['nip'] as String;
    final nama = (_session!['nama'] as String?) ?? nip;

    if (peran == 'Admin') {
      return AdminShell(onLogout: _onLogout);
    }
    return UserShell(nip: nip, nama: nama, onLogout: _onLogout);
  }
}

/// Shell admin: Beranda / Presensi (Kelola Karyawan) / Pengajuan + FAB Tambah Karyawan + Logout.
class AdminShell extends StatefulWidget {
  final VoidCallback onLogout;
  const AdminShell({super.key, required this.onLogout});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  void _openTambah() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TambahKaryawanScreen()),
    );
    setState(() {});
  }

  void _openLaporan() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LaporanScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      BerandaAdminScreen(onOpenLaporan: _openLaporan),
      const KelolaKaryawanScreen(),
      const PengajuanScreen(),
    ];

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            const ['Beranda Admin', 'Kelola Karyawan', 'Pengajuan Izin & Cuti'][_index],
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
        floatingActionButton: (_index == 0 || _index == 1)
            ? FloatingActionButton.extended(
                heroTag: 'tambah_admin',
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                onPressed: _openTambah,
                icon: const Icon(Icons.person_add_alt_1, size: 20),
                label: const Text('Tambah karyawan',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          backgroundColor: Colors.white,
          indicatorColor: AppColors.mintChip,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people_rounded, color: AppColors.primary),
              label: 'Karyawan',
            ),
            NavigationDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon: Icon(Icons.description_rounded, color: AppColors.primary),
              label: 'Pengajuan',
            ),
          ],
        ),
      ),
    );
  }
}
