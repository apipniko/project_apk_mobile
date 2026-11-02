import 'package:flutter/material.dart';

import '../db/db.dart';
import '../theme.dart';
import '../widgets.dart';

class PengajuanScreen extends StatefulWidget {
  const PengajuanScreen({
    super.key,
    required this.actorNip,
    required this.actorRole,
  });

  final String actorNip;
  final String actorRole;

  @override
  State<PengajuanScreen> createState() => _PengajuanScreenState();
}

class _PengajuanScreenState extends State<PengajuanScreen> {
  final _search = TextEditingController();
  late Future<_InboxData> _future;
  String _kategori = 'Semua kategori';
  String _departemen = 'Semua divisi';

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

  Future<_InboxData> _load() async {
    final requests = await Db.semuaPengajuan();
    final departments = await Db.availableDepartments();
    final employee = widget.actorRole == 'Manager Divisi'
        ? await Db.karyawanByNip(widget.actorNip)
        : null;
    return _InboxData(
      requests: requests,
      departments: departments
          .map((row) => row['departemen'] as String)
          .toList(),
      managerDepartment: employee?['departemen'] as String?,
    );
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _review(Map<String, Object?> request, bool approve) async {
    final noteController = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'Setujui pengajuan?' : 'Tolak pengajuan?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${request['nama'] ?? request['nip']} · ${request['kategori']}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Catatan keputusan (opsional)',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              maxLines: 3,
              maxLength: 300,
              decoration: const InputDecoration(hintText: 'Tulis catatan untuk karyawan'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: approve
                ? null
                : FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(context, noteController.text.trim()),
            child: Text(approve ? 'Setujui' : 'Tolak'),
          ),
        ],
      ),
    );
    noteController.dispose();
    if (note == null || !mounted) return;
    try {
      await Db.putuskanPengajuan(
        id: request['id'] as int,
        actorNip: widget.actorNip,
        actorRole: widget.actorRole,
        disetujui: approve,
        catatan: note,
      );
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve ? 'Pengajuan berhasil disetujui.' : 'Pengajuan berhasil ditolak.',
          ),
        ),
      );
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Keputusan tidak dapat disimpan: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_InboxData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Antrean pengajuan gagal dimuat: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        final requests = data.requests.where((request) {
          if (widget.actorRole == 'Manager Divisi' &&
              (data.managerDepartment == null ||
                  request['departemen'] != data.managerDepartment)) {
            return false;
          }
          if (_kategori != 'Semua kategori' && request['kategori'] != _kategori) {
            return false;
          }
          if (_departemen != 'Semua divisi' &&
              request['departemen'] != _departemen) {
            return false;
          }
          final query = _search.text.trim().toLowerCase();
          return query.isEmpty ||
              (request['nama'] as String? ?? '').toLowerCase().contains(query) ||
              (request['nip'] as String? ?? '').toLowerCase().contains(query);
        }).toList();
        final waitingManager = requests
            .where((request) => request['status'] == 'Menunggu Manager')
            .toList();
        final waitingHr = requests
            .where((request) => request['status'] == 'Siap ditinjau HR')
            .toList();
        final history = requests
            .where((request) =>
                request['status'] != 'Menunggu Manager' &&
                request['status'] != 'Siap ditinjau HR')
            .toList();
        final canReviewManager =
            widget.actorRole == 'Manager Divisi' || widget.actorRole == 'Admin';
        final canReviewHr = widget.actorRole == 'HR' || widget.actorRole == 'Admin';
        final categories = {
          'Semua kategori',
          ...data.requests.map((request) => request['kategori'] as String),
        }.toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Row(
              children: [
                const Expanded(
                  child: ScreenHeader(
                    title: 'Pengajuan izin & cuti',
                    subtitle: 'Persetujuan berjenjang: manager, lalu HR',
                  ),
                ),
                RoundIconButton(Icons.refresh, onTap: _reload),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _QueueCard(
                    value: '${waitingHr.length}',
                    label: 'Siap ditinjau HR',
                    bg: AppColors.mintChip,
                    fg: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QueueCard(
                    value: '${waitingManager.length}',
                    label: 'Menunggu manager',
                    bg: AppColors.lavenderChip,
                    fg: AppColors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SearchField(
              hint: 'Cari nama atau NIP karyawan',
              controller: _search,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _FilterDropdown(
                    value: _kategori,
                    options: categories,
                    onChanged: (value) => setState(() => _kategori = value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterDropdown(
                    value: _departemen,
                    options: ['Semua divisi', ...data.departments],
                    onChanged: (value) => setState(() => _departemen = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SectionHeader(
              title: 'Siap ditinjau HR',
              count: waitingHr.length,
            ),
            const SizedBox(height: 10),
            if (waitingHr.isEmpty)
              const _EmptySection('Tidak ada pengajuan di antrean HR.')
            else
              ...waitingHr.map(
                (request) => _RequestCard(
                  request: request,
                  canReview: canReviewHr,
                  onApprove: () => _review(request, true),
                  onReject: () => _review(request, false),
                ),
              ),
            const SizedBox(height: 18),
            _SectionHeader(
              title: 'Menunggu Manager Divisi',
              count: waitingManager.length,
            ),
            const SizedBox(height: 10),
            if (waitingManager.isEmpty)
              const _EmptySection('Tidak ada pengajuan yang menunggu manager.')
            else
              ...waitingManager.map(
                (request) => _RequestCard(
                  request: request,
                  canReview: canReviewManager,
                  onApprove: () => _review(request, true),
                  onReject: () => _review(request, false),
                ),
              ),
            const SizedBox(height: 14),
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary, size: 19),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text(
                      'Manager Divisi meninjau terlebih dahulu. Pengajuan yang disetujui '
                      'manager diteruskan ke HR untuk keputusan akhir.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _SectionHeader(title: 'Riwayat pengajuan', count: history.length),
            const SizedBox(height: 10),
            if (history.isEmpty)
              const _EmptySection('Belum ada pengajuan yang diputuskan.')
            else
              ...history.map(
                (request) => _RequestCard(request: request),
              ),
          ],
        );
      },
    );
  }
}

class _InboxData {
  const _InboxData({
    required this.requests,
    required this.departments,
    required this.managerDepartment,
  });

  final List<Map<String, Object?>> requests;
  final List<String> departments;
  final String? managerDepartment;
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Container(
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
                .map((option) => DropdownMenuItem(
                      value: option,
                      child: Text(
                        option,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ))
                .toList(),
            onChanged: (next) {
              if (next != null) onChanged(next);
            },
          ),
        ),
      );
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({
    required this.value,
    required this.label,
    required this.bg,
    required this.fg,
  });

  final String value;
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: fg),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: fg)),
          ],
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          Text('$count pengajuan', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      );
}

