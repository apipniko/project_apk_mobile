import 'package:flutter/material.dart';

import '../db/db.dart';
import '../theme.dart';
import '../widgets.dart';

class BerandaAdminScreen extends StatefulWidget {
  const BerandaAdminScreen({
    super.key,
    this.onOpenLaporan,
    this.onOpenPengajuan,
    this.actorNip = 'admin',
    this.actorRole = 'Admin',
  });

  final VoidCallback? onOpenLaporan;
  final VoidCallback? onOpenPengajuan;
  final String actorNip;
  final String actorRole;

  @override
  State<BerandaAdminScreen> createState() => _BerandaAdminScreenState();
}

class _BerandaAdminScreenState extends State<BerandaAdminScreen> {
  final _search = TextEditingController();
  late Future<_DashboardData> _future;
  String _department = 'Semua divisi';
  String _status = 'Semua status';
  int _visibleCount = 5;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<_DashboardData> _load() async {
    final results = await Future.wait([
      Db.allKaryawan(hanyaAktif: true),
      Db.availableDepartments(),
      Db.semuaPengajuan(),
    ]);
    var employees = results[0];
    var requests = results[2];
    var departments = results[1]
        .map((row) => row['departemen'] as String)
        .toList();
    if (widget.actorRole == 'Manager Divisi') {
      final manager = await Db.karyawanByNip(widget.actorNip);
      final department = manager?['departemen'];
      employees = employees
          .where((row) => department != null && row['departemen'] == department)
          .toList();
      requests = requests
          .where((row) => department != null && row['departemen'] == department)
          .toList();
      departments = department == null ? [] : [department as String];
    }
    final present = employees.where((row) => row['jamMasuk'] != null).length;
    final late = employees
        .where((row) => row['statusPresensi'] == 'Terlambat')
        .length;
    final permission = employees
        .where((row) => row['statusPresensi'] == 'Izin')
        .length;
    final absent = employees
        .where((row) => row['statusPresensi'] == 'Alpha')
        .length;
    return _DashboardData(
      summary: {
        'total': employees.length,
        'hadir': present,
        'tepatWaktu': present - late,
        'terlambat': late,
        'izin': permission,
        'alpha': absent,
      },
      employees: employees,
      departments: departments,
      pendingRequests: requests
          .where(
            (row) =>
                row['status'] == 'Menunggu Manager' ||
                row['status'] == 'Siap ditinjau HR',
          )
          .length,
    );
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Beranda gagal dimuat: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        final query = _search.text.trim().toLowerCase();
        final filtered = data.employees.where((employee) {
          final status = employee['statusPresensi'] as String? ?? 'Alpha';
          return (_department == 'Semua divisi' ||
                  employee['departemen'] == _department) &&
              (_status == 'Semua status' || status == _status) &&
              (query.isEmpty ||
                  (employee['nama'] as String).toLowerCase().contains(query) ||
                  (employee['nip'] as String).toLowerCase().contains(query));
        }).toList();
        final shown = filtered.take(_visibleCount).toList();
        final late = data.summary['terlambat'] ?? 0;
        final present = data.summary['hadir'] ?? 0;
        final permission = data.summary['izin'] ?? 0;
        final absent = data.summary['alpha'] ?? 0;

        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Beranda admin',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Pantau kehadiran seluruh tim',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.onOpenLaporan != null) ...[
                    RoundIconButton(
                      Icons.download_outlined,
                      onTap: widget.onOpenLaporan,
                    ),
                    const SizedBox(width: 8),
                  ],
                  RoundIconButton(Icons.refresh, onTap: _reload),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Presensi hari ini',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        Text(
                          Db.displayDate(Db.dateKey(DateTime.now())),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _BigStat(value: '$present', label: 'Hadir'),
                        _BigStat(value: '$late', label: 'Terlambat'),
                        _BigStat(value: '$permission', label: 'Izin'),
                        _BigStat(value: '$absent', label: 'Alpha'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: widget.onOpenPengajuan,
                borderRadius: BorderRadius.circular(18),
                child: AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.lavenderChip,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          color: AppColors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${data.pendingRequests} pengajuan menunggu',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Buka antrean persetujuan',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SearchField(
                hint: 'Cari nama atau NIP karyawan',
                controller: _search,
                onChanged: (_) => setState(() => _visibleCount = 5),
              ),
              const SizedBox(height: 8),
              _DashboardDropdown(
                value: _department,
                options: ['Semua divisi', ...data.departments],
                onChanged: (value) => setState(() {
                  _department = value;
                  _visibleCount = 5;
                }),
              ),
              const SizedBox(height: 8),
              _DashboardDropdown(
                value: _status,
                options: const [
                  'Semua status',
                  'Tepat Waktu',
                  'Terlambat',
                  'Izin',
                  'Belum presensi',
                  'Alpha',
                  'Tidak dijadwalkan',
                ],
                onChanged: (value) => setState(() {
                  _status = value;
                  _visibleCount = 5;
                }),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Direktori karyawan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    '${filtered.length} karyawan',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (shown.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Tidak ada karyawan yang cocok dengan filter.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
              else
                ...shown.map(_KaryawanTile.new),
              if (filtered.length > _visibleCount) ...[
                const SizedBox(height: 4),
                SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _visibleCount += 5),
                    child: const Text('Muat lainnya'),
                  ),
                ),
              ],
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardData {
  const _DashboardData({
    required this.summary,
    required this.employees,
    required this.departments,
    required this.pendingRequests,
  });

  final Map<String, int> summary;
  final List<Map<String, Object?>> employees;
  final List<String> departments;
  final int pendingRequests;
}

class _DashboardDropdown extends StatelessWidget {
  const _DashboardDropdown({
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
    padding: const EdgeInsets.symmetric(horizontal: 14),
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
                child: Text(option, style: const TextStyle(fontSize: 13)),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    ),
  );
}

class _BigStat extends StatelessWidget {
  const _BigStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    ),
  );
}

class _KaryawanTile extends StatelessWidget {
  const _KaryawanTile(this.employee);

  final Map<String, Object?> employee;

  @override
  Widget build(BuildContext context) {
    final status = employee['statusPresensi'] as String? ?? 'Alpha';
    final statusColor = status == 'Tepat Waktu'
        ? AppColors.green
        : status == 'Terlambat'
        ? AppColors.amber
        : status == 'Izin'
        ? AppColors.blue
        : AppColors.textMuted;
    final clockIn = employee['jamMasuk'] as String? ?? '--:--';
    final clockOut = employee['jamKeluar'] as String? ?? '--:--';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 21,
              backgroundColor: AppColors.mintChip,
              child: Text(
                (employee['nama'] as String).characters.first.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee['nama'] as String,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${employee['jabatan']} · ${employee['departemen']}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    'NIP ${employee['nip']}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    status == 'Izin' ? 'Izin disetujui' : status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (employee['jamMasuk'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 15,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$clockIn\n$clockOut',
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
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
