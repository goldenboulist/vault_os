import 'dart:convert';
import 'package:crypto/crypto.dart';

class EncryptionService {
  // Simple XOR encryption for demo purposes
  // In production, use proper AES encryption from 'encrypt' package
  static String encrypt(String plaintext, String key) {
    final keyBytes = utf8.encode(key);
    final dataBytes = utf8.encode(plaintext);
    final encrypted = <int>[];
    
    for (int i = 0; i < dataBytes.length; i++) {
      encrypted.add(dataBytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    
    return base64.encode(encrypted);
  }
  
  static String decrypt(String ciphertext, String key) {
    final keyBytes = utf8.encode(key);
    final encryptedBytes = base64.decode(ciphertext);
    final decrypted = <int>[];
    
    for (int i = 0; i < encryptedBytes.length; i++) {
      decrypted.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    
    return utf8.decode(decrypted);
  }
  
  // Generate a secure hash for integrity checking
  static String generateHash(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Verify data integrity
  static bool verifyHash(String data, String hash) {
    final computedHash = generateHash(data);
    return computedHash == hash;
  }
}
