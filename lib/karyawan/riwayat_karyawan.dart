import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import '../db/db.dart';

/// Riwayat presensi pribadi dari SQLite.
class UserRiwayatScreen extends StatelessWidget {
  const UserRiwayatScreen({super.key, required this.nip});

  final String nip;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<Map<String, Object?>>>(
          future: Db.riwayatPresensi(nip),
          builder: (context, snap) {
            final rows = snap.data ?? [];
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                const SizedBox(height: 8),
                const ScreenHeader(title: 'Riwayat presensi'),
                if (rows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(
                        child: Text('Belum ada presensi tercatat',
                            style: TextStyle(color: AppColors.textMuted))),
                  )
                else
                  ...rows.map((r) => AppCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r['tanggal'] as String,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: AppColors.textDark)),
                                  const SizedBox(height: 2),
                                  Text(
                                      'Masuk ${r['jamMasuk'] ?? '--'}  -  Pulang ${r['jamKeluar'] ?? '--'}',
                                      style: const TextStyle(
                                          fontSize: 12, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            StatusChip(
                              r['status'] as String,
                              bg: r['status'] == 'Tepat Waktu'
                                  ? AppColors.mintChip
                                  : const Color(0xFFFFF3DF),
                              fg: r['status'] == 'Tepat Waktu'
                                  ? AppColors.primary
                                  : AppColors.amber,
                            ),
                          ],
                        ),
                      )),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }
}
