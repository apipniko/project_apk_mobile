import 'package:flutter/material.dart';
import '../theme.dart';
import '../db/db.dart';
import 'beranda_karyawan.dart';
import 'riwayat_karyawan.dart';
import 'ajukan_karyawan.dart';

/// Shell app karyawan: Beranda / Riwayat / Ajukan + logout.
/// Menggunakan lazy loading per tab agar tidak membebani database di awal.
class UserShell extends StatefulWidget {
  const UserShell({super.key, required this.nip, required this.nama, required this.onLogout});

  final String nip;
  final String nama;
  final VoidCallback onLogout;

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  int _index = 0;
  final Map<int, Widget> _cachedScreens = {};

  Widget _buildScreen(int index) {
    return _cachedScreens.putIfAbsent(index, () {
      switch (index) {
        case 0:
          return UserBerandaScreen(nip: widget.nip, nama: widget.nama);
        case 1:
          return UserRiwayatScreen(nip: widget.nip);
        case 2:
          return UserAjukanScreen(nip: widget.nip);
        default:
          return const SizedBox.shrink();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            const ['Beranda', 'Riwayat presensi', 'Pengajuan saya'][_index],
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          actions: [
            IconButton(
              tooltip: 'Keluar',
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await Db.logout();
                widget.onLogout();
              },
            ),
          ],
        ),
        body: _buildScreen(_index),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          backgroundColor: Colors.white,
          indicatorColor: AppColors.mintChip,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
                label: 'Beranda'),
            NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history_rounded, color: AppColors.primary),
                label: 'Riwayat'),
            NavigationDestination(
                icon: Icon(Icons.description_outlined),
                selectedIcon: Icon(Icons.description_rounded, color: AppColors.primary),
                label: 'Ajukan'),
          ],
        ),
      ),
    );
  }
}
