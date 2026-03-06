import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum SortMode { title, strength, date }

class TopBar extends StatefulWidget {
  final SortMode sortMode;
  final ValueChanged<SortMode> onSortChanged;
  final VoidCallback onNewEntry;
  final ValueChanged<String> onSearch;

  const TopBar({
    super.key,
    required this.sortMode,
    required this.onSortChanged,
    required this.onNewEntry,
    required this.onSearch,
  });

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  final _searchController = TextEditingController();
  bool _searchFocused = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 61,
      decoration: const BoxDecoration(
        color: AppTheme.background,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Search bar — expands to fill available space
          Expanded(
            child: Focus(
              onFocusChange: (f) => setState(() => _searchFocused = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _searchFocused
                        ? AppTheme.accentCyan.withValues(alpha: 0.5)
                        : AppTheme.border,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 11),
                    const Icon(Icons.search, color: AppTheme.textMuted, size: 15),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: widget.onSearch,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          height: 1.0, // prevents vertical drift
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search vault...',
                          hintStyle: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                            height: 1.0,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Sort buttons
          _SortButton(
            label: 'Title',
            selected: widget.sortMode == SortMode.title,
            onTap: () => widget.onSortChanged(SortMode.title),
          ),
          const SizedBox(width: 4),
          _SortButton(
            label: 'Strength',
            selected: widget.sortMode == SortMode.strength,
            onTap: () => widget.onSortChanged(SortMode.strength),
          ),
          const SizedBox(width: 4),
          _SortButton(
            label: 'Date',
            selected: widget.sortMode == SortMode.date,
            onTap: () => widget.onSortChanged(SortMode.date),
          ),

          const SizedBox(width: 16),

          // New Entry button
          _NewEntryButton(onTap: widget.onNewEntry),
        ],
      ),
    );
  }
}

class _SortButton extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_SortButton> createState() => _SortButtonState();
}

class _SortButtonState extends State<_SortButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.selected
                ? Color(0xFF00EAFF).withValues(alpha: 0.2)
                : _hovered
                    ? AppTheme.border
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
                      BoxShadow(
                        color: widget.selected ? Color(0xFF00EAFF).withValues(alpha: 0.15) : Colors.transparent,
                        blurRadius: 7.5,
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: widget.selected ? Color(0xFF00EAFF).withValues(alpha: 0.05) : Colors.transparent,
                        blurRadius: 15,
                        spreadRadius: 0,
                      ),
                    ],
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.selected ? Color(0xFF00EAFF) : AppTheme.textSecondary,
              fontSize: 13,
              fontWeight:
                  widget.selected ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _NewEntryButton extends StatefulWidget {
  final VoidCallback onTap;
  const _NewEntryButton({required this.onTap});

  @override
  State<_NewEntryButton> createState() => _NewEntryButtonState();
}

class _NewEntryButtonState extends State<_NewEntryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered
                ? Color(0xFF00EAFF).withValues(alpha: 0.5)
                : Color(0xFF00EAFF),
            boxShadow: [
                      BoxShadow(
                        color: Color(0xFF00EAFF).withValues(alpha: 0.15),
                        blurRadius: 20,
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Color(0xFF00EAFF).withValues(alpha: 0.05),
                        blurRadius: 40,
                        spreadRadius: 0,
                      ),
                    ],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.add, color: Colors.black, size: 20),
              SizedBox(width: 6),
              Text(
                'NEW ENTRY',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}