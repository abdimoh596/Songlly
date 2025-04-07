import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'api_path.dart';
import 'auth_tokens.dart';
import 'spotify_auth_api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SpotifyAuthService {
  final String? clientId;
  final String? clientSecret;
  final String redirectUri = 'songly://callback'; // Custom scheme set in Spotify Dashboard
  late final String state;

  SpotifyAuthService({this.clientId, this.clientSecret}) {
    state = DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<String?> getAccessToken() async {
    final saved = await AuthTokens.readFromStorage();
    if (saved != null) return saved.accessToken;

    final authCode = await _getAuthCodeViaBrowser();
    if (authCode == null) return null;

    final tokens = await SpotifyAuthApi.getAuthTokens(authCode, redirectUri);
    await tokens.saveToStorage();
    return tokens.accessToken;
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final tokens = await AuthTokens.readFromStorage();
    if (tokens == null) return null;

    final response = await http.get(
      Uri.parse(APIPath.getCurrentUser),
      headers: {
        'Authorization': 'Bearer ${tokens.accessToken}',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch profile');
    }
  }

  Future<Map<String, dynamic>?> getFeaturedPlaylists() async {
    final tokens = await AuthTokens.readFromStorage();
    if (tokens == null) return null;

    print('Access Token: ${tokens.accessToken}');

    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/me/playlists'),
      headers: {
        'Authorization': 'Bearer ${tokens.accessToken}',
      },
    );

    print('Status code: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch playlists');
    }
  }

  Future<String?> _getAuthCodeViaBrowser() async {
    final authUrl = APIPath.requestAuthorization(clientId, redirectUri, state);

    final completer = Completer<String?>();
    StreamSubscription<Uri>? sub;

    final appLinks = AppLinks();

    sub = appLinks.uriLinkStream.listen((Uri uri) {
      final code = extractAuthCodeFromUri(uri);
      if (code != null) {
        completer.complete(code);
        sub?.cancel();
      }
    });

    try {
      if (await canLaunchUrl(Uri.parse(authUrl))) {
        await launchUrl(Uri.parse(authUrl), mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $authUrl';
      }
    } catch (e) {
      throw 'Error launching the authentication URL: $e';
    }

    return completer.future.timeout(const Duration(minutes: 2), onTimeout: () {
      sub?.cancel();
      return null;
    });
  }

  String? extractAuthCodeFromUri(Uri uri) {
    if (uri.queryParameters.containsKey('code') &&
        uri.queryParameters['state'] == state) {
      return uri.queryParameters['code'];
    }
    return null;
  }
}