import 'package:flutter/material.dart';
import '../models/password_entry.dart';
import '../theme/app_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Sidebar extends StatelessWidget {
  final VaultState vault;
  final String selectedCategoryId;
  final ValueChanged<String> onCategorySelected;
  final void Function(VaultCategory cat) onCategoryCreated;
  final void Function(VaultCategory cat) onCategoryUpdated;
  final void Function(VaultCategory cat) onCategoryDeleted;
  final VoidCallback onLock;

  const Sidebar({
    super.key,
    required this.vault,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.onCategoryCreated,
    required this.onCategoryUpdated,
    required this.onCategoryDeleted,
    required this.onLock,
  });

  @override
  Widget build(BuildContext context) {
    final cats = vault.categories;

    return SafeArea(
      bottom: false,
      child: Container(
        width: 226,
        color: AppTheme.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Logo ────────────────────────────────────────────────────
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Color(0xFF00EAFF).withValues(alpha: 0.2),
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
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: SvgPicture.string(
                        '''
                      <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" 
                      viewBox="0 0 24 24" fill="none" stroke="currentColor" 
                      stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/>
                      </svg>
                        ''',
                        width: 16,
                        height: 16,
                        colorFilter: ColorFilter.mode(
                          Color(0xFF00EAFF),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'VAULT_OS',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: AppTheme.border, height: 1),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(label: 'CATEGORIES'),
                    const SizedBox(height: 6),

                    // Category list
                    ...cats.map((cat) => _CategoryItem(
                          key: ValueKey(cat.id),
                          cat: cat,
                          count: vault.countForCategory(cat.id),
                          selected: selectedCategoryId == cat.id,
                          onTap: () => onCategorySelected(cat.id),
                          onEdit: cat.isBuiltIn
                              ? null
                              : () => _showEditDialog(context, cat),
                          onDelete: cat.isBuiltIn
                              ? null
                              : () => _showDeleteConfirm(context, cat),
                        )),

                    // Add category button
                    _AddCategoryBtn(
                      onTap: () => _showCreateDialog(context),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(color: AppTheme.border, height: 1),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _ToolItem(
                      icon: Icons.settings_outlined, label: 'Settings'),
                  _LockItem(onTap: onLock),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _showCreateDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => _CategoryFormDialog(
        title: 'New Category',
        onSave: (name, icon, color) {
          final cat = VaultCategory(
            id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
            name: name,
            icon: icon,
            accentColor: color,
            isBuiltIn: false,
          );
          onCategoryCreated(cat);
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, VaultCategory cat) {
    showDialog<void>(
      context: context,
      builder: (_) => _CategoryFormDialog(
        title: 'Edit Category',
        existing: cat,
        onSave: (name, icon, color) {
          onCategoryUpdated(cat.copyWith(
              name: name, icon: icon, accentColor: color));
        },
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, VaultCategory cat) {
    final count = vault.countForCategory(cat.id);
    showDialog<void>(
      context: context,
      builder: (_) => _DeleteCategoryDialog(
        cat: cat,
        entryCount: count,
        onConfirm: () => onCategoryDeleted(cat),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Category item row
// ══════════════════════════════════════════════════════════════════════════════

class _CategoryItem extends StatefulWidget {
  final VaultCategory cat;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _CategoryItem({
    super.key,
    required this.cat,
    required this.count,
    required this.selected,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<_CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<_CategoryItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.selected;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? widget.cat.accentColor.withValues(alpha: 0.08)
                : _hovered
                    ? AppTheme.sidebarHover
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isActive
                ? Border.all(
                    color: widget.cat.accentColor.withValues(alpha: 0.2))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.cat.icon,
                size: 15,
                color: isActive
                    ? widget.cat.accentColor
                    : AppTheme.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.cat.name,
                  style: TextStyle(
                    color: isActive
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Action buttons on hover (custom only)
              if (_hovered && !widget.cat.isBuiltIn) ...[
                _MicroBtn(
                  icon: Icons.edit_outlined,
                  onTap: widget.onEdit ?? () {},
                  color: AppTheme.accentBlue,
                ),
                const SizedBox(width: 2),
                _MicroBtn(
                  icon: Icons.delete_outline_rounded,
                  onTap: widget.onDelete ?? () {},
                  color: const Color(0xFFFF4444),
                ),
              ] else if (widget.count > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive
                        ? widget.cat.accentColor.withValues(alpha: 0.15)
                        : AppTheme.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.count}',
                    style: TextStyle(
                      color: isActive
                          ? widget.cat.accentColor
                          : AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Add category button
// ══════════════════════════════════════════════════════════════════════════════

class _AddCategoryBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _AddCategoryBtn({required this.onTap});

  @override
  State<_AddCategoryBtn> createState() => _AddCategoryBtnState();
}

class _AddCategoryBtnState extends State<_AddCategoryBtn> {
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
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered
                ? AppTheme.accentCyan.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered
                  ? AppTheme.accentCyan.withValues(alpha: 0.3)
                  : AppTheme.border.withValues(alpha: 0.5),
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.add,
                  size: 14,
                  color: _hovered
                      ? AppTheme.accentCyan
                      : AppTheme.textMuted),
              const SizedBox(width: 8),
              Text(
                'Add Category',
                style: TextStyle(
                  color: _hovered
                      ? AppTheme.accentCyan
                      : AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Category form dialog (create + edit)
// ══════════════════════════════════════════════════════════════════════════════

class _CategoryFormDialog extends StatefulWidget {
  final String title;
  final VaultCategory? existing;
  final void Function(String name, IconData icon, Color color) onSave;

  const _CategoryFormDialog({
    required this.title,
    this.existing,
    required this.onSave,
  });

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  late TextEditingController _nameCtrl;
  late IconData _selectedIcon;
  late Color _selectedColor;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.existing?.name ?? '');
    _selectedIcon =
        widget.existing?.icon ?? kCategoryIcons.first;
    _selectedColor =
        widget.existing?.accentColor ?? kCategoryColors.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _nameError = 'Name is required');
      return;
    }
    widget.onSave(
        _nameCtrl.text.trim(), _selectedIcon, _selectedColor);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 420,
        decoration: BoxDecoration(
          color: const Color(0xFF0E1119),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 50),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _DialogHeader(
              title: widget.title,
              onClose: () => Navigator.pop(context),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name field
                  _FieldLabel('CATEGORY NAME *'),
                  const SizedBox(height: 8),
                  _DarkTextField(
                    controller: _nameCtrl,
                    hint: 'e.g. Gaming, Personal...',
                    error: _nameError,
                    onChanged: (_) =>
                        setState(() => _nameError = null),
                  ),
                  const SizedBox(height: 20),

                  // Color picker
                  _FieldLabel('ACCENT COLOR'),
                  const SizedBox(height: 10),
                  _ColorPicker(
                    selected: _selectedColor,
                    onSelected: (c) =>
                        setState(() => _selectedColor = c),
                  ),
                  const SizedBox(height: 20),

                  // Icon picker
                  _FieldLabel('ICON'),
                  const SizedBox(height: 10),
                  _IconPicker(
                    selected: _selectedIcon,
                    accentColor: _selectedColor,
                    onSelected: (i) =>
                        setState(() => _selectedIcon = i),
                  ),
                  const SizedBox(height: 22),

                  // Preview
                  _CategoryPreview(
                    name: _nameCtrl.text.isEmpty
                        ? 'Preview'
                        : _nameCtrl.text,
                    icon: _selectedIcon,
                    color: _selectedColor,
                  ),
                  const SizedBox(height: 22),
                ],
              ),
            ),

            // Footer
            _DialogFooter(
              confirmLabel:
                  widget.existing != null ? 'Save Changes' : 'Create',
              accentColor: _selectedColor,
              onCancel: () => Navigator.pop(context),
              onConfirm: _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Delete category confirm dialog
// ══════════════════════════════════════════════════════════════════════════════

class _DeleteCategoryDialog extends StatelessWidget {
  final VaultCategory cat;
  final int entryCount;
  final VoidCallback onConfirm;

  const _DeleteCategoryDialog({
    required this.cat,
    required this.entryCount,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 380,
        decoration: BoxDecoration(
          color: const Color(0xFF0E1119),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF3A1515)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 40),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF2A0A0A),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFFCC3333)
                        .withValues(alpha: 0.4)),
              ),
              child: Icon(cat.icon,
                  color: const Color(0xFFFF4444), size: 22),
            ),
            const SizedBox(height: 16),
            const Text(
              'Delete Category',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.5),
                children: [
                  const TextSpan(text: 'Delete '),
                  TextSpan(
                    text: '"${cat.name}"',
                    style: TextStyle(
                        color: cat.accentColor,
                        fontWeight: FontWeight.w600),
                  ),
                  if (entryCount > 0)
                    TextSpan(
                      text:
                          '? Its $entryCount ${entryCount == 1 ? 'entry' : 'entries'} will be moved to Other.',
                    )
                  else
                    const TextSpan(
                        text: '? This action cannot be undone.'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _OutlineBtn(
                    label: 'Cancel',
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DangerBtn(
                    label: 'Delete',
                    onTap: () {
                      Navigator.pop(context);
                      onConfirm();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Reusable dialog sub-widgets
// ══════════════════════════════════════════════════════════════════════════════

class _DialogHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const _DialogHeader({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.border))),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
            ),
          ),
          const Spacer(),
          _CloseBtn(onTap: onClose),
        ],
      ),
    );
  }
}

class _DialogFooter extends StatelessWidget {
  final String confirmLabel;
  final Color accentColor;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _DialogFooter({
    required this.confirmLabel,
    required this.accentColor,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border))),
      child: Row(
        children: [
          Expanded(child: _OutlineBtn(label: 'Cancel', onTap: onCancel)),
          const SizedBox(width: 10),
          Expanded(
            child: _AccentBtn(
                label: confirmLabel,
                color: accentColor,
                onTap: onConfirm),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5),
    );
  }
}

class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? error;
  final ValueChanged<String>? onChanged;

  const _DarkTextField({
    required this.controller,
    required this.hint,
    this.error,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF090C13),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: error != null
                  ? AppTheme.accentOrange.withValues(alpha: 0.6)
                  : AppTheme.border,
            ),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                  fontFamily: 'monospace'),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(error!,
              style: const TextStyle(
                  color: AppTheme.accentOrange, fontSize: 11)),
        ],
      ],
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color> onSelected;

  const _ColorPicker({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kCategoryColors.map((c) {
        final isSelected = c.toARGB32() == selected.toARGB32();
        return GestureDetector(
          onTap: () => onSelected(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 8)]
                  : [],
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.black, size: 14)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

class _IconPicker extends StatelessWidget {
  final IconData selected;
  final Color accentColor;
  final ValueChanged<IconData> onSelected;

  const _IconPicker({
    required this.selected,
    required this.accentColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kCategoryIcons.map((icon) {
        final isSelected = icon == selected;
        return GestureDetector(
          onTap: () => onSelected(icon),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.15)
                  : const Color(0xFF090C13),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.6)
                    : AppTheme.border,
              ),
            ),
            child: Icon(icon,
                size: 17,
                color: isSelected ? accentColor : AppTheme.textMuted),
          ),
        );
      }).toList(),
    );
  }
}

class _CategoryPreview extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;

  const _CategoryPreview({
    required this.name,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 10),
          Text(
            name,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              name,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Small reusable button widgets
// ══════════════════════════════════════════════════════════════════════════════

class _MicroBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _MicroBtn(
      {required this.icon, required this.onTap, required this.color});

  @override
  State<_MicroBtn> createState() => _MicroBtnState();
}

class _MicroBtnState extends State<_MicroBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Icon(widget.icon, size: 13, color: widget.color),
        ),
      ),
    );
  }
}

