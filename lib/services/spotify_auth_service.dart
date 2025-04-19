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
import 'dart:math';


class SpotifyAuthService {
  final String? clientId;
  final String? clientSecret;
  final String redirectUri = 'songly://callback'; // Custom scheme set in Spotify Dashboard
  late final String state;

  int? savedTracksTotal;
  int? topArtistsTotal;
  int? topTracksTotal;
  int? artistAlbumsTotal;
  int? artistTopTracksTotal;
  int? albumTracksTotal;
  int? retryAfter;
  

  SpotifyAuthService({this.clientId, this.clientSecret}) {
    state = DateTime.now().millisecondsSinceEpoch.toString();
  }

  int getRandomInt(int n) {
    if (n <= 0) return 0;
    final random = Random();
    int seed = random.nextInt(n);
    if (n <= 2 || seed < 2) {
      return random.nextInt(n);
    }
    return seed - 2;
  }

  int getRandomInt2(int n) {
    if (n <= 0) return 0;
    final random = Random();
    int seed = random.nextInt(n);
    if (n <= 1 || seed < 1) {
      return random.nextInt(n);
    }
    return seed - 1;
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

    if (response.statusCode == 429) {
      if (response.headers['retry-after'] != null) {
        retryAfter = int.parse(response.headers['retry-after']!);
      }
      retryAfter = null;
    }
    // if the access token is expired, refresh it and try again
    if (response.statusCode == 200) {
      retryAfter = null;
      return json.decode(response.body);
    } 
    else if (response.statusCode == 401) {
      retryAfter = null;
      AuthTokens.clearStorage();
      await getAccessToken();
      final tokens1 = await AuthTokens.readFromStorage();
      if (tokens1 == null) return null;
      final response1 = await http.get(
      Uri.parse(APIPath.getCurrentUser),
      headers: {
        'Authorization': 'Bearer ${tokens1.accessToken}',
        }
      );
      if (response1.statusCode == 429) {
        if (response1.headers['retry-after'] != null) {
          retryAfter = int.parse(response1.headers['retry-after']!);
        }
        retryAfter = null;
      }
      if (response1.statusCode == 200) {
        retryAfter = null;
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
      Uri.parse(APIPath.getSavedSongs(getRandomInt(savedTracksTotal ?? 0))),
      headers: {
        'Authorization': 'Bearer ${tokens.accessToken}',
      },
    );

    if (response.statusCode == 429) {
      if (response.headers['retry-after'] != null) {
        retryAfter = int.parse(response.headers['retry-after']!);
      }
      retryAfter = null;
    }
    // if the access token is expired, refresh it and try again
    if (response.statusCode == 200) {
      retryAfter = null;
      processSavedSongsResponse(json.decode(response.body));
      return json.decode(response.body);
    } 
    else if (response.statusCode == 401) {
      retryAfter = null;
      AuthTokens.clearStorage();
      await getAccessToken();
      final tokens1 = await AuthTokens.readFromStorage();
      if (tokens1 == null) return null;
      final response1 = await http.get(
      Uri.parse(APIPath.getSavedSongs(getRandomInt(savedTracksTotal ?? 0))),
      headers: {
        'Authorization': 'Bearer ${tokens1.accessToken}',
        }
      );

      if (response1.statusCode == 429) {
        if (response1.headers['retry-after'] != null) {
          retryAfter = int.parse(response1.headers['retry-after']!);
        }
        retryAfter = null;
      }
      if (response1.statusCode == 200) {
        retryAfter = null;
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
    savedTracksTotal = data['total'];
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
      Uri.parse(APIPath.getTopArtists(getRandomInt(topArtistsTotal ?? 0))),
      headers: {
        'Authorization': 'Bearer ${tokens.accessToken}',
      },
    );
    if (response.statusCode == 429) {
      if (response.headers['retry-after'] != null) {
        retryAfter = int.parse(response.headers['retry-after']!);
      }
      retryAfter = null;
    }
    // if the access token is expired, refresh it and try again
    if (response.statusCode == 200) {
      retryAfter = null;
      processTopArtistsResponse(json.decode(response.body));
      return json.decode(response.body);
    } 
    else if (response.statusCode == 401) {
      retryAfter = null;
      AuthTokens.clearStorage();
      await getAccessToken();
      final tokens1 = await AuthTokens.readFromStorage();
      if (tokens1 == null) return null;
      final response1 = await http.get(
      Uri.parse(APIPath.getTopArtists(getRandomInt(topArtistsTotal ?? 0))),
      headers: {
        'Authorization': 'Bearer ${tokens1.accessToken}',
        }
      );

      if (response1.statusCode == 429) {
        if (response1.headers['retry-after'] != null) {
          retryAfter = int.parse(response1.headers['retry-after']!);
        }
        retryAfter = null;
      }
      if (response1.statusCode == 200) {
        retryAfter = null;
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
    topArtistsTotal = data['total'];
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
      Uri.parse(APIPath.getTopTracks(getRandomInt(topTracksTotal ?? 0))),
      headers: {
        'Authorization': 'Bearer ${tokens.accessToken}',
      },
    );

    if (response.statusCode == 429) {
      if (response.headers['retry-after'] != null) {
        retryAfter = int.parse(response.headers['retry-after']!);
      }
      retryAfter = null;
    }
    // if the access token is expired, refresh it and try again
    if (response.statusCode == 200) {
      retryAfter = null;
      processTopTracksResponse(json.decode(response.body));
      return json.decode(response.body);
    } 
    else if (response.statusCode == 401) {
      retryAfter = null;
      AuthTokens.clearStorage();
      await getAccessToken();
      final tokens1 = await AuthTokens.readFromStorage();
      if (tokens1 == null) return null;
      final response1 = await http.get(
      Uri.parse(APIPath.getTopTracks(getRandomInt(topTracksTotal ?? 0))),
      headers: {
        'Authorization': 'Bearer ${tokens1.accessToken}',
        }
      );

      if (response1.statusCode == 429) {
        if (response1.headers['retry-after'] != null) {
          retryAfter = int.parse(response1.headers['retry-after']!);
        }
        retryAfter = null;
      }
      if (response1.statusCode == 200) {
        retryAfter = null;
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
    topTracksTotal = data['total'];
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
        Uri.parse(APIPath.getArtistAlbums(artist.id, getRandomInt2(artistAlbumsTotal ?? 0))),
        headers: {
          'Authorization': 'Bearer ${tokens.accessToken}',
        },
      );

      if (response.statusCode == 429) {
        if (response.headers['retry-after'] != null) {
          retryAfter = int.parse(response.headers['retry-after']!);
        }
        retryAfter = null;
      }
      // if the access token is expired, refresh it and try again
      if (response.statusCode == 200) {
        retryAfter = null;
        artistAlbumsTotal = json.decode(response.body)['total'];
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> items = data['items'];

        for (final albumJson in items) {
          final album = Album.fromJson(albumJson);
          GlobalMusicData.instance.albums.add(album);
        }
      } 
      else if (response.statusCode == 401) {
        retryAfter = null;
        AuthTokens.clearStorage();
        await getAccessToken();
        final tokens1 = await AuthTokens.readFromStorage();
        if (tokens1 == null) throw Exception('No access token found');
        final response1 = await http.get(
        Uri.parse(APIPath.getArtistAlbums(artist.id, getRandomInt2(artistAlbumsTotal ?? 0))),
        headers: {
          'Authorization': 'Bearer ${tokens1.accessToken}',
          }
        );

        if (response1.statusCode == 429) {
          if (response1.headers['retry-after'] != null) {
            retryAfter = int.parse(response1.headers['retry-after']!);
          }
          retryAfter = null;
        }
        if (response1.statusCode == 200) {
          retryAfter = null;
          artistAlbumsTotal = json.decode(response1.body)['total'];
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
        Uri.parse(APIPath.getArtistsTopTracks(artist.id, getRandomInt2(artistTopTracksTotal ?? 0))),
        headers: {
          'Authorization': 'Bearer ${tokens.accessToken}',
        },
      );

      if (response.statusCode == 429) {
        if (response.headers['retry-after'] != null) {
          retryAfter = int.parse(response.headers['retry-after']!);
        }
        retryAfter = null;
      }

      // if the access token is expired, refresh it and try again
      if (response.statusCode == 200) {
        retryAfter = null;
        artistTopTracksTotal = json.decode(response.body)['total'];
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> tracks = data['tracks'];

        for (final trackJson in tracks) {
          final track = Track.fromJson(trackJson);
          GlobalMusicData.instance.recommendedTracks.add(track);
        }
      } 
      else if (response.statusCode == 401) {
        retryAfter = null;
        AuthTokens.clearStorage();
        await getAccessToken();
        final tokens1 = await AuthTokens.readFromStorage();
        if (tokens1 == null) throw Exception('No access token found');
        final response1 = await http.get(
        Uri.parse(APIPath.getArtistsTopTracks(artist.id, getRandomInt2(artistTopTracksTotal ?? 0))),
        headers: {
          'Authorization': 'Bearer ${tokens1.accessToken}',
          }
        );

        if (response1.statusCode == 429) {
          if (response1.headers['retry-after'] != null) {
            retryAfter = int.parse(response1.headers['retry-after']!);
          }
          retryAfter = null;
        }

        if (response1.statusCode == 200) {
          retryAfter = null;
          artistTopTracksTotal = json.decode(response1.body)['total'];
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

  Future<void> getAlbumTracks() async {
    // Get the access token from storage
    final tokens = await AuthTokens.readFromStorage();
    // If no tokens are found, return null
    if (tokens == null) throw Exception('No access token found');

    for (final album in List.from(GlobalMusicData.instance.albums)) {
      final response = await http.get(
        Uri.parse(APIPath.getAlbumTracks(album.id, getRandomInt2(albumTracksTotal ?? 0))),
        headers: {
          'Authorization': 'Bearer ${tokens.accessToken}',
        },
      );

      if (response.statusCode == 429) {
        if (response.headers['retry-after'] != null) {
          retryAfter = int.parse(response.headers['retry-after']!);
        }
        retryAfter = null;
      }
      // if the access token is expired, refresh it and try again
      if (response.statusCode == 200) {
        retryAfter = null;
        albumTracksTotal = json.decode(response.body)['total'];
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> items = data['items'];

        for (var item in items) {
          item['album'] = {'id': album.id};
          Track track = Track.fromJson(item);
          GlobalMusicData.instance.recommendedTracks.add(track);
        }
      } 
      else if (response.statusCode == 401) {
        retryAfter = null;
        AuthTokens.clearStorage();
        await getAccessToken();
        final tokens1 = await AuthTokens.readFromStorage();
        if (tokens1 == null) throw Exception('No access token found');
        final response1 = await http.get(
        Uri.parse(APIPath.getAlbumTracks(album.id, getRandomInt2(albumTracksTotal ?? 0))),
        headers: {
          'Authorization': 'Bearer ${tokens1.accessToken}',
          }
        );

        if (response1.statusCode == 429) {
          if (response1.headers['retry-after'] != null) {
            retryAfter = int.parse(response1.headers['retry-after']!);
          }
          retryAfter = null;
        }
        if (response1.statusCode == 200) {
          retryAfter = null;
          albumTracksTotal = json.decode(response1.body)['total'];
          final Map<String, dynamic> data = json.decode(response.body);
          final List<dynamic> items = data['items'];

          for (var item in items) {
            item['album'] = {'id': album.id};
            Track track = Track.fromJson(item);
            GlobalMusicData.instance.recommendedTracks.add(track);
          }
        } else {
          throw Exception('Failed to fetch artist top tracks');
        }
      }
      await Future.delayed(Duration(milliseconds: 300));
    }
  }
  Future<void> preRecommend() {
    GlobalMusicData.instance.clearAll();
    getUserSavedSongs();
    getUserTopArtists();
    getUserTopTracks();
    return Future.delayed(Duration(milliseconds: 0));
  }

  Future<void> recommend() {
    getArtistAlbums();
    getArtistsTopTracks();
    getAlbumTracks();
    return Future.delayed(Duration(milliseconds: 0));
  }
  String retryAfterTime(int retryAfterSeconds) {
    int days = retryAfterSeconds ~/ (24 * 3600);
    int hours = (retryAfterSeconds % (24 * 3600)) ~/ 3600;
    int minutes = (retryAfterSeconds % 3600) ~/ 60;
    int seconds = retryAfterSeconds % 60;

    List<String> parts = [];

    if (days > 0) parts.add('$days day${days == 1 ? '' : 's'}');
    if (hours > 0) parts.add('$hours hour${hours == 1 ? '' : 's'}');
    if (minutes > 0) parts.add('$minutes minute${minutes == 1 ? '' : 's'}');
    if (seconds > 0) parts.add('$seconds second${seconds == 1 ? '' : 's'}');

    return parts.isNotEmpty ? parts.join(', ') : '0 seconds';
  }

  Future<String?> fetchAlbumImageUrl(String albumId) async {
    // Get the access token from storage
    final tokens = await AuthTokens.readFromStorage();
    // If no tokens are found, return null
    if (tokens == null) return null;

    // use access token to get user profile
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/albums/$albumId'),
      headers: {
        'Authorization': 'Bearer ${tokens.accessToken}',
      },
    );

    if (response.statusCode == 429) {
      if (response.headers['retry-after'] != null) {
        retryAfter = int.parse(response.headers['retry-after']!);
      }
      retryAfter = null;
    }
    // if the access token is expired, refresh it and try again
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final images = data['images'];
      if (images != null && images.isNotEmpty) {
        return images[0]['url']; // Typically 640x640
      }
    } 
    else if (response.statusCode == 401) {
      retryAfter = null;
      AuthTokens.clearStorage();
      await getAccessToken();
      final tokens1 = await AuthTokens.readFromStorage();
      if (tokens1 == null) return null;
      final response1 = await http.get(
      Uri.parse('https://api.spotify.com/v1/albums/$albumId'),
      headers: {
        'Authorization': 'Bearer ${tokens1.accessToken}',
        }
      );

      if (response1.statusCode == 429) {
        if (response1.headers['retry-after'] != null) {
          retryAfter = int.parse(response1.headers['retry-after']!);
        }
        retryAfter = null;
      }
      if (response1.statusCode == 200) {
        final data = json.decode(response.body);
        final images = data['images'];
        if (images != null && images.isNotEmpty) {
          return images[0]['url']; // Typically 640x640
        }
      } else {
        return null;
      }
    }
    return null;
  }

  Future<List<String?>> getArtistName(Track track) async {
    String artistIds = track.artistIds.join(',');
    // Get the access token from storage
    final tokens = await AuthTokens.readFromStorage();
    // If no tokens are found, return null
    if (tokens == null) return [];

    // use access token to get user profile
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/artists?ids=$artistIds'),
      headers: {
        'Authorization': 'Bearer ${tokens.accessToken}',
      },
    );

    if (response.statusCode == 429) {
      if (response.headers['retry-after'] != null) {
        retryAfter = int.parse(response.headers['retry-after']!);
      }
      retryAfter = null;
    }
    // if the access token is expired, refresh it and try again
    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      final List<dynamic> artistsJson = json['artists'];
      return artistsJson.map<String>((artist) => artist['name'] as String).toList();
    } 
    else if (response.statusCode == 401) {
      retryAfter = null;
      AuthTokens.clearStorage();
      await getAccessToken();
      final tokens1 = await AuthTokens.readFromStorage();
      if (tokens1 == null) return [];
      final response1 = await http.get(
      Uri.parse('https://api.spotify.com/v1/artists?ids=$artistIds'),
      headers: {
        'Authorization': 'Bearer ${tokens1.accessToken}',
        }
      );

      if (response1.statusCode == 429) {
        if (response1.headers['retry-after'] != null) {
          retryAfter = int.parse(response1.headers['retry-after']!);
        }
        retryAfter = null;
      }
      if (response1.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final List<dynamic> artistsJson = json['artists'];
        return artistsJson.map<String>((artist) => artist['name'] as String).toList();
      } else {
        return [];
      }
    }
    return [];
  }

  Future<String> getAlbumName(Track track) async {
    // Get the access token from storage
    final tokens = await AuthTokens.readFromStorage();
    // If no tokens are found, return null
    if (tokens == null) return "";

    // use access token to get user profile
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/albums/${track.albumId}'),
      headers: {
        'Authorization': 'Bearer ${tokens.accessToken}',
      },
    );

    if (response.statusCode == 429) {
      if (response.headers['retry-after'] != null) {
        retryAfter = int.parse(response.headers['retry-after']!);
      }
      retryAfter = null;
    }
    // if the access token is expired, refresh it and try again
    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      return json['name'] as String;
    } 
    else if (response.statusCode == 401) {
      retryAfter = null;
      AuthTokens.clearStorage();
      await getAccessToken();
      final tokens1 = await AuthTokens.readFromStorage();
      if (tokens1 == null) return "";
      final response1 = await http.get(
      Uri.parse('https://api.spotify.com/v1/albums/${track.albumId}'),
      headers: {
        'Authorization': 'Bearer ${tokens1.accessToken}',
        }
      );

      if (response1.statusCode == 429) {
        if (response1.headers['retry-after'] != null) {
          retryAfter = int.parse(response1.headers['retry-after']!);
        }
        retryAfter = null;
      }
      if (response1.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        return json['name'] as String;
      } else {
        return "";
      }
    }
    return "";
  }

  Future<bool> isAlreadySaved(Track track) async {
    // Get the access token from storage
    final tokens = await AuthTokens.readFromStorage();
    // If no tokens are found, return null
    if (tokens == null) return false;

    // use access token to get user profile
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/me/tracks/contains?ids=${track.id}'),
      headers: {
        'Authorization': 'Bearer ${tokens.accessToken}',
      },
    );

    if (response.statusCode == 429) {
      if (response.headers['retry-after'] != null) {
        retryAfter = int.parse(response.headers['retry-after']!);
      }
      retryAfter = null;
    }
    // if the access token is expired, refresh it and try again
    if (response.statusCode == 200) {
      retryAfter = null;
      return json.decode(response.body)[0] as bool;
    } 
    else if (response.statusCode == 401) {
      retryAfter = null;
      AuthTokens.clearStorage();
      await getAccessToken();
      final tokens1 = await AuthTokens.readFromStorage();
      if (tokens1 == null) return false;
      final response1 = await http.get(
      Uri.parse('https://api.spotify.com/v1/me/tracks/contains?ids=${track.id}'),
      headers: {
        'Authorization': 'Bearer ${tokens1.accessToken}',
        }
      );

      if (response1.statusCode == 429) {
        if (response1.headers['retry-after'] != null) {
          retryAfter = int.parse(response1.headers['retry-after']!);
        }
        retryAfter = null;
      }
      if (response1.statusCode == 200) {
        retryAfter = null;
        return json.decode(response1.body)[0] as bool;
      } else {
        return false;
      }
    }
    return false;
  }

  Future<void> saveTrack(Track track) async {
    // Get the access token from storage
    final tokens = await AuthTokens.readFromStorage();
    // If no tokens are found, return null
    if (tokens == null) return;

    // use access token to get user profile
    final response = await http.put(
      Uri.parse('https://api.spotify.com/v1/me/tracks?ids=${track.id}'),
      headers: {
        'Authorization': 'Bearer ${tokens.accessToken}',
      },
    );

    if (response.statusCode == 429) {
      if (response.headers['retry-after'] != null) {
        retryAfter = int.parse(response.headers['retry-after']!);
      }
      retryAfter = null;
    }
    // if the access token is expired, refresh it and try again
    if (response.statusCode == 200) {
      retryAfter = null;
      return;
    } 
    else if (response.statusCode == 401) {
      retryAfter = null;
      AuthTokens.clearStorage();
      await getAccessToken();
      final tokens1 = await AuthTokens.readFromStorage();
      if (tokens1 == null) return;
      final response1 = await http.put(
      Uri.parse('https://api.spotify.com/v1/me/tracks?ids=${track.id}'),
      headers: {
        'Authorization': 'Bearer ${tokens1.accessToken}',
        }
      );

      if (response1.statusCode == 429) {
        if (response1.headers['retry-after'] != null) {
          retryAfter = int.parse(response1.headers['retry-after']!);
        }
        retryAfter = null;
      }
      if (response1.statusCode == 200) {
        retryAfter = null;
        return;
      } else {
        return;
      }
    }
    return;
  }

  void shuffleRecommendedTracks() {
    final list = GlobalMusicData.instance.recommendedTracks.toList();
    list.shuffle(Random());
    GlobalMusicData.instance.recommendedTracks = list.toSet();
  }
}