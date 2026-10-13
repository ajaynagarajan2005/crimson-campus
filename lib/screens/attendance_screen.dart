import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_page.dart';

const double _minimumAttendance = 0.75;

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final overall = overallAttendance;
    final atRisk = attendanceRecords.where((r) => r.ratio < _minimumAttendance).length;

    return GlassPage(
      title: 'Attendance',
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(20),
          tint: 0.18,
          child: Row(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: overall,
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                      color: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      semanticsLabel: 'Overall attendance',
                    ),
                    Center(
                      child: Text(
                        '${(overall * 100).round()}%',
                        style: AppText.h1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Overall attendance', style: AppText.title),
                    const SizedBox(height: 4),
                    const Text('University minimum is 75% per course.', style: AppText.caption),
                    const SizedBox(height: 10),
                    StatusBadge(
                      label: atRisk == 0 ? 'All courses on track' : '$atRisk course at risk',
                      tone: atRisk == 0 ? BadgeTone.success : BadgeTone.warning,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SectionHeader(title: 'By course', icon: Icons.list_alt_rounded),
        for (final record in attendanceRecords) _AttendanceTile(record: record),
      ],
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  const _AttendanceTile({required this.record});

  final CourseAttendance record;

  @override
  Widget build(BuildContext context) {
    final ratio = record.ratio;
    final (label, tone) = ratio < _minimumAttendance
        ? ('At risk', BadgeTone.warning)
        : ratio < 0.85
            ? ('Borderline', BadgeTone.info)
            : ('Good', BadgeTone.success);

    // How many more classes can be missed, or must be attended, to stay at 75%.
    final String advice;
    if (ratio >= _minimumAttendance) {
      final canMiss = (record.attended / _minimumAttendance - record.total).floor();
      advice = canMiss > 0 ? 'You can miss $canMiss more' : 'Attend every class to stay above 75%';
    } else {
      final needed = ((_minimumAttendance * record.total - record.attended) /
              (1 - _minimumAttendance))
          .ceil();
      advice = 'Attend the next $needed classes to reach 75%';
    }

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${record.code} · ${record.title}', style: AppText.title),
              ),
              StatusBadge(label: label, tone: tone),
            ],
          ),
          const SizedBox(height: 10),
          GlassProgressBar(
            value: ratio,
            color: ratio < _minimumAttendance ? AppColors.warning : Colors.white,
          ),
          const SizedBox(height: 8),
          Text(
            '${record.attended}/${record.total} classes · ${(ratio * 100).round()}% · $advice',
            style: AppText.caption,
          ),
        ],
      ),
    );
  }
}
