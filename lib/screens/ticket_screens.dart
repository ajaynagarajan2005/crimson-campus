import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/student.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_page.dart';

/// Icon for each helpdesk category.
IconData ticketCategoryIcon(String category) => switch (category) {
      'IT & Wi-Fi' => Icons.wifi_rounded,
      'Academics' => Icons.school_rounded,
      'Hostel' => Icons.apartment_rounded,
      'Fees' => Icons.account_balance_wallet_rounded,
      _ => Icons.help_outline_rounded,
    };

/// Open / in progress tickets are still being handled; resolved / closed are done.
bool ticketIsResolved(HelpdeskTicket t) {
  final s = t.status.toLowerCase();
  return s == 'resolved' || s == 'closed';
}

BadgeTone ticketTone(HelpdeskTicket t) {
  if (ticketIsResolved(t)) return BadgeTone.success;
  if (t.status.toLowerCase() == 'in progress') return BadgeTone.info;
  return BadgeTone.warning;
}

/// Tappable summary of one ticket; opens the detail page.
class TicketTile extends StatelessWidget {
  const TicketTile({super.key, required this.ticket});

  final HelpdeskTicket ticket;

  @override
  Widget build(BuildContext context) {
    final raised = parseUtcTimestamp(ticket.createdAt);
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 10),
      semanticLabel: 'Ticket ${ticket.ticketNo}, ${ticket.status}. Opens details',
      onTap: () => Navigator.pushNamed(context, AppRoutes.ticketDetail, arguments: ticket),
      child: Row(
        children: [
          IconBubble(icon: ticketCategoryIcon(ticket.category), size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(ticket.ticketNo, style: AppText.title)),
                    StatusBadge(label: ticket.status, tone: ticketTone(ticket), dense: true),
                  ],
                ),
                const SizedBox(height: 2),
                Text(ticket.message, style: AppText.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                MetaLine(
                  icon: Icons.schedule_rounded,
                  text: '${ticket.category} · ${raised == null ? ticket.createdAt : formatTimeAgo(raised)}',
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded, color: context.accentInk),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// History: every ticket, with counts, filters and search.
// ---------------------------------------------------------------------------

enum _Filter { all, open, resolved }

class TicketHistoryScreen extends StatefulWidget {
  const TicketHistoryScreen({super.key});

  @override
  State<TicketHistoryScreen> createState() => _TicketHistoryScreenState();
}

class _TicketHistoryScreenState extends State<TicketHistoryScreen> {
  _Filter _filter = _Filter.all;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<HelpdeskTicket>>(
      valueListenable: AppState.instance.tickets,
      builder: (context, tickets, _) {
        final open = tickets.where((t) => !ticketIsResolved(t)).length;
        final resolved = tickets.length - open;
        final q = _query.trim().toLowerCase();
        final shown = tickets.where((t) {
          final matchesFilter = switch (_filter) {
            _Filter.all => true,
            _Filter.open => !ticketIsResolved(t),
            _Filter.resolved => ticketIsResolved(t),
          };
          final matchesQuery = q.isEmpty ||
              t.ticketNo.toLowerCase().contains(q) ||
              t.category.toLowerCase().contains(q) ||
              t.message.toLowerCase().contains(q);
          return matchesFilter && matchesQuery;
        }).toList();

        return GlassPage(
          title: 'Ticket history',
          children: [
            Row(
              children: [
                Expanded(child: _Count(label: 'Total', value: tickets.length, icon: Icons.inbox_rounded)),
                const SizedBox(width: 10),
                Expanded(child: _Count(label: 'Open', value: open, icon: Icons.pending_actions_rounded)),
                const SizedBox(width: 10),
                Expanded(child: _Count(label: 'Resolved', value: resolved, icon: Icons.task_alt_rounded)),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(color: context.ink),
              decoration: const InputDecoration(
                hintText: 'Search by ticket number, category or message',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final (filter, label) in const [
                  (_Filter.all, 'All'),
                  (_Filter.open, 'Open'),
                  (_Filter.resolved, 'Resolved'),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: _filter == filter,
                    onSelected: (_) => setState(() => _filter = filter),
                    showCheckmark: false,
                    selectedColor: context.selectedBg,
                    backgroundColor: context.faint,
                    side: BorderSide(color: context.hairline),
                    labelStyle: TextStyle(
                      color: _filter == filter ? context.selectedFg : context.ink,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: const StadiumBorder(),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (tickets.isEmpty)
              const _EmptyState(
                icon: Icons.inbox_rounded,
                title: 'No tickets yet',
                message: 'Tickets you raise from the Helpdesk will appear here.',
              )
            else if (shown.isEmpty)
              const _EmptyState(
                icon: Icons.search_off_rounded,
                title: 'No matching tickets',
                message: 'Try a different filter or search.',
              )
            else
              for (final ticket in shown) TicketTile(ticket: ticket),
          ],
        );
      },
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.label, required this.value, required this.icon});

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      borderRadius: AppRadius.tile,
      child: Column(
        children: [
          Icon(icon, color: context.accentInk, size: 20),
          const SizedBox(height: 4),
          Text('$value', style: AppText.h2),
          Text(label, style: AppText.caption),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, size: 40, color: context.accentInk),
          const SizedBox(height: 10),
          Text(title, style: AppText.title, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(message, style: AppText.body, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail: everything about one ticket.
// ---------------------------------------------------------------------------

class TicketDetailScreen extends StatelessWidget {
  const TicketDetailScreen({super.key, required this.ticket});

  final HelpdeskTicket? ticket;

  @override
  Widget build(BuildContext context) {
    final t = ticket;
    if (t == null) {
      return GlassPage(
        title: 'Ticket',
        children: [
          const _EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Ticket not found',
            message: 'Open a ticket from your ticket history.',
          ),
          const SizedBox(height: 14),
          PillButton(
            label: 'Ticket history',
            icon: Icons.history_rounded,
            expand: true,
            onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.ticketHistory),
          ),
        ],
      );
    }

    final raised = parseUtcTimestamp(t.createdAt);
    final resolved = ticketIsResolved(t);
    final inProgress = resolved || t.status.toLowerCase() == 'in progress';

    return GlassPage(
      title: t.ticketNo,
      children: [
        // Summary
        GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconBubble(icon: ticketCategoryIcon(t.category), size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.ticketNo, style: AppText.h2),
                        Text(t.category, style: AppText.body),
                      ],
                    ),
                  ),
                  StatusBadge(label: t.status, tone: ticketTone(t)),
                ],
              ),
              const Divider(),
              InfoRow(icon: Icons.confirmation_number_rounded, label: 'Ticket number', value: t.ticketNo),
              InfoRow(icon: ticketCategoryIcon(t.category), label: 'Category', value: t.category),
              InfoRow(
                icon: Icons.event_rounded,
                label: 'Raised on',
                value: raised == null ? '${t.createdAt} UTC' : '${formatLocalDateTime(raised)} (${formatTimeAgo(raised)})',
              ),
              InfoRow(icon: Icons.flag_rounded, label: 'Status', value: t.status),
            ],
          ),
        ),
        const SectionHeader(title: 'Your message', icon: Icons.chat_bubble_outline_rounded),
        GlassContainer(
          child: SelectableText(t.message, style: AppText.body.copyWith(fontSize: 15, color: context.ink)),
        ),
        const SectionHeader(title: 'Progress', icon: Icons.timeline_rounded),
        GlassContainer(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            children: [
              _Step(
                done: true,
                isLast: false,
                title: 'Ticket submitted',
                detail: raised == null ? 'Received by Student Services' : formatLocalDateTime(raised),
              ),
              _Step(
                done: inProgress,
                isLast: false,
                title: 'With Student Services',
                detail: inProgress ? 'An adviser is working on it' : 'Waiting for an adviser (usually within 24 hours)',
              ),
              _Step(
                done: resolved,
                isLast: true,
                title: 'Resolved',
                detail: resolved ? 'This ticket is closed' : 'You will see the outcome here',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PillButton(
          label: 'Copy ticket number',
          icon: Icons.copy_rounded,
          expand: true,
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: t.ticketNo));
            if (context.mounted) showCampusSnack(context, '${t.ticketNo} copied', icon: Icons.copy_rounded);
          },
        ),
        const SizedBox(height: 12),
        PillButton(
          label: 'All my tickets',
          icon: Icons.history_rounded,
          filled: false,
          expand: true,
          onPressed: () => Navigator.pushNamed(context, AppRoutes.ticketHistory),
        ),
        const SizedBox(height: 12),
        Text(
          'Quote ${t.ticketNo} if you contact Student Services about this issue.',
          textAlign: TextAlign.center,
          style: AppText.caption,
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.done, required this.isLast, required this.title, required this.detail});

  final bool done;
  final bool isLast;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? context.selectedBg : Colors.transparent,
                    border: Border.all(color: done ? context.selectedBg : context.hairline, width: 2),
                  ),
                  child: done ? Icon(Icons.check_rounded, size: 16, color: context.selectedFg) : null,
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: done ? context.selectedBg : context.hairline)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.title.copyWith(color: done ? null : context.inkMuted)),
                  Text(detail, style: AppText.caption),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
