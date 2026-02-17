import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soka/models/models.dart';

class PaypalCredentialsCacheService {
  static const String _encryptedPayloadPrefsKey =
      'paypal_credentials_encrypted_v1';
  static const String _ivPrefsKey = 'paypal_credentials_iv_v1';
  static const String _aesKeySecureStorageKey = 'paypal_credentials_aes_v1';

  final FlutterSecureStorage _secureStorage;

  PaypalCredentialsCacheService({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<void> save(PaypalCredentials credentials) async {
    credentials.validate();

    final prefs = await SharedPreferences.getInstance();
    final key = await _resolveKey();
    final iv = encrypt.IV(Uint8List.fromList(_randomBytes(16)));
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc),
    );

    final plain = json.encode(credentials.toJson());
    final encrypted = encrypter.encrypt(plain, iv: iv);

    await prefs.setString(_encryptedPayloadPrefsKey, encrypted.base64);
    await prefs.setString(_ivPrefsKey, iv.base64);
  }

  Future<PaypalCredentials?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final encryptedPayload = prefs.getString(_encryptedPayloadPrefsKey);
    final ivBase64 = prefs.getString(_ivPrefsKey);

    if (encryptedPayload == null ||
        encryptedPayload.isEmpty ||
        ivBase64 == null ||
        ivBase64.isEmpty) {
      return null;
    }

    try {
      final key = await _resolveKey();
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );
      final plain = encrypter.decrypt(
        encrypt.Encrypted.fromBase64(encryptedPayload),
        iv: encrypt.IV.fromBase64(ivBase64),
      );

      final decoded = json.decode(plain);
      if (decoded is! Map<String, dynamic>) {
        await clear();
        return null;
      }

      final credentials = PaypalCredentials.fromJson(decoded);
      credentials.validate();
      return credentials;
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_encryptedPayloadPrefsKey);
    await prefs.remove(_ivPrefsKey);
  }

  Future<encrypt.Key> _resolveKey() async {
    var base64Key = await _secureStorage.read(key: _aesKeySecureStorageKey);
    if (base64Key == null || base64Key.isEmpty) {
      base64Key = base64Encode(_randomBytes(32));
      await _secureStorage.write(key: _aesKeySecureStorageKey, value: base64Key);
    }
    return encrypt.Key(base64Decode(base64Key));
  }

  List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }
}
