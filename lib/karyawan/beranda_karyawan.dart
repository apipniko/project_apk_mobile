import 'dart:async';

import 'package:flutter/material.dart';

import '../db/db.dart';
import '../theme.dart';
import '../widgets.dart';
import 'presensi_verifikasi.dart';

class UserBerandaScreen extends StatefulWidget {
  const UserBerandaScreen({
    super.key,
    required this.nip,
    required this.nama,
    required this.onOpenAjukan,
  });

  final String nip;
  final String nama;
  final Future<void> Function() onOpenAjukan;

  @override
  State<UserBerandaScreen> createState() => _UserBerandaScreenState();
}

class _UserBerandaScreenState extends State<UserBerandaScreen> {
  String _now = '';
  Map<String, Object?>? _hariIni;
  Map<String, Object?>? _employee;
  List<Map<String, Object?>> _monthRows = [];
  int? _sisaCuti;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _loadDashboard();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    final now = DateTime.now();
    if (!mounted) return;
    setState(() {
      _now =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    });
  }

  String get _todayKey => Db.dateKey(DateTime.now());

  String get _todayLabel {
    const weekdays = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
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
    final date = DateTime.now();
    return '${weekdays[date.weekday - 1]}, ${date.day} '
        '${months[date.month - 1]} ${date.year}';
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  Future<void> _loadDashboard() async {
    try {
      final records = await Db.riwayatPresensi(widget.nip);
      final employee = await Db.karyawanByNip(widget.nip);
      if (employee == null) {
        throw const DbException('Data karyawan tidak ditemukan.');
      }
      final remainingLeave = await Db.sisaCutiTahunan(widget.nip);
      final monthKey = _todayKey.substring(0, 7);
      if (!mounted) return;
      setState(() {
        _error = null;
        _hariIni = records.firstWhere(
          (record) => record['tanggal'] == _todayKey,
          orElse: () => <String, Object?>{},
        );
        _monthRows = records
            .where(
              (record) =>
                  (record['tanggal'] as String).startsWith(monthKey) &&
                  record['jamMasuk'] != null,
            )
            .toList();
        _employee = employee;
        _sisaCuti = remainingLeave;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Ringkasan beranda gagal dimuat: $error');
    }
  }

  Future<void> _presensi(bool isMasuk) async {
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            UserPresensiVerificationScreen(nip: widget.nip, isMasuk: isMasuk),
      ),
    );
    if (completed == true && mounted) await _loadDashboard();
  }

  Future<void> _openAjukan() async {
    await widget.onOpenAjukan();
    if (mounted) await _loadDashboard();
  }

  int? _minutes(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }

  String _duration(int minutes) => '${minutes ~/ 60}j ${minutes % 60}m';

  @override
  Widget build(BuildContext context) {
    final checkIn = _hariIni?['jamMasuk'] as String?;
    final checkOut = _hariIni?['jamKeluar'] as String?;
    final checkedIn = checkIn != null;
    final checkedOut = checkOut != null;
    final lateCount = _monthRows
        .where((row) => row['status'] == 'Terlambat')
        .length;
    final checkInMinutes = _minutes(checkIn);
    final checkOutMinutes = _minutes(checkOut);
    final nowMinutes = DateTime.now().hour * 60 + DateTime.now().minute;
    final elapsed = checkInMinutes == null
        ? null
        : ((checkOutMinutes ?? nowMinutes) - checkInMinutes).clamp(0, 24 * 60);
    final attendanceStatus = checkedOut
        ? 'Selesai bekerja'
        : checkedIn
        ? 'Sedang bekerja'
        : 'Belum presensi';
    final actionLabel = checkedOut
        ? 'Presensi hari ini selesai'
        : checkedIn
        ? 'Presensi pulang'
        : 'Presensi masuk';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboard,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_greeting, ${widget.nama}',
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _todayLabel,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Pengajuan saya',
                    onPressed: _openAjukan,
                    icon: const Icon(Icons.notifications_none_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                AppCard(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.red, fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _AttendanceStatusCard(
                time: _now,
                status: attendanceStatus,
                checkIn: checkIn,
                checkOut: checkOut,
                elapsed: elapsed == null ? null : _duration(elapsed),
                actionLabel: actionLabel,
                actionEnabled: !checkedOut,
                onAction: () => _presensi(!checkedIn),
              ),
              const SizedBox(height: 12),
              _QuickActionCard(onTap: _openAjukan),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Ringkasan Bulan Ini',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${_monthLabel(DateTime.now().month)} ${DateTime.now().year}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MonthlyMetric(
                      icon: Icons.beach_access_outlined,
                      value: _sisaCuti?.toString() ?? '—',
                      label: 'Sisa cuti',
                      color: const Color(0xFF188174),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MonthlyMetric(
                      icon: Icons.event_available_outlined,
                      value: '${_monthRows.length}',
                      label: 'Hari hadir',
                      color: const Color(0xFF398D6A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MonthlyMetric(
                      icon: Icons.more_time_rounded,
                      value: '$lateCount',
                      label: 'Terlambat',
                      color: AppColors.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Ringkasan Hari Ini',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    'Update $_now',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _TodaySummaryCard(
                schedule:
                    _employee?['jadwal'] as String? ?? 'Jadwal belum diatur',
                checkIn: checkIn,
                checkOut: checkOut,
                status: attendanceStatus,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _monthLabel(int month) => const [
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
  ][month - 1];
}

class _AttendanceStatusCard extends StatelessWidget {
  const _AttendanceStatusCard({
    required this.time,
    required this.status,
    required this.checkIn,
    required this.checkOut,
    required this.elapsed,
    required this.actionLabel,
    required this.actionEnabled,
    required this.onAction,
  });

  final String time;
  final String status;
  final String? checkIn;
  final String? checkOut;
  final String? elapsed;
  final String actionLabel;
  final bool actionEnabled;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status hari ini',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, color: AppColors.green, size: 7),
                    const SizedBox(width: 5),
                    Text(
                      actionEnabled ? 'Aktif' : 'Selesai',
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _AttendanceTime(
                  label: 'MASUK',
                  value: checkIn ?? '--:--',
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'DURASI',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    elapsed ?? '--',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: FilledButton.icon(
              onPressed: actionEnabled ? onAction : null,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryDark,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.8),
                disabledForegroundColor: AppColors.textMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(
                actionEnabled ? Icons.face_retouching_natural : Icons.check,
                size: 17,
              ),
              label: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          if (checkOut != null) ...[
            const SizedBox(height: 8),
            Text(
              'Pulang $checkOut',
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}

class _AttendanceTime extends StatelessWidget {
  const _AttendanceTime({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: Colors.white60,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.lavenderChip,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.event_available_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Butuh cuti atau izin?',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Ajukan pengajuan dengan mudah',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    ),
  );
}

class _MonthlyMetric extends StatelessWidget {
  const _MonthlyMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
    child: Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
        ),
      ],
    ),
  );
}

class _TodaySummaryCard extends StatelessWidget {
  const _TodaySummaryCard({
    required this.schedule,
    required this.checkIn,
    required this.checkOut,
    required this.status,
  });

  final String schedule;
  final String? checkIn;
  final String? checkOut;
  final String status;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(13),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.lavenderChip,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jadwal kerja',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                  ),
                  Text(
                    schedule,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 18),
        Row(
          children: [
            Expanded(
              child: _TodayDetail(label: 'Masuk', value: checkIn ?? 'Belum'),
            ),
            Expanded(
              child: _TodayDetail(label: 'Pulang', value: checkOut ?? 'Belum'),
            ),
            Expanded(
              child: _TodayDetail(label: 'Status', value: status),
            ),
          ],
        ),
      ],
    ),
  );
}

class _TodayDetail extends StatelessWidget {
  const _TodayDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.textDark,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}
