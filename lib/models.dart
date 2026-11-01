/// Model data. Field DB dipakai sqflite; field presensi dummy dipakai layar beranda.
class Karyawan {
  final int? id; // null = belum tersimpan di DB
  final String nama;
  final String nip;
  final String email;
  final String departemen;
  final String jabatan;
  final String jadwal;
  final String mulaiBekerja;
  final String peran;
  final int alokasiCuti;
  final bool wajahLengkap;

  // Field tampilan presensi (dummy, dari prototype) — tidak masuk DB.
  final String? jamMasuk;
  final String? jamKeluar;
  final String? status;
  final int? telatMenit;

  const Karyawan({
    this.id,
    required this.nama,
    required this.nip,
    this.email = '',
    this.departemen = '',
    required this.jabatan,
    this.jadwal = 'Regular - Senin-Jumat',
    this.mulaiBekerja = '',
    this.peran = 'Karyawan',
    this.alokasiCuti = 0,
    this.wajahLengkap = false,
    this.jamMasuk,
    this.jamKeluar,
    this.status,
    this.telatMenit,
  });

  Karyawan copyWith({int? id, bool? wajahLengkap}) => Karyawan(
        id: id ?? this.id,
        nama: nama,
        nip: nip,
        email: email,
        departemen: departemen,
        jabatan: jabatan,
        jadwal: jadwal,
        mulaiBekerja: mulaiBekerja,
        peran: peran,
        alokasiCuti: alokasiCuti,
        wajahLengkap: wajahLengkap ?? this.wajahLengkap,
        jamMasuk: jamMasuk,
        jamKeluar: jamKeluar,
        status: status,
        telatMenit: telatMenit,
      );
}

class Pengajuan {
  final String nama;
  final String jabatan;
  final String nip;
  final String kategori;
  final String tanggal;
  final String durasi;
  final String status;
  final String catatan;
  final String waktuMasuk;

  const Pengajuan({
    required this.nama,
    required this.jabatan,
    required this.nip,
    required this.kategori,
    required this.tanggal,
    required this.durasi,
    required this.status,
    required this.catatan,
    required this.waktuMasuk,
  });
}
