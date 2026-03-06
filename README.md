# VaultOS

A secure password management application built with Flutter, designed to provide a modern and intuitive interface for storing and managing sensitive credentials with robust encryption and security features.

## Features

- **Secure Authentication**: Master password protection with PBKDF2 key derivation and salted hashing
- **Encrypted Storage**: Local database storage with secure key management using Flutter Secure Storage
- **Password Organization**: Categorize passwords with built-in and custom categories
- **Password Strength Analysis**: Automatic strength evaluation (Strong/Good/Weak) based on complexity criteria
- **Modern UI**: Dark theme with Material Design components and intuitive navigation
- **Cross-Platform**: Supports Android, iOS, Windows, macOS, Linux, and Web
- **Two-Factor Authentication Tracking**: Mark entries that use 2FA
- **Secure Password Generation**: Built-in tools for creating strong passwords
- **Search and Filter**: Quickly find passwords by title, username, or category

## Security Features

- **PBKDF2 Key Derivation**: 50,000+ iterations for master password hashing
- **Salted Hashing**: Unique salt for each installation to prevent rainbow table attacks
- **Constant-Time Comparison**: Prevents timing attacks during password verification
- **Secure Storage**: Uses platform-specific secure storage (Keychain/Keystore)
- **Local-Only Storage**: No cloud synchronization - data stays on your device
- **Memory Safety**: Sensitive data is handled securely in memory

## Installation

### Prerequisites

- Flutter SDK (version 3.11.0 or higher)
- Dart SDK
- Platform-specific development tools (Android Studio, Xcode, etc.)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd vault_os
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run
```

## Usage

### First Time Setup

1. Launch the application
2. Create a master password (minimum 8 characters)
3. Set up security questions for password recovery
4. Start adding your password entries

### Adding Passwords

1. Click the "Add Entry" button
2. Fill in the required fields:
   - Title/Service Name
   - Username/Email
   - Password
   - Category selection
   - Website URL (optional)
   - Notes (optional)
3. Save the entry

### Managing Categories

- Use built-in categories (Social, Finance, Work, Email, Shopping, Security, Other)
- Create custom categories with custom icons and colors
- Organize passwords for better accessibility

### Security Best Practices

- Use a strong master password with mixed characters, numbers, and symbols
- Enable device biometric authentication when available
- Regularly update weak passwords
- Use the password strength indicator to guide password creation
- Keep your master password secure and never share it

## Architecture

The application follows a clean architecture pattern with the following key components:

### Core Services

- **AuthService**: Handles authentication, password hashing, and key derivation
- **EncryptionService**: Manages data encryption and decryption
- **VaultStorageService**: Provides database operations for password entries
- **SimpleVaultStorage**: Lightweight storage implementation

### Data Models

- **PasswordEntry**: Represents a stored password with metadata
- **VaultCategory**: Defines categories for organizing passwords
- **VaultState**: Manages application state and data operations

### UI Components

- **LockScreen**: Authentication interface
- **VaultScreen**: Main password management interface
- **PasswordCard**: Individual password entry display
- **Sidebar**: Navigation and category management

## Dependencies

- `flutter`: UI framework
- `flutter_secure_storage`: Secure local storage
- `crypto`: Cryptographic functions
- `sqflite`: SQLite database operations
- `path`: File path utilities
- `flutter_svg`: SVG image support

## Development

### Project Structure

```
lib/
├── main.dart                 # Application entry point
├── models/                   # Data models
│   └── password_entry.dart
├── services/                 # Business logic
│   ├── auth_service.dart
│   ├── encryption_service.dart
│   └── vault_storage_service.dart
├── screens/                  # UI screens
│   ├── lock_screen.dart
│   └── vault_screen.dart
├── widgets/                  # Reusable UI components
│   ├── password_card.dart
│   ├── new_entry_dialog.dart
│   └── sidebar.dart
└── theme/                    # App theming
    └── app_theme.dart
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Security Considerations

- This application stores all data locally on the device
- No data is transmitted to external servers
- The master password is never stored in plaintext
- All sensitive operations are performed in memory
- Regular security audits are recommended for production use

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues, questions, or contributions, please open an issue on the GitHub repository.

## Version History

- **Version 0.1.0**: Initial release with core password management features
  - Master password authentication
  - Basic CRUD operations for passwords
  - Category management
  - Password strength analysis
  - Cross-platform support
