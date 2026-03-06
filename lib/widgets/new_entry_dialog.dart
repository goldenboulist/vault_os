import 'dart:math';
import 'package:flutter/material.dart';
import '../models/password_entry.dart';
import '../theme/app_theme.dart';

class NewEntryDialog extends StatefulWidget {
  final List<VaultCategory> categories;
  final List<PasswordEntry> existingEntries; // Add existing entries for auto-completion
  final PasswordEntry? existingEntry; // null = create, non-null = edit
  final void Function(PasswordEntry entry) onSave;

  const NewEntryDialog({
    super.key,
    required this.categories,
    this.existingEntries = const [], // Default to empty list
    required this.onSave,
    this.existingEntry,
  });

  bool get isEditing => existingEntry != null;

  @override
  State<NewEntryDialog> createState() => _NewEntryDialogState();
}

class _NewEntryDialogState extends State<NewEntryDialog> {
  late TextEditingController _serviceCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _passwordCtrl;
  late TextEditingController _urlCtrl;
  late TextEditingController _notesCtrl;

  late String _selectedCategoryId;
  late bool _hasTwoFA;
  bool _passwordVisible = false;

  String? _serviceError;
  String? _usernameError;
  String? _passwordError;

  // Auto-completion state
  bool _showSuggestions = false;

  List<VaultCategory> get _selectableCategories =>
      widget.categories.where((c) => c.id != 'all').toList();

  // Get unique usernames from existing entries
  List<String> get _existingUsernames {
    final usernames = widget.existingEntries
        .map((entry) => entry.username.toLowerCase())
        .toSet()
        .toList();
    usernames.sort();
    return usernames;
  }

  // Filter suggestions based on input
  List<String> get _filteredSuggestions {
    final input = _usernameCtrl.text.toLowerCase();
    if (input.isEmpty) return [];
    
    return _existingUsernames
        .where((username) => username.contains(input))
        .take(5) // Limit to 5 suggestions
        .toList();
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existingEntry;
    _serviceCtrl  = TextEditingController(text: e?.title ?? '');
    _usernameCtrl = TextEditingController(text: e?.username ?? '');
    _passwordCtrl = TextEditingController(text: e?.password ?? '');
    _urlCtrl      = TextEditingController(text: e?.websiteUrl ?? '');
    _notesCtrl    = TextEditingController(text: e?.notes ?? '');
    _selectedCategoryId = e?.categoryId ?? kCatOther;
    _hasTwoFA     = e?.hasTwoFA ?? false;
    // Show password in edit mode so user can see current value
    _passwordVisible = widget.isEditing;
  }

  @override
  void dispose() {
    _serviceCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _urlCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _generatePassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()_+-=';
    final rng = Random.secure();
    final pwd =
        List.generate(24, (_) => chars[rng.nextInt(chars.length)]).join();
    setState(() {
      _passwordCtrl.text = pwd;
      _passwordVisible = true;
      _passwordError = null;
    });
  }

  bool _validate() {
    setState(() {
      _serviceError  = _serviceCtrl.text.trim().isEmpty  ? 'Service name is required' : null;
      _usernameError = _usernameCtrl.text.trim().isEmpty ? 'Username / email is required' : null;
      _passwordError = _passwordCtrl.text.isEmpty        ? 'Password is required' : null;
    });
    return _serviceError == null &&
        _usernameError == null &&
        _passwordError == null;
  }

