import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/sample_data.dart';
import '../models/student.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'inti_logo.dart';

/// Digital student ID: photo, name, student ID, programme and a QR code of
/// the student ID. Designed at ID-card proportions and scaled to fit.
class VirtualIdCard extends StatelessWidget {
  const VirtualIdCard({super.key, required this.student});

  final Student student;

  static const double _designWidth = 360;
  static const double _designHeight = 228; // ID-1 card ratio (85.6 × 54 mm)

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Virtual student ID for ${student.name}, ID ${student.id}',
      child: LayoutBuilder(
        builder: (context, box) {
          final width = box.maxWidth.isFinite ? box.maxWidth : _designWidth;
          return SizedBox(
            width: width,
            height: width * _designHeight / _designWidth,
            child: FittedBox(
              child: SizedBox(width: _designWidth, height: _designHeight, child: _card()),
            ),
          );
        },
      ),
    );
  }

  Widget _card() {
    final photoPath = student.photoUrl;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFFF4F4)],
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            // Red header band
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primaryDark, AppColors.primary, Color(0xFFE53935)]),
              ),
              child: const Row(
                children: [
                  IntiLogo(height: 16, padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      universityName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    'STUDENT',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.6),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo
                    Container(
                      width: 92,
                      height: 116,
                      decoration: BoxDecoration(
                        color: AppColors.tintBlush,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1.5),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: photoPath == null
                          ? _placeholder()
                          : Image.network(
                              AppState.instance.api.mediaUrl(photoPath),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _placeholder(),
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF2A0606),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _field('Student ID', student.id),
                          _field('Programme', student.programme),
                          _field('Study', '${student.year} · Semester ${student.semester}'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: QrImageView(
                            data: 'INTI-STUDENT:${student.id}',
                            size: 70,
                            padding: EdgeInsets.zero,
                            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF2A0606)),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF2A0606),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B8E4A),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 1),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: 22,
              alignment: Alignment.center,
              color: AppColors.primary.withValues(alpha: 0.08),
              child: const Text(
                'Crimson Campus digital ID · present with your physical card when required',
                style: TextStyle(color: Color(0xFF6E3434), fontSize: 9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Center(
        child: Text(
          student.initials,
          style: const TextStyle(color: AppColors.primary, fontSize: 30, fontWeight: FontWeight.w800),
        ),
      );

  Widget _field(String label, String value) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(color: Color(0xFF9A5A5A), fontSize: 8.5, fontWeight: FontWeight.w700, letterSpacing: 0.8),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF2A0606), fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
}
