import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'simple_vault_storage.dart';

// Simple PBKDF2 implementation since crypto package doesn't include it directly
class PBKDF2 {
  static List<int> deriveKey(
    String password,
    String salt,
    int iterations,
    int keyLength,
    Hash hash,
  ) {
    final passwordBytes = utf8.encode(password);
    final saltBytes = base64.decode(salt);
    
    return _pbkdf2(passwordBytes, saltBytes, iterations, keyLength, hash);
  }
  
  static List<int> _pbkdf2(
    List<int> password,
    List<int> salt,
    int iterations,
    int keyLength,
    Hash hash,
  ) {
    final hmac = Hmac(hash, password);
    final result = <int>[];
    var blockCount = 1;
    
    while (result.length < keyLength) {
      final block = _hmacSha1(hmac, salt, blockCount);
      var u = block;
      final blockResult = List<int>.from(u);
      
      for (int i = 1; i < iterations; i++) {
        u = _hmacSha1(hmac, u, 0);
        for (int j = 0; j < blockResult.length; j++) {
          blockResult[j] ^= u[j];
        }
      }
      
      result.addAll(blockResult);
      blockCount++;
    }
    
    return result.take(keyLength).toList();
  }
  
  static List<int> _hmacSha1(Hmac hmac, List<int> data, int blockNumber) {
    final input = List<int>.from(data);
    final bytes = ByteData(4);
    bytes.setUint32(0, blockNumber, Endian.big);
    input.addAll(bytes.buffer.asUint8List());
    return hmac.convert(input).bytes;
  }
}

class AuthService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _masterKeyHashKey = 'master_key_hash';
  static const String _saltKey = 'master_key_salt';

  // Check if master password is already set
  static Future<bool> hasMasterPassword() async {
    final hash = await _secureStorage.read(key: _masterKeyHashKey);
    return hash != null;
  }

  // Create new master password with proper hashing
  static Future<bool> createMasterPassword(String password) async {
    if (password.length < 8) return false;
    
    // Generate random salt
    final salt = _generateSalt();
    
    // Hash password with salt using PBKDF2
    final hash = _hashPassword(password, salt);
    
    // Store salt and hash securely
    await _secureStorage.write(key: _saltKey, value: salt);
    await _secureStorage.write(key: _masterKeyHashKey, value: hash);
    
    return true;
  }

  // Verify master password
  static Future<bool> verifyMasterPassword(String password) async {
    final storedHash = await _secureStorage.read(key: _masterKeyHashKey);
    final salt = await _secureStorage.read(key: _saltKey);
    
    if (storedHash == null || salt == null) return false;
    
    // Hash provided password with stored salt
    final computedHash = _hashPassword(password, salt);
    
    // Constant-time comparison to prevent timing attacks
    return _constantTimeEquals(storedHash, computedHash);
  }

  // Generate encryption key from master password
  static Future<String> deriveEncryptionKey(String password) async {
    final salt = await _secureStorage.read(key: _saltKey);
    if (salt == null) throw Exception('No salt found');
    
    // Use PBKDF2 to derive a 256-bit key for encryption
    final key = _hashPassword(password, salt, iterations: 100000);
    return key;
  }

  // Generate random salt
  static String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64.encode(saltBytes);
  }

  // Hash password using PBKDF2
  static String _hashPassword(String password, String salt, {int iterations = 50000}) {
    final hash = PBKDF2.deriveKey(password, salt, iterations, 32, sha256);
    return base64.encode(hash);
  }

  // Constant-time string comparison
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    
    return result == 0;
  }

  // Clear all stored data (for testing/reset)
  static Future<void> clearAll() async {
    await _secureStorage.delete(key: _masterKeyHashKey);
    await _secureStorage.delete(key: _saltKey);
  }

  // Reset master password and clear all vault data
  static Future<bool> resetMasterPassword() async {
    try {
      // Clear authentication data first
      await _secureStorage.delete(key: _masterKeyHashKey);
      await _secureStorage.delete(key: _saltKey);
      
      // Clear all vault data using simple storage
      await SimpleVaultStorage.clearAll();
      
      return true;
    } catch (e) {
      return false;
    }
  }
}
