import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets.dart';
import '../db/db.dart';

/// Ajukan izin/cuti + daftar pengajuan pribadi (SQLite).
class UserAjukanScreen extends StatefulWidget {
  const UserAjukanScreen({super.key, required this.nip});

  final String nip;

  @override
  State<UserAjukanScreen> createState() => _UserAjukanScreenState();
}

class _UserAjukanScreenState extends State<UserAjukanScreen> {
  final keterangan = TextEditingController();
  String kategori = 'Izin sakit (SKD)';
  DateTime mulai = DateTime.now();
  DateTime selesai = DateTime.now();
  late Future<List<Map<String, Object?>>> _future;
  int? _sisaCuti;
  bool _submitting = false;

  static const _kategoriList = [
    'Izin sakit (SKD)',
    'Cuti Tahunan',
    'Izin keperluan keluarga',
  ];

  @override
  void initState() {
    super.initState();
    _future = Db.pengajuanSaya(widget.nip);
    _loadSisaCuti();
  }

  void _reload() => setState(() => _future = Db.pengajuanSaya(widget.nip));

  Future<void> _loadSisaCuti() async {
    try {
      final remaining = await Db.sisaCutiTahunan(widget.nip);
      if (mounted) setState(() => _sisaCuti = remaining);
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sisa cuti gagal dimuat: $error')));
    }
  }

  @override
  void dispose() {
    keterangan.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool isMulai}) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: isMulai ? mulai : selesai,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (d == null) return;
    setState(() {
      if (isMulai) {
        mulai = d;
        if (selesai.isBefore(mulai)) selesai = mulai;
      } else {
        selesai = d;
      }
    });
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _dateKey(DateTime date) => Db.dateKey(date);

  Future<void> _submit() async {
    if (_submitting) return;
    if (keterangan.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Keterangan wajib diisi')));
      return;
    }
    if (selesai.isBefore(mulai)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal selesai tidak boleh sebelum tanggal mulai.'),
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await Db.buatPengajuan(
        nip: widget.nip,
        kategori: kategori,
        tanggalMulai: _dateKey(mulai),
        tanggalSelesai: _dateKey(selesai),
        keterangan: keterangan.text.trim(),
      );
      keterangan.clear();
      _reload();
      await _loadSisaCuti();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengajuan terkirim ke manager divisi')),
      );
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pengajuan gagal dikirim: $error')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pengajuan saya',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, Object?>>>(
          future: _future,
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(
                child: Text('Pengajuan gagal dimuat: ${snap.error}'),
              );
            }
            final rows = snap.data ?? [];
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                const SizedBox(height: 8),
                const ScreenHeader(
                  title: 'Ajukan izin & cuti',
                  subtitle: 'Persetujuan berjenjang: manager divisi, lalu HR',
                ),
                const SizedBox(height: 8),

                // Form pengajuan
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kategori',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final k in _kategoriList)
                            ChoiceChip(
                              label: Text(
                                k,
                                style: const TextStyle(fontSize: 12),
                              ),
                              selected: kategori == k,
                              selectedColor: AppColors.mintChip,
                              labelStyle: TextStyle(
                                color: kategori == k
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                              side: BorderSide(
                                color: kategori == k
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                              onSelected: (_) => setState(() => kategori = k),
                            ),
                        ],
                      ),
                      if (kategori == 'Cuti Tahunan') ...[
                        const SizedBox(height: 8),
                        Text(
                          _sisaCuti == null
                              ? 'Memuat sisa cuti...'
                              : 'Sisa alokasi cuti tahunan: $_sisaCuti hari kerja',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _TanggalBox(
                              label: 'Mulai',
                              value: _fmt(mulai),
                              onTap: () => _pick(isMulai: true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _TanggalBox(
                              label: 'Selesai',
                              value: _fmt(selesai),
                              onTap: () => _pick(isMulai: false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: keterangan,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText:
                              'Keterangan (contoh: surat dokter terlampir)',
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Kirim pengajuan'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Pengajuan saya',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                if (rows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 24, bottom: 24),
                    child: Center(
                      child: Text(
                        'Belum ada pengajuan',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  ...rows.map(
                    (r) => AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  r['kategori'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                              StatusChip(
                                r['status'] as String,
                                bg: r['status'] == 'Disetujui HR'
                                    ? const Color(0xFFE8F6EE)
                                    : (r['status'] as String).startsWith(
                                        'Ditolak',
                                      )
                                    ? const Color(0xFFFDECEC)
                                    : const Color(0xFFFFF3DF),
                                fg: r['status'] == 'Disetujui HR'
                                    ? AppColors.green
                                    : (r['status'] as String).startsWith(
                                        'Ditolak',
                                      )
                                    ? AppColors.red
                                    : AppColors.amber,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${Db.displayDate(r['tanggalMulai'] as String)} s.d. '
                            '${Db.displayDate(r['tanggalSelesai'] as String)} - '
                            '${r['keterangan']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TanggalBox extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _TanggalBox({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.event, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
