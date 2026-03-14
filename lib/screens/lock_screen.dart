import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../theme/app_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';
import '../models/password_entry.dart';
import '../widgets/password_reset_dialog.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  final Function(VaultState) onVaultReady;

  const LockScreen({super.key, required this.onUnlocked, required this.onVaultReady});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  bool _isUnlockTab = true;
  bool _passwordVisible = false;
  bool _isLoading = false;
  String? _error;
  bool _hasMasterPassword = false;

  bool get _isDesktopPlatform {
    final platform = defaultTargetPlatform;
    return platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux;
  }

  double _scaleFor(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final baseWidth = _isDesktopPlatform ? 1280.0 : 360.0;
    return (width / baseWidth).clamp(0.90, 1.35);
  }

  double _minTapForPlatform() => _isDesktopPlatform ? 40.0 : 48.0;

  final TextEditingController _masterKeyCtrl = TextEditingController();
  // Initialize fields (used in Initialize mode)
  final TextEditingController _newKeyCtrl = TextEditingController();
  final TextEditingController _confirmKeyCtrl = TextEditingController();
  bool _newVisible = false;
  bool _confirmVisible = false;

  late AnimationController _shieldPulse;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _checkMasterPasswordExists();
    _shieldPulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _shieldPulse, curve: Curves.easeInOut),
    );
  }

  Future<void> _checkMasterPasswordExists() async {
    final hasPassword = await AuthService.hasMasterPassword();
    if (mounted) {
      setState(() {
        _hasMasterPassword = hasPassword;
        // Force unlock tab if master password exists
        if (_hasMasterPassword) {
          _isUnlockTab = true;
        }
      });
    }
  }

  @override
  void dispose() {
    _shieldPulse.dispose();
    _masterKeyCtrl.dispose();
    _newKeyCtrl.dispose();
    _confirmKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    if (_masterKeyCtrl.text.isEmpty) {
      setState(() => _error = 'Master key is required');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Verify master password against stored hash
      final isValid = await AuthService.verifyMasterPassword(_masterKeyCtrl.text);
      
      if (mounted) {
        setState(() => _isLoading = false);
        if (isValid) {
          // Initialize vault with master password
          final vaultState = VaultState();
          await vaultState.initialize(_masterKeyCtrl.text);
          
          // Pass initialized vault state back to main
          widget.onVaultReady(vaultState);
          widget.onUnlocked();
        } else {
          setState(() => _error = 'Invalid master key');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Authentication failed';
        });
      }
    }
  }

  Future<void> _initialize() async {
    if (_newKeyCtrl.text.isEmpty) {
      setState(() => _error = 'Master key is required');
      return;
    }
    if (_newKeyCtrl.text != _confirmKeyCtrl.text) {
      setState(() => _error = 'Keys do not match');
      return;
    }
    if (_newKeyCtrl.text.length < 8) {
      setState(() => _error = 'Key must be at least 8 characters');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Create new master password
      final success = await AuthService.createMasterPassword(_newKeyCtrl.text);
      
      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          // Initialize vault with new master password
          final vaultState = VaultState();
          await vaultState.initialize(_newKeyCtrl.text);
          
          // Pass initialized vault state back to main
          widget.onVaultReady(vaultState);
          widget.onUnlocked();
        } else {
          setState(() => _error = 'Failed to create master key');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Initialization failed: ${e.toString()}';
        });
      }
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => PasswordResetDialog(
        onResetComplete: () {
          setState(() {
            _error = null;
            _masterKeyCtrl.clear();
            _newKeyCtrl.clear();
            _confirmKeyCtrl.clear();
            _hasMasterPassword = false;
            _isUnlockTab = false; // Switch to initialize tab after reset
          });
          // Create fresh VaultState after reset
          final freshVaultState = VaultState();
          freshVaultState.reset();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;
    final isDesktop = platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux;
    return Scaffold(
    backgroundColor: AppTheme.background,
    body: Stack(
      children: [
        // ── Grid Background ─────────────────────────────────────────
        Positioned.fill(
          child: CustomPaint(
            painter: _VaultGridPainter(
              glowValue: _glowAnim.value,
            ),
          ),
        ), 
        LayoutBuilder(
          builder: (context, constraints) {
            final screenSize = MediaQuery.sizeOf(context);
            final baseWidth = isDesktop ? 1280.0 : 360.0;
            final scale = (constraints.maxWidth / baseWidth).clamp(0.90, 1.35);
            final minTap = isDesktop ? 40.0 : 48.0;

            final horizontalPadding = (isDesktop ? 32.0 : 16.0) * scale;
            final contentMaxWidth = isDesktop
                ? 520.0
                : (screenSize.width - (horizontalPadding * 2)).clamp(0.0, 420.0);

            final shieldSize = (80.0 * scale).clamp(minTap, 104.0);
            final shieldIconSize = (40.0 * scale).clamp(20.0, 56.0);
            final cardWidth = (isDesktop ? 420.0 : 370.0) * scale;
            final effectiveCardWidth = cardWidth.clamp(
              0.0,
              contentMaxWidth,
            );

            final titleStyle = Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3.5,
                );
            final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3.0,
                  fontFamily: 'monospace',
                );
            final footerStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                );

            return Center(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: (isDesktop ? 28.0 : 20.0) * scale,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: contentMaxWidth,
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── Shield icon ──────────────────────────────────────────────
                          AnimatedBuilder(
                            animation: _glowAnim,
                            builder: (_, child) => Container(
                              width: shieldSize,
                              height: shieldSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF00EAFF)
                                    .withValues(alpha: 0.10), // bg-primary/10
                                border: Border.all(
                                  color: const Color(0xFF00EAFF)
                                      .withValues(alpha: 0.30), // border-primary/30
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00EAFF).withValues(
                                      alpha: 0.15 * _glowAnim.value,
                                    ), // animated glow
                                    blurRadius: 25 * scale,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: child,
                            ),
                            child: Center(
                              child: SvgPicture.string(
                                '''
            <svg xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="1.5"
                stroke-linecap="round"
                stroke-linejoin="round">
              <path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/>
            </svg>
                      ''',
                                width: shieldIconSize,
                                height: shieldIconSize,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFF00EAFF),
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 22 * scale),

                          // ── Title ────────────────────────────────────────────────────
                          Text('VAULT_OS', style: titleStyle, textAlign: TextAlign.center),
                          SizedBox(height: 6 * scale),
                          Text(
                            'ENCRYPTED PASSWORD VAULT',
                            style: subtitleStyle,
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: 36 * scale),

                          // ── Card ─────────────────────────────────────────────────────
                          Container(
                            width: effectiveCardWidth,
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.border, width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00EAFF)
                                      .withValues(alpha: 0.15 * _glowAnim.value),
                                  blurRadius: 20 * scale,
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF00EAFF)
                                      .withValues(alpha: 0.05 * _glowAnim.value),
                                  blurRadius: 40 * scale,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // AES badge
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    20 * scale,
                                    18 * scale,
                                    20 * scale,
                                    14 * scale,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: (7 * scale).clamp(6.0, 10.0),
                                        height: (7 * scale).clamp(6.0, 10.0),
                                        decoration: BoxDecoration(
                                          color: AppTheme.accentGreen,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.accentGreen
                                                  .withValues(alpha: 0.6),
                                              blurRadius: 6 * scale,
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 8 * scale),
                                      Expanded(
                                        child: Text(
                                          'AES-256 ENCRYPTION ACTIVE',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 1.2,
                                                fontFamily: 'monospace',
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const Divider(color: AppTheme.border, height: 1),
                                SizedBox(height: 18 * scale),

                                // ── Tab switcher ──────────────────────────────────────
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20 * scale,
                                  ),
                                  child: _TabSwitcher(
                                    isUnlock: _isUnlockTab,
                                    hasMasterPassword: _hasMasterPassword,
                                    minHeight: minTap,
                                    scale: scale,
                                    onSwitch: (val) => setState(() {
                                      _isUnlockTab = val;
                                    }),
                                  ),
                                ),

                                SizedBox(height: 22 * scale),

                                // ── Form ──────────────────────────────────────────────
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20 * scale,
                                  ),
                                  child: _isUnlockTab
                                      ? _buildUnlockForm()
                                      : _buildInitForm(),
                                ),

                                // Error
                                if (_error != null) ...[
                                  SizedBox(height: 10 * scale),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20 * scale,
                                    ),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12 * scale,
                                        vertical: 8 * scale,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2A0A0A),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0xFFCC3333)
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            size: (13 * scale).clamp(12.0, 16.0),
                                            color: const Color(0xFFFF4444),
                                          ),
                                          SizedBox(width: 8 * scale),
                                          Expanded(
                                            child: Text(
                                              _error!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: const Color(0xFFFF6666),
                                                    fontFamily: 'monospace',
                                                  ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],

                                SizedBox(height: 18 * scale),

                                // ── Primary action button ──────────────────────────────
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20 * scale,
                                  ),
                                  child: _UnlockButton(
                                    isLoading: _isLoading,
                                    label: _isUnlockTab
                                        ? 'UNLOCK VAULT'
                                        : 'INITIALIZE VAULT',
                                    icon: _isUnlockTab
                                        ? Icons.lock_open_rounded
                                        : Icons.add_moderator_outlined,
                                    minHeight: minTap,
                                    scale: scale,
                                    onTap: _isUnlockTab ? _unlock : _initialize,
                                  ),
                                ),

                                SizedBox(height: 16 * scale),
                              ],
                            ),
                          ),

                          SizedBox(height: 28 * scale),

                          // ── Footer note ──────────────────────────────────────────────
                          Text(
                            'Your vault is encrypted locally with AES-256-GCM.',
                            style: footerStyle,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4 * scale),
                          Text(
                            'Master key is never transmitted or stored.',
                            style: footerStyle,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ]
    ),
    );
  }

  // ── Unlock form ───────────────────────────────────────────────────────────

  Widget _buildUnlockForm() {
    final scale = _scaleFor(context);
    final minTap = _minTapForPlatform();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MASTER KEY',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
        ),
        SizedBox(height: 8 * scale),
        _KeyField(
          controller: _masterKeyCtrl,
          hint: 'Enter master passphrase...',
          visible: _passwordVisible,
          onToggle: () =>
              setState(() => _passwordVisible = !_passwordVisible),
          onSubmit: _unlock,
          onChanged: (_) => setState(() => _error = null),
        ),
        SizedBox(height: 12 * scale),
        Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _showResetDialog,
            child: SizedBox(
              height: minTap,
              child: Center(
                child: Text(
                  'Forgot password?',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.accentCyan,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: AppTheme.accentCyan,
                      ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Initialize form ───────────────────────────────────────────────────────

  Widget _buildInitForm() {
    final scale = _scaleFor(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CREATE MASTER KEY',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
        ),
        SizedBox(height: 8 * scale),
        _KeyField(
          controller: _newKeyCtrl,
          hint: 'Choose a strong passphrase...',
          visible: _newVisible,
          onToggle: () => setState(() => _newVisible = !_newVisible),
          onChanged: (_) => setState(() => _error = null),
        ),
        SizedBox(height: 14 * scale),
        Text(
          'CONFIRM MASTER KEY',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
        ),
        SizedBox(height: 8 * scale),
        _KeyField(
          controller: _confirmKeyCtrl,
          hint: 'Repeat passphrase...',
          visible: _confirmVisible,
          onToggle: () =>
              setState(() => _confirmVisible = !_confirmVisible),
          onSubmit: _initialize,
          onChanged: (_) => setState(() => _error = null),
        ),
      ],
    );
  }
}

