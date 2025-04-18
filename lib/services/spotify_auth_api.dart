import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/auth_tokens.dart';
import '../models/api_path.dart';

class SpotifyAuthApi {
  static final clientId = dotenv.env['SPOTIFY_CLIENT_ID'];
  static final clientSecret = dotenv.env['SPOTIFY_CLIENT_SECRET'];
  static final base64Credential =
      utf8.fuse(base64).encode('$clientId:$clientSecret');

  static Future<AuthTokens> getAuthTokens(
      String? code, String? redirectUri) async {
    final response = await http.post(
      Uri.parse(APIPath.requestToken),
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
      },
      headers: {HttpHeaders.authorizationHeader: 'Basic $base64Credential'},
    );

    if (response.statusCode == 200) {
      return AuthTokens.fromJson(json.decode(response.body));
    } else {
      throw Exception(
          'Failed to load token with status code ${response.statusCode}');
    }
  }

  static Future<AuthTokens> getNewTokens(
      {required AuthTokens originalTokens}) async {
    final response = await http.post(
      Uri.parse(APIPath.requestToken),
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': originalTokens.refreshToken,
      },
      headers: {HttpHeaders.authorizationHeader: 'Basic $base64Credential'},
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      if (responseBody['refresh_token'] == null) {
        responseBody['refresh_token'] = originalTokens.refreshToken;
      }

      return AuthTokens.fromJson(responseBody);
    } else {
      throw Exception(
          'Failed to refresh token with status code ${response.statusCode}');
    }
  }
}