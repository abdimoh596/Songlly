import 'artist.dart';
import 'album.dart';
import 'track.dart';

class GlobalMusicData {
  // Private constructor
  GlobalMusicData._privateConstructor();

  // The single instance
  static final GlobalMusicData _instance = GlobalMusicData._privateConstructor();

  // Public accessor
  static GlobalMusicData get instance => _instance;

  // Sets to store global music data
  Set<Artist> artists = {};
  Set<Album> albums = {};
  Set<Track> savedTracks = {};
  Set<Track> recommendedTracks = {};

  void clearAll() {
    artists.clear();
    albums.clear();
    savedTracks.clear();
  }
}