class _VaultGridPainter extends CustomPainter {
  final double glowValue;

  _VaultGridPainter({required this.glowValue});

  static const double gridSize = 40;
  static const Color glowColor = Color(0xFF00EAFF);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = glowColor.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    // Vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VaultGridPainter oldDelegate) =>
      oldDelegate.glowValue != glowValue;
}

// ══════════════════════════════════════════════════════════════════════════════
// Tab switcher — UNLOCK / INITIALIZE
// ══════════════════════════════════════════════════════════════════════════════

class _TabSwitcher extends StatelessWidget {
  final bool isUnlock;
  final bool hasMasterPassword;
  final ValueChanged<bool> onSwitch;
  final double minHeight;
  final double scale;

  const _TabSwitcher({
    required this.isUnlock, 
    required this.hasMasterPassword,
    required this.minHeight,
    required this.scale,
    required this.onSwitch
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: (38 * scale).clamp(minHeight, 52.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Row(
        children: [
          _Tab(
            label: 'UNLOCK', 
            active: isUnlock, 
            onTap: () => onSwitch(true)
          ),
          _Tab(
            label: 'INITIALIZE', 
            active: !isUnlock && !hasMasterPassword,
            disabled: hasMasterPassword,
            onTap: hasMasterPassword ? null : () => onSwitch(false)
          ),
        ],
      ),
    );
  }
}

class _Tab  extends StatefulWidget {
  final String label;
  final bool active;
  final bool disabled;
  final VoidCallback? onTap;

