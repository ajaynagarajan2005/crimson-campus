import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_page.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final books = borrowedBooks
        .where((b) =>
            query.isEmpty ||
            b.title.toLowerCase().contains(query) ||
            b.author.toLowerCase().contains(query))
        .toList();

    return ValueListenableBuilder<Set<String>>(
      valueListenable: AppState.instance.renewedBooks,
      builder: (context, renewed, _) => _page(context, books, renewed),
    );
  }

  Widget _page(BuildContext context, List<LibraryBook> books, Set<String> renewed) {
    return GlassPage(
      title: 'Library',
      children: [
        TextField(
          onChanged: (value) => setState(() => _query = value),
          style: TextStyle(color: context.ink),
          decoration: const InputDecoration(
            hintText: 'Search your borrowed books',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  IconBubble(icon: Icons.event_seat_rounded, size: 40),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reading hall · Level 2', style: AppText.title),
                        Text('Open today 8:00 AM – 11:00 PM', style: AppText.caption),
                      ],
                    ),
                  ),
                  StatusBadge(label: 'Available', tone: BadgeTone.success),
                ],
              ),
              const SizedBox(height: 14),
              const GlassProgressBar(value: 42 / 120),
              const SizedBox(height: 6),
              Text('42 of 120 seats free right now', style: AppText.caption.copyWith(color: context.ink)),
            ],
          ),
        ),
        SectionHeader(
          title: 'Borrowed books (${borrowedBooks.length})',
          icon: Icons.menu_book_rounded,
        ),
        if (books.isEmpty)
          const GlassContainer(
            child: Text('No borrowed books match your search.', style: AppText.body),
          ),
        for (final book in books)
          GlassContainer(
            margin: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 62,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, AppColors.tintBlush],
                    ),
                  ),
                  child: const Icon(Icons.auto_stories_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(book.title, style: AppText.title),
                      Text(book.author, style: AppText.caption),
                      const SizedBox(height: 6),
                      StatusBadge(
                        label: renewed.contains(book.id)
                            ? 'Renewed · +14 days'
                            : book.due,
                        tone: renewed.contains(book.id)
                            ? BadgeTone.success
                            : (book.dueSoon ? BadgeTone.warning : BadgeTone.light),
                        dense: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  onPressed: renewed.contains(book.id)
                      ? null
                      : () => runCampusAction<void>(
                            context,
                            () => AppState.instance.renewBook(book.id),
                            success: (_) => 'Renewed "${book.title}" for 14 days',
                          ),
                  style: TextButton.styleFrom(
                    foregroundColor: context.accentInk,
                    disabledForegroundColor: context.inkMuted,
                    minimumSize: const Size(64, 48),
                  ),
                  child: Text(renewed.contains(book.id) ? 'Done' : 'Renew'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
