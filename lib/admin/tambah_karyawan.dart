import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import '../db/db.dart';

/// Layar "Tambah karyawan" (prototaip Figma) — simpan ke SQLite.
class TambahKaryawanScreen extends StatefulWidget {
  const TambahKaryawanScreen({super.key});

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
  String mulaiBekerja = '28 Okt 2024';
  String peran = 'Karyawan';

  bool _saving = false;

  static const _departemenList = ['SDM', 'Finance', 'Engineering', 'Marketing', 'Operasional', 'Design'];
  static const _peranList = ['Karyawan', 'Manager Divisi', 'HR', 'Admin'];
  static const _jadwalList = ['Regular - Senin-Jumat', 'Shift - 3 hari kerja', 'Flexi - hasil oriented'];

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
      setState(() => mulaiBekerja =
          '${d.day} ${_bulan[d.month - 1]} ${d.year}');
    }
  }

  static const _bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (await Db.nipExists(nip.text.trim())) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('NIP ${nip.text.trim()} sudah dipakai karyawan lain')));
        }
        return;
      }
      await Db.insertKaryawan({
        'nama': nama.text.trim(),
        'nip': nip.text.trim(),
        'email': email.text.trim(),
        'departemen': departemen,
        'jabatan': jabatan,
        'jadwal': jadwal,
        'mulaiBekerja': mulaiBekerja,
        'peran': peran,
        'alokasiCuti': int.tryParse(cuti.text.trim()) ?? 0,
        'wajahLengkap': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });
      await Db.registerUser(nip.text.trim(), 'karyawan123', 'Karyawan');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Karyawan tersimpan + undangan terkirim (dummy)')));
        Navigator.of(context).pop(true);
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
                const ScreenHeader(
                  title: 'Tambah karyawan',
                  subtitle: 'Akun baru - Semua kolom wajib diisi',
                  action: RoundIconButton(Icons.close),
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
                    if (!s.contains('@')) return 'Format email tidak valid';
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
                _Label('Alokasi cuti 2024'),
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
                const Text('Alokasi awal prorata; dapat disesuaikan sesuai kebijakan perusahaan.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 20),

                const _SectionTitle('Undangan & aktivasi'),
                AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Row(
                        children: [
                          Icon(Icons.mark_email_read_outlined, size: 18, color: AppColors.primary),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('Kirim undangan lewat email',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppColors.textDark)),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text('Tautan aktivasi berlaku 72 jam. Karyawan membuat kata sandi sendiri.',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.face_retouching_natural, size: 18, color: AppColors.primary),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                                'Setelah akun diaktifkan, karyawan wajib registrasi wajah '
                                'di aplikasi sebelum dapat presensi. Admin tidak mengunggah data wajah.',
                                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Batal',
                              style: TextStyle(
                                  color: AppColors.textDark, fontWeight: FontWeight.w700)),
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
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send, size: 18),
                          label: const Text('Simpan & kirim undangan'),
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
      child: Text(text,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
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
      child: Text(text,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
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
            DropdownMenuItem(value: it, child: Text(it, style: const TextStyle(fontSize: 14))),
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
