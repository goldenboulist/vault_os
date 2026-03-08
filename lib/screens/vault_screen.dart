import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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

  bool get _isDesktopPlatform {
    final platform = defaultTargetPlatform;
    return platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux;
  }

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final useDrawer = !_isDesktopPlatform || screenWidth < 900;

        final baseWidth = _isDesktopPlatform ? 1280.0 : 350.0;
        final scale = (screenWidth / baseWidth).clamp(0.90, 1.35);
        final minTap = _isDesktopPlatform ? 40.0 : 48.0;

        final content = Column(
          children: [
            if (useDrawer)
              SizedBox(
                height: (61 * scale).clamp(minTap, 72.0),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.only(left: minTap),
                        child: TopBar(
                          sortMode: _sortMode,
                          onSortChanged: (m) => setState(() => _sortMode = m),
                          onNewEntry: _showCreateEntryDialog,
                          onSearch: (q) => setState(() => _searchQuery = q),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Builder(
                        builder: (context) => SizedBox(
                          width: minTap,
                          child: IconButton(
                            onPressed: () => Scaffold.of(context).openDrawer(),
                            icon: const Icon(Icons.menu),
                            tooltip: 'Menu',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
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
                      scale: scale,
                      onEdit: _showEditEntryDialog,
                      onDelete: _deleteEntry,
                    ),
            ),
          ],
        );

        return Scaffold(
          backgroundColor: AppTheme.background,
          drawer: useDrawer
              ? Drawer(
                  backgroundColor: AppTheme.background,
                  child: Sidebar(
                    vault: widget.vaultState,
                    selectedCategoryId: _selectedCategoryId,
                    onCategorySelected: (id) {
                      setState(() => _selectedCategoryId = id);
                      Navigator.of(context).maybePop();
                    },
                    onCategoryCreated: _onCategoryCreated,
                    onCategoryUpdated: _onCategoryUpdated,
                    onCategoryDeleted: _onCategoryDeleted,
                    onLock: widget.onLock,
                  ),
                )
              : null,
          body: useDrawer
              ? SafeArea(child: content)
              : Row(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(color: AppTheme.border, width: 1),
                        ),
                      ),
                      child: Sidebar(
                        vault: widget.vaultState,
                        selectedCategoryId: _selectedCategoryId,
                        onCategorySelected: (id) =>
                            setState(() => _selectedCategoryId = id),
                        onCategoryCreated: _onCategoryCreated,
                        onCategoryUpdated: _onCategoryUpdated,
                        onCategoryDeleted: _onCategoryDeleted,
                        onLock: widget.onLock,
                      ),
                    ),
                    Expanded(child: content),
                  ],
                ),
        );
      },
    );
  }
}

// ── Password grid ─────────────────────────────────────────────────────────────

class _PasswordGrid extends StatelessWidget {
  final List<PasswordEntry> entries;
  final VaultState vault;
  final String pageTitle;
  final double scale;
  final void Function(PasswordEntry) onEdit;
  final void Function(String id) onDelete;

  const _PasswordGrid({
    required this.entries,
    required this.vault,
    required this.pageTitle,
    required this.scale,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final horizontal = 24.0 * scale;
    final top = 26.0 * scale;
    final headerBottom = 18.0 * scale;
    final gridBottom = 24.0 * scale;
    final spacing = 12.0 * scale;

    final titleStyle = Theme.of(context).textTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        );

    final countStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppTheme.textMuted,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxExtent = (constraints.maxWidth * 0.95).clamp(280.0, 520.0);
        final cardHeight = (195.0 * scale).clamp(175.0, 220.0);

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  top,
                  horizontal,
                  headerBottom,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pageTitle, style: titleStyle),
                          SizedBox(height: 4 * scale),
                          Text(
                            '${entries.length} ${entries.length == 1 ? 'entry' : 'entries'}',
                            style: countStyle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, gridBottom),
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
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: maxExtent,
                  mainAxisExtent: cardHeight,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;
    final isDesktop = platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux;
    final baseWidth = isDesktop ? 1280.0 : 360.0;
    final scale = (MediaQuery.sizeOf(context).width / baseWidth).clamp(0.90, 1.35);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: (64 * scale).clamp(52.0, 84.0),
            height: (64 * scale).clamp(52.0, 84.0),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Icon(
              Icons.search_off_outlined,
              color: AppTheme.textMuted,
              size: (28 * scale).clamp(22.0, 38.0),
            ),
          ),
          SizedBox(height: 16 * scale),
          Text(
            'No entries found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 6 * scale),
          Text(
            'Try a different search or category',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}