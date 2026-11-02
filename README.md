# RAWAN — Presensi dan Pengelolaan Karyawan

Aplikasi Flutter untuk pencatatan presensi, pengajuan izin/cuti, persetujuan berjenjang, direktori karyawan, dan laporan HR. Data disimpan pada SQLite lokal di perangkat; aplikasi ini belum memakai server atau sinkronisasi antarperangkat.

## Menjalankan aplikasi

```shell
flutter pub get
flutter run
```

Di Windows, aktifkan Developer Mode agar Flutter dapat membuat symlink plugin sebelum menjalankan `flutter pub get`.

Web menggunakan `sqflite_common_ffi_web` dan aset SQLite WASM yang sudah tersedia di folder `web/`.

## Akun demo

- Admin: `admin` / `admin123`
- Karyawan: `96820` / `karyawan123`
- Karyawan demo lainnya memakai kata sandi awal `karyawan123`.

Karyawan baru juga dibuat dengan kata sandi awal tersebut. Akun disimpan lokal; aplikasi tidak mengirim email undangan. Karyawan dapat mengganti kata sandi dari halaman Profil.

## Alur utama

- Navigasi karyawan mengikuti desain Beranda, Riwayat, dan Profil. Beranda menampilkan status presensi hari ini, ringkasan kehadiran bulanan, serta pintasan pengajuan.
- Karyawan mencatat satu kali presensi masuk dan pulang per hari setelah deteksi satu wajah dan pengambilan lokasi GPS; pengajuan izin/cuti dibuka dari pintasan Beranda.
- Riwayat presensi dapat difilter per bulan, diringkas berdasarkan status dan durasi, serta disalin sebagai CSV.
- Cuti tahunan memeriksa alokasi hari kerja dan mencegah tanggal bertumpang-tindih dengan pengajuan aktif.
- Persetujuan dilakukan oleh Manager Divisi untuk departemennya, kemudian HR/Admin memberi keputusan akhir.
- HR/Admin mengelola akun karyawan, termasuk mengaktifkan atau menonaktifkannya. Akun nonaktif tidak dapat masuk, mencatat presensi, atau membuat pengajuan.
- HR/Admin melihat ringkasan presensi serta laporan harian, mingguan, atau bulanan melalui navigasi utama.
- Laporan dapat disalin sebagai CSV dari filter yang sedang aktif.

## Catatan implementasi

Autentikasi dan penyimpanan SQLite saat ini ditujukan untuk demo/perangkat lokal. Kata sandi belum di-hash, perubahan tidak tersinkron ke perangkat lain, dan email/reset akun memerlukan backend perusahaan sebelum dipakai di produksi. Deteksi wajah hanya memastikan ada tepat satu wajah di foto; aplikasi tidak mengidentifikasi orang, melakukan pemeriksaan liveness, atau menyimpan foto. Koordinat GPS dan akurasinya disimpan lokal untuk setiap presensi masuk/pulang, tanpa pembatasan geofence kantor. Kamera dan deteksi wajah tersedia di Android; alur presensi ini tidak dapat diselesaikan melalui web.

## Pemeriksaan

```shell
flutter analyze
flutter test
```