class _EmptySection extends StatelessWidget {
  const _EmptySection(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
      );
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    this.canReview = false,
    this.onApprove,
    this.onReject,
  });

  final Map<String, Object?> request;
  final bool canReview;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final status = request['status'] as String;
    final rejected = status.startsWith('Ditolak');
    final approved = status == 'Disetujui HR';
    final statusColor = rejected
        ? AppColors.red
        : approved
            ? AppColors.green
            : AppColors.amber;
    final start = request['tanggalMulai'] as String;
    final end = request['tanggalSelesai'] as String;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
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
                      Text(
                        request['nama'] as String? ?? request['nip'] as String,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${request['jabatan'] ?? '-'} · NIP ${request['nip']}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: StatusChip(
                    request['kategori'] as String,
                    bg: AppColors.lavenderChip,
                    fg: AppColors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${Db.displayDate(start)} – ${Db.displayDate(end)}',
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              request['keterangan'] as String,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            if ((request['catatanKeputusan'] as String? ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Catatan: ${request['catatanKeputusan']}',
                style: TextStyle(fontSize: 12, color: statusColor),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (canReview) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.red,
                        side: const BorderSide(color: AppColors.border),
                        minimumSize: const Size.fromHeight(40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Tolak'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onApprove,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Setujui'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
