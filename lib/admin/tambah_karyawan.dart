import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets.dart';
import '../db/db.dart';

/// Layar "Tambah karyawan" (prototaip Figma) — simpan ke SQLite.
class TambahKaryawanScreen extends StatefulWidget {
  const TambahKaryawanScreen({super.key, this.employee});

  final Map<String, Object?>? employee;

  @override
  State<TambahKaryawanScreen> createState() => _TambahKaryawanScreenState();
}

class _TambahKaryawanScreenState extends State<TambahKaryawanScreen> {
  final _form = GlobalKey<FormState>();
  final nama = TextEditingController();
  final nip = TextEditingController();
  final email = TextEditingController();
  final cuti = TextEditingController(text: '2');

  String departemen = 'SDM';
  String jabatan = 'Staf HR';
  String jadwal = 'Regular - Senin-Jumat';
  String mulaiBekerja = _formatDate(DateTime.now());
  String peran = 'Karyawan';
  String statusKaryawan = 'Aktif';

  bool _saving = false;

  static const _departemenList = [
    'SDM',
    'Finance',
    'Engineering',
    'Marketing',
    'Operasional',
    'Design',
  ];
  static const _peranList = ['Karyawan', 'Manager Divisi', 'HR', 'Admin'];
  static const _jadwalList = [
    'Regular - Senin-Jumat',
    'Shift - 3 hari kerja',
    'Flexi - hasil oriented',
  ];

  @override
  void initState() {
    super.initState();
    final employee = widget.employee;
    if (employee == null) return;
    nama.text = employee['nama'] as String;
    nip.text = employee['nip'] as String;
    email.text = employee['email'] as String;
    cuti.text = '${employee['alokasiCuti']}';
    departemen = employee['departemen'] as String;
    jabatan = employee['jabatan'] as String;
    jadwal = employee['jadwal'] as String;
    mulaiBekerja = employee['mulaiBekerja'] as String;
    peran = employee['peran'] as String;
    statusKaryawan = employee['statusKaryawan'] as String? ?? 'Aktif';
  }

  @override
  void dispose() {
    nama.dispose();
    nip.dispose();
    email.dispose();
    cuti.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (d != null) {
      setState(
        () => mulaiBekerja = '${d.day} ${_bulan[d.month - 1]} ${d.year}',
      );
    }
  }

