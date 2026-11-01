import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';

/// Layar "Laporan kehadiran" — ringkasan perPARTMENT + rincian TW/T/I/A per karyawan.
class LaporanScreen extends StatelessWidget {
  const LaporanScreen({super.key});

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
                        Text('Laporan kehadiran',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark)),
                        SizedBox(height: 4),
                        Text('Ringkasan untuk operasional HR',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  RoundIconButton(Icons.download_outlined, onTap: () {}),
                ],
              ),
              const SizedBox(height: 16),

              // Header biru tua: tingkat kehadiran
              Container(
                width: double.infinity,
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
                        Text('Periode laporan',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('24 Oktober 2024',
                            style: TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Departemen',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('Semua departemen',
                            style: TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 24),
                    const Text('Tingkat kehadiran',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('138 dari 148 karyawan',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('132 tepat waktu - 6 terlambat',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stat harian: Hadir/Izin sakit/Alpha
              Row(
                children: [
                  Expanded(child: _StatBox(value: '132', label: 'Tepat waktu', fg: AppColors.green)),
                  const SizedBox(width: 10),
                  Expanded(child: _StatBox(value: '6', label: 'Terlambat', fg: AppColors.amber)),
                  const SizedBox(width: 10),
                  Expanded(child: _StatBox(value: '2', label: 'Izin sakit', fg: AppColors.blue)),
                  const SizedBox(width: 10),
                  Expanded(child: _StatBox(value: '2', label: 'Alpha', fg: AppColors.red)),
                ],
              ),
              const SizedBox(height: 20),

              // Filter tanggal + departemen
              const Row(
                children: [
                  Expanded(child: DropdownField(hint: '24 Okt 2024', icon: Icons.event)),
                  SizedBox(width: 8),
                  Expanded(child: DropdownField(hint: 'Harian')),
                ],
              ),
              const SizedBox(height: 8),
              const DropdownField(hint: 'Semua departemen'),
              const SizedBox(height: 20),

              const Text('Rincian per karyawan',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 4),
              const Text('148 karyawan',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 12),

              // Tabel TW / T / I / A
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  children: [
                    _Row(nama: 'Bintanx', jabatan: 'UI/UX Design', tw: 18, t: 2, i: 0, a: 0),
                    _DividerRow(),
                    _Row(nama: 'Dimas Pratama DP', jabatan: 'Frontend Engineer', tw: 15, t: 5, i: 0, a: 0),
                    _DividerRow(),
                    _Row(nama: 'Dewi Lestari', jabatan: 'Finance', tw: 20, t: 0, i: 0, a: 0),
                    _DividerRow(),
                    _Row(nama: 'Rian Hidayat', jabatan: 'Operasional', tw: 12, t: 4, i: 2, a: 2),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Keterangan',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark)),
                    SizedBox(height: 6),
                    Text('TW: Tepat Waktu - T: Terlambat - I/S: Izin/Sakit - A: Alpa',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    SizedBox(height: 2),
                    Text('Angka menunjukkan jumlah hari dalam periode laporan.',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.file_download_outlined, size: 20),
                  label: const Text('Ekspor laporan (PDF atau Excel)'),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text('Mengikuti filter laporan aktif',
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

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color fg;
  const _StatBox({required this.value, required this.label, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: fg)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _DividerRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Divider(color: AppColors.border, height: 1);
}

class _Row extends StatelessWidget {
  final String nama;
  final String jabatan;
  final int tw, t, i, a;
  const _Row({required this.nama, required this.jabatan, required this.tw, required this.t, required this.i, required this.a});

  @override
  Widget build(BuildContext context) {
    TextStyle numStyle(Color c) => TextStyle(
        fontSize: 13, fontWeight: FontWeight.w700, color: c);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nama,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textDark)),
                Text(jabatan,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          Text('$tw', style: numStyle(AppColors.green)),
          const SizedBox(width: 14),
          Text('$t', style: numStyle(AppColors.amber)),
          const SizedBox(width: 14),
          Text('$i', style: numStyle(AppColors.blue)),
          const SizedBox(width: 14),
          Text('$a', style: numStyle(AppColors.red)),
        ],
      ),
    );
  }
}
