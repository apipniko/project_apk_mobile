import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db/db.dart';
import '../theme.dart';
import '../widgets.dart';

class UserRiwayatScreen extends StatefulWidget {
  const UserRiwayatScreen({super.key, required this.nip});

  final String nip;

  @override
  State<UserRiwayatScreen> createState() => _UserRiwayatScreenState();
}

class _UserRiwayatScreenState extends State<UserRiwayatScreen> {
  late Future<List<Map<String, Object?>>> _future;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  String _filter = 'Semua';

  @override
  void initState() {
    super.initState();
    _future = Db.riwayatPresensi(widget.nip);
  }

  void _reload() => setState(() => _future = Db.riwayatPresensi(widget.nip));

  void _moveMonth(int offset) {
    setState(() {
      _month = DateTime(_month.year, _month.month + offset);
    });
  }

  Future<void> _pickMonth() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Pilih bulan riwayat',
    );
    if (selected == null) return;
    setState(() => _month = DateTime(selected.year, selected.month));
  }

  Future<void> _copyCsv(List<Map<String, Object?>> rows) async {
    if (rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada data presensi untuk diekspor.'),
        ),
      );
      return;
    }
    String cell(Object? value) =>
        '"${(value?.toString() ?? '').replaceAll('"', '""')}"';
    final csv = [
      ['Tanggal', 'Jam masuk', 'Jam pulang', 'Status'],
      ...rows.map(
        (row) => [
          row['tanggal'],
          row['jamMasuk'],
          row['jamKeluar'],
          row['status'],
        ],
      ),
    ].map((row) => row.map(cell).join(',')).join('\r\n');
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV riwayat berhasil disalin.')),
    );
  }

  String get _monthLabel {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${months[_month.month - 1]} ${_month.year}';
  }

  int _minutes(String? value) {
    if (value == null) return -1;
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value);
    if (match == null) return -1;
    return int.parse(match[1]!) * 60 + int.parse(match[2]!);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, Object?>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Riwayat presensi gagal dimuat: ${snapshot.error}'),
                const SizedBox(height: 8),
                TextButton(onPressed: _reload, child: const Text('Coba lagi')),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final monthKey =
            '${_month.year.toString().padLeft(4, '0')}-${_month.month.toString().padLeft(2, '0')}';
        final monthRows = snapshot.data!
            .where((row) => (row['tanggal'] as String).startsWith(monthKey))
            .toList();
        final onTime = monthRows
            .where((row) => row['status'] == 'Tepat Waktu')
            .length;
        final late = monthRows
            .where((row) => row['status'] == 'Terlambat')
            .length;
        final minutesWorked = monthRows.fold<int>(0, (total, row) {
          final start = _minutes(row['jamMasuk'] as String?);
          final end = _minutes(row['jamKeluar'] as String?);
          return start >= 0 && end >= start ? total + end - start : total;
        });
        final rows = monthRows.where((row) {
          return _filter == 'Semua' || row['status'] == _filter;
        }).toList();

        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              ScreenHeader(
                title: 'Riwayat presensi',
                subtitle: 'Pantau kehadiran dan jam kerja',
                action: IconButton(
                  tooltip: 'Salin riwayat sebagai CSV',
                  onPressed: () => _copyCsv(monthRows),
                  icon: const Icon(Icons.download_outlined),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Bulan sebelumnya',
                      onPressed: () => _moveMonth(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _pickMonth,
                        icon: const Icon(
                          Icons.calendar_month_outlined,
                          size: 18,
                        ),
                        label: Text(
                          _monthLabel,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Bulan berikutnya',
                      onPressed: () => _moveMonth(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _HistorySummary(
                month: _monthLabel,
                daysPresent: monthRows.length,
                onTime: onTime,
                late: late,
                minutesWorked: minutesWorked,
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filter in const [
                      'Semua',
                      'Tepat Waktu',
                      'Terlambat',
                    ]) ...[
                      ChoiceChip(
                        label: Text(filter),
                        selected: _filter == filter,
                        onSelected: (_) => setState(() => _filter = filter),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: _filter == filter
                              ? Colors.white
                              : AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                        side: BorderSide(
                          color: _filter == filter
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      const SizedBox(width: 7),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Rincian ${rows.length} hari',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 10),
              if (rows.isEmpty)
                AppCard(
                  child: Text(
                    'Belum ada presensi pada $_monthLabel.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                )
              else
                ...rows.map(
                  (row) => AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.mintChip,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.event_available_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                Db.displayDate(row['tanggal'] as String),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Masuk ${row['jamMasuk'] ?? '--'}  ·  Pulang ${row['jamKeluar'] ?? '--'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              if (row['latitudeMasuk'] != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  row['latitudePulang'] == null
                                      ? 'Lokasi GPS masuk tercatat'
                                      : 'Lokasi GPS masuk dan pulang tercatat',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        StatusChip(
                          row['status'] as String,
                          bg: row['status'] == 'Tepat Waktu'
                              ? AppColors.mintChip
                              : const Color(0xFFFFF3DF),
                          fg: row['status'] == 'Tepat Waktu'
                              ? AppColors.primary
                              : AppColors.amber,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _HistorySummary extends StatelessWidget {
  const _HistorySummary({
    required this.month,
    required this.daysPresent,
    required this.onTime,
    required this.late,
    required this.minutesWorked,
  });

  final String month;
  final int daysPresent;
  final int onTime;
  final int late;
  final int minutesWorked;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.primaryDark,
      borderRadius: BorderRadius.circular(14),
    ),
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              color: Colors.white70,
              size: 17,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                month,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${minutesWorked ~/ 60}j ${minutesWorked % 60}m',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryValue(value: '$daysPresent', label: 'Hari hadir'),
            ),
            Expanded(
              child: _SummaryValue(value: '$onTime', label: 'Tepat waktu'),
            ),
            Expanded(
              child: _SummaryValue(value: '$late', label: 'Terlambat'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9)),
    ],
  );
}