  static const _bulan = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static String _formatDate(DateTime date) =>
      '${date.day} ${_bulan[date.month - 1]} ${date.year}';

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final existing = widget.employee;
      if (existing == null && await Db.nipExists(nip.text.trim())) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'NIP ${nip.text.trim()} sudah dipakai karyawan lain',
              ),
            ),
          );
        }
        return;
      }
      if (existing == null && await Db.emailExists(email.text.trim())) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email sudah digunakan karyawan lain'),
            ),
          );
        }
        return;
      }
      final data = <String, Object?>{
        'nama': nama.text.trim(),
        'email': email.text.trim(),
        'departemen': departemen,
        'jabatan': jabatan.trim(),
        'jadwal': jadwal,
        'mulaiBekerja': mulaiBekerja,
        'peran': peran,
        'statusKaryawan': statusKaryawan,
        'alokasiCuti': int.parse(cuti.text.trim()),
        'wajahLengkap': existing?['wajahLengkap'] ?? 0,
      };
      if (existing == null) {
        await Db.buatKaryawan(
          karyawan: {
            ...data,
            'nip': nip.text.trim(),
            'createdAt': DateTime.now().toIso8601String(),
          },
          password: 'karyawan123',
        );
      } else {
        await Db.updateKaryawan(nip: existing['nip'] as String, data: data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existing == null
                  ? 'Akun tersimpan. Kata sandi awal: karyawan123 (ubah setelah masuk).'
                  : 'Perubahan data karyawan berhasil disimpan.',
            ),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Karyawan gagal disimpan: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                ScreenHeader(
                  title: widget.employee == null
                      ? 'Tambah karyawan'
                      : 'Edit karyawan',
                  subtitle: widget.employee == null
                      ? 'Akun baru - Semua kolom wajib diisi'
                      : 'Perbarui data dan akses karyawan',
                  action: RoundIconButton(
                    Icons.close,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
                const _SectionTitle('Identitas karyawan'),
                _Label('Nama lengkap'),
                TextFormField(
                  controller: nama,
                  decoration: _dec('Contoh: Salsa Amelia'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                _Label('NIP'),
                TextFormField(
                  controller: nip,
                  keyboardType: TextInputType.number,
                  readOnly: widget.employee != null,
                  decoration: _dec('Nomor Induk Pegawai'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                _Label('Email kerja'),
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _dec('nama@perusahaan.id'),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return 'Wajib diisi';
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                const _SectionTitle('Penempatan & akses'),
                _Label('Departemen'),
                _DropdownPilihan(
                  value: departemen,
                  items: _departemenList,
                  onChanged: (v) => setState(() => departemen = v!),
                ),
                const SizedBox(height: 12),
                _Label('Jabatan'),
                TextFormField(
                  initialValue: jabatan,
                  decoration: _dec('Contoh: Staf HR'),
                  onChanged: (v) => jabatan = v,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                _Label('Jadwal kerja'),
                _DropdownPilihan(
                  value: jadwal,
                  items: _jadwalList,
                  onChanged: (v) => setState(() => jadwal = v!),
                ),
                const SizedBox(height: 12),
                _Label('Mulai bekerja'),
                _DropdownPilihan(
                  value: mulaiBekerja,
                  items: [mulaiBekerja],
                  icon: Icons.event,
                  onChanged: (_) => _pickDate(),
                ),
                const SizedBox(height: 12),
                _Label('Peran akun'),
                _DropdownPilihan(
                  value: peran,
                  items: _peranList,
                  onChanged: (v) => setState(() => peran = v!),
                ),
                const SizedBox(height: 12),
                _Label('Status karyawan'),
                _DropdownPilihan(
                  value: statusKaryawan,
                  items: const ['Aktif', 'Nonaktif'],
                  onChanged: (v) => setState(() => statusKaryawan = v!),
                ),
                const SizedBox(height: 12),
                _Label('Alokasi cuti ${DateTime.now().year}'),
                TextFormField(
                  controller: cuti,
                  keyboardType: TextInputType.number,
                  decoration: _dec('Jumlah hari'),
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    if (n == null || n < 0) return 'Masukkan angka yang valid';
                    return null;
                  },
                ),
                const SizedBox(height: 6),
                const Text(
                  'Alokasi awal prorata; dapat disesuaikan sesuai kebijakan perusahaan.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),

                if (widget.employee == null) ...[
                  const _SectionTitle('Akun & aktivasi'),
                  AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(
                              Icons.mark_email_read_outlined,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Akun dibuat di perangkat ini',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Email undangan belum dikirim. Kata sandi awal akun adalah karyawan123.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Karyawan dapat masuk dengan NIP dan kata sandi awal. '
                                'Pengiriman email memerlukan layanan email perusahaan.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.maybePop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send, size: 18),
                          label: Text(
                            widget.employee == null
                                ? 'Simpan karyawan'
                                : 'Simpan perubahan',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(hintText: hint);
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

class _DropdownPilihan extends StatelessWidget {
  final String value;
  final List<String> items;
  final IconData icon;
  final ValueChanged<String?> onChanged;
  const _DropdownPilihan({
    required this.value,
    required this.items,
    required this.onChanged,
    this.icon = Icons.expand_more,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: [
          for (final it in items)
            DropdownMenuItem(
              value: it,
              child: Text(it, style: const TextStyle(fontSize: 14)),
            ),
        ],
        onChanged: onChanged,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 13),
        ),
        icon: Icon(icon, size: 20, color: AppColors.textMuted),
        isExpanded: true,
      ),
    );
  }
}