  const _Tab({
    required this.label, 
    required this.active, 
    this.disabled = false,
    this.onTap
  });

   @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        onEnter: widget.disabled ? null : (_) => setState(() => _hovered = true),
        onExit: widget.disabled ? null : (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.disabled ? null : widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: widget.active ? Color(0xFF00EAFF).withValues(alpha: 0.8) : Colors.transparent,
              boxShadow: [
                BoxShadow(
                  color: widget.active ? Color(0xFF00EAFF).withValues(alpha: 0.15) : Colors.transparent,
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: widget.active ? Color(0xFF00EAFF).withValues(alpha: 0.05) : Colors.transparent,
                  blurRadius: 40,
                  spreadRadius: 0,
                ),
              ],
              borderRadius: BorderRadius.circular(5),
            ),
            child: Center(
              child: Text(
                widget.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: widget.active
                      ? Colors.black
                      : widget.disabled
                          ? AppTheme.textMuted.withValues(alpha: 0.3)
                          : _hovered
                              ? Colors.white
                              : AppTheme.textMuted,
                  fontWeight:
                      widget.active ? FontWeight.w500 : FontWeight.w400,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Key input field
// ══════════════════════════════════════════════════════════════════════════════

class _KeyField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final bool visible;
  final VoidCallback onToggle;
  final VoidCallback? onSubmit;
  final ValueChanged<String>? onChanged;

  const _KeyField({
    required this.controller,
    required this.hint,
    required this.visible,
    required this.onToggle,
    this.onSubmit,
    this.onChanged,
  });

  @override
  State<_KeyField> createState() => _KeyFieldState();
}

class _KeyFieldState extends State<_KeyField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;
    final isDesktop = platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux;
    final minTap = isDesktop ? 40.0 : 48.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      constraints: BoxConstraints(minHeight: minTap),
      decoration: BoxDecoration(
        color: const Color(0xFF090C13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _focused
              ? AppTheme.accentCyan.withValues(alpha: 0.5)
              : AppTheme.border,
          width: _focused ? 1.5 : 1.0,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: AppTheme.accentCyan.withValues(alpha: 0.08),
                  blurRadius: 12,
                )
              ]
            : [],
      ),
      child: Focus(
        onFocusChange: (f) => setState(() => _focused = f),
        child: TextField(
          controller: widget.controller,
          obscureText: !widget.visible,
          onChanged: widget.onChanged,
          onSubmitted: (_) => widget.onSubmit?.call(),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
                fontFamily: 'monospace',
                letterSpacing: 1.2,
              ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textMuted,
                  fontFamily: 'monospace',
                  letterSpacing: 0,
                ),
            border: InputBorder.none,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            suffixIconConstraints: BoxConstraints(
              minWidth: minTap,
              minHeight: minTap,
            ),
            suffixIcon: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onToggle,
              child: SizedBox(
                width: minTap,
                height: minTap,
                child: Center(
                  child: Icon(
                    widget.visible
                        ? Icons.visibility_off_outlined
                        : Icons.remove_red_eye_outlined,
                    color: AppTheme.textMuted,
                    size: 17,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Primary unlock button
// ══════════════════════════════════════════════════════════════════════════════

class _UnlockButton extends StatefulWidget {
  final bool isLoading;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final double minHeight;
  final double scale;

  const _UnlockButton({
    required this.isLoading,
    required this.label,
    required this.icon,
    required this.minHeight,
    required this.scale,
    required this.onTap,
  });

  @override
  State<_UnlockButton> createState() => _UnlockButtonState();
}

class _UnlockButtonState extends State<_UnlockButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.isLoading ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: (46 * widget.scale).clamp(widget.minHeight, 60.0),
          decoration: BoxDecoration(
            color: AppTheme.accentCyan,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentCyan
                    .withValues(alpha: _hovered ? 0.45 : 0.22),
                blurRadius: (_hovered ? 22 : 10) * widget.scale,
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.icon,
                          size: (15 * widget.scale).clamp(14.0, 20.0),
                          color: Colors.black),
                      SizedBox(width: 8 * widget.scale),
                      Text(
                        widget.label,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.0,
                            ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}