import 'package:flutter/material.dart';
import '../services/simple_vault_storage.dart';

// ══════════════════════════════════════════════════════════════════════════════
// VaultCategory — replaces the old Category enum
// ══════════════════════════════════════════════════════════════════════════════

class VaultCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color accentColor;
  final bool isBuiltIn; // built-in categories cannot be deleted

  const VaultCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.accentColor,
    this.isBuiltIn = false,
  });

  VaultCategory copyWith({String? name, IconData? icon, Color? accentColor}) {
    return VaultCategory(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      accentColor: accentColor ?? this.accentColor,
      isBuiltIn: isBuiltIn,
    );
  }

  Color get bgColor => accentColor.withValues(alpha: 0.12);
}

// ── Built-in categories ───────────────────────────────────────────────────────

const String kCatAll      = 'all';
const String kCatSocial   = 'social';
const String kCatFinance  = 'finance';
const String kCatWork     = 'work';
const String kCatEmail    = 'email';
const String kCatShopping = 'shopping';
const String kCatSecurity = 'security';
const String kCatOther    = 'other';

final List<VaultCategory> kBuiltInCategories = [
  const VaultCategory(
    id: kCatAll, name: 'All Items',
    icon: Icons.grid_view_rounded,
    accentColor: Color(0xFF00D4FF), isBuiltIn: true,
  ),
];

// Icon choices for custom categories
const List<IconData> kCategoryIcons = [
  Icons.folder_outlined,
  Icons.star_outline_rounded,
  Icons.favorite_outline_rounded,
  Icons.home_outlined,
  Icons.school_outlined,
  Icons.sports_esports_outlined,
  Icons.health_and_safety_outlined,
  Icons.travel_explore_outlined,
  Icons.attach_money_rounded,
  Icons.cloud_outlined,
  Icons.devices_outlined,
  Icons.music_note_outlined,
  Icons.local_cafe_outlined,
  Icons.fitness_center_outlined,
  Icons.build_outlined,
  Icons.pets_outlined,
];

// Color choices for custom categories
const List<Color> kCategoryColors = [
  Color(0xFF00D4FF), Color(0xFF00FF88), Color(0xFF4D7CFE),
  Color(0xFF9B6DFF), Color(0xFFFF6B35), Color(0xFFFF4444),
  Color(0xFFFFCC44), Color(0xFFD44DFF), Color(0xFF4DFF9F),
  Color(0xFF4D9FFF), Color(0xFFFF9B4D), Color(0xFFFF6666),
];

// ══════════════════════════════════════════════════════════════════════════════
// PasswordStrength
// ══════════════════════════════════════════════════════════════════════════════

enum PasswordStrength { strong, good, weak }

// ══════════════════════════════════════════════════════════════════════════════
// PasswordEntry
// ══════════════════════════════════════════════════════════════════════════════

class PasswordEntry {
  final String id;
  final String title;
  final String username;
  final String password;
  final String logoAsset;
  final String categoryId; // references VaultCategory.id
  final bool hasTwoFA;
  final bool hasSharing;
  final PasswordStrength strength;
  final DateTime lastModified;
  final String? websiteUrl;
  final String? notes;

  PasswordEntry({
    required this.id,
    required this.title,
    required this.username,
    required this.password,
    required this.logoAsset,
    required this.categoryId,
    this.hasTwoFA = false,
    this.hasSharing = false,
    required this.strength,
    required this.lastModified,
    this.websiteUrl,
    this.notes,
  });

