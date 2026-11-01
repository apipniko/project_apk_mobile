import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import '../data_dummy.dart';
import '../models.dart';

/// Layar "Pengajuan izin & cuti" — antrean persetujuan berjenjang + riwayat.
class PengajuanScreen extends StatelessWidget {
  const PengajuanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final siapHr = pengajuanList.where((p) => p.status == 'Siap ditinjau HR').toList();
    final menungguMgr = pengajuanList.where((p) => p.status == 'Menunggu Manager').toList();
    final riwayat = pengajuanList.where((p) => p.status == 'Disetujui HR').toList();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pengajuan izin & cuti',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark)),
                        SizedBox(height: 4),
                        Text('24 Oktober 2024 - Persetujuan berjenjang',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  RoundIconButton(Icons.filter_list, onTap: () {}),
                ],
              ),
              const SizedBox(height: 16),

              // Ringkasan antrean
              Row(
                children: [
                  Expanded(
                    child: _QueueCard(
                      value: '2',
                      label: 'Siap ditinjau HR',
                      bg: AppColors.mintChip,
                      fg: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QueueCard(
                      value: '1',
                      label: 'Menunggu manager',
                      bg: AppColors.lavenderChip,
                      fg: AppColors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const SearchField(hint: 'Cari nama atau NIP karyawan'),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Expanded(child: DropdownField(hint: 'Semua kategori')),
                  SizedBox(width: 8),
                  Expanded(child: DropdownField(hint: 'Semua divisi')),
                ],
              ),
              const SizedBox(height: 20),

              const Text('Siap ditinjau HR',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 12),
              ...siapHr.map((p) => _PengajuanCard(p, actionable: true)),

              const SizedBox(height: 20),
              const Text('Menunggu Manager Divisi',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 12),
              ...menungguMgr.map((p) => _PengajuanCard(p, actionable: false)),

              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Urutan persetujuan',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textDark)),
                    SizedBox(height: 4),
                    Text(
                        'Manager Divisi lebih dulu, baru HR. Pengajuan baru masuk ke antrean '
                        'HR setelah disetujui manager.',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Riwayat pengajuan',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  Text('Lihat semua',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              ...riwayat.map((p) => _PengajuanCard(p, actionable: false)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
          );
  }
}

class _QueueCard extends StatelessWidget {
  final String value;
  final String label;
  final Color bg;
  final Color fg;
  const _QueueCard({required this.value, required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: fg)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: fg)),
        ],
      ),
    );
  }
}

class _PengajuanCard extends StatelessWidget {
  final Pengajuan p;
  final bool actionable;
  const _PengajuanCard(this.p, {required this.actionable});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.nama,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textDark)),
                    Text('${p.jabatan} - NIP${p.nip}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              StatusChip(p.kategori, bg: AppColors.lavenderChip, fg: AppColors.blue),
            ],
          ),
          const SizedBox(height: 10),
          Text('${p.tanggal} - ${p.durasi}',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
          const SizedBox(height: 4),
          Text(p.catatan,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text('Masuk ${p.waktuMasuk}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          if (actionable) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size.fromHeight(40),
                    ),
                    child: const Text('Tolak',
                        style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Setujui'),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(p.status,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: p.status == 'Disetujui HR' ? AppColors.green : AppColors.amber)),
          ],
        ],
      ),
    );
  }
}
