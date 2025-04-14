import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import '../models/api_path.dart';
import '../models/auth_tokens.dart';
import 'spotify_auth_api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/album.dart';
import '../models/track.dart';
import '../models/artist.dart';
import '../models/global_music_data.dart';


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

  String? extractAuthCodeFromUri(Uri uri) {
    if (uri.queryParameters.containsKey('code') &&
        uri.queryParameters['state'] == state) {
      return uri.queryParameters['code'];
    }
    return null;
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

  Future<Map<String, dynamic>?> getUserProfile() async {
    // Get the access token from storage
    final tokens = await AuthTokens.readFromStorage();
    // If no tokens are found, return null
    if (tokens == null) return null;

    // use access token to get user profile
    final response = await http.get(
      Uri.parse(APIPath.getCurrentUser),
      headers: {
        'Authorization': 'Bearer ${tokens.accessToken}',
      },
    );

    // if the access token is expired, refresh it and try again
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } 
    else if (response.statusCode == 401) {
      AuthTokens.clearStorage();
      getAccessToken();
      final tokens1 = await AuthTokens.readFromStorage();
      if (tokens1 == null) return null;
      final response1 = await http.get(
      Uri.parse(APIPath.getCurrentUser),
      headers: {
        'Authorization': 'Bearer ${tokens1.accessToken}',
        }
      );
      if (response1.statusCode == 200) {
        return json.decode(response1.body);
      } else {
        throw Exception('Failed to fetch profile');
      }
    } 
    else {
      throw Exception('Failed to fetch profile');
    }
  }

  Future<String> getUserName() {
    return getUserProfile().then((profile) {
      if (profile != null && profile['display_name'] != null) {
        return profile['display_name'];
      } else {
        return 'User';
      }
    });
  }

  Future<Map<String, dynamic>?> getUserSavedSongs() async {
    // Get the access token from storage
    final tokens = await AuthTokens.readFromStorage();
    // If no tokens are found, return null
    if (tokens == null) return null;

    // use access token to get user profile
    final response = await http.get(
      Uri.parse(APIPath.getSavedSongs),
      headers: {
        'Authorization': 'Bearer ${tokens.accessToken}',
      },
    );

    // if the access token is expired, refresh it and try again
    if (response.statusCode == 200) {
      processSavedSongsResponse(json.decode(response.body));
      return json.decode(response.body);
    } 
    else if (response.statusCode == 401) {
      AuthTokens.clearStorage();
      getAccessToken();
      final tokens1 = await AuthTokens.readFromStorage();
      if (tokens1 == null) return null;
      final response1 = await http.get(
      Uri.parse(APIPath.getSavedSongs),
      headers: {
        'Authorization': 'Bearer ${tokens1.accessToken}',
        }
      );
      if (response1.statusCode == 200) {
        processSavedSongsResponse(json.decode(response1.body));
        return json.decode(response1.body);
      } else {
        throw Exception('Failed to fetch saved songs');
      }
    } 
    else {
      throw Exception('Failed to fetch saved songs');
    }
  }

  void processSavedSongsResponse(Map<String, dynamic> data) {
    final items = data['items'] as List;

    for (final item in items) {
      final trackJson = item['track'];

      // Parse and add artists
      for (final artistJson in trackJson['artists']) {
        final artist = Artist.fromJson(artistJson);
        GlobalMusicData.instance.artists.add(artist);
      }

      // Parse and add album
      final album = Album.fromJson(trackJson['album']);
      GlobalMusicData.instance.albums.add(album);

      // Parse and add track
      final track = Track.fromJson(trackJson);
      GlobalMusicData.instance.savedTracks.add(track);
    }
  }

  Future<Map<String, dynamic>?> getUserTopArtists() async {
    // Get the access token from storage
    final tokens = await AuthTokens.readFromStorage();
    // If no tokens are found, return null
    if (tokens == null) return null;

    // use access token to get user profile
    final response = await http.get(
      Uri.parse(APIPath.getTopArtists),
      headers: {
        'Authorization': 'Bearer ${tokens.accessToken}',
      },
    );

    // if the access token is expired, refresh it and try again
    if (response.statusCode == 200) {
      processTopArtistsResponse(json.decode(response.body));
      return json.decode(response.body);
    } 
    else if (response.statusCode == 401) {
      AuthTokens.clearStorage();
      getAccessToken();
      final tokens1 = await AuthTokens.readFromStorage();
      if (tokens1 == null) return null;
      final response1 = await http.get(
      Uri.parse(APIPath.getTopArtists),
      headers: {
        'Authorization': 'Bearer ${tokens1.accessToken}',
        }
      );
      if (response1.statusCode == 200) {
        processTopArtistsResponse(json.decode(response1.body));
        return json.decode(response1.body);
      } else {
        throw Exception('Failed to fetch top artists');
      }
    } 
    else {
      throw Exception('Failed to fetch top artists');
    }
  }

  void processTopArtistsResponse(Map<String, dynamic> data) {
    final items = data['items'] as List;

    for (final artistJson in items) {
      final artist = Artist.fromJson(artistJson);
      GlobalMusicData.instance.artists.add(artist);
    }
  }

  Future<Map<String, dynamic>?> getUserTopTracks() async {
    // Get the access token from storage
    final tokens = await AuthTokens.readFromStorage();
    // If no tokens are found, return null
    if (tokens == null) return null;

    // use access token to get user profile
    final response = await http.get(
      Uri.parse(APIPath.getTopTracks),
      headers: {
        'Authorization': 'Bearer ${tokens.accessToken}',
      },
    );

    // if the access token is expired, refresh it and try again
    if (response.statusCode == 200) {
      processTopTracksResponse(json.decode(response.body));
      return json.decode(response.body);
    } 
    else if (response.statusCode == 401) {
      AuthTokens.clearStorage();
      getAccessToken();
      final tokens1 = await AuthTokens.readFromStorage();
      if (tokens1 == null) return null;
      final response1 = await http.get(
      Uri.parse(APIPath.getTopTracks),
      headers: {
        'Authorization': 'Bearer ${tokens1.accessToken}',
        }
      );
      if (response1.statusCode == 200) {
        processTopTracksResponse(json.decode(response1.body));
        return json.decode(response1.body);
      } else {
        throw Exception('Failed to fetch top tracks');
      }
    } 
    else {
      throw Exception('Failed to fetch top tracks');
    }
  }

  void processTopTracksResponse(Map<String, dynamic> data) {
    final items = data['items'] as List;

    for (final trackJson in items) {
      // Parse artists
      for (final artistJson in trackJson['artists']) {
        final artist = Artist.fromJson(artistJson);
        GlobalMusicData.instance.artists.add(artist);
      }

      // Parse album
      final album = Album.fromJson(trackJson['album']);
      GlobalMusicData.instance.albums.add(album);

      // Parse track
      final track = Track.fromJson(trackJson);
      GlobalMusicData.instance.savedTracks.add(track); // or recommendedTracks if you prefer
    }
  }

  Future<void> getArtistAlbums() async {
    // Get the access token from storage
    final tokens = await AuthTokens.readFromStorage();
    // If no tokens are found, return null
    if (tokens == null) throw Exception('No access token found');


    for (final artist in GlobalMusicData.instance.artists) {
      final response = await http.get(
        Uri.parse(APIPath.getArtistAlbums(artist.id)),
        headers: {
          'Authorization': 'Bearer ${tokens.accessToken}',
        },
      );
      // if the access token is expired, refresh it and try again
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> items = data['items'];

        for (final albumJson in items) {
          final album = Album.fromJson(albumJson);
          GlobalMusicData.instance.albums.add(album);
        }
      } 
      else if (response.statusCode == 401) {
        AuthTokens.clearStorage();
        getAccessToken();
        final tokens1 = await AuthTokens.readFromStorage();
        if (tokens1 == null) throw Exception('No access token found');
        final response1 = await http.get(
        Uri.parse(APIPath.getArtistAlbums(artist.id)),
        headers: {
          'Authorization': 'Bearer ${tokens1.accessToken}',
          }
        );

        if (response1.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          final List<dynamic> items = data['items'];

          for (final albumJson in items) {
            final album = Album.fromJson(albumJson);
            GlobalMusicData.instance.albums.add(album);
          }
        } else {
          throw Exception('Failed to fetch artist albums');
        }
      }
      await Future.delayed(Duration(milliseconds: 300));
    }
  }
  

  Future<void> getArtistsTopTracks() async {
    // Get the access token from storage
    final tokens = await AuthTokens.readFromStorage();
    // If no tokens are found, return null
    if (tokens == null) throw Exception('No access token found');

    for (final artist in GlobalMusicData.instance.artists) {
      final response = await http.get(
        Uri.parse(APIPath.getArtistsTopTracks(artist.id)),
        headers: {
          'Authorization': 'Bearer ${tokens.accessToken}',
        },
      );

      // if the access token is expired, refresh it and try again
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> tracks = data['tracks'];

        for (final trackJson in tracks) {
          final track = Track.fromJson(trackJson);
          GlobalMusicData.instance.recommendedTracks.add(track);
        }
      } 
      else if (response.statusCode == 401) {
        AuthTokens.clearStorage();
        getAccessToken();
        final tokens1 = await AuthTokens.readFromStorage();
        if (tokens1 == null) throw Exception('No access token found');
        final response1 = await http.get(
        Uri.parse(APIPath.getArtistsTopTracks(artist.id)),
        headers: {
          'Authorization': 'Bearer ${tokens1.accessToken}',
          }
        );

        if (response1.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          final List<dynamic> tracks = data['tracks'];

          for (final trackJson in tracks) {
            final track = Track.fromJson(trackJson);
            GlobalMusicData.instance.recommendedTracks.add(track);
          }
        } else {
          throw Exception('Failed to fetch artist top tracks');
        }
      }
      await Future.delayed(Duration(milliseconds: 300));
    }
  }
}