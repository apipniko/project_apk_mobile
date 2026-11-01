import 'models.dart';

/// Data contoh sesuai prototype Figma (tanpa DB) — dipakai layar beranda/presensi.
const karyawanList = <Karyawan>[
  Karyawan(
    nama: 'Bintanx', jabatan: 'UI/UX Design', nip: '96820',
    departemen: 'Design', wajahLengkap: true, jamMasuk: '08:02', jamKeluar: '17:03',
    status: 'Tepat Waktu',
  ),
  Karyawan(
    nama: 'Dimas Pratama DP', jabatan: 'Frontend Engineer', nip: '91204',
    departemen: 'Engineering', wajahLengkap: true, jamMasuk: '08:24', jamKeluar: '17:03',
    status: 'Terlambat', telatMenit: 24,
  ),
  Karyawan(
    nama: 'Dewi Lestari', jabatan: 'Finance', nip: '98096',
    departemen: 'Finance', wajahLengkap: true, jamMasuk: '07:55', jamKeluar: '17:03',
    status: 'Tepat Waktu',
  ),
  Karyawan(
    nama: 'Rian Hidayat', jabatan: 'Operasional', nip: '79911',
    departemen: 'Operasional', wajahLengkap: true,
  ),
  Karyawan(
    nama: 'Nadia Putri', jabatan: 'Marketing', nip: '95126',
    departemen: 'Marketing', wajahLengkap: false,
  ),
];

const pengajuanList = <Pengajuan>[
  Pengajuan(
    nama: 'Dewi Lestari', jabatan: 'Finance', nip: '98096',
    kategori: 'Izin sakit (SKD)', tanggal: '28-29 Okt 2024', durasi: '2 hari',
    status: 'Siap ditinjau HR', catatan: 'Surat dokter tersedia',
    waktuMasuk: '24 Okt, 10:15',
  ),
  Pengajuan(
    nama: 'Bintanx', jabatan: 'UI/UX Design', nip: '96820',
    kategori: 'Cuti Tahunan', tanggal: '30-31 Okt 2024', durasi: '2 hari',
    status: 'Menunggu Manager', catatan: 'HR belum dapat menyetujui atau menolak',
    waktuMasuk: '24 Okt, 09:40',
  ),
  Pengajuan(
    nama: 'Dimas Pratama DP', jabatan: 'Frontend Engineer', nip: '91204',
    kategori: 'Cuti Tahunan', tanggal: '21-22 Okt', durasi: '2 hari',
    status: 'Disetujui HR', catatan: 'Diputuskan 19 Okt 2024 - 15:20 WIB',
    waktuMasuk: '18 Okt, 14:02',
  ),
];
