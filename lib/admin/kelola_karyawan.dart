import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import '../data_dummy.dart';
import '../db/db.dart';

/// Layar "Kelola karyawan" \u2014 daftar dari SQLite + data contoh prototaip.
class KelolaKaryawanScreen extends StatefulWidget {
  const KelolaKaryawanScreen({super.key});

  @override
  State<KelolaKaryawanScreen> createState() => _KelolaKaryawanScreenState();
}

class _KelolaKaryawanScreenState extends State<KelolaKaryawanScreen> {
  late Future<List<Map<String, Object?>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  void _reload() => setState(() => _future = _load());

  Future<List<Map<String, Object?>>> _load() async {
    final dbRows = await Db.allKaryawan();
    final dariDb = dbRows.map((r) => {
          'id': r['id'],
          'nama': r['nama'],
          'nip': r['nip'],
          'departemen': r['departemen'],
          'jabatan': r['jabatan'],
          'peran': r['peran'],
          'wajahLengkap': (r['wajahLengkap'] as int) == 1,
          'dariDb': true,
        }).toList();
    final contoh = karyawanList.map((k) => {
          'id': null,
          'nama': k.nama,
          'nip': k.nip,
          'departemen': k.departemen,
          'jabatan': k.jabatan,
          'peran': 'Karyawan',
          'wajahLengkap': k.wajahLengkap,
          'dariDb': false,
          'status': k.status,
          'telatMenit': k.telatMenit,
        }).toList();
    return [...dariDb, ...contoh];
  }

  Future<void> _hapus(Map<String, Object?> k) async {
    final id = k['id'] as int?;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data contoh prototaip tidak bisa dihapus')));
      _reload();
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Hapus ${k['nama']}?'),
        content: const Text('Data akan dihapus permanen dari database.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await Db.deleteKaryawan(id);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<Map<String, Object?>>>(
          future: _future,
          builder: (context, snap) {
            final list = snap.data ?? const <Map<String, Object?>>[];
            final terlambat =
                list.where((k) => k['status'] == 'Terlambat').length;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kelola karyawan',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textDark)),
                            SizedBox(height: 4),
                            Text('Karyawan database + data contoh',
                                style:
                                    TextStyle(fontSize: 13, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      RoundIconButton(Icons.refresh, onTap: _reload),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const SearchField(hint: 'Cari nama atau NIP karyawan'),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${list.length} karyawan',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                      if (terlambat > 0)
                        Text('$terlambat terlambat',
                            style:
                                const TextStyle(fontSize: 12, color: AppColors.amber)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (snap.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    ...list.map((k) => _Tile(
                          k: k,
                          onDelete: () => _hapus(k),
                        )),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final Map<String, Object?> k;
  final VoidCallback onDelete;
  const _Tile({required this.k, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dariDb = k['dariDb'] as bool;
    final Color statusColor;
    final String statusText;
    if (dariDb) {
      statusColor = AppColors.blue;
      statusText = (k['wajahLengkap'] as bool)
          ? 'Registrasi wajah lengkap'
          : 'Menunggu registrasi wajah';
    } else if (k['status'] == 'Terlambat') {
      statusColor = AppColors.amber;
      statusText = 'Terlambat ${k['telatMenit']} menit';
    } else if (k['status'] == 'Tepat Waktu') {
      statusColor = AppColors.green;
      statusText = 'Tepat Waktu';
    } else {
      statusColor = AppColors.textMuted;
      statusText = 'Tidak ada catatan presensi';
    }
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
                  Row(
                    children: [
                      Expanded(
                        child: Text('${k['nama']}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.textDark)),
                      ),
                      if (dariDb)
                        const StatusChip('DB',
                            bg: AppColors.mintChip, fg: AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('${k['jabatan']} - ${k['departemen']}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  Text('NIP${k['nip']} - ${k['peran']}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  Text(statusText,
                      style: TextStyle(
                          fontSize: 12, color: statusColor, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            IconButton(
              onPressed: dariDb ? onDelete : null,
              icon: Icon(Icons.delete_outline,
                  size: 20,
                  color: dariDb ? AppColors.red : AppColors.border),
            ),
          ],
        ),
      ),
    );
  }
}
