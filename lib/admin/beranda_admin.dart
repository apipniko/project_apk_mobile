import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import '../data_dummy.dart';
import '../models.dart';

/// Layar "Beranda admin" — ringkasan hari ini + direktori karyawan.
/// Angka & warna persis prototype Figma PROJECT-50JT.
class BerandaAdminScreen extends StatelessWidget {
  final VoidCallback? onOpenLaporan;
  const BerandaAdminScreen({super.key, this.onOpenLaporan});

  @override
  Widget build(BuildContext context) {
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
                        Text('Beranda admin',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark)),
                        SizedBox(height: 4),
                        Text('Pantau kehadiran seluruh tim',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  RoundIconButton(Icons.download_outlined, onTap: onOpenLaporan),
                ],
              ),
              const SizedBox(height: 16),

              // Kartu ringkasan gelap (teal tua) — presensi hari ini
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Presensi hari ini',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Text('24 Okt 2024',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        _BigStat(value: '138', label: 'Hadir'),
                        SizedBox(width: 20),
                        _BigStat(value: '7', label: 'Terlambat'),
                        SizedBox(width: 20),
                        _BigStat(value: '3', label: 'Izin'),
                        SizedBox(width: 20),
                        _BigStat(value: '3', label: 'Alpha'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Kartu pengajuan menunggu
              AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.lavenderChip,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.description_outlined, color: AppColors.blue),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('2 pengajuan menunggu',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.textDark)),
                          SizedBox(height: 2),
                          Text('1 siap ditinjau HR - 1 menunggu manager',
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Search + filter
              const Row(
                children: [
                  Expanded(flex: 2, child: SearchField(hint: 'Cari nama atau NIP karyawan')),
                  SizedBox(width: 8),
                  Expanded(flex: 1, child: DropdownField(hint: 'Semua divisi')),
                ],
              ),
              const SizedBox(height: 8),
              const DropdownField(hint: 'Semua status'),
              const SizedBox(height: 20),

              const Text('Direktori karyawan',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 12),
              ...karyawanList.map(_KaryawanTile.new),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Muat lainnya',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text('Menampilkan 5 dari 151 akun - Diurut Nama A-Z',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
          );
  }
}

class _BigStat extends StatelessWidget {
  final String value;
  final String label;
  const _BigStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _KaryawanTile extends StatelessWidget {
  final Karyawan k;
  const _KaryawanTile(this.k);

  @override
  Widget build(BuildContext context) {
    final statusChip = k.wajahLengkap
        ? const StatusChip('Registrasi wajah lengkap',
            bg: AppColors.mintChip, fg: AppColors.primary)
        : const StatusChip('Menunggu registrasi wajah',
            bg: Color(0xFFFFF3DF), fg: AppColors.amber);
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
                    Text(k.nama,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textDark)),
                    const SizedBox(height: 2),
                    Text(k.jabatan,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              statusChip,
            ],
          ),
          if (k.jamMasuk != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text('${k.jamMasuk} - ${k.jamKeluar}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                if (k.telatMenit != null) ...[
                  const SizedBox(width: 8),
                  Text('Terlambat ${k.telatMenit} menit',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.amber, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Text('Tidak ada catatan presensi',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }
}
