import 'package:flutter/material.dart';

import '../db/db.dart';
import '../theme.dart';
import '../widgets.dart';

class UserProfilScreen extends StatelessWidget {
  const UserProfilScreen({
    super.key,
    required this.nip,
    required this.onLogout,
  });

  final String nip;
  final VoidCallback onLogout;

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Anda perlu masuk kembali untuk menggunakan RAWAN.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed == true) onLogout();
  }

  Future<void> _changePassword(BuildContext context) async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirmation = TextEditingController();
    final newPassword = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah kata sandi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: current,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Kata sandi saat ini'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: next,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Kata sandi baru'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmation,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Ulangi kata sandi baru'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (next.text.trim() != confirmation.text.trim()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Konfirmasi kata sandi tidak sama.')),
                );
                return;
              }
              Navigator.pop(context, next.text.trim());
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    final currentPassword = current.text;
    current.dispose();
    next.dispose();
    confirmation.dispose();
    if (newPassword == null || !context.mounted) return;
    try {
      await Db.changePassword(
        nip: nip,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kata sandi berhasil diperbarui.')),
      );
    } on Exception catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kata sandi gagal diperbarui: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, Object?>?>(
      future: Db.karyawanByNip(nip),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Profil gagal dimuat: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final employee = snapshot.data;
        if (employee == null) {
          return const Center(child: Text('Data profil tidak ditemukan.'));
        }
        final name = employee['nama'] as String;
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            ScreenHeader(
              title: 'Profil',
              subtitle: 'Informasi akun dan penempatan kerja',
              action: IconButton(
                tooltip: 'Keluar',
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            AppCard(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: AppColors.mintChip,
                    child: Text(
                      name.isEmpty ? '?' : name[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${employee['jabatan']} · ${employee['departemen']}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  StatusChip(
                    employee['peran'] as String,
                    bg: AppColors.mintChip,
                    fg: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi karyawan',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ProfileRow(label: 'NIP', value: employee['nip'] as String),
                  _ProfileRow(label: 'Email kerja', value: employee['email'] as String),
                  _ProfileRow(
                    label: 'Departemen',
                    value: employee['departemen'] as String,
                  ),
                  _ProfileRow(label: 'Jabatan', value: employee['jabatan'] as String),
                  _ProfileRow(label: 'Jadwal kerja', value: employee['jadwal'] as String),
                  _ProfileRow(
                    label: 'Mulai bekerja',
                    value: employee['mulaiBekerja'] as String,
                  ),
                  _ProfileRow(
                    label: 'Sisa alokasi cuti',
                    value: '${employee['alokasiCuti']} hari',
                    last: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Perubahan data pribadi dikelola oleh HR. Hubungi HR bila ada '
                      'informasi yang perlu diperbarui.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _changePassword(context),
              icon: const Icon(Icons.lock_outline),
              label: const Text('Ubah kata sandi'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value.isEmpty ? '-' : value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}
