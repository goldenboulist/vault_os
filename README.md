# VaultOS

<div align="center">
  <img src="assets/app_icon.png" alt="VaultOS Logo" width="120" height="120">
  
  **A Secure Password Management Solution**
  
  [![Flutter Version](https://img.shields.io/badge/Flutter-3.11.0+-blue.svg)](https://flutter.dev)
  [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
  [![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux%20%7C%20Web-lightgrey.svg)]()
</div>

VaultOS is a comprehensive password management application built with Flutter, designed to provide secure local storage for sensitive credentials with enterprise-grade encryption and a modern, intuitive interface.

## Table of Contents

- [Features](#features)
- [Security Architecture](#security-architecture)
- [Installation](#installation)
- [Getting Started](#getting-started)
- [Usage Guide](#usage-guide)
- [Development](#development)
- [Contributing](#contributing)
- [Security Considerations](#security-considerations)
- [License](#license)

## Features

### Core Functionality
- **Master Password Protection**: PBKDF2 key derivation with configurable iterations
- **Encrypted Local Storage**: SQLite database with AES encryption
- **Password Organization**: Built-in and custom categories with icons
- **Password Strength Analysis**: Real-time strength evaluation with visual indicators
- **Advanced Search**: Filter by title, username, category, or custom fields
- **Two-Factor Authentication Tracking**: Mark and manage 2FA-enabled accounts

### User Interface
- **Modern Design**: Material Design 3 with dark theme support
- **Cross-Platform**: Native performance on all major platforms
- **Responsive Layout**: Optimized for mobile, tablet, and desktop
- **Intuitive Navigation**: Sidebar-based category management
- **Secure Password Generator**: Customizable password creation tools

### Security Features
- **PBKDF2 Key Derivation**: 50,000+ iterations for master password hashing
- **Salted Hashing**: Unique salt per installation prevents rainbow table attacks
- **Constant-Time Comparison**: Timing attack prevention during authentication
- **Platform Secure Storage**: Keychain (iOS) and Keystore (Android) integration
- **Local-Only Architecture**: No cloud synchronization or data transmission
- **Memory Safety**: Secure handling of sensitive data in memory

## Security Architecture

VaultOS implements a defense-in-depth approach to security:

### Authentication Layer
- Master password hashed using PBKDF2 with random salt
- Configurable iteration count (default: 50,000)
- Constant-time string comparison prevents timing attacks

### Encryption Layer
- AES-256 encryption for all stored password data
- Encryption keys derived from master password using secure key derivation
- Separate encryption for database entries and metadata

### Storage Layer
- SQLite database for structured data storage
- Flutter Secure Storage for sensitive keys and salts
- Platform-specific secure storage mechanisms

## Installation

### System Requirements
- Flutter SDK 3.11.0 or higher
- Dart SDK compatible with Flutter version
- Platform-specific development tools:
  - Android: Android Studio or Android SDK
  - iOS: Xcode 12.0 or higher
  - Windows: Visual Studio 2019 or higher
  - macOS: Xcode and CocoaPods
  - Linux: GTK development libraries

### Quick Setup

1. **Clone the Repository**
   ```bash
   git clone https://github.com/your-username/vault_os.git
   cd vault_os
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Verify Setup**
   ```bash
   flutter doctor
   ```

4. **Run the Application**
   ```bash
   flutter run
   ```

### Platform-Specific Build

For production builds on specific platforms:

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release

# Web
flutter build web --release
```

## Getting Started

### Initial Configuration

1. **Launch VaultOS** for the first time
2. **Create Master Password** (minimum 8 characters, recommended 12+)
3. **Set Up Security Questions** for password recovery
4. **Configure Security Settings** (biometric authentication, auto-lock, etc.)

### First Password Entry

1. Click "Add Entry" in the main interface
2. Fill in required information:
   - Service/Title
   - Username/Email
   - Password
   - Category selection
3. Add optional details:
   - Website URL
   - Notes
   - 2FA status
4. Save the encrypted entry

## Usage Guide

### Password Management

**Adding Entries**
- Use the "Add Entry" button for new passwords
- Select appropriate category for organization
- Utilize the password generator for strong credentials

**Editing Entries**
- Click on any password card to view details
- Edit functionality available for all fields
- Password strength indicator updates in real-time

**Deleting Entries**
- Swipe to delete or use the delete button
- Confirmation required for permanent deletion
- Entries are permanently removed from encrypted storage

### Category Management

**Built-in Categories**
- Social Media
- Financial Services
- Work Accounts
- Email Services
- Shopping Platforms
- Security Tools
- Other

**Custom Categories**
- Create unlimited custom categories
- Assign custom icons and colors
- Organize according to personal preferences

### Search and Filter

- **Quick Search**: Find entries by title or username
- **Category Filter**: View passwords by specific category
- **Advanced Search**: Filter by multiple criteria
- **Recent Entries**: Quick access to recently used passwords

## Development

### Project Structure

```
lib/
├── main.dart                    # Application entry point
├── models/                      # Data models and entities
│   └── password_entry.dart
├── services/                    # Business logic and services
│   ├── auth_service.dart
│   ├── encryption_service.dart
│   ├── simple_vault_storage.dart
│   └── vault_storage_service.dart
├── screens/                     # UI screens and pages
│   ├── lock_screen.dart
│   └── vault_screen.dart
├── theme/                       # Application theming
│   └── app_theme.dart
└── widgets/                     # Reusable UI components
    ├── password_card.dart
    ├── new_entry_dialog.dart
    └── sidebar.dart
```

### Core Services

**AuthService**
- Master password validation
- PBKDF2 key derivation
- Session management

**EncryptionService**
- Data encryption/decryption
- Key management
- Secure random generation

**VaultStorageService**
- Database operations
- CRUD operations for password entries
- Category management

**SimpleVaultStorage**
- Lightweight storage implementation
- Local data persistence
- Query optimization

### Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| flutter | SDK | UI framework |
| flutter_secure_storage | ^10.0.0 | Platform secure storage |
| crypto | ^3.0.3 | Cryptographic functions |
| sqflite | ^2.3.0 | SQLite database operations |
| path | ^1.8.3 | File path utilities |
| flutter_svg | ^2.0.9 | SVG image support |
| flutter_dotenv | ^5.1.0 | Environment configuration |

### Development Workflow

1. **Environment Setup**
   ```bash
   flutter pub get
   flutter pub run build_runner build
   ```

2. **Testing**
   ```bash
   flutter test
   flutter test --coverage
   ```

3. **Code Analysis**
   ```bash
   flutter analyze
   dart format .
   ```

4. **Build Verification**
   ```bash
   flutter build apk --debug
   flutter build web --debug
   ```

## Contributing

We welcome contributions to VaultOS! Please follow these guidelines:

### Development Process

1. **Fork the Repository**
2. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Implement Changes**
   - Follow existing code style
   - Add appropriate tests
   - Update documentation
4. **Test Thoroughly**
   ```bash
   flutter test
   flutter analyze
   ```
5. **Submit Pull Request**
   - Provide clear description
   - Include test results
   - Document breaking changes

### Code Standards

- Follow Dart official style guide
- Use meaningful variable and function names
- Add documentation comments for public APIs
- Maintain test coverage above 80%
- Ensure all security features are properly tested

### Security Contributions

- Security-related changes require additional review
- Follow responsible disclosure for vulnerabilities
- Include security impact assessment in PR description

## Security Considerations

### Threat Model

VaultOS is designed to protect against:
- Unauthorized access to stored passwords
- Data extraction from device storage
- Memory-based attacks during runtime
- Dictionary and brute force attacks

### Limitations

- **Local Storage Only**: No cloud synchronization or backup
- **Single Device**: Data is not shared between devices
- **Master Password Recovery**: Limited to security questions
- **Physical Access**: Device compromise defeats all protections

### Best Practices

- Use a strong, unique master password
- Enable device biometric authentication
- Regularly update the application
- Backup data securely (manual export/import)
- Keep the operating system updated

### Auditing

- Regular security audits recommended for production use
- Penetration testing should validate encryption implementation
- Code reviews should focus on security-critical paths

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

```
Copyright (c) 2024 VaultOS Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```

## Support

For issues, questions, or contributions:

- **Issues**: [GitHub Issues](https://github.com/your-username/vault_os/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-username/vault_os/discussions)
- **Security Issues**: Private message or secure email for vulnerability reports

## Version History

### Version 0.1.0+1 (Current)
- Initial release with core password management features
- Master password authentication with PBKDF2
- Encrypted local storage with SQLite
- Category management system
- Password strength analysis
- Cross-platform support
- Modern Material Design interface

---

**Built with Flutter | Secure by Design | Privacy First**
