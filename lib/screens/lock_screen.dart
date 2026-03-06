import 'package:flutter/material.dart';
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
        Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Shield icon ──────────────────────────────────────────────
            AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, child) => Container(
                width: 80,  // w-20
                height: 80, // h-20
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00EAFF).withValues(alpha: 0.10), // bg-primary/10
                  border: Border.all(
                    color: const Color(0xFF00EAFF).withValues(alpha: 0.30), // border-primary/30
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00EAFF)
                          .withValues(alpha: 0.15 * _glowAnim.value), // animated glow
                      blurRadius: 25,
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
                  width: 40,   // matches w-10 h-10 inside 80 container
                  height: 40,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF00EAFF),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 22),

            // ── Title ────────────────────────────────────────────────────
            const Text(
              'VAULT_OS',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'ENCRYPTED PASSWORD VAULT',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 3.0,
              ),
            ),

            const SizedBox(height: 36),

            // ── Card ─────────────────────────────────────────────────────
            Container(
              width: 370,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border, width: 1),
                boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00EAFF)
                      .withValues(alpha: 0.15 * _glowAnim.value),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: const Color(0xFF00EAFF)
                      .withValues(alpha: 0.05 * _glowAnim.value),
                  blurRadius: 40,
                  spreadRadius: 0,
                ),
              ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // AES badge
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentGreen
                                    .withValues(alpha: 0.6),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'AES-256 ENCRYPTION ACTIVE',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: AppTheme.border, height: 1),
                  const SizedBox(height: 18),

                  // ── Tab switcher ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _TabSwitcher(
                      isUnlock: _isUnlockTab,
                      hasMasterPassword: _hasMasterPassword,
                      onSwitch: (val) => setState(() {
                        _isUnlockTab = val;
                      }),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ── Form ──────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _isUnlockTab
                        ? _buildUnlockForm()
                        : _buildInitForm(),
                  ),

                  // Error
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A0A0A),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: const Color(0xFFCC3333)
                                  .withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                size: 13, color: Color(0xFFFF4444)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                    color: Color(0xFFFF6666),
                                    fontSize: 12,
                                    fontFamily: 'monospace'),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // ── Primary action button ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _UnlockButton(
                      isLoading: _isLoading,
                      label: _isUnlockTab ? 'UNLOCK VAULT' : 'INITIALIZE VAULT',
                      icon: _isUnlockTab
                          ? Icons.lock_open_rounded
                          : Icons.add_moderator_outlined,
                      onTap: _isUnlockTab ? _unlock : _initialize,
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Footer note ──────────────────────────────────────────────
            const Text(
              'Your vault is encrypted locally with AES-256-GCM.',
              style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontFamily: 'monospace'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Master key is never transmitted or stored.',
              style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontFamily: 'monospace'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      ]
    ),
    );
  }

  // ── Unlock form ───────────────────────────────────────────────────────────

  Widget _buildUnlockForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MASTER KEY',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        _KeyField(
          controller: _masterKeyCtrl,
          hint: 'Enter master passphrase...',
          visible: _passwordVisible,
          onToggle: () =>
              setState(() => _passwordVisible = !_passwordVisible),
          onSubmit: _unlock,
          onChanged: (_) => setState(() => _error = null),
        ),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: _showResetDialog,
            child: const Text(
              'Forgot password?',
              style: TextStyle(
                color: AppTheme.accentCyan,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: AppTheme.accentCyan,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Initialize form ───────────────────────────────────────────────────────

  Widget _buildInitForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CREATE MASTER KEY',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        _KeyField(
          controller: _newKeyCtrl,
          hint: 'Choose a strong passphrase...',
          visible: _newVisible,
          onToggle: () => setState(() => _newVisible = !_newVisible),
          onChanged: (_) => setState(() => _error = null),
        ),
        const SizedBox(height: 14),
        const Text(
          'CONFIRM MASTER KEY',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
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

  const _TabSwitcher({
    required this.isUnlock, 
    required this.hasMasterPassword,
    required this.onSwitch
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
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
                style: TextStyle(
                  color: widget.active 
                    ? Colors.black 
                    : widget.disabled 
                      ? AppTheme.textMuted.withValues(alpha: 0.3)
                      : _hovered 
                        ? Colors.white 
                        : AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: widget.active ? FontWeight.w500 : FontWeight.w400,
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
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
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontFamily: 'monospace',
            letterSpacing: 1.2,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
              fontFamily: 'monospace',
              letterSpacing: 0,
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            suffixIcon: GestureDetector(
              onTap: widget.onToggle,
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

  const _UnlockButton({
    required this.isLoading,
    required this.label,
    required this.icon,
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
          height: 46,
          decoration: BoxDecoration(
            color: AppTheme.accentCyan,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentCyan
                    .withValues(alpha: _hovered ? 0.45 : 0.22),
                blurRadius: _hovered ? 22 : 10,
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
                      Icon(widget.icon, size: 15, color: Colors.black),
                      const SizedBox(width: 8),
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
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