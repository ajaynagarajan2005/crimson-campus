import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Programmes offered in the sign-up and edit-profile dropdowns.
const List<String> programmeOptions = [
  'BSc (Hons) Computer Science',
  'BSc (Hons) Software Engineering',
  'BSc (Hons) Information Technology',
  'BSc (Hons) Cyber Security',
  'Bachelor of Engineering (Hons) Mechanical',
  'Bachelor of Engineering (Hons) Electrical & Electronic',
  'Bachelor of Business (Hons) Management',
  'Bachelor of Accounting (Hons)',
  'BA (Hons) Mass Communication',
  'Bachelor of Biotechnology (Hons)',
  'Diploma in Information Technology',
  'Foundation in Science',
];

const String otherProgramme = 'Other (type below)';

/// Labelled text field styled for the glass theme.
class CampusTextField extends StatelessWidget {
  const CampusTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.validator,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.suffix,
    this.autofillHints,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final Widget? suffix;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final errorColor = scheme.brightness == Brightness.light ? scheme.error : AppColors.warning;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        autofillHints: autofillHints,
        onFieldSubmitted: onSubmitted,
        textCapitalization: textCapitalization,
        style: TextStyle(color: scheme.onSurface, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          suffixIcon: suffix,
          errorStyle: TextStyle(color: errorColor, fontWeight: FontWeight.w600),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.tile),
            borderSide: BorderSide(color: errorColor),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.tile),
            borderSide: BorderSide(color: errorColor, width: 1.6),
          ),
        ),
      ),
    );
  }
}

/// Dropdown styled to match [CampusTextField].
class CampusDropdown<T> extends StatelessWidget {
  const CampusDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemLabel,
  });

  final String label;
  final IconData icon;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String Function(T item)? itemLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        dropdownColor: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF7A0F0F),
        borderRadius: BorderRadius.circular(AppRadius.tile),
        iconEnabledColor: Theme.of(context).colorScheme.onSurface,
        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 15,
        ),
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        items: [
          for (final item in items)
            DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabel?.call(item) ?? '$item',
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

/// Inline error panel for form-level errors such as "wrong password".
class FormErrorBanner extends StatelessWidget {
  const FormErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.warning,
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFF5A3B00)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF5A3B00),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Validators ---------------------------------------------------------------

String? requiredField(String? value, String name) =>
    (value == null || value.trim().isEmpty) ? 'Enter your $name' : null;

String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Enter your email';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
    return 'Enter a valid email address';
  }
  return null;
}

String? validateStudentId(String? value) {
  final v = value?.trim() ?? '';
  if (v.length < 3) return 'Enter your student ID';
  if (!RegExp(r'^[A-Za-z0-9-]+$').hasMatch(v)) {
    return 'Letters, numbers and dashes only';
  }
  return null;
}

String? validateCgpa(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return null; // optional
  final cgpa = double.tryParse(v);
  if (cgpa == null || cgpa < 0 || cgpa > 4) return 'CGPA must be between 0.00 and 4.00';
  return null;
}

String? validateCredits(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return null; // optional
  final credits = int.tryParse(v);
  if (credits == null || credits < 0 || credits > 400) return 'Enter a whole number of credits';
  return null;
}

/// Two fields side by side on wide screens, stacked on narrow phones.
class FieldPair extends StatelessWidget {
  const FieldPair({super.key, required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 400) {
          return Column(children: [first, second]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 12),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}