  void _save() {
    if (!_validate()) return;
    final pwd      = _passwordCtrl.text;
    final strength = PasswordEntry.deriveStrength(pwd);

    final entry = widget.isEditing
        ? widget.existingEntry!.copyWith(
            title:      _serviceCtrl.text.trim(),
            username:   _usernameCtrl.text.trim(),
            password:   pwd,
            categoryId: _selectedCategoryId,
            hasTwoFA:   _hasTwoFA,
            strength:   strength,
            lastModified: DateTime.now(),
            websiteUrl: _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
            notes:      _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          )
        : PasswordEntry(
            id:           DateTime.now().millisecondsSinceEpoch.toString(),
            title:        _serviceCtrl.text.trim(),
            username:     _usernameCtrl.text.trim(),
            password:     pwd,
            logoAsset:    'custom',
            categoryId:   _selectedCategoryId,
            hasTwoFA:     _hasTwoFA,
            strength:     strength,
            lastModified: DateTime.now(),
            websiteUrl:   _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
            notes:        _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          );

    widget.onSave(entry);
    Navigator.pop(context);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.93,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0E1119),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderLight, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.75),
              blurRadius: 60, spreadRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('SERVICE NAME *'),
                    const SizedBox(height: 8),
                    _textField(
                      controller: _serviceCtrl,
                      hint: 'e.g. GitHub, Gmail...',
                      error: _serviceError,
                      onChanged: (_) => setState(() => _serviceError = null),
                    ),
                    const SizedBox(height: 20),

                    _label('CATEGORY'),
                    const SizedBox(height: 10),
                    _buildCategoryChips(),
                    const SizedBox(height: 20),

                    _label('USERNAME / EMAIL *'),
                    const SizedBox(height: 8),
                    _buildUsernameField(),
                    const SizedBox(height: 20),

                    _label('PASSWORD *'),
                    const SizedBox(height: 8),
                    _buildPasswordRow(),
                    if (_passwordError != null) ...[
                      const SizedBox(height: 4),
                      Text(_passwordError!,
                          style: const TextStyle(
                              color: AppTheme.accentOrange, fontSize: 11)),
                    ],
                    const SizedBox(height: 20),

                    _label('WEBSITE URL'),
                    const SizedBox(height: 8),
                    _textField(
                      controller: _urlCtrl,
                      hint: 'github.com',
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 20),

                    _buildTwoFARow(),
                    const SizedBox(height: 20),

                    _label('NOTES'),
                    const SizedBox(height: 8),
                    _buildNotesField(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ── Sub-builders ──────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Text(
            widget.isEditing ? 'EDIT ENTRY' : 'NEW ENTRY',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5,
            ),
          ),
          if (widget.isEditing) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: AppTheme.accentBlue.withValues(alpha: 0.3)),
              ),
              child: Text(
                widget.existingEntry!.title,
                style: const TextStyle(
                  color: AppTheme.accentBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const Spacer(),
          _CloseBtn(onTap: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    String? error,
    ValueChanged<String>? onChanged,
    TextInputType? keyboardType,
  }) {
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
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 13, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 13, fontFamily: 'monospace'),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 13),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(error,
              style: const TextStyle(
                  color: AppTheme.accentOrange, fontSize: 11)),
        ],
      ],
    );
  }

  Widget _buildPasswordRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF090C13),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _passwordError != null
                    ? AppTheme.accentOrange.withValues(alpha: 0.6)
                    : AppTheme.border,
              ),
            ),
            child: TextField(
              controller: _passwordCtrl,
              obscureText: !_passwordVisible,
              onChanged: (_) => setState(() => _passwordError = null),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontFamily: 'monospace',
                letterSpacing: 1.5,
              ),
              decoration: InputDecoration(
                hintText: '••••••••••••••••',
                hintStyle: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 13, letterSpacing: 2),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 13),
                suffixIcon: GestureDetector(
                  onTap: () =>
                      setState(() => _passwordVisible = !_passwordVisible),
                  child: Icon(
                    _passwordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppTheme.textMuted,
                    size: 17,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _GenerateBtn(onTap: _generatePassword),
      ],
    );
  }

  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF090C13),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _usernameError != null
                  ? AppTheme.accentOrange.withValues(alpha: 0.6)
                  : AppTheme.border,
            ),
          ),
          child: TextField(
            controller: _usernameCtrl,
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) {
              setState(() {
                _usernameError = null;
                _showSuggestions = value.isNotEmpty && _filteredSuggestions.isNotEmpty;
              });
            },
            onTap: () {
              setState(() {
                _showSuggestions = _usernameCtrl.text.isNotEmpty && _filteredSuggestions.isNotEmpty;
              });
            },
            style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 13, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: 'user@example.com',
              hintStyle: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 13, fontFamily: 'monospace'),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 13),
            ),
          ),
        ),
        if (_usernameError != null) ...[
          const SizedBox(height: 4),
          Text(_usernameError!,
              style: const TextStyle(
                  color: AppTheme.accentOrange, fontSize: 11)),
        ],
        // Auto-completion suggestions
        if (_showSuggestions && _filteredSuggestions.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F2E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _filteredSuggestions.map((suggestion) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _usernameCtrl.text = suggestion;
                      _showSuggestions = false;
                      _usernameError = null;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppTheme.border.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    child: Text(
                      suggestion,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _selectableCategories.map((cat) {
        return _CategoryChip(
          cat: cat,
          selected: _selectedCategoryId == cat.id,
          onTap: () => setState(() => _selectedCategoryId = cat.id),
        );
      }).toList(),
    );
  }

  Widget _buildTwoFARow() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TWO-FACTOR AUTH',
                  style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5)),
              SizedBox(height: 2),
              Text('Tag this entry with a 2FA badge',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            ],
          ),
        ),
        Switch(
          value: _hasTwoFA,
          onChanged: (v) => setState(() => _hasTwoFA = v),
          activeThumbColor: AppTheme.accentCyan,
          activeTrackColor: AppTheme.accentCyan.withValues(alpha: 0.25),
          inactiveTrackColor: AppTheme.border,
          inactiveThumbColor: AppTheme.textMuted,
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF090C13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: TextField(
        controller: _notesCtrl,
        maxLines: 4,
        style: const TextStyle(
            color: AppTheme.textSecondary, fontSize: 13, fontFamily: 'monospace'),
        decoration: const InputDecoration(
          hintText: 'Additional secure notes...',
          hintStyle: TextStyle(
              color: AppTheme.textMuted, fontSize: 13, fontFamily: 'monospace'),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.all(14),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border))),
      child: Row(
        children: [
          Expanded(
              child: _CancelBtn(onTap: () => Navigator.pop(context))),
          const SizedBox(width: 12),
          Expanded(
              child: _SaveBtn(
            label: widget.isEditing ? 'SAVE CHANGES' : 'SAVE ENTRY',
            onTap: _save,
          )),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ══════════════════════════════════════════════════════════════════════════════

class _CategoryChip extends StatefulWidget {
  final VaultCategory cat;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip(
      {required this.cat, required this.selected, required this.onTap});

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final sel = widget.selected;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: sel
                ? widget.cat.accentColor.withValues(alpha: 0.1)
                : _hovered
                    ? AppTheme.border
                    : const Color(0xFF090C13),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: sel
                  ? widget.cat.accentColor.withValues(alpha: 0.55)
                  : _hovered
                      ? AppTheme.borderLight
                      : AppTheme.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.cat.icon,
                  size: 13,
                  color: sel
                      ? widget.cat.accentColor
                      : AppTheme.textMuted),
              const SizedBox(width: 6),
              Text(
                widget.cat.name,
                style: TextStyle(
                  color: sel
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenerateBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _GenerateBtn({required this.onTap});

  @override
  State<_GenerateBtn> createState() => _GenerateBtnState();
}

class _GenerateBtnState extends State<_GenerateBtn>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {
          _spin.forward(from: 0);
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: _hovered
                ? AppTheme.accentCyan.withValues(alpha: 0.1)
                : const Color(0xFF090C13),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered
                  ? AppTheme.accentCyan.withValues(alpha: 0.4)
                  : AppTheme.border,
            ),
          ),
          child: Center(
            child: AnimatedBuilder(
              animation: _spin,
              builder: (_, child) => Transform.rotate(
                  angle: _spin.value * 2 * pi, child: child),
              child: Icon(Icons.refresh_rounded,
                  size: 18,
                  color: _hovered
                      ? AppTheme.accentCyan
                      : AppTheme.textMuted),
            ),
          ),
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
          duration: const Duration(milliseconds: 150),
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: _hovered ? AppTheme.border : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color:
                    _hovered ? AppTheme.borderLight : AppTheme.border),
          ),
          child: Icon(Icons.close,
              color: _hovered
                  ? AppTheme.textSecondary
                  : AppTheme.textMuted,
              size: 14),
        ),
      ),
    );
  }
}

class _CancelBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _CancelBtn({required this.onTap});

  @override
  State<_CancelBtn> createState() => _CancelBtnState();
}

class _CancelBtnState extends State<_CancelBtn> {
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
          padding: const EdgeInsets.symmetric(vertical: 14),
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
            child: Text('CANCEL',
                style: TextStyle(
                    color: _hovered
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8)),
          ),
        ),
      ),
    );
  }
}

class _SaveBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _SaveBtn({required this.label, required this.onTap});

  @override
  State<_SaveBtn> createState() => _SaveBtnState();
}

class _SaveBtnState extends State<_SaveBtn> {
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.accentCyan,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentCyan
                    .withValues(alpha: _hovered ? 0.40 : 0.18),
                blurRadius: _hovered ? 22 : 8,
              ),
            ],
          ),
          child: Center(
            child: Text(widget.label,
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8)),
          ),
        ),
      ),
    );
  }
}