import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/spotify_auth_api.dart';

class AuthTokens {
  AuthTokens(this.accessToken, this.refreshToken);
  String? accessToken;
  String? refreshToken;

  static String accessTokenKey = 'songly-access-token';
  static String refreshTokenKey = 'songly-refresh-token';

  AuthTokens.fromJson(Map<String, dynamic> json)
      : accessToken = json['access_token'],
        refreshToken = json['refresh_token'];

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
      };

  Future<void> saveToStorage() async {
    try {
      final storage = FlutterSecureStorage();
      await storage.write(key: accessTokenKey, value: accessToken);
      await storage.write(key: refreshTokenKey, value: refreshToken);
    } catch (e) {
      throw Exception("Failed to save tokens: $e");
    }
  }

  static Future<AuthTokens?> readFromStorage() async {
    String? accessKey;
    String? refreshKey;

    final storage = FlutterSecureStorage();
    accessKey = await storage.read(key: accessTokenKey);
    refreshKey = await storage.read(key: refreshTokenKey);
    if (accessKey == null || refreshKey == null) return null;

    return AuthTokens(accessKey, refreshKey);
  }

  static Future<void> clearStorage() async {
    final storage = FlutterSecureStorage();
    await storage.delete(key: accessTokenKey);
    await storage.delete(key: refreshTokenKey);
  }

  static Future<void> updateTokenToLatest() async {
    final savedTokens = await readFromStorage();
    if (savedTokens == null) throw Exception("No saved token found");

    final tokens =
        await SpotifyAuthApi.getNewTokens(originalTokens: savedTokens);
    await tokens.saveToStorage();
  }
}