class _CloseBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _CloseBtn({required this.onTap});

  @override
  State<_CloseBtn> createState() => _CloseBtnState();
}

class _CloseBtnState extends State<_CloseBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color:
                _hovered ? AppTheme.border : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color: _hovered
                    ? AppTheme.borderLight
                    : AppTheme.border),
          ),
          child: Icon(Icons.close,
              size: 13,
              color: _hovered
                  ? AppTheme.textSecondary
                  : AppTheme.textMuted),
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineBtn({required this.label, required this.onTap});

  @override
  State<_OutlineBtn> createState() => _OutlineBtnState();
}

class _OutlineBtnState extends State<_OutlineBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _hovered
                ? const Color(0xFF1A1E2A)
                : const Color(0xFF090C13),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color:
                    _hovered ? AppTheme.borderLight : AppTheme.border),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                  color: _hovered
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccentBtn extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AccentBtn(
      {required this.label, required this.color, required this.onTap});

  @override
  State<_AccentBtn> createState() => _AccentBtnState();
}

class _AccentBtnState extends State<_AccentBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: widget.color
                    .withValues(alpha: _hovered ? 0.4 : 0.18),
                blurRadius: _hovered ? 18 : 8,
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }
}

class _DangerBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _DangerBtn({required this.label, required this.onTap});

  @override
  State<_DangerBtn> createState() => _DangerBtnState();
}

