import 'package:flutter/material.dart';

import '../models/student.dart';
import '../routes.dart';
import '../services/browser.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/campus_themed.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_page.dart';
import '../widgets/virtual_id_card.dart';
import 'dashboard_screen.dart';

/// Student profile (from the database), preferences and sign out.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need your email or student ID and password to log back in.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.primaryDark),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await AppState.instance.logout();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.landing, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return ValueListenableBuilder<Student?>(
      valueListenable: state.student,
      builder: (context, student, _) {
        if (student == null) return const SizedBox.shrink();
        return GlassPage(
          title: 'Profile',
          actions: [
            const ThemeToggleButton(),
            IconButton(
              tooltip: 'Edit profile',
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => showEditProfileSheet(context, student),
            ),
          ],
          children: [
            _Header(student: student),
            const SectionHeader(title: 'Virtual student ID', icon: Icons.badge_rounded),
            GestureDetector(
              onTap: () => _showIdFullScreen(context, student),
              child: VirtualIdCard(student: student),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                PillButton(
                  label: student.photoUrl == null ? 'Upload photo' : 'Change photo',
                  icon: Icons.photo_camera_rounded,
                  onPressed: () => changeProfilePhoto(context),
                ),
                PillButton(
                  label: 'Show ID',
                  icon: Icons.fullscreen_rounded,
                  filled: false,
                  onPressed: () => _showIdFullScreen(context, student),
                ),
                if (student.photoUrl != null)
                  PillButton(
                    label: 'Remove photo',
                    icon: Icons.delete_outline_rounded,
                    filled: false,
                    onPressed: () => runCampusAction<void>(
                      context,
                      AppState.instance.removePhoto,
                      success: (_) => 'Photo removed',
                    ),
                  ),
              ],
            ),
            const SectionHeader(title: 'Personal details', icon: Icons.person_rounded),
            GlassContainer(
              child: Column(
                children: [
                  InfoRow(icon: Icons.numbers_rounded, label: 'Student ID', value: student.id),
                  InfoRow(icon: Icons.mail_rounded, label: 'Student email', value: student.email),
                  InfoRow(icon: Icons.phone_rounded, label: 'Phone', value: student.phone ?? 'Not added'),
                  InfoRow(icon: Icons.apartment_rounded, label: 'Residence', value: student.residence ?? 'Not added'),
                  InfoRow(icon: Icons.person_pin_rounded, label: 'Academic advisor', value: student.advisor),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PillButton(
              label: 'Edit profile',
              icon: Icons.edit_rounded,
              filled: false,
              expand: true,
              onPressed: () => showEditProfileSheet(context, student),
            ),
            const SectionHeader(title: 'Notifications', icon: Icons.tune_rounded),
            ValueListenableBuilder<NotificationPreferences>(
              valueListenable: state.preferences,
              builder: (context, prefs, _) => GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
                child: Column(
                  children: [
                    _ToggleRow(
                      icon: Icons.notifications_active_rounded,
                      label: 'Campus announcements',
                      value: prefs.announcements,
                      onChanged: (v) => _savePrefs(context, prefs.copyWith(announcements: v)),
                    ),
                    _ToggleRow(
                      icon: Icons.alarm_rounded,
                      label: 'Class reminders',
                      value: prefs.classReminders,
                      onChanged: (v) => _savePrefs(context, prefs.copyWith(classReminders: v)),
                    ),
                    _ToggleRow(
                      icon: Icons.directions_bus_rounded,
                      label: 'Shuttle alerts',
                      value: prefs.shuttleAlerts,
                      onChanged: (v) => _savePrefs(context, prefs.copyWith(shuttleAlerts: v)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PillButton(
              label: 'Help & support',
              icon: Icons.support_agent_rounded,
              filled: false,
              expand: true,
              onPressed: () => Navigator.pushNamed(context, AppRoutes.helpdesk),
            ),
            const SizedBox(height: 12),
            PillButton(
              label: 'Log out',
              icon: Icons.logout_rounded,
              expand: true,
              onPressed: () => _signOut(context),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        );
      },
    );
  }

  void _savePrefs(BuildContext context, NotificationPreferences next) {
    runCampusAction<void>(context, () => AppState.instance.setPreferences(next));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    final progress = student.creditsRequired == 0
        ? 0.0
        : student.creditsEarned / student.creditsRequired;
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      tint: 0.18,
      child: Column(
        children: [
          ProfileAvatar(student: student, size: 96, onEditPhoto: () => changeProfilePhoto(context)),
          const SizedBox(height: 14),
          Text(student.name, style: AppText.h1, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(student.programme, style: AppText.body, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              StatusBadge(label: student.id, tone: BadgeTone.info),
              StatusBadge(label: student.year),
              StatusBadge(label: 'Semester ${student.semester}'),
              const StatusBadge(label: 'Active', tone: BadgeTone.success),
            ],
          ),
          const Divider(),
          Row(
            children: [
              const Expanded(child: Text('Degree progress', style: AppText.title)),
              Text(
                '${student.creditsEarned}/${student.creditsRequired} credits',
                style: AppText.caption,
              ),
            ],
          ),
          const SizedBox(height: 10),
          GlassProgressBar(value: progress, height: 10),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(
          children: [
            Icon(icon, color: context.accentInk, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet that edits the student's record in the database.
Future<void> showEditProfileSheet(BuildContext context, Student student) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.isLight ? Colors.white : const Color(0xFF6E0B0B),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
    ),
    builder: (context) => _EditProfileSheet(student: student),
  );
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.student});

  final Student student;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.student.name);
  late final _programme = TextEditingController(text: widget.student.programme);
  late final _cgpa = TextEditingController(text: widget.student.cgpa?.toStringAsFixed(2) ?? '');
  late final _credits = TextEditingController(text: '${widget.student.creditsEarned}');
  late final _phone = TextEditingController(text: widget.student.phone ?? '');
  late final _residence = TextEditingController(text: widget.student.residence ?? '');
  late int _semester = widget.student.semester.clamp(1, 8);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _programme, _cgpa, _credits, _phone, _residence]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final cgpaText = _cgpa.text.trim();
    try {
      await AppState.instance.updateProfile({
        'full_name': _name.text.trim(),
        'programme': _programme.text.trim(),
        'semester': _semester,
        'cgpa': cgpaText.isEmpty ? null : double.parse(cgpaText),
        'credits_earned': int.tryParse(_credits.text.trim()) ?? 0,
        'phone': _phone.text.trim(),
        'residence': _residence.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context);
      showCampusSnack(context, 'Profile saved');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: context.hairline,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                  const Text('Edit profile', style: AppText.h2),
                  const SizedBox(height: 16),
                  if (_error != null) FormErrorBanner(message: _error!),
                  CampusTextField(
                    controller: _name,
                    label: 'Full name',
                    icon: Icons.person_rounded,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your full name' : null,
                  ),
                  CampusTextField(
                    controller: _programme,
                    label: 'Programme',
                    icon: Icons.menu_book_rounded,
                    validator: (v) => requiredField(v, 'programme'),
                  ),
                  CampusDropdown<int>(
                    label: 'Current semester',
                    icon: Icons.layers_rounded,
                    value: _semester,
                    items: const [1, 2, 3, 4, 5, 6, 7, 8],
                    itemLabel: (s) => 'Semester $s',
                    onChanged: (v) => setState(() => _semester = v ?? _semester),
                  ),
                  FieldPair(
                    first: CampusTextField(
                          controller: _cgpa,
                          label: 'CGPA',
                          icon: Icons.star_rounded,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: validateCgpa,
                        ),
                    second: CampusTextField(
                          controller: _credits,
                          label: 'Credits',
                          icon: Icons.workspace_premium_rounded,
                          keyboardType: TextInputType.number,
                          validator: validateCredits,
                        ),
                  ),
                  CampusTextField(
                    controller: _phone,
                    label: 'Phone',
                    icon: Icons.phone_iphone_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                  CampusTextField(
                    controller: _residence,
                    label: 'Residence / hostel',
                    icon: Icons.apartment_rounded,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 4),
                  PillButton(
                    label: _saving ? 'Saving…' : 'Save changes',
                    icon: Icons.save_rounded,
                    expand: true,
                    onPressed: _saving ? null : _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


/// Picks an image and uploads it as the student's profile / ID photo.
Future<void> changeProfilePhoto(BuildContext context) async {
  final bytes = await Browser.pickImage();
  if (!context.mounted) return;
  if (bytes == null) {
    if (!Browser.supportsLocation) {
      showCampusSnack(context, 'Photo upload works in the web version of the app.', icon: Icons.info_rounded);
    }
    return; // cancelled
  }
  if (bytes.length > 5 * 1024 * 1024) {
    showCampusSnack(context, 'That photo is over 5 MB. Please choose a smaller one.', icon: Icons.info_rounded);
    return;
  }
  await runCampusAction<void>(
    context,
    () => AppState.instance.uploadPhoto(bytes),
    success: (_) => 'Photo updated on your virtual ID',
    icon: (_) => Icons.badge_rounded,
  );
}

void _showIdFullScreen(BuildContext context, Student student) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.75),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: VirtualIdCard(student: student),
          ),
          const SizedBox(height: 16),
          PillButton(label: 'Close', icon: Icons.close_rounded, onPressed: () => Navigator.pop(context)),
        ],
      ),
    ),
  );
}
