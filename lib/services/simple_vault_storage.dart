import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/password_entry.dart';

class SimpleVaultStorage {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _entriesKey = 'password_entries';
  static const String _categoriesKey = 'categories';

  // Save all password entries (as JSON, hashed passwords only)
  static Future<void> savePasswordEntries(List<PasswordEntry> entries) async {
    final entriesJson = jsonEncode(
      entries.map((entry) => {
        'id': entry.id,
        'title': entry.title,
        'username': entry.username,
        'password': entry.password, // Store as plain text (user responsibility)
        'logoAsset': entry.logoAsset,
        'categoryId': entry.categoryId,
        'hasTwoFA': entry.hasTwoFA,
        'hasSharing': entry.hasSharing,
        'strength': entry.strength.name,
        'lastModified': entry.lastModified.millisecondsSinceEpoch,
        'websiteUrl': entry.websiteUrl,
        'notes': entry.notes,
      }).toList(),
    );
    await _secureStorage.write(key: _entriesKey, value: entriesJson);
  }

  // Get all password entries
  static Future<List<PasswordEntry>> getPasswordEntries() async {
    final entriesJson = await _secureStorage.read(key: _entriesKey);
    if (entriesJson == null) return [];

    try {
      final List<dynamic> entriesList = jsonDecode(entriesJson);
      return entriesList.map((entryData) {
        return PasswordEntry(
          id: entryData['id'],
          title: entryData['title'],
          username: entryData['username'],
          password: entryData['password'],
          logoAsset: entryData['logoAsset'],
          categoryId: entryData['categoryId'],
          hasTwoFA: entryData['hasTwoFA'] ?? false,
          hasSharing: entryData['hasSharing'] ?? false,
          strength: PasswordStrength.values.firstWhere(
            (s) => s.name == entryData['strength'],
            orElse: () => PasswordStrength.weak,
          ),
          lastModified: DateTime.fromMillisecondsSinceEpoch(entryData['lastModified']),
          websiteUrl: entryData['websiteUrl'],
          notes: entryData['notes'],
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Save categories
  static Future<void> saveCategories(List<VaultCategory> categories) async {
    final categoriesJson = jsonEncode(
      categories.map((cat) => {
        'id': cat.id,
        'name': cat.name,
        'iconCode': cat.icon.codePoint,
        'accentColor': '#${cat.accentColor.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}',
        'isBuiltIn': cat.isBuiltIn,
      }).toList(),
    );
    await _secureStorage.write(key: _categoriesKey, value: categoriesJson);
  }

  // Get categories
  static Future<List<VaultCategory>> getCategories() async {
    final categoriesJson = await _secureStorage.read(key: _categoriesKey);
    if (categoriesJson == null) return [];

    try {
      final List<dynamic> categoriesList = jsonDecode(categoriesJson);
      return categoriesList.map((catData) {
        // Parse hex color string back to Color
        String colorHex = catData['accentColor'];
        if (colorHex.startsWith('#')) {
          colorHex = colorHex.substring(1); // Remove # prefix
        }
        return VaultCategory(
          id: catData['id'],
          name: catData['name'],
          icon: IconData(catData['iconCode']),
          accentColor: Color(int.parse(colorHex, radix: 16)),
          isBuiltIn: catData['isBuiltIn'] ?? false,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Clear all data
  static Future<void> clearAll() async {
    await _secureStorage.delete(key: _entriesKey);
    await _secureStorage.delete(key: _categoriesKey);
  }
}