class _DangerBtnState extends State<_DangerBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _hovered
                ? const Color(0xFF4A1212)
                : const Color(0xFF3A0F0F),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFCC3333)
                  .withValues(alpha: _hovered ? 0.8 : 0.4),
            ),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                  color: _hovered
                      ? const Color(0xFFFF6666)
                      : const Color(0xFFFF4444),
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolItem extends StatefulWidget {
  final IconData icon;
  final String label;

  const _ToolItem({required this.icon, required this.label});

  @override
  State<_ToolItem> createState() => _ToolItemState();
}

class _ToolItemState extends State<_ToolItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _hovered ? AppTheme.sidebarHover : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(widget.icon, size: 15, color: AppTheme.textMuted),
            const SizedBox(width: 10),
            Text(widget.label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _LockItem extends StatefulWidget {
  final VoidCallback onTap;
  const _LockItem({required this.onTap});

  @override
  State<_LockItem> createState() => _LockItemState();
}

class _LockItemState extends State<_LockItem> {
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
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:
                _hovered ? const Color(0xFF2A1010) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_outline,
                  size: 15,
                  color: _hovered
                      ? AppTheme.accentOrange
                      : const Color(0xFFCC4444)),
              const SizedBox(width: 10),
              Text(
                'Lock Vault',
                style: TextStyle(
                    color: _hovered
                        ? AppTheme.accentOrange
                        : const Color(0xFFCC4444),
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 2),
      child: Text(
        label,
        style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2),
      ),
    );
  }
}