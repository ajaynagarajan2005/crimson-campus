import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_page.dart';

class FeesScreen extends StatelessWidget {
  const FeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pending = feeItems.where((f) => !f.paid).toList();
    final outstanding = pending.fold<int>(0, (sum, f) => sum + f.amount);

    return GlassPage(
      title: 'Fees',
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(20),
          tint: 0.18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('OUTSTANDING BALANCE', style: AppText.overline),
              const SizedBox(height: 6),
              Text(formatInr(outstanding), style: AppText.display),
              const SizedBox(height: 6),
              Text(
                pending.isEmpty
                    ? 'You are all paid up.'
                    : '${pending.length} pending payments · next ${pending.first.due.replaceFirst('Due ', 'due on ')}',
                style: AppText.body,
              ),
              const SizedBox(height: AppSpacing.md),
              PillButton(
                label: 'Pay now',
                icon: Icons.lock_rounded,
                expand: true,
                onPressed: pending.isEmpty
                    ? null
                    : () => showCampusSnack(
                          context,
                          'Opening the secure payment portal (demo)',
                          icon: Icons.open_in_new_rounded,
                        ),
              ),
            ],
          ),
        ),
        const SectionHeader(title: 'Semester 5 statement', icon: Icons.receipt_long_rounded),
        for (final fee in feeItems)
          GlassContainer(
            margin: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                IconBubble(
                  icon: fee.paid ? Icons.check_rounded : Icons.schedule_rounded,
                  size: 40,
                  background: fee.paid ? context.selectedBg : AppColors.warning,
                  iconColor: fee.paid ? context.selectedFg : const Color(0xFF5A3B00),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fee.title, style: AppText.title),
                      Text(fee.due, style: AppText.caption),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatInr(fee.amount),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    StatusBadge(
                      label: fee.paid ? 'Paid' : 'Due soon',
                      tone: fee.paid ? BadgeTone.success : BadgeTone.warning,
                      dense: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
