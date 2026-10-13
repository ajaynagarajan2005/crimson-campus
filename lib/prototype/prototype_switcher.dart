// PROTOTYPE: floating bar for flipping between UI variants. Debug builds only.
// Delete together with the variants once one is chosen.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/browser.dart';

/// Currently shown "About INTI" variant, seeded from ?variant= in the URL.
final ValueNotifier<String> aboutVariant = ValueNotifier<String>(_initialVariant());

String _initialVariant() {
  final fromUrl = Browser.queryParam('variant')?.toUpperCase();
  return const ['A', 'B', 'C'].contains(fromUrl) ? fromUrl! : 'A';
}

class PrototypeSwitcher extends StatefulWidget {
  const PrototypeSwitcher({super.key, required this.variants, required this.current});

  /// Variant key -> short name, e.g. {'A': 'Zoom reel'}.
  final Map<String, String> variants;
  final ValueNotifier<String> current;

  @override
  State<PrototypeSwitcher> createState() => _PrototypeSwitcherState();
}

class _PrototypeSwitcherState extends State<PrototypeSwitcher> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    // Leave arrow keys alone while typing in a field.
    final focused = FocusManager.instance.primaryFocus?.context;
    if (focused != null &&
        (focused.widget is EditableText || focused.findAncestorWidgetOfExactType<EditableText>() != null)) {
      return false;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _cycle(-1);
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _cycle(1);
      return true;
    }
    return false;
  }

  void _cycle(int delta) {
    final keys = widget.variants.keys.toList();
    final index = keys.indexOf(widget.current.value);
    final next = keys[(index + delta + keys.length) % keys.length];
    widget.current.value = next;
    Browser.setQueryParam('variant', next);
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return ValueListenableBuilder<String>(
      valueListenable: widget.current,
      builder: (context, key, _) => ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width - 24),
        child: Material(
        color: const Color(0xEE111111),
        shape: const StadiumBorder(side: BorderSide(color: Color(0xFFFFD54F), width: 1.5)),
        elevation: 12,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Previous variant (←)',
                color: Colors.white,
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => _cycle(-1),
              ),
              Flexible(
                child: Text(
                  'PROTOTYPE  $key · ${widget.variants[key]}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              IconButton(
                tooltip: 'Next variant (→)',
                color: Colors.white,
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => _cycle(1),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
