import 'package:flutter/material.dart';

import '../db/db.dart';
import '../theme.dart';
import '../widgets.dart';
import 'tambah_karyawan.dart';

class KelolaKaryawanScreen extends StatefulWidget {
  const KelolaKaryawanScreen({
    super.key,
    this.canDelete = true,
    this.canEdit = true,
    this.managerNip,
    this.currentActorNip,
  });

  final bool canDelete;
  final bool canEdit;
  final String? managerNip;
  final String? currentActorNip;

  @override
  State<KelolaKaryawanScreen> createState() => _KelolaKaryawanScreenState();
}

class _KelolaKaryawanScreenState extends State<KelolaKaryawanScreen> {
  final _search = TextEditingController();
  late Future<_EmployeeListData> _future;
  String _department = 'Semua divisi';
  String _status = 'Semua status';
  String _employmentStatus = 'Semua status karyawan';

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

  Future<_EmployeeListData> _load() async {
    final results = await Future.wait([
      Db.allKaryawan(),
      Db.availableDepartments(),
    ]);
    var employees = results[0];
    var departments = results[1]
        .map((row) => row['departemen'] as String)
        .toList();
    if (widget.managerNip != null) {
      final manager = await Db.karyawanByNip(widget.managerNip!);
      final department = manager?['departemen'];
      employees = employees
          .where((row) => department != null && row['departemen'] == department)
          .toList();
      departments = department == null ? [] : [department as String];
    }
    return _EmployeeListData(employees: employees, departments: departments);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _edit(Map<String, Object?> employee) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TambahKaryawanScreen(employee: employee),
      ),
    );
    if (changed == true && mounted) _reload();
  }

  Future<void> _hapus(Map<String, Object?> employee) async {
    final id = employee['id'] as int;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus ${employee['nama']}?'),
        content: const Text(
          'Akun, riwayat presensi, dan pengajuan karyawan ini akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await Db.deleteKaryawan(id);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data karyawan berhasil dihapus.')),
      );
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Data gagal dihapus: $error')));
    }
  }

  Future<void> _ubahStatus(Map<String, Object?> employee) async {
    final oldStatus = employee['statusKaryawan'] as String? ?? 'Aktif';
    final newStatus = oldStatus == 'Aktif' ? 'Nonaktif' : 'Aktif';
    if (newStatus == 'Nonaktif' && employee['nip'] == widget.currentActorNip) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda tidak dapat menonaktifkan akun sendiri.'),
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${newStatus == 'Aktif' ? 'Aktifkan' : 'Nonaktifkan'} akun ${employee['nama']}?',
        ),
        content: Text(
          newStatus == 'Nonaktif'
              ? 'Karyawan tidak dapat masuk, mencatat presensi, atau mengajukan izin sampai akunnya diaktifkan kembali.'
              : 'Karyawan akan dapat masuk dan menggunakan aplikasi kembali.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(newStatus),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await Db.setEmployeeStatus(
        nip: employee['nip'] as String,
        status: newStatus,
      );
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Akun karyawan sekarang $newStatus.')),
      );
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status akun gagal diperbarui: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_EmployeeListData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Data karyawan gagal dimuat: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        final query = _search.text.trim().toLowerCase();
        final employees = data.employees.where((employee) {
          final status = employee['statusPresensi'] as String? ?? 'Alpha';
          final accountStatus =
              employee['statusKaryawan'] as String? ?? 'Aktif';
          final attendanceStatus = accountStatus == 'Nonaktif'
              ? 'Akun nonaktif'
              : status;
          return (_department == 'Semua divisi' ||
                  employee['departemen'] == _department) &&
              (_employmentStatus == 'Semua status karyawan' ||
                  accountStatus == _employmentStatus) &&
              (_status == 'Semua status' || attendanceStatus == _status) &&
              (query.isEmpty ||
                  (employee['nama'] as String).toLowerCase().contains(query) ||
                  (employee['nip'] as String).toLowerCase().contains(query));
        }).toList();
        final late = employees
            .where((employee) => employee['statusPresensi'] == 'Terlambat')
            .length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kelola karyawan',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Direktori dan status presensi hari ini',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                RoundIconButton(Icons.refresh, onTap: _reload),
              ],
            ),
            const SizedBox(height: 16),
            SearchField(
              hint: 'Cari nama atau NIP karyawan',
              controller: _search,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            _EmployeeDropdown(
              value: _department,
              options: ['Semua divisi', ...data.departments],
              onChanged: (value) => setState(() => _department = value),
            ),
            const SizedBox(height: 8),
            _EmployeeDropdown(
              value: _employmentStatus,
              options: const ['Semua status karyawan', 'Aktif', 'Nonaktif'],
              onChanged: (value) => setState(() => _employmentStatus = value),
            ),
            const SizedBox(height: 8),
            _EmployeeDropdown(
              value: _status,
              options: const [
                'Semua status',
                'Tepat Waktu',
                'Terlambat',
                'Izin',
                'Belum presensi',
                'Alpha',
                'Tidak dijadwalkan',
                'Akun nonaktif',
              ],
              onChanged: (value) => setState(() => _status = value),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${employees.length} karyawan',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                if (late > 0)
                  Text(
                    '$late terlambat',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.amber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (employees.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: Text(
                    'Tidak ada karyawan yang cocok dengan filter.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
              )
            else
              ...employees.map(
                (employee) => _EmployeeTile(
                  employee: employee,
                  canDelete: widget.canDelete,
                  canEdit: widget.canEdit,
                  onToggleStatus: () => _ubahStatus(employee),
                  onEdit: () => _edit(employee),
                  onDelete: () => _hapus(employee),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EmployeeListData {
  const _EmployeeListData({required this.employees, required this.departments});

  final List<Map<String, Object?>> employees;
  final List<String> departments;
}

class _EmployeeDropdown extends StatelessWidget {
  const _EmployeeDropdown({
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

class _EmployeeTile extends StatelessWidget {
  const _EmployeeTile({
    required this.employee,
    required this.canDelete,
    required this.canEdit,
    required this.onToggleStatus,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, Object?> employee;
  final bool canDelete;
  final bool canEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final accountStatus = employee['statusKaryawan'] as String? ?? 'Aktif';
    final status = accountStatus == 'Nonaktif'
        ? 'Akun nonaktif'
        : employee['statusPresensi'] as String? ?? 'Alpha';
    final statusColor = status == 'Tepat Waktu'
        ? AppColors.green
        : status == 'Terlambat'
        ? AppColors.amber
        : status == 'Izin'
        ? AppColors.blue
        : AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee['nama'] as String,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${employee['jabatan']} · ${employee['departemen']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    'NIP ${employee['nip']} · ${employee['peran']}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  StatusChip(
                    accountStatus,
                    bg: accountStatus == 'Aktif'
                        ? AppColors.mintChip
                        : const Color(0xFFFDECEC),
                    fg: accountStatus == 'Aktif'
                        ? AppColors.primary
                        : AppColors.red,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    status == 'Izin' ? 'Izin disetujui' : status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (canEdit || canDelete)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canEdit)
                    IconButton(
                      tooltip: accountStatus == 'Aktif'
                          ? 'Nonaktifkan akun'
                          : 'Aktifkan akun',
                      onPressed: onToggleStatus,
                      icon: Icon(
                        accountStatus == 'Aktif'
                            ? Icons.person_off_outlined
                            : Icons.person_add_alt_1_outlined,
                        size: 19,
                        color: accountStatus == 'Aktif'
                            ? AppColors.amber
                            : AppColors.primary,
                      ),
                    ),
                  if (canEdit)
                    IconButton(
                      tooltip: 'Edit data karyawan',
                      onPressed: onEdit,
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 19,
                        color: AppColors.primary,
                      ),
                    ),
                  if (canDelete)
                    IconButton(
                      tooltip: 'Hapus karyawan',
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: AppColors.red,
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
