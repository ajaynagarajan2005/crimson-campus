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
import 'ticket_form.dart';

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
                Text(ticket.headline, style: AppText.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                MetaLine(
                  icon: Icons.schedule_rounded,
                  text: [
                    ticket.category,
                    if (ticket.priority != null) '${ticket.priority} priority',
                    raised == null ? ticket.createdAt : formatTimeAgo(raised),
                  ].join(' · '),
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

/// Compact card for the grid view of the ticket history.
class TicketGridCard extends StatelessWidget {
  const TicketGridCard({super.key, required this.ticket});

  final HelpdeskTicket ticket;

  @override
  Widget build(BuildContext context) {
    final raised = parseUtcTimestamp(ticket.createdAt);
    return GlassContainer(
      height: 188,
      borderRadius: AppRadius.tile,
      semanticLabel: 'Ticket ${ticket.ticketNo}, ${ticket.status}. Opens details',
      onTap: () => Navigator.pushNamed(context, AppRoutes.ticketDetail, arguments: ticket),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBubble(icon: ticketCategoryIcon(ticket.category), size: 36),
              const Spacer(),
              StatusBadge(label: ticket.status, tone: ticketTone(ticket), dense: true),
            ],
          ),
          const SizedBox(height: 10),
          Text(ticket.ticketNo, style: AppText.title),
          Text(ticket.headline, style: AppText.body, maxLines: 2, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Text(
            [ticket.category, if (ticket.priority != null) ticket.priority!].join(' · '),
            style: AppText.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(raised == null ? ticket.createdAt : formatTimeAgo(raised), style: AppText.caption),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// History: every ticket, with counts, filters and search.
// ---------------------------------------------------------------------------

enum _Filter { all, open, resolved }

enum _View { list, grid }

class TicketHistoryScreen extends StatefulWidget {
  const TicketHistoryScreen({super.key});

  @override
  State<TicketHistoryScreen> createState() => _TicketHistoryScreenState();
}

class _TicketHistoryScreenState extends State<TicketHistoryScreen> {
  _View _view = _View.list;
  _Filter _filter = _Filter.all;
  String? _category;
  DateTimeRange? _range;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _hasFilters =>
      _filter != _Filter.all || _category != null || _range != null || _search.text.trim().isNotEmpty;

  void _clearFilters() {
    _search.clear();
    setState(() {
      _filter = _Filter.all;
      _category = null;
      _range = null;
    });
  }

  Future<void> _pickRange() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDateRangePicker(
      context: context,
      firstDate: today.subtract(const Duration(days: 365 * 2)),
      lastDate: today,
      initialDateRange: _range,
      helpText: 'Tickets raised between',
    );
    if (picked != null) setState(() => _range = picked);
  }

  void _lastDays(int days) {
    final today = DateUtils.dateOnly(DateTime.now());
    setState(() => _range = DateTimeRange(start: today.subtract(Duration(days: days - 1)), end: today));
  }

  bool _inRange(HelpdeskTicket t) {
    final range = _range;
    if (range == null) return true;
    final raised = parseUtcTimestamp(t.createdAt);
    if (raised == null) return false;
    final day = DateUtils.dateOnly(raised);
    return !day.isBefore(range.start) && !day.isAfter(range.end);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<HelpdeskTicket>>(
      valueListenable: AppState.instance.tickets,
      builder: (context, tickets, _) {
        final open = tickets.where((t) => !ticketIsResolved(t)).length;
        final resolved = tickets.length - open;
        final q = _search.text.trim().toLowerCase();
        final shown = tickets.where((t) {
          final matchesFilter = switch (_filter) {
            _Filter.all => true,
            _Filter.open => !ticketIsResolved(t),
            _Filter.resolved => ticketIsResolved(t),
          };
          final matchesCategory = _category == null || t.category == _category;
          final matchesQuery = q.isEmpty ||
              t.ticketNo.toLowerCase().contains(q) ||
              t.category.toLowerCase().contains(q) ||
              (t.subject?.toLowerCase().contains(q) ?? false) ||
              t.message.toLowerCase().contains(q);
          return matchesFilter && matchesCategory && matchesQuery && _inRange(t);
        }).toList();

        return GlassPage(
          title: 'Ticket history',
          children: [
            // Toolbar: view switch on the left, result count and reset on the right.
            Row(
              children: [
                _ViewToggle(view: _view, onChanged: (v) => setState(() => _view = v)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Showing ${shown.length} of ${tickets.length}', style: AppText.caption),
                ),
                if (_hasFilters)
                  TextButton.icon(
                    onPressed: _clearFilters,
                    style: TextButton.styleFrom(foregroundColor: context.accentInk, minimumSize: const Size(48, 44)),
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                    label: const Text('Clear'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
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
              controller: _search,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: context.ink),
              decoration: InputDecoration(
                hintText: 'Search by ticket number, subject, category or message',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(_search.clear),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Date raised', style: AppText.caption),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: _range == null
                      ? 'Select dates'
                      : '${formatDayMonth(_range!.start)} – ${formatDayMonth(_range!.end)}',
                  icon: Icons.date_range_rounded,
                  selected: _range != null,
                  onTap: _pickRange,
                ),
                _FilterChip(label: 'Last 7 days', selected: false, onTap: () => _lastDays(7)),
                _FilterChip(label: 'Last 30 days', selected: false, onTap: () => _lastDays(30)),
                if (_range != null)
                  _FilterChip(
                    label: 'Any date',
                    icon: Icons.close_rounded,
                    selected: false,
                    onTap: () => setState(() => _range = null),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Category', style: AppText.caption),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in [null, ...ticketCategories])
                  _FilterChip(
                    label: c ?? 'All',
                    icon: c == null ? null : ticketCategoryIcon(c),
                    selected: _category == c,
                    onTap: () => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Status', style: AppText.caption),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final (filter, label) in const [
                  (_Filter.all, 'All'),
                  (_Filter.open, 'Open'),
                  (_Filter.resolved, 'Resolved'),
                ])
                  _FilterChip(label: label, selected: _filter == filter, onTap: () => setState(() => _filter = filter)),
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
                message: 'Try a different date, category or search.',
              )
            else if (_view == _View.list)
              for (final ticket in shown) TicketTile(ticket: ticket)
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 10.0;
                  final columns = constraints.maxWidth >= 640 ? 3 : 2;
                  final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final ticket in shown) SizedBox(width: width, child: TicketGridCard(ticket: ticket)),
                    ],
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

/// List / grid switch shown at the top left of the history.
class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.view, required this.onChanged});

  final _View view;
  final ValueChanged<_View> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget button(_View v, IconData icon, String label) {
      final selected = view == v;
      return Tooltip(
        message: label,
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          child: InkWell(
            onTap: () => onChanged(v),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 48,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? context.selectedBg : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Icon(icon, size: 22, color: selected ? context.selectedFg : context.accentInk),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.faint,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: context.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(_View.list, Icons.view_list_rounded, 'List view'),
          button(_View.grid, Icons.grid_view_rounded, 'Grid view'),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      avatar: icon == null ? null : Icon(icon, size: 18, color: selected ? context.selectedFg : context.accentInk),
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: context.selectedBg,
      backgroundColor: context.faint,
      side: BorderSide(color: context.hairline),
      labelStyle: TextStyle(color: selected ? context.selectedFg : context.ink, fontWeight: FontWeight.w600),
      shape: const StadiumBorder(),
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
              if (t.subject != null) InfoRow(icon: Icons.title_rounded, label: 'Subject', value: t.subject!),
              if (t.priority != null) InfoRow(icon: Icons.priority_high_rounded, label: 'Priority', value: t.priority!),
            ],
          ),
        ),
        const SectionHeader(title: 'Your message', icon: Icons.chat_bubble_outline_rounded),
        GlassContainer(
          child: SelectableText(t.message, style: AppText.body.copyWith(fontSize: 15, color: context.ink)),
        ),
        if (t.preferredDate != null || t.contactMethod != null) ...[
          const SectionHeader(title: 'Your preference', icon: Icons.tune_rounded),
          GlassContainer(
            child: Column(
              children: [
                if (parseIsoDate(t.preferredDate) case final date?)
                  InfoRow(icon: Icons.event_available_rounded, label: 'Preferred date', value: formatDate(date)),
                if (t.contactMethod != null)
                  InfoRow(
                    icon: contactMethodIcon(t.contactMethod!),
                    label: 'Contact me by',
                    value: t.contactMethod == 'Phone' && t.contactPhone != null
                        ? 'Phone · ${t.contactPhone}'
                        : t.contactMethod!,
                  ),
              ],
            ),
          ),
        ],
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
