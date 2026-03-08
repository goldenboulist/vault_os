import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/password_entry.dart';
import '../theme/app_theme.dart';
import 'service_logo.dart';
import 'badges.dart';

class PasswordCard extends StatefulWidget {
  final PasswordEntry entry;
  final VaultCategory? category;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PasswordCard({
    super.key,
    required this.entry,
    this.category,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<PasswordCard> createState() => _PasswordCardState();
}

class _PasswordCardState extends State<PasswordCard>
    with TickerProviderStateMixin {
  bool _isHovered = false;
  bool _passwordVisible = false;
  bool _usernameCopied = false;
  bool _passwordCopied = false;

  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.01).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    setState(() => _isHovered = hovering);
    hovering ? _scaleController.forward() : _scaleController.reverse();
  }

  Future<void> _copyUsername() async {
    await Clipboard.setData(ClipboardData(text: widget.entry.username));
    if (!mounted) return;
    setState(() => _usernameCopied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _usernameCopied = false);
  }

  Future<void> _copyPassword() async {
    await Clipboard.setData(ClipboardData(text: widget.entry.password));
    if (!mounted) return;
    setState(() => _passwordCopied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _passwordCopied = false);
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => _DeleteConfirmDialog(
        title: widget.entry.title,
        onConfirm: widget.onDelete ?? () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isHovered ? AppTheme.surfaceElevated : AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered ? AppTheme.borderLight : AppTheme.border,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ServiceLogo(
                      service: widget.entry.websiteUrl, size: 38),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.entry.title,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            if (cat != null) CategoryTag(category: cat),
                            if (widget.entry.hasTwoFA) ...[
                              const SizedBox(width: 5),
                              const TwoFABadge(),
                            ],
                            if (widget.entry.hasSharing) ...[
                              const SizedBox(width: 5),
                              const Icon(Icons.share_outlined,
                                  size: 12,
                                  color: AppTheme.textMuted),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Action buttons — visible on hover (desktop) or always (mobile)
                  AnimatedOpacity(
                    opacity: (_isHovered || Theme.of(context).platform == TargetPlatform.android || Theme.of(context).platform == TargetPlatform.iOS) ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 180),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CardActionBtn(
                          icon: Icons.edit_outlined,
                          color: AppTheme.accentBlue,
                          onTap: widget.onEdit ?? () {},
                        ),
                        const SizedBox(width: 4),
                        _CardActionBtn(
                          icon: Icons.delete_outline_rounded,
                          color: const Color(0xFFFF4444),
                          onTap: () => _confirmDelete(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(color: AppTheme.border, height: 1),
              const SizedBox(height: 10),

              // ── Username ──────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.entry.username,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _CopyBtn(
                      copied: _usernameCopied, onTap: _copyUsername),
                ],
              ),

              const SizedBox(height: 8),

              // ── Password ──────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _passwordVisible
                          ? widget.entry.password
                          : '•' *
                              widget.entry.password.length.clamp(8, 16),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontFamily: 'monospace',
                        letterSpacing: 1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _SmallIconBtn(
                    icon: _passwordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    onTap: () => setState(
                        () => _passwordVisible = !_passwordVisible),
                  ),
                  const SizedBox(width: 2),
                  _CopyBtn(
                      copied: _passwordCopied, onTap: _copyPassword),
                ],
              ),

              const SizedBox(height: 12),

              // ── Strength bar + date ───────────────────────────────────
              Row(
                children: [
                  Expanded(
                      child:
                          StrengthBar(strength: widget.entry.strength)),
                  const SizedBox(width: 10),
                  Text(
                    widget.entry.formattedDate,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Card action button (edit / delete in top-right)
// ══════════════════════════════════════════════════════════════════════════════

class _CardActionBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CardActionBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  State<_CardActionBtn> createState() => _CardActionBtnState();
}

class _CardActionBtnState extends State<_CardActionBtn> {
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
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.15)
                : AppTheme.border.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _hovered
                  ? widget.color.withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
          ),
          child: Icon(widget.icon, size: 13, color: widget.color),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Copy button with check feedback
// ══════════════════════════════════════════════════════════════════════════════

class _CopyBtn extends StatefulWidget {
  final bool copied;
  final VoidCallback onTap;

  const _CopyBtn({required this.copied, required this.onTap});

  @override
  State<_CopyBtn> createState() => _CopyBtnState();
}

class _CopyBtnState extends State<_CopyBtn> {
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
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: widget.copied
                ? AppTheme.accentGreen.withValues(alpha: 0.12)
                : _hovered
                    ? AppTheme.border
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: widget.copied
                ? const Icon(Icons.check,
                    key: ValueKey<String>('check'),
                    size: 13,
                    color: AppTheme.accentGreen)
                : Icon(Icons.copy_outlined,
                    key: const ValueKey<String>('copy'),
                    size: 13,
                    color: _hovered
                        ? AppTheme.textSecondary
                        : AppTheme.textMuted),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Visibility icon button
// ══════════════════════════════════════════════════════════════════════════════

class _SmallIconBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SmallIconBtn({required this.icon, required this.onTap});

  @override
  State<_SmallIconBtn> createState() => _SmallIconBtnState();
}

class _SmallIconBtnState extends State<_SmallIconBtn> {
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
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: _hovered ? AppTheme.border : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Icon(widget.icon,
              size: 13,
              color:
                  _hovered ? AppTheme.textSecondary : AppTheme.textMuted),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Delete confirm dialog
// ══════════════════════════════════════════════════════════════════════════════

class _DeleteConfirmDialog extends StatelessWidget {
  final String title;
  final VoidCallback onConfirm;

  const _DeleteConfirmDialog(
      {required this.title, required this.onConfirm});

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
              child: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFFF4444), size: 22),
            ),
            const SizedBox(height: 16),
            const Text('Delete Entry',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.5),
                children: [
                  const TextSpan(
                      text: 'Are you sure you want to delete '),
                  TextSpan(
                      text: title,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600)),
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
                      onTap: () => Navigator.pop(context)),
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
            child: Text(widget.label,
                style: TextStyle(
                    color: _hovered
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
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
            child: Text(widget.label,
                style: TextStyle(
                    color: _hovered
                        ? const Color(0xFFFF6666)
                        : const Color(0xFFFF4444),
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}