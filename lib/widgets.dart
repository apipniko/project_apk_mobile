import 'package:flutter/material.dart';
import 'theme.dart';

/// Kartu dasar putih sudut membulat, dipakai di semua layar.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

/// Chip status kecil (Tepat Waktu / Terlambat / dll).
class StatusChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const StatusChip(this.label, {super.key, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

/// Tombol ikon bulat kecil (47x47) di pojok kanan header.
class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const RoundIconButton(this.icon, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 20, color: AppColors.textDark),
        ),
      ),
    );
  }
}

/// Header layar: judul besar + subjudul optional + aksi kanan.
class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  const ScreenHeader({super.key, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!,
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Field dropdown statis (sesuai prototype, divisi/status hanya tampilan).
class DropdownField extends StatelessWidget {
  final String hint;
  final IconData icon;
  const DropdownField({super.key, required this.hint, this.icon = Icons.expand_more});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
              child: Text(hint,
                  style: const TextStyle(fontSize: 14, color: AppColors.textDark))),
          Icon(icon, size: 20, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

/// Search bar bulat putih.
class SearchField extends StatelessWidget {
  final String hint;
  const SearchField({super.key, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
