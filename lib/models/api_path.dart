class APIPath {
  static final List<String> _scopes = [
    'user-read-private',
    'user-read-email',
    'playlist-read-private',
    'user-modify-playback-state',
    'user-read-playback-state',
    'playlist-read-collaborative',
    'user-library-read',
    'user-library-modify',
    'user-top-read',
    'playlist-modify-public',
    'playlist-modify-private',
    'playlist-read-private',
  ];

  static String requestAuthorization(
          String? clientId, String? redirectUri, String state) =>
      'https://accounts.spotify.com/authorize?client_id=$clientId&response_type=code&redirect_uri=$redirectUri&state=$state&scope=${_scopes.join('%20')}';

  static String requestToken = 'https://accounts.spotify.com/api/token';
  static String getCurrentUser = 'https://api.spotify.com/v1/me';
  static String getSavedSongs(int? offset) => 
      'https://api.spotify.com/v1/me/tracks?offset=$offset&limit=2';
  static String getTopTracks(int? offset) => 
      'https://api.spotify.com/v1/me/top/tracks?offset=$offset&limit=2';
  static String getTopArtists(int? offset) => 
      'https://api.spotify.com/v1/me/top/artists?offset=$offset&limit=2';
  static String getArtistAlbums(String? artistId, int? offset) =>
      'https://api.spotify.com/v1/artists/$artistId/albums?offset=$offset&limit=1';
  static String getArtistsTopTracks(String? artistId, int? offset) =>
      'https://api.spotify.com/v1/artists/$artistId/top-tracks?offset=$offset&limit=1';
  static String getAlbumTracks(String? albumId, int? offset) =>
      'https://api.spotify.com/v1/albums/$albumId/tracks?offset=$offset&limit=1';
  static String play = 'https://api.spotify.com/v1/me/player/play';
  static String pause = 'https://api.spotify.com/v1/me/player/pause';
  static String player = 'https://api.spotify.com/v1/me/player';
}