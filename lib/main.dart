import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/lock_screen.dart';
import 'screens/vault_screen.dart';
import 'models/password_entry.dart';

void main() {
  runApp(const VaultOSApp());
}

class VaultOSApp extends StatefulWidget {
  const VaultOSApp({super.key});

  @override
  State<VaultOSApp> createState() => _VaultOSAppState();
}

class _VaultOSAppState extends State<VaultOSApp> {
  bool _unlocked = false;
  VaultState _vaultState = VaultState();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: null,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _unlocked
          ? VaultScreen(
              onLock: () => setState(() {
                _unlocked = false;
              }),
              vaultState: _vaultState,
            )
          : LockScreen(
              onUnlocked: () async {
                // For now, we'll handle the password inside LockScreen
                // and pass a callback that initializes the vault
                setState(() {
                  _unlocked = true;
                });
              },
              onVaultReady: (vaultState) {
                // Initialize the vault state when ready
                _vaultState = vaultState;
              },
            ),
    );
  }
}