import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class AiKeyStorage {
  Future<void> saveApiKey(String key);
  Future<String?> readApiKey();
  Future<void> deleteApiKey();
}

class SecureAiKeyStorage implements AiKeyStorage {
  SecureAiKeyStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'ai_api_key';
  String? _fallbackInMemoryKey;

  @override
  Future<void> saveApiKey(String key) async {
    _fallbackInMemoryKey = key;
    try {
      await _storage.write(key: _key, value: key);
    } catch (_) {}
  }

  @override
  Future<String?> readApiKey() async {
    try {
      final val = await _storage.read(key: _key);
      return val ?? _fallbackInMemoryKey;
    } catch (_) {
      return _fallbackInMemoryKey;
    }
  }

  @override
  Future<void> deleteApiKey() async {
    _fallbackInMemoryKey = null;
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
  }
}
