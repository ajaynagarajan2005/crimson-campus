import 'package:flutter/material.dart';

import '../models/student.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/glass_container.dart';

const ticketCategories = ['IT & Wi-Fi', 'Academics', 'Hostel', 'Fees', 'Other'];
const ticketPriorities = ['Low', 'Medium', 'High', 'Urgent'];
const ticketContactMethods = ['Email', 'Phone', 'In person'];

IconData contactMethodIcon(String method) => switch (method) {
      'Phone' => Icons.call_rounded,
      'In person' => Icons.storefront_rounded,
      _ => Icons.mail_rounded,
    };

/// Step-by-step ticket form: student details, request details, preferences
/// and confirmation, with a completion percentage across all four.
class TicketForm extends StatefulWidget {
  const TicketForm({super.key});

  @override
  State<TicketForm> createState() => _TicketFormState();
}

class _TicketFormState extends State<TicketForm> {
  static const _steps = [
    ('Student', Icons.badge_rounded),
    ('Request', Icons.edit_note_rounded),
    ('Preference', Icons.tune_rounded),
    ('Confirm', Icons.fact_check_rounded),
  ];

  final _subject = TextEditingController();
  final _message = TextEditingController();
  final _phone = TextEditingController();

  int _step = 0;
  bool _studentReviewed = false;
  String _category = ticketCategories.first;
  String? _priority;
  DateTime? _preferredDate;
  String? _contactMethod;
  bool _confirmed = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _phone.text = AppState.instance.student.value?.phone ?? '';
    for (final c in [_subject, _message, _phone]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool get _subjectOk => _subject.text.trim().length >= 3;
  bool get _messageOk => _message.text.trim().length >= 5;
  bool get _phoneOk => _contactMethod != 'Phone' || _phone.text.trim().length >= 6;

  bool _stepDone(int step) => switch (step) {
        0 => _studentReviewed,
        1 => _subjectOk && _messageOk && _priority != null,
        2 => _preferredDate != null && _contactMethod != null && _phoneOk,
        _ => _confirmed,
      };

  /// Share of the form filled in, from 0 to 1.
  double get _completion {
    final checks = [
      _studentReviewed,
      _subjectOk,
      _messageOk,
      _priority != null,
      _preferredDate != null,
      _contactMethod != null && _phoneOk,
      _confirmed,
    ];
    return checks.where((c) => c).length / checks.length;
  }

  String? _missing(int step) => switch (step) {
        1 when !_subjectOk => 'Add a short subject (at least 3 characters)',
        1 when !_messageOk => 'Describe your issue (at least 5 characters)',
        1 when _priority == null => 'Choose a priority',
        2 when _preferredDate == null => 'Pick a preferred date',
        2 when _contactMethod == null => 'Choose how we should contact you',
        2 when !_phoneOk => 'Enter a phone number we can call',
        3 when !_confirmed => 'Tick the box to confirm your details',
        _ => null,
      };

  void _goTo(int step) {
    FocusScope.of(context).unfocus();
    setState(() {
      if (_step == 0 && step > 0) _studentReviewed = true;
      _step = step;
    });
  }

  void _next() {
    if (_step == 0) {
      _goTo(1);
      return;
    }
    final missing = _missing(_step);
    if (missing != null) {
      showCampusSnack(context, missing, icon: Icons.info_rounded);
      return;
    }
    _goTo(_step + 1);
  }

  Future<void> _submit() async {
    for (var s = 1; s < _steps.length; s++) {
      final missing = _missing(s);
      if (missing != null) {
        showCampusSnack(context, missing, icon: Icons.info_rounded);
        setState(() => _step = s);
        return;
      }
    }
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    final ticket = await runCampusAction<HelpdeskTicket>(
      context,
      () => AppState.instance.raiseTicket(
        TicketRequest(
          category: _category,
          subject: _subject.text,
          message: _message.text,
          priority: _priority,
          preferredDate: _preferredDate,
          contactMethod: _contactMethod,
          contactPhone: _phone.text,
        ),
      ),
      success: (t) => 'Ticket ${t.ticketNo} raised under ${t.category}. We reply within 24 hours.',
      icon: (_) => Icons.confirmation_number_rounded,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ticket == null) return;
    _subject.clear();
    _message.clear();
    setState(() {
      _step = 0;
      _studentReviewed = false;
      _category = ticketCategories.first;
      _priority = null;
      _preferredDate = null;
      _contactMethod = null;
      _confirmed = false;
    });
    Navigator.pushNamed(context, AppRoutes.ticketDetail, arguments: ticket);
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_completion * 100).round();
    final last = _step == _steps.length - 1;
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Request completion', style: AppText.title)),
              Text('$percent%', style: AppText.h3.copyWith(color: context.accentInk)),
            ],
          ),
          const SizedBox(height: 8),
          GlassProgressBar(value: _completion),
          const SizedBox(height: AppSpacing.md),
          _StepIndicator(
            steps: _steps,
            current: _step,
            done: _stepDone,
            onTap: _goTo,
          ),
          const Divider(height: 28),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: KeyedSubtree(
              key: ValueKey(_step),
              child: switch (_step) {
                0 => _studentStep(),
                1 => _requestStep(),
                2 => _preferenceStep(),
                _ => _confirmStep(),
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (_step > 0) ...[
                Expanded(
                  child: PillButton(
                    label: 'Back',
                    icon: Icons.arrow_back_rounded,
                    filled: false,
                    expand: true,
                    onPressed: _submitting ? null : () => _goTo(_step - 1),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                flex: 2,
                child: PillButton(
                  label: last ? (_submitting ? 'Submitting…' : 'Submit ticket') : 'Next',
                  icon: last ? Icons.send_rounded : Icons.arrow_forward_rounded,
                  expand: true,
                  onPressed: _submitting ? null : (last ? _submit : _next),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Step 1 ------------------------------------------------------------------

  Widget _studentStep() {
    final s = AppState.instance.student.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepTitle(title: 'Student details', subtitle: 'From your profile — check they are correct.'),
        InfoRow(icon: Icons.person_rounded, label: 'Full name', value: s?.name ?? '—'),
        InfoRow(icon: Icons.badge_rounded, label: 'Student ID', value: s?.id ?? '—'),
        InfoRow(icon: Icons.mail_rounded, label: 'Email', value: s?.email ?? '—'),
        InfoRow(
          icon: Icons.school_rounded,
          label: 'Programme',
          value: s == null ? '—' : '${s.programme} · Semester ${s.semester}',
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          style: TextStyle(color: context.ink),
          decoration: const InputDecoration(
            labelText: 'Contact phone (optional)',
            prefixIcon: Icon(Icons.call_rounded),
          ),
        ),
      ],
    );
  }

  // Step 2 ------------------------------------------------------------------

  Widget _requestStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepTitle(title: 'Request details', subtitle: 'Tell us what you need help with.'),
        const Text('Category', style: AppText.caption),
        const SizedBox(height: 8),
        _Choices(
          options: ticketCategories,
          selected: _category,
          onSelected: (c) => setState(() => _category = c),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _subject,
          maxLength: 120,
          style: TextStyle(color: context.ink),
          decoration: const InputDecoration(labelText: 'Subject', counterText: ''),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _message,
          minLines: 3,
          maxLines: 5,
          style: TextStyle(color: context.ink),
          decoration: const InputDecoration(labelText: 'Describe your issue', alignLabelWithHint: true),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text('Priority', style: AppText.caption),
        const SizedBox(height: 8),
        _Choices(
          options: ticketPriorities,
          selected: _priority,
          onSelected: (p) => setState(() => _priority = p),
        ),
      ],
    );
  }

  // Step 3 ------------------------------------------------------------------

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _preferredDate ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 90)),
      helpText: 'Preferred date',
    );
    if (picked != null) setState(() => _preferredDate = picked);
  }

  Widget _preferenceStep() {
    final today = DateUtils.dateOnly(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepTitle(title: 'Preference', subtitle: 'When and how should Student Services reach you?'),
        const Text('Preferred date', style: AppText.caption),
        const SizedBox(height: 8),
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 14,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final day = today.add(Duration(days: i));
              return _DateChip(
                date: day,
                label: i == 0 ? 'Today' : weekdayShort[day.weekday],
                selected: _preferredDate != null && DateUtils.isSameDay(day, _preferredDate),
                onTap: () => setState(() => _preferredDate = day),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _pickDate,
            style: TextButton.styleFrom(foregroundColor: context.accentInk, minimumSize: const Size(48, 44)),
            icon: const Icon(Icons.calendar_month_rounded),
            label: Text(_preferredDate == null ? 'Pick another date' : formatDate(_preferredDate!)),
          ),
        ),
        const SizedBox(height: 8),
        const Text('Contact me by', style: AppText.caption),
        const SizedBox(height: 8),
        _Choices(
          options: ticketContactMethods,
          selected: _contactMethod,
          icon: contactMethodIcon,
          onSelected: (m) => setState(() => _contactMethod = m),
        ),
        if (_contactMethod == 'Phone') ...[
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: context.ink),
            decoration: const InputDecoration(labelText: 'Phone number', prefixIcon: Icon(Icons.call_rounded)),
          ),
        ],
      ],
    );
  }

  // Step 4 ------------------------------------------------------------------

  Widget _confirmStep() {
    final s = AppState.instance.student.value;
    final contact = _contactMethod == null
        ? '—'
        : _contactMethod == 'Phone'
            ? 'Phone · ${_phone.text.trim()}'
            : _contactMethod == 'Email'
                ? 'Email · ${s?.email ?? ''}'
                : 'In person at Student Services';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepTitle(title: 'Confirmation details', subtitle: 'Review everything before you submit.'),
        _SummaryGroup(
          title: 'Student',
          onEdit: () => _goTo(0),
          rows: [
            (Icons.person_rounded, 'Name', s == null ? '—' : '${s.name} (${s.id})'),
            (Icons.mail_rounded, 'Email', s?.email ?? '—'),
          ],
        ),
        _SummaryGroup(
          title: 'Request',
          onEdit: () => _goTo(1),
          rows: [
            (Icons.category_rounded, 'Category', _category),
            (Icons.title_rounded, 'Subject', _subject.text.trim().isEmpty ? '—' : _subject.text.trim()),
            (Icons.notes_rounded, 'Description', _message.text.trim().isEmpty ? '—' : _message.text.trim()),
            (Icons.flag_rounded, 'Priority', _priority ?? '—'),
          ],
        ),
        _SummaryGroup(
          title: 'Preference',
          onEdit: () => _goTo(2),
          rows: [
            (Icons.event_rounded, 'Preferred date', _preferredDate == null ? '—' : formatDate(_preferredDate!)),
            (contactMethodIcon(_contactMethod ?? 'Email'), 'Contact', contact),
          ],
        ),
        const SizedBox(height: 4),
        CheckboxListTile(
          value: _confirmed,
          onChanged: (v) => setState(() => _confirmed = v ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: context.selectedBg,
          checkColor: context.selectedFg,
          title: const Text('I confirm these details are correct', style: AppText.title),
        ),
      ],
    );
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.h3),
          Text(subtitle, style: AppText.caption),
        ],
      ),
    );
  }
}