  PasswordEntry copyWith({
    String? title,
    String? username,
    String? password,
    String? logoAsset,
    String? categoryId,
    bool? hasTwoFA,
    bool? hasSharing,
    PasswordStrength? strength,
    DateTime? lastModified,
    String? websiteUrl,
    String? notes,
  }) {
    return PasswordEntry(
      id: id,
      title: title ?? this.title,
      username: username ?? this.username,
      password: password ?? this.password,
      logoAsset: logoAsset ?? this.logoAsset,
      categoryId: categoryId ?? this.categoryId,
      hasTwoFA: hasTwoFA ?? this.hasTwoFA,
      hasSharing: hasSharing ?? this.hasSharing,
      strength: strength ?? this.strength,
      lastModified: lastModified ?? this.lastModified,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      notes: notes ?? this.notes,
    );
  }

  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final y = lastModified.year.toString().substring(2);
    return '${months[lastModified.month - 1]} ${lastModified.day}, $y';
  }

  static PasswordStrength deriveStrength(String pwd) {
    if (pwd.length >= 14 &&
        pwd.contains(RegExp(r'[A-Z]')) &&
        pwd.contains(RegExp(r'[0-9]')) &&
        pwd.contains(RegExp(r'[^A-Za-z0-9]'))) {
      return PasswordStrength.strong;
    } else if (pwd.length >= 10) {
      return PasswordStrength.good;
    }
    return PasswordStrength.weak;
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// VaultState — single source of truth for entries + categories
// ══════════════════════════════════════════════════════════════════════════════

class VaultState extends ChangeNotifier {
  // Categories — built-in first, custom appended
  final List<VaultCategory> _categories = List.from(kBuiltInCategories);

  // Entries
  final List<PasswordEntry> _entries = [];

  bool _isInitialized = false;

  // Reset initialization state (for password reset)
  void reset() {
    _isInitialized = false;
    _entries.clear();
    _categories.clear();
    _categories.addAll(kBuiltInCategories);
  }

  // ── Initialization ────────────────────────────────────────────────────────────

  Future<void> initialize(String masterPassword) async {
    if (_isInitialized) return;

    try {
      // Load existing data (no encryption key needed for simple storage)
      await _loadData();
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to initialize vault: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      // Load password entries
      final entries = await SimpleVaultStorage.getPasswordEntries();
      _entries.clear();
      _entries.addAll(entries);

      // Load categories
      final categories = await SimpleVaultStorage.getCategories();
      _categories.clear();
      _categories.addAll(kBuiltInCategories); // Keep built-in categories
      _categories.addAll(categories.where((c) => !c.isBuiltIn)); // Add custom categories
    } catch (e) {
      // If loading fails, start with empty data
      _entries.clear();
      _categories.clear();
      _categories.addAll(kBuiltInCategories);
    }
  }

  // ── Getters ────────────────────────────────────────────────────────────────

  List<PasswordEntry> get entries => List.unmodifiable(_entries);
  List<VaultCategory> get categories => List.unmodifiable(_categories);

  VaultCategory? categoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  int countForCategory(String id) {
    if (id == kCatAll) return _entries.length;
    return _entries.where((e) => e.categoryId == id).length;
  }

  // ── Entry CRUD ─────────────────────────────────────────────────────────────

  Future<void> addEntry(PasswordEntry entry) async {
    _entries.add(entry);
    
    if (_isInitialized) {
      await SimpleVaultStorage.savePasswordEntries(_entries);
    }
    
    notifyListeners();
  }

  Future<void> updateEntry(PasswordEntry updated) async {
    final idx = _entries.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      _entries[idx] = updated;
      
      if (_isInitialized) {
        await SimpleVaultStorage.savePasswordEntries(_entries);
      }
      
      notifyListeners();
    }
  }

  Future<void> removeEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    
    if (_isInitialized) {
      await SimpleVaultStorage.savePasswordEntries(_entries);
    }
    
    notifyListeners();
  }

  // ── Category CRUD ──────────────────────────────────────────────────────────

  Future<void> addCategory(VaultCategory cat) async {
    _categories.add(cat);
    
    if (_isInitialized) {
      await SimpleVaultStorage.saveCategories(_categories);
    }
    
    notifyListeners();
  }

  Future<void> updateCategory(VaultCategory updated) async {
    final idx = _categories.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      _categories[idx] = updated;
      
      if (_isInitialized) {
        await SimpleVaultStorage.saveCategories(_categories);
      }
      
      notifyListeners();
    }
  }

  /// Deletes a custom category and moves its entries to "Other"
  Future<void> removeCategory(String id) async {
    if (kBuiltInCategories.any((c) => c.id == id)) return;
    
    _categories.removeWhere((c) => c.id == id);
    
    for (int i = 0; i < _entries.length; i++) {
      if (_entries[i].categoryId == id) {
        _entries[i] = _entries[i].copyWith(categoryId: kCatOther);
        
        if (_isInitialized) {
          await SimpleVaultStorage.savePasswordEntries(_entries);
        }
      }
    }
    
    if (_isInitialized) {
      await SimpleVaultStorage.saveCategories(_categories);
    }
    
    notifyListeners();
  }

  // ── Cleanup ────────────────────────────────────────────────────────────────

  @override
  Future<void> dispose() async {
    // No need to close anything for simple storage
    super.dispose();
  }
}