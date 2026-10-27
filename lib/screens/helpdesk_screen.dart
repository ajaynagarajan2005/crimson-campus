import 'package:flutter/material.dart';

import '../models/student.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_page.dart';
import 'service_desk_screen.dart';
import 'ticket_form.dart';
import 'ticket_screens.dart';

class HelpdeskScreen extends StatefulWidget {
  const HelpdeskScreen({super.key});

  @override
  State<HelpdeskScreen> createState() => _HelpdeskScreenState();
}

class _HelpdeskScreenState extends State<HelpdeskScreen> {
  static const _faqs = [
    ('How do I reset my portal password?', 'Use "Forgot password" on the student portal. A reset link is sent to your university email within 5 minutes.'),
    ('How do I connect to campus Wi-Fi?', 'Join "SRU-Secure" and sign in with your student ID and portal password. Guests use "SRU-Guest".'),
    ('Where can I get a bonafide certificate?', 'Request it under Academics › Certificates on the portal. It is ready to collect from the Academic Office in 2 working days.'),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      title: 'Helpdesk',
      children: [
        const GlassContainer(
          tint: 0.18,
          child: Row(
            children: [
              IconBubble(icon: Icons.support_agent_rounded, size: 52),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How can we help?', style: AppText.h2),
                    Text('Student Services · 24/7 support', style: AppText.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _ContactTile(
              icon: Icons.call_rounded,
              label: 'Call',
              onTap: () => showCampusSnack(context, 'Calling Student Services (demo)', icon: Icons.call_rounded),
            ),
            const SizedBox(width: 10),
            _ContactTile(
              icon: Icons.mail_rounded,
              label: 'Email',
              onTap: () => showCampusSnack(context, 'Opening an email to Student Services (demo)', icon: Icons.mail_rounded),
            ),
            const SizedBox(width: 10),
            _ContactTile(
              icon: Icons.chat_rounded,
              label: 'Live chat',
              onTap: () => showCampusSnack(context, 'An agent will join the chat shortly (demo)', icon: Icons.chat_rounded),
            ),
          ],
        ),
        const SectionHeader(title: 'Service desks', icon: Icons.storefront_rounded),
        const ServiceDeskGrid(),
        const SectionHeader(title: 'Raise a ticket', icon: Icons.confirmation_number_rounded),
        const TicketForm(),
        ValueListenableBuilder<List<HelpdeskTicket>>(
          valueListenable: AppState.instance.tickets,
          builder: (context, tickets, _) {
            if (tickets.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(
                  title: 'My tickets (${tickets.length})',
                  icon: Icons.inbox_rounded,
                  actionLabel: 'View all',
                  onAction: () => Navigator.pushNamed(context, AppRoutes.ticketHistory),
                ),
                for (final ticket in tickets.take(3)) TicketTile(ticket: ticket),
                if (tickets.length > 3)
                  TextButton.icon(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.ticketHistory),
                    style: TextButton.styleFrom(foregroundColor: context.accentInk, minimumSize: const Size(48, 48)),
                    icon: const Icon(Icons.history_rounded),
                    label: Text('See all ${tickets.length} tickets'),
                  ),
              ],
            );
          },
        ),
        const SectionHeader(title: 'Common questions', icon: Icons.help_rounded),
        GlassContainer(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (final (question, answer) in _faqs)
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(question, style: AppText.title),
                    iconColor: context.accentInk,
                    collapsedIconColor: context.accentInk,
                    shape: const Border(),
                    collapsedShape: const Border(),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    expandedAlignment: Alignment.centerLeft,
                    children: [Text(answer, style: AppText.body)],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassContainer(
        height: 92,
        padding: EdgeInsets.zero,
        borderRadius: AppRadius.tile,
        alignment: Alignment.center,
        onTap: onTap,
        semanticLabel: label,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconBubble(icon: icon, size: 40),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