/// Numbered steps; a tick replaces the number once a step is complete.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.steps, required this.current, required this.done, required this.onTap});

  final List<(String, IconData)> steps;
  final int current;
  final bool Function(int step) done;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(
            child: Semantics(
              button: true,
              selected: i == current,
              label: 'Step ${i + 1}, ${steps[i].$1}${done(i) ? ', complete' : ''}',
              child: InkWell(
                onTap: () => onTap(i),
                borderRadius: BorderRadius.circular(AppRadius.chip),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == current || done(i) ? context.selectedBg : context.faint,
                          border: Border.all(color: i == current ? context.selectedBg : context.hairline, width: 2),
                        ),
                        child: done(i) && i != current
                            ? Icon(Icons.check_rounded, size: 18, color: context.selectedFg)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: i == current ? context.selectedFg : context.ink,
                                ),
                              ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[i].$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption.copyWith(
                          fontWeight: i == current ? FontWeight.w700 : null,
                          color: i == current ? context.accentInk : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (i < steps.length - 1)
            Container(
              width: 14,
              height: 2,
              margin: const EdgeInsets.only(bottom: 18),
              color: done(i) ? context.selectedBg : context.hairline,
            ),
        ],
      ],
    );
  }
}

/// Single-choice chips in the app's style.
class _Choices extends StatelessWidget {
  const _Choices({required this.options, required this.selected, required this.onSelected, this.icon});

  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;
  final IconData Function(String option)? icon;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          ChoiceChip(
            avatar: icon == null
                ? null
                : Icon(icon!(o), size: 18, color: o == selected ? context.selectedFg : context.accentInk),
            label: Text(o),
            selected: o == selected,
            onSelected: (_) => onSelected(o),
            showCheckmark: false,
            selectedColor: context.selectedBg,
            backgroundColor: context.faint,
            side: BorderSide(color: context.hairline),
            labelStyle: TextStyle(
              color: o == selected ? context.selectedFg : context.ink,
              fontWeight: FontWeight.w600,
            ),
            shape: const StadiumBorder(),
          ),
      ],
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.date, required this.label, required this.selected, required this.onTap});

  final DateTime date;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? context.selectedFg : context.ink;
    return Semantics(
      button: true,
      selected: selected,
      label: formatDate(date),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.tile),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? context.selectedBg : context.faint,
              borderRadius: BorderRadius.circular(AppRadius.tile),
              border: Border.all(color: selected ? context.selectedBg : context.hairline),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: fg)),
                Text('${date.day}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: fg)),
                Text(formatDayMonth(date).split(' ').last, style: TextStyle(fontSize: 11, color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryGroup extends StatelessWidget {
  const _SummaryGroup({required this.title, required this.rows, required this.onEdit});

  final String title;
  final List<(IconData, String, String)> rows;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 8),
      decoration: BoxDecoration(
        color: context.faint,
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppText.title)),
              TextButton.icon(
                onPressed: onEdit,
                style: TextButton.styleFrom(foregroundColor: context.accentInk, minimumSize: const Size(48, 40)),
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('Edit'),
              ),
            ],
          ),
          for (final (icon, label, value) in rows) InfoRow(icon: icon, label: label, value: value),
        ],
      ),
    );
  }
}
