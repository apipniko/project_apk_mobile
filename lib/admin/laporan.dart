import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db/db.dart';
import '../theme.dart';
import '../widgets.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  DateTime _selectedDate = DateTime.now();
  String _period = 'Harian';
  String _department = 'Semua departemen';
  late Future<_ReportData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  DateTime get _periodStart {
    if (_period == 'Mingguan') {
      return _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    }
    if (_period == 'Bulanan') {
      return DateTime(_selectedDate.year, _selectedDate.month);
    }
    return DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
  }

  DateTime get _periodEnd {
    if (_period == 'Mingguan') return _periodStart.add(const Duration(days: 6));
    if (_period == 'Bulanan') {
      return DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    }
    return _periodStart;
  }

  Future<_ReportData> _load() async {
    final departments = await Db.availableDepartments();
    final employees = await Db.laporanPresensi(
      mulai: _periodStart,
      selesai: _periodEnd,
      departemen: _department == 'Semua departemen' ? null : _department,
    );
    return _ReportData(
      employees: employees,
      departments: departments
          .map((row) => row['departemen'] as String)
          .toList(),
    );
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    setState(() {
      _selectedDate = date;
      _future = _load();
    });
  }

  Future<void> _copyCsv(List<Map<String, Object?>> employees) async {
    final buffer = StringBuffer(
      'Nama,NIP,Departemen,Tepat Waktu,Terlambat,Izin,Alpha\n',
    );
    for (final employee in employees) {
      final name = (employee['nama'] as String).replaceAll('"', '""');
      final department = (employee['departemen'] as String).replaceAll(
        '"',
        '""',
      );
      buffer.writeln(
        '"$name",${employee['nip']},"$department",'
        '${employee['tepatWaktu']},${employee['terlambat']},'
        '${employee['izin']},${employee['alpha']}',
      );
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data laporan CSV disalin ke clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text(
                'Laporan kehadiran',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            )
          : null,
      body: SafeArea(
        child: FutureBuilder<_ReportData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Laporan gagal dimuat: ${snapshot.error}'),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;
            final employees = data.employees;
            final present = employees.fold<int>(
              0,
              (sum, row) => sum + (row['tepatWaktu'] as int),
            );
            final late = employees.fold<int>(
              0,
              (sum, row) => sum + (row['terlambat'] as int),
            );
            final leave = employees.fold<int>(
              0,
              (sum, row) => sum + (row['izin'] as int),
            );
            final absent = employees.fold<int>(
              0,
              (sum, row) => sum + (row['alpha'] as int),
            );
            final expected = present + late + leave + absent;
            final start = _periodStart;
            final end = _periodEnd;

            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Ringkasan untuk operasional HR',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    RoundIconButton(Icons.refresh, onTap: _reload),
                  ],
                ),
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
                      const Text(
                        'Periode laporan',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${Db.displayDate(Db.dateKey(start))} – ${Db.displayDate(Db.dateKey(end))}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Divider(color: Colors.white24, height: 24),
                      const Text(
                        'Kehadiran tercatat',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$present tepat waktu · $late terlambat',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$expected hari kerja terhitung · ${employees.length} karyawan',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        value: '$present',
                        label: 'Tepat waktu',
                        fg: AppColors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatBox(
                        value: '$late',
                        label: 'Terlambat',
                        fg: AppColors.amber,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatBox(
                        value: '$leave',
                        label: 'Izin',
                        fg: AppColors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatBox(
                        value: '$absent',
                        label: 'Alpha',
                        fg: AppColors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ReportFilter(
                        value: Db.displayDate(Db.dateKey(_selectedDate)),
                        icon: Icons.event,
                        onTap: _pickDate,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ReportDropdown(
                        value: _period,
                        options: const ['Harian', 'Mingguan', 'Bulanan'],
                        onChanged: (value) => setState(() {
                          _period = value;
                          _future = _load();
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _ReportDropdown(
                  value: _department,
                  options: ['Semua departemen', ...data.departments],
                  onChanged: (value) => setState(() {
                    _department = value;
                    _future = _load();
                  }),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Rincian per karyawan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      '${employees.length} karyawan',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (employees.isEmpty)
                  const _EmptyReport()
                else
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        const _ReportTableHeader(),
                        const Divider(color: AppColors.border, height: 1),
                        for (
                          var index = 0;
                          index < employees.length;
                          index++
                        ) ...[
                          _ReportRow(employee: employees[index]),
                          if (index != employees.length - 1)
                            const Divider(color: AppColors.border, height: 1),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                AppCard(
                  padding: const EdgeInsets.all(14),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keterangan',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'TW: Tepat waktu · T: Terlambat · I: Izin · A: Alpha',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Alpha dihitung pada hari kerja yang tidak memiliki presensi atau izin disetujui.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _copyCsv(employees),
                    icon: const Icon(Icons.copy_all_outlined, size: 20),
                    label: const Text('Salin laporan CSV'),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Mengikuti periode dan departemen yang dipilih',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReportData {
  const _ReportData({required this.employees, required this.departments});

  final List<Map<String, Object?>> employees;
  final List<String> departments;
}

class _ReportFilter extends StatelessWidget {
  const _ReportFilter({
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.primary),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ReportDropdown extends StatelessWidget {
  const _ReportDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: 46,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        items: options
            .map(
              (option) => DropdownMenuItem(
                value: option,
                child: Text(
                  option,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            )
            .toList(),
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    ),
  );
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.value, required this.label, required this.fg});

  final String value;
  final String label;
  final Color fg;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 3),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: fg,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
        ),
      ],
    ),
  );
}

class _ReportTableHeader extends StatelessWidget {
  const _ReportTableHeader();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(child: Text('Karyawan', style: _tableHeaderStyle)),
        SizedBox(
          width: 24,
          child: Text(
            'TW',
            textAlign: TextAlign.center,
            style: _tableHeaderStyle,
          ),
        ),
        SizedBox(
          width: 24,
          child: Text(
            'T',
            textAlign: TextAlign.center,
            style: _tableHeaderStyle,
          ),
        ),
        SizedBox(
          width: 24,
          child: Text(
            'I',
            textAlign: TextAlign.center,
            style: _tableHeaderStyle,
          ),
        ),
        SizedBox(
          width: 24,
          child: Text(
            'A',
            textAlign: TextAlign.center,
            style: _tableHeaderStyle,
          ),
        ),
      ],
    ),
  );
}

const _tableHeaderStyle = TextStyle(
  color: AppColors.textMuted,
  fontSize: 10,
  fontWeight: FontWeight.w700,
);

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.employee});

  final Map<String, Object?> employee;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                employee['nama'] as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                employee['jabatan'] as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        _ReportNumber(
          value: employee['tepatWaktu'] as int,
          color: AppColors.green,
        ),
        _ReportNumber(
          value: employee['terlambat'] as int,
          color: AppColors.amber,
        ),
        _ReportNumber(value: employee['izin'] as int, color: AppColors.blue),
        _ReportNumber(value: employee['alpha'] as int, color: AppColors.red),
      ],
    ),
  );
}

class _ReportNumber extends StatelessWidget {
  const _ReportNumber({required this.value, required this.color});

  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 24,
    child: Text(
      '$value',
      textAlign: TextAlign.center,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

class _EmptyReport extends StatelessWidget {
  const _EmptyReport();

  @override
  Widget build(BuildContext context) => const AppCard(
    child: Padding(
      padding: EdgeInsets.all(10),
      child: Text(
        'Tidak ada karyawan pada periode ini.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
      ),
    ),
  );
}
