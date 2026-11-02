import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../db/db.dart';
import '../theme.dart';
import '../widgets.dart';
import '../utils/captured_photo_cleanup_stub.dart'
    if (dart.library.io) '../utils/captured_photo_cleanup_io.dart'
    as photo_cleanup;

class UserPresensiVerificationScreen extends StatefulWidget {
  const UserPresensiVerificationScreen({
    super.key,
    required this.nip,
    required this.isMasuk,
  });

  final String nip;
  final bool isMasuk;

  @override
  State<UserPresensiVerificationScreen> createState() =>
      _UserPresensiVerificationScreenState();
}

class _UserPresensiVerificationScreenState
    extends State<UserPresensiVerificationScreen> {
  CameraController? _camera;
  bool _cameraLoading = true;
  bool _submitting = false;
  bool _success = false;
  String? _error;
  String _completedAt = '';
  double? _accuracy;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    if (kIsWeb) {
      setState(() {
        _cameraLoading = false;
        _error = 'Deteksi wajah tersedia di aplikasi Android. Presensi kamera tidak dapat disimulasikan di web.';
      });
      return;
    }
    setState(() {
      _cameraLoading = true;
      _error = null;
    });
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('noCamera', 'Kamera tidak ditemukan.');
      }
      final selected = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _camera = controller;
      setState(() => _cameraLoading = false);
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _cameraLoading = false;
        _error =
            'Kamera tidak dapat dibuka: ${error.description ?? error.code}';
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _cameraLoading = false;
        _error = 'Kamera gagal disiapkan: $error';
      });
    }
  }

  Future<Position> _currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const DbException(
        'Layanan lokasi perangkat belum aktif. Aktifkan GPS, lalu coba lagi.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const DbException(
        'Izin lokasi diperlukan untuk mencatat titik GPS presensi.',
      );
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).timeout(const Duration(seconds: 20));
  }

  Future<void> _submit() async {
    final camera = _camera;
    if (_submitting || camera == null || !camera.value.isInitialized) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    XFile? capturedImage;
    FaceDetector? detector;
    try {
      capturedImage = await camera.takePicture();
      detector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: false,
          enableLandmarks: false,
          enableContours: false,
          performanceMode: FaceDetectorMode.fast,
        ),
      );
      final faces = await detector.processImage(
        InputImage.fromFilePath(capturedImage.path),
      );
      if (faces.length != 1) {
        throw DbException(
          faces.isEmpty
              ? 'Wajah tidak terdeteksi. Posisikan wajah di dalam bingkai dan coba lagi.'
              : 'Terdeteksi lebih dari satu wajah. Pastikan hanya Anda yang terlihat.',
        );
      }

      final position = await _currentPosition();
      final now = DateTime.now();
      final time =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final changed = await Db.catatPresensi(
        nip: widget.nip,
        tanggal: Db.dateKey(now),
        jam: time,
        isMasuk: widget.isMasuk,
        latitude: position.latitude,
        longitude: position.longitude,
        akurasi: position.accuracy,
      );
      if (changed == 0) {
        throw const DbException(
          'Presensi tidak dapat dicatat. Periksa status masuk/pulang hari ini.',
        );
      }
      if (!mounted) return;
      setState(() {
        _success = true;
        _completedAt = time;
        _accuracy = position.accuracy;
      });
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Pengambilan gambar gagal: ${error.description ?? error.code}';
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      await detector?.close();
      if (capturedImage != null) {
        await photo_cleanup.deleteCapturedPhoto(capturedImage.path);
      }
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openSettings() async {
    if (_error?.contains('Layanan lokasi') == true) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.isMasuk ? 'masuk' : 'pulang';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _success ? 'Presensi berhasil' : 'Verifikasi wajah $action',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: _success
            ? _SuccessContent(
                isMasuk: widget.isMasuk,
                time: _completedAt,
                accuracy: _accuracy!,
                onDone: () => Navigator.of(context).pop(true),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  const ScreenHeader(
                    title: 'Persiapan presensi',
                    subtitle: 'Akses kamera dan lokasi diperlukan',
                  ),
                  AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.privacy_tip_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Foto hanya diproses sementara untuk mendeteksi satu wajah dan langsung dihapus. Aplikasi tidak mencocokkan identitas wajah atau menyimpan foto. Lokasi GPS dicatat bersama presensi.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _cameraContent(),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _error!,
                            style: const TextStyle(
                              color: AppColors.red,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (!kIsWeb)
                            TextButton.icon(
                              onPressed: _openSettings,
                              icon: const Icon(Icons.settings_outlined),
                              label: const Text('Buka pengaturan'),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed:
                          _submitting || _cameraLoading || _camera == null
                          ? null
                          : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.face_retouching_natural),
                      label: Text(
                        _submitting
                            ? 'Memverifikasi dan mencatat...'
                            : 'Verifikasi & catat presensi $action',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Batal'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _cameraContent() {
    if (_cameraLoading) {
      return const AppCard(
        child: SizedBox(
          height: 280,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) {
      return AppCard(
        child: SizedBox(
          height: 280,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.no_photography_outlined,
                  color: AppColors.textMuted,
                  size: 36,
                ),
                const SizedBox(height: 8),
                Text(
                  _error ?? 'Kamera belum tersedia.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _initializeCamera,
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: camera.value.aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            CameraPreview(camera),
            IgnorePointer(
              child: Center(
                child: Container(
                  width: 210,
                  height: 260,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(120),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'Posisikan satu wajah di dalam bingkai',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessContent extends StatelessWidget {
  const _SuccessContent({
    required this.isMasuk,
    required this.time,
    required this.accuracy,
    required this.onDone,
  });

  final bool isMasuk;
  final String time;
  final double accuracy;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
    children: [
      const Icon(Icons.check_circle, color: AppColors.green, size: 72),
      const SizedBox(height: 14),
      Text(
        'Presensi ${isMasuk ? 'masuk' : 'pulang'} berhasil!',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textDark,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Tercatat pukul $time · ${Db.displayDate(Db.dateKey(DateTime.now()))}',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      ),
      const SizedBox(height: 24),
      AppCard(
        child: Column(
          children: [
            _VerificationRow(
              icon: Icons.face_retouching_natural,
              label: 'Deteksi wajah',
              value: '1 wajah terdeteksi',
            ),
            const Divider(height: 22),
            _VerificationRow(
              icon: Icons.location_on_outlined,
              label: 'Lokasi GPS tercatat',
              value: 'Akurasi ±${accuracy.round()} m',
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: onDone,
          child: const Text('Kembali ke beranda'),
        ),
      ),
    ],
  );
}

class _VerificationRow extends StatelessWidget {
  const _VerificationRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 19, color: AppColors.primary),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ),
      Text(
        value,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
    ],
  );
}
