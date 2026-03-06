import 'package:flutter/material.dart';
import '../models/password_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/sidebar.dart';
import '../widgets/top_bar.dart';
import '../widgets/password_card.dart';
import '../widgets/new_entry_dialog.dart';

class VaultScreen extends StatefulWidget {
  final VoidCallback onLock;
  final VaultState vaultState;
  
  const VaultScreen({super.key, required this.onLock, required this.vaultState});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  String _selectedCategoryId = kCatAll;
  SortMode _sortMode = SortMode.title;
  String _searchQuery = '';

  // ── Computed ───────────────────────────────────────────────────────────────

  List<PasswordEntry> get _filteredEntries {
    var entries = List<PasswordEntry>.from(widget.vaultState.entries);

    if (_selectedCategoryId != kCatAll) {
      entries = entries.where((e) => e.categoryId == _selectedCategoryId).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      entries = entries
          .where((e) =>
              e.title.toLowerCase().contains(q) ||
              e.username.toLowerCase().contains(q))
          .toList();
    }

    switch (_sortMode) {
      case SortMode.title:
        entries.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortMode.strength:
        entries.sort((a, b) => b.strength.index.compareTo(a.strength.index));
        break;
      case SortMode.date:
        entries.sort((a, b) => b.lastModified.compareTo(a.lastModified));
        break;
    }

    return entries;
  }

  String get _pageTitle {
    if (_selectedCategoryId == kCatAll) return 'All Passwords';
    final cat = widget.vaultState.categoryById(_selectedCategoryId);
    return cat != null ? '${cat.name} Passwords' : 'Passwords';
  }

  // ── Entry actions ──────────────────────────────────────────────────────────

  void _showCreateEntryDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => NewEntryDialog(
        categories: widget.vaultState.categories,
        existingEntries: widget.vaultState.entries,
        onSave: (entry) async {
          await widget.vaultState.addEntry(entry);
          setState(() {});
        },
      ),
    );
  }

  void _showEditEntryDialog(PasswordEntry entry) {
    showDialog<void>(
      context: context,
      builder: (_) => NewEntryDialog(
        categories: widget.vaultState.categories,
        existingEntries: widget.vaultState.entries,
        existingEntry: entry,
        onSave: (updated) async {
          await widget.vaultState.updateEntry(updated);
          setState(() {});
        },
      ),
    );
  }

  void _deleteEntry(String id) async {
    await widget.vaultState.removeEntry(id);
    setState(() {});
  }

  // ── Category actions ───────────────────────────────────────────────────────

  void _onCategoryCreated(VaultCategory cat) async {
    await widget.vaultState.addCategory(cat);
    setState(() {});
  }

  void _onCategoryUpdated(VaultCategory cat) async {
    await widget.vaultState.updateCategory(cat);
    setState(() {});
  }

  void _onCategoryDeleted(VaultCategory cat) async {
    if (_selectedCategoryId == cat.id) {
      setState(() => _selectedCategoryId = kCatAll);
    }
    await widget.vaultState.removeCategory(cat.id);
    setState(() {});
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEntries;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          Container(
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: AppTheme.border, width: 1)),
            ),
            child: Sidebar(
              vault: widget.vaultState,
              selectedCategoryId: _selectedCategoryId,
              onCategorySelected: (id) => setState(() => _selectedCategoryId = id),
              onCategoryCreated: _onCategoryCreated,
              onCategoryUpdated: _onCategoryUpdated,
              onCategoryDeleted: _onCategoryDeleted,
              onLock: widget.onLock,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                TopBar(
                  sortMode: _sortMode,
                  onSortChanged: (m) => setState(() => _sortMode = m),
                  onNewEntry: _showCreateEntryDialog,
                  onSearch: (q) => setState(() => _searchQuery = q),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const _EmptyState()
                      : _PasswordGrid(
                          entries: filtered,
                          vault: widget.vaultState,
                          pageTitle: _pageTitle,
                          onEdit: _showEditEntryDialog,
                          onDelete: _deleteEntry,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Password grid ─────────────────────────────────────────────────────────────

class _PasswordGrid extends StatelessWidget {
  final List<PasswordEntry> entries;
  final VaultState vault;
  final String pageTitle;
  final void Function(PasswordEntry) onEdit;
  final void Function(String id) onDelete;

  const _PasswordGrid({
    required this.entries,
    required this.vault,
    required this.pageTitle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pageTitle,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${entries.length} ${entries.length == 1 ? 'entry' : 'entries'}',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final entry = entries[index];
                return PasswordCard(
                  entry: entry,
                  category: vault.categoryById(entry.categoryId),
                  onEdit: () => onEdit(entry),
                  onDelete: () => onDelete(entry.id),
                );
              },
              childCount: entries.length,
            ),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 520,
              mainAxisExtent: 195,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(Icons.search_off_outlined, color: AppTheme.textMuted, size: 28),
          ),
          const SizedBox(height: 16),
          const Text(
            'No entries found',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try a different search or category',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}