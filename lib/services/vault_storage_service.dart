import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/password_entry.dart';
import 'encryption_service.dart';

class VaultStorageService {
  static Database? _database;
  static String? _encryptionKey;

  // Reset static state (for password reset)
  static void resetState() {
    _database = null;
    _encryptionKey = null;
  }

  // Initialize database
  static Future<void> initialize(String encryptionKey) async {
    _encryptionKey = encryptionKey;
    
    if (_database != null) return;
    
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'vault.db');
    
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Create database tables
  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE password_entries (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        username TEXT NOT NULL,
        password TEXT NOT NULL,
        logo_asset TEXT NOT NULL,
        category_id TEXT NOT NULL,
        has_two_fa INTEGER NOT NULL DEFAULT 0,
        has_sharing INTEGER NOT NULL DEFAULT 0,
        strength TEXT NOT NULL,
        last_modified INTEGER NOT NULL,
        website_url TEXT,
        notes TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon_code INTEGER NOT NULL,
        accent_color TEXT NOT NULL,
        is_built_in INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // Save password entry
  static Future<void> savePasswordEntry(PasswordEntry entry) async {
    if (_database == null) throw Exception('Database not initialized');
    if (_encryptionKey == null) throw Exception('Encryption key not set');

    final encryptedPassword = EncryptionService.encrypt(entry.password, _encryptionKey!);
    final encryptedNotes = entry.notes != null ? EncryptionService.encrypt(entry.notes!, _encryptionKey!) : null;
    final encryptedWebsiteUrl = entry.websiteUrl != null ? EncryptionService.encrypt(entry.websiteUrl!, _encryptionKey!) : null;

    await _database!.insert(
      'password_entries',
      {
        'id': entry.id,
        'title': entry.title,
        'username': entry.username,
        'password': encryptedPassword,
        'logo_asset': entry.logoAsset,
        'category_id': entry.categoryId,
        'has_two_fa': entry.hasTwoFA ? 1 : 0,
        'has_sharing': entry.hasSharing ? 1 : 0,
        'strength': entry.strength.name,
        'last_modified': entry.lastModified.millisecondsSinceEpoch,
        'website_url': encryptedWebsiteUrl,
        'notes': encryptedNotes,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all password entries
  static Future<List<PasswordEntry>> getPasswordEntries() async {
    if (_database == null) throw Exception('Database not initialized');
    if (_encryptionKey == null) throw Exception('Encryption key not set');

    final List<Map<String, dynamic>> maps = await _database!.query('password_entries');
    
    return List.generate(maps.length, (i) {
      final map = maps[i];
      final encryptedPassword = map['password'] as String;
      final encryptedNotes = map['notes'] as String?;
      final encryptedWebsiteUrl = map['website_url'] as String?;
      
      return PasswordEntry(
        id: map['id'] as String,
        title: map['title'] as String,
        username: map['username'] as String,
        password: EncryptionService.decrypt(encryptedPassword, _encryptionKey!),
        logoAsset: map['logo_asset'] as String,
        categoryId: map['category_id'] as String,
        hasTwoFA: (map['has_two_fa'] as int) == 1,
        hasSharing: (map['has_sharing'] as int) == 1,
        strength: PasswordStrength.values.firstWhere(
          (e) => e.name == map['strength'] as String,
          orElse: () => PasswordStrength.weak,
        ),
        lastModified: DateTime.fromMillisecondsSinceEpoch(map['last_modified'] as int),
        websiteUrl: encryptedWebsiteUrl != null ? EncryptionService.decrypt(encryptedWebsiteUrl, _encryptionKey!) : null,
        notes: encryptedNotes != null ? EncryptionService.decrypt(encryptedNotes, _encryptionKey!) : null,
      );
    });
  }

  // Delete password entry
  static Future<void> deletePasswordEntry(String id) async {
    if (_database == null) throw Exception('Database not initialized');
    
    await _database!.delete(
      'password_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Save category
  static Future<void> saveCategory(VaultCategory category) async {
    if (_database == null) throw Exception('Database not initialized');

    await _database!.insert(
      'categories',
      {
        'id': category.id,
        'name': category.name,
        'icon_code': category.icon.codePoint,
        // ignore: deprecated_member_use
        'accent_color': '#${category.accentColor.value.toRadixString(16).padLeft(8, '0')}',
        'is_built_in': category.isBuiltIn ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all categories
  static Future<List<VaultCategory>> getCategories() async {
    if (_database == null) throw Exception('Database not initialized');

    final List<Map<String, dynamic>> maps = await _database!.query('categories');
    
    return List.generate(maps.length, (i) {
      final map = maps[i];
      return VaultCategory(
        id: map['id'] as String,
        name: map['name'] as String,
        icon: IconData(map['icon_code'] as int, fontFamily: 'MaterialIcons'),
        accentColor: Color(int.parse(map['accent_color'] as String, radix: 16)),
        isBuiltIn: (map['is_built_in'] as int) == 1,
      );
    });
  }

  // Delete category
  static Future<void> deleteCategory(String id) async {
    if (_database == null) throw Exception('Database not initialized');
    
    await _database!.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Close database
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _encryptionKey = null;
    }
  }

  // Clear all data (for testing/reset)
  static Future<void> clearAll() async {
    if (_database == null) throw Exception('Database not initialized');
    
    await _database!.delete('password_entries');
    await _database!.delete('categories');
  }
}
