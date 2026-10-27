import 'package:flutter/material.dart';

import '../models/student.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_page.dart';

/// A campus office students can visit or ask for help.
class ServiceDesk {
  const ServiceDesk({
    required this.name,
    required this.summary,
    required this.icon,
    required this.location,
    required this.email,
    required this.openDays,
    required this.opens,
    required this.closes,
    required this.ticketCategory,
  });

  final String name;
  final String summary;
  final IconData icon;
  final String location;
  final String email;

  /// Weekdays the desk is staffed (DateTime.monday … DateTime.sunday).
  final Set<int> openDays;

  /// Opening and closing hour, 24-hour clock.
  final int opens;
  final int closes;

  /// Helpdesk category that requests from this desk are filed under.
  final String ticketCategory;

  String get hours => '${_hh(opens)} – ${_hh(closes)}';

  String get days => openDays.length == 7
      ? 'Every day'
      : openDays.containsAll(const {1, 2, 3, 4, 5, 6})
          ? 'Mon – Sat'
          : 'Mon – Fri';

  bool isOpenAt(DateTime now) =>
      openDays.contains(now.weekday) && now.hour >= opens && now.hour < closes;

  /// "Closes 18:00" while open, otherwise when it next opens.
  String statusDetail(DateTime now) {
    if (isOpenAt(now)) return 'Closes ${_hh(closes)}';
    if (openDays.contains(now.weekday) && now.hour < opens) return 'Opens ${_hh(opens)} today';
    for (var i = 1; i <= 7; i++) {
      final day = now.add(Duration(days: i));
      if (openDays.contains(day.weekday)) {
        final when = i == 1 ? 'tomorrow' : _weekdays[day.weekday - 1];
        return 'Opens ${_hh(opens)} $when';
      }
    }
    return 'Closed';
  }

  static String _hh(int hour) => '${hour.toString().padLeft(2, '0')}:00';
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
}

const _weekdaysOnly = {1, 2, 3, 4, 5};

const serviceDesks = [
  ServiceDesk(
    name: 'IT Helpdesk',
    summary: 'Student portal accounts, campus Wi-Fi, email and lab computers.',
    icon: Icons.headset_mic_rounded,
    location: 'Block A, Level 2 · Room A2-05',
    email: 'ithelpdesk@campus.example',
    openDays: _weekdaysOnly,
    opens: 9,
    closes: 18,
    ticketCategory: 'IT & Wi-Fi',
  ),
  ServiceDesk(
    name: 'Library',
    summary: 'Borrowing, study rooms, e-resources and research help.',
    icon: Icons.local_library_rounded,
    location: 'Library Building, Ground Floor',
    email: 'library@campus.example',
    openDays: {1, 2, 3, 4, 5, 6},
    opens: 8,
    closes: 22,
    ticketCategory: 'Academics',
  ),
  ServiceDesk(
    name: 'Counselling',
    summary: 'Confidential wellbeing support and counselling appointments.',
    icon: Icons.psychology_rounded,
    location: 'Student Centre, Level 1',
    email: 'counselling@campus.example',
    openDays: _weekdaysOnly,
    opens: 9,
    closes: 17,
    ticketCategory: 'Other',
  ),
  ServiceDesk(
    name: 'Accommodation',
    summary: 'Hostel rooms, maintenance requests and check-in or check-out.',
    icon: Icons.apartment_rounded,
    location: 'Hostel Office, Block H',
    email: 'hostel@campus.example',
    openDays: {1, 2, 3, 4, 5, 6},
    opens: 8,
    closes: 20,
    ticketCategory: 'Hostel',
  ),
  ServiceDesk(
    name: 'Finance Office',
    summary: 'Fee statements, payment plans, refunds and receipts.',
    icon: Icons.account_balance_wallet_rounded,
    location: 'Block B, Level 1 · Bursary counter',
    email: 'finance@campus.example',
    openDays: _weekdaysOnly,
    opens: 9,
    closes: 17,
    ticketCategory: 'Fees',
  ),
  ServiceDesk(
    name: 'Career Services',
    summary: 'Internships, CV reviews, mock interviews and job fairs.',
    icon: Icons.work_rounded,
    location: 'Student Centre, Level 2',
    email: 'careers@campus.example',
    openDays: _weekdaysOnly,
    opens: 9,
    closes: 17,
    ticketCategory: 'Other',
  ),
];

/// Grid card for one desk on the Helpdesk page; opens the desk page.
class ServiceDeskCard extends StatelessWidget {
  const ServiceDeskCard({super.key, required this.desk});

  final ServiceDesk desk;

  @override
  Widget build(BuildContext context) {
    final open = desk.isOpenAt(DateTime.now());
    return GlassContainer(
      height: 172,
      borderRadius: AppRadius.tile,
      semanticLabel: '${desk.name}, ${open ? 'open' : 'closed'}. Opens details',
      onTap: () => Navigator.pushNamed(context, AppRoutes.serviceDesk, arguments: desk),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBubble(icon: desk.icon, size: 40),
              const Spacer(),
              Icon(Icons.north_east_rounded, size: 18, color: context.accentInk),
            ],
          ),
          const Spacer(),
          Text(desk.name, style: AppText.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(desk.summary, style: AppText.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          StatusBadge(
            label: open ? 'Open now' : 'Closed',
            tone: open ? BadgeTone.success : BadgeTone.warning,
            dense: true,
          ),
        ],
      ),
    );
  }
}

/// Two-column grid of every desk.
class ServiceDeskGrid extends StatelessWidget {
  const ServiceDeskGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final columns = constraints.maxWidth >= 640 ? 3 : 2;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final desk in serviceDesks) SizedBox(width: width, child: ServiceDeskCard(desk: desk)),
          ],
        );
      },
    );
  }
}

/// Details for one desk, with a one-tap support request.
class ServiceDeskScreen extends StatefulWidget {
  const ServiceDeskScreen({super.key, required this.desk});

  final ServiceDesk desk;

  @override
  State<ServiceDeskScreen> createState() => _ServiceDeskScreenState();
}

class _ServiceDeskScreenState extends State<ServiceDeskScreen> {
  bool _requesting = false;

  Future<void> _requestSupport() async {
    final desk = widget.desk;
    setState(() => _requesting = true);
    final ticket = await runCampusAction<HelpdeskTicket>(
      context,
      () => AppState.instance.raiseTicket(
        TicketRequest(
          category: desk.ticketCategory,
          subject: '${desk.name} support request',
          message: 'Support request for ${desk.name}. Please get in touch with me.',
        ),
      ),
      success: (t) => '${desk.name} request recorded as ${t.ticketNo}.',
      icon: (_) => Icons.confirmation_number_rounded,
    );
    if (!mounted) return;
    setState(() => _requesting = false);
    if (ticket != null) {
      Navigator.pushNamed(context, AppRoutes.ticketDetail, arguments: ticket);
    }
  }

  @override
  Widget build(BuildContext context) {
    final desk = widget.desk;
    final now = DateTime.now();
    final open = desk.isOpenAt(now);
    return GlassPage(
      title: desk.name,
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconBubble(icon: desk.icon, size: 52),
                  const Spacer(),
                  StatusBadge(label: open ? 'Open now' : 'Closed', tone: open ? BadgeTone.success : BadgeTone.warning),
                ],
              ),
              const SizedBox(height: 14),
              Text(desk.name, style: AppText.h2),
              const SizedBox(height: 4),
              Text(desk.summary, style: AppText.body),
              const Divider(height: 28),
              InfoRow(icon: Icons.place_rounded, label: 'Location', value: desk.location),
              InfoRow(icon: Icons.schedule_rounded, label: 'Opening hours', value: '${desk.days} · ${desk.hours}'),
              InfoRow(icon: Icons.mail_rounded, label: 'Contact', value: desk.email),
              InfoRow(
                icon: open ? Icons.check_circle_rounded : Icons.do_not_disturb_on_rounded,
                label: 'Status',
                value: '${open ? 'Open' : 'Closed'} · ${desk.statusDetail(now)}',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PillButton(
          label: _requesting ? 'Sending request…' : 'Request support',
          icon: Icons.support_agent_rounded,
          expand: true,
          onPressed: _requesting ? null : _requestSupport,
        ),
        const SizedBox(height: 12),
        PillButton(
          label: 'Back to Helpdesk',
          icon: Icons.arrow_back_rounded,
          filled: false,
          expand: true,
          onPressed: () => Navigator.maybePop(context),
        ),
        const SizedBox(height: 12),
        Text(
          'Requests are filed under ${desk.ticketCategory} — track them in My tickets.',
          textAlign: TextAlign.center,
          style: AppText.caption,
        ),
      ],
    );
  }
}
