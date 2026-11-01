import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../db/db.dart';

/// Beranda karyawan: jam live + tombol presensi masuk/pulang.
class UserBerandaScreen extends StatefulWidget {
  const UserBerandaScreen({super.key, required this.nip, required this.nama});

  final String nip;
  final String nama;

  @override
  State<UserBerandaScreen> createState() => _UserBerandaScreenState();
}

class _UserBerandaScreenState extends State<UserBerandaScreen> {
  String _now = '';
  Map<String, Object?>? _hariIni;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _loadHariIni();
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
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    });
  }

  String get _tanggalHariIni {
    final now = DateTime.now();
    const bulan = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    return '${now.day} ${bulan[now.month - 1]} ${now.year}';
  }

  Future<void> _loadHariIni() async {
    final rows = await Db.riwayatPresensi(widget.nip);
    if (!mounted) return;
    setState(() {
      _hariIni = rows.isEmpty
          ? null
          : rows.firstWhere((r) => r['tanggal'] == _tanggalHariIni,
              orElse: () => <String, Object?>{});
    });
  }

  Future<void> _presensi(bool isMasuk) async {
    final now = DateTime.now();
    final jam =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    await Db.catatPresensi(
      nip: widget.nip,
      tanggal: _tanggalHariIni,
      jam: jam,
      isMasuk: isMasuk,
    );
    await _loadHariIni();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isMasuk
            ? 'Presensi masuk $jam tercatat'
            : 'Presensi pulang $jam tercatat')));
  }

  @override
  Widget build(BuildContext context) {
    final sudahMasuk = _hariIni != null &&
        (_hariIni!['jamMasuk'] as String?) != null;
    final sudahPulang = _hariIni != null &&
        (_hariIni!['jamKeluar'] as String?) != null;

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Halo, ${widget.nama}',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark)),
                        const SizedBox(height: 4),
                        Text('NIP ${widget.nip}',
                            style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.mintChip,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Karyawan',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Kartu jam besar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(_now,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2)),
                    const SizedBox(height: 4),
                    Text(_tanggalHariIni,
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          sudahPulang
                              ? Icons.check_circle
                              : sudahMasuk
                                  ? Icons.schedule
                                  : Icons.login,
                          color: sudahPulang ? AppColors.green : Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          sudahPulang
                              ? 'Masuk ${_hariIni!['jamMasuk']} - Pulang ${_hariIni!['jamKeluar']}'
                              : sudahMasuk
                                  ? 'Sudah masuk ${_hariIni!['jamMasuk']}'
                                  : 'Belum presensi hari ini',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _PresensiButton(
                      label: 'Presensi Masuk',
                      icon: Icons.login_rounded,
                      enabled: !sudahMasuk,
                      onTap: () => _presensi(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PresensiButton(
                      label: 'Presensi Pulang',
                      icon: Icons.logout_rounded,
                      enabled: sudahMasuk && !sudahPulang,
                      onTap: () => _presensi(false),
                      outline: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresensiButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final bool outline;
  final VoidCallback onTap;

  const _PresensiButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.outline = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = outline
        ? OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            side: BorderSide(
                color: enabled ? AppColors.primary : AppColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            foregroundColor: enabled ? AppColors.primary : AppColors.textMuted,
          )
        : ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          );
    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
    return outline
        ? OutlinedButton(onPressed: enabled ? onTap : null, style: style, child: child)
        : ElevatedButton(onPressed: enabled ? onTap : null, style: style, child: child);
  }
}
