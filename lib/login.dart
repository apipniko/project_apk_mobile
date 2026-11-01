import 'package:flutter/material.dart';
import 'db/db.dart';

/// Layar Sign In bergaya desain RAWAN:
/// - Atas: header gelap (#0C1115) dengan logo "R" + nama "RAWAN" + tagline
/// - Bawah: form putih (Email, Password, Remember me, Forgot Password, Log in)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLogin});

  final void Function(String nip, String peran, String nama) onLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nip = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _remember = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nip.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    final user = await Db.login(_nip.text, _pass.text);
    if (!mounted) return;
    if (user == null) {
      setState(() { _loading = false; _error = 'Email atau password salah.'; });
      return;
    }
    final peran = user['peran'] as String;
    final nipUser = (user['nip'] as String).trim();
    final nama = await Db.namaDariNip(nipUser);
    await Db.saveSession(nipUser, peran);
    if (mounted) widget.onLogin(nipUser, peran, nama);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1115),
      body: Column(
        children: [
          // ── HEADER GELAP ──────────────────────────────────────────────
          Expanded(
            flex: 4,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    // Logo bulat
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E3D36),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text('R',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Nama app
                    const Text('RAWAN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Tagline
                    const Text('Rekam Wajah Karyawan',
                      style: TextStyle(
                        color: Color(0xFF8A9BA8),
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── FORM PUTIH (bottom sheet style) ───────────────────────────
          Expanded(
            flex: 6,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul
                    const Text('Sign In',
                      style: TextStyle(
                        color: Color(0xFF0C1115),
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text('Welcome back. Access your personal sanctuary.',
                      style: TextStyle(
                        color: Color(0xFF6B7A80),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Error
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDECEC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(_error!,
                          style: const TextStyle(color: Color(0xFFD64545), fontSize: 13)),
                      ),
                    ],

                    // Label EMAIL ADDRESS
                    const Text('EMAIL ADDRESS',
                      style: TextStyle(
                        color: Color(0xFF0C1115),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _InputField(
                      controller: _nip,
                      hint: 'NIP atau email',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 20),

                    // Label PASSWORD
                    const Text('PASSWORD',
                      style: TextStyle(
                        color: Color(0xFF0C1115),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _InputField(
                      controller: _pass,
                      hint: '••••••••',
                      icon: Icons.lock_outline,
                      obscure: _obscure,
                      suffix: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: const Color(0xFF8A9BA8),
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Remember me + Forgot password
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _remember = !_remember),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 20, height: 20,
                                decoration: BoxDecoration(
                                  color: _remember ? const Color(0xFF0E3D36) : Colors.white,
                                  border: Border.all(
                                    color: _remember ? const Color(0xFF0E3D36) : const Color(0xFFCDD5D8),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: _remember
                                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                                  : null,
                              ),
                              const SizedBox(width: 8),
                              const Text('Remember me',
                                style: TextStyle(
                                  color: Color(0xFF4A5568),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Forgot Password?',
                            style: TextStyle(
                              color: Color(0xFF0E3D36),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Tombol Log in
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0E3D36),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _loading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Log in',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                      ),
                    ),

                    // Demo hint
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFDDE7E9)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Akun demo',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0C1115),
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text('Admin: admin / admin123',
                            style: TextStyle(fontSize: 12, color: Color(0xFF6B7A80))),
                          Text('Karyawan: 96820 / karyawan123',
                            style: TextStyle(fontSize: 12, color: Color(0xFF6B7A80))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Field input bergaya RAWAN — border tipis, ikon kiri, rounded 12px
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Color(0xFF0C1115), fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFADB8C0), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF8A9BA8), size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF8FAFA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE7E9)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE7E9)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0E3D36), width: 1.5),
        ),
      ),
    );
  }
}
