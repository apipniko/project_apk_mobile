import 'package:flutter/material.dart';

import '../theme.dart';
import 'ajukan_karyawan.dart';
import 'beranda_karyawan.dart';
import 'profil_karyawan.dart';
import 'riwayat_karyawan.dart';

class UserShell extends StatefulWidget {
  const UserShell({
    super.key,
    required this.nip,
    required this.nama,
    required this.onLogout,
  });

  final String nip;
  final String nama;
  final VoidCallback onLogout;

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  int _index = 0;
  final Map<int, Widget> _cachedScreens = {};

  Future<void> _openAjukan() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => UserAjukanScreen(nip: widget.nip),
      ),
    );
  }

  Widget _buildScreen(int index) {
    return _cachedScreens.putIfAbsent(index, () {
      switch (index) {
        case 0:
          return UserBerandaScreen(
            nip: widget.nip,
            nama: widget.nama,
            onOpenAjukan: _openAjukan,
          );
        case 1:
          return UserRiwayatScreen(nip: widget.nip);
        case 2:
          return UserProfilScreen(
            nip: widget.nip,
            onLogout: widget.onLogout,
          );
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
        body: _buildScreen(_index),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (index) => setState(() => _index = index),
          backgroundColor: Colors.white,
          indicatorColor: AppColors.mintChip,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(
                Icons.history_rounded,
                color: AppColors.primary,
              ),
              label: 'Riwayat',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
