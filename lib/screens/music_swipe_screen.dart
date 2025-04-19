import 'package:flutter/material.dart';
import '../models/global_music_data.dart';
import '../models/track.dart';
import '../services/spotify_auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MusicSwipeScreen extends StatefulWidget {
  const MusicSwipeScreen({super.key});

  @override
  State<MusicSwipeScreen> createState() => _MusicSwipeScreenState();
}

class _MusicSwipeScreenState extends State<MusicSwipeScreen> {
  Track? currentTrack;
  String? albumImageUrl;
  List<String?> artistNames = [];
  String albumName = "No Album Name";

  final spotifyAuth = SpotifyAuthService(
    clientId: dotenv.env['SPOTIFY_CLIENT_ID'],
    clientSecret: dotenv.env['SPOTIFY_CLIENT_SECRET'],
  );

  @override
  void initState() {
    super.initState();
    _getNextTrack();
  }

  void _getNextTrack() async {
    if (GlobalMusicData.instance.recommendedTracks.isNotEmpty) {
      final track = GlobalMusicData.instance.recommendedTracks.first;

      if (await spotifyAuth.isAlreadySaved(track)) {
        GlobalMusicData.instance.recommendedTracks.remove(track);
        _getNextTrack(); // Skip already saved track
        return;
      }
      GlobalMusicData.instance.recommendedTracks.remove(track);

      final imageUrl = await spotifyAuth.fetchAlbumImageUrl(track.albumId);
      final trackArtists = await spotifyAuth.getArtistName(track);
      final trackAlbum = await spotifyAuth.getAlbumName(track);

      setState(() {
        currentTrack = track;
        albumImageUrl = imageUrl;
        artistNames = trackArtists;
        albumName = trackAlbum;
      });
    } else {
      Navigator.pop(context); // Finished
    }
  }

  void _handleSwipe(bool liked) {
    if (liked) {
      spotifyAuth.saveTrack(currentTrack!);
    }
    _getNextTrack();
  }

  @override
  Widget build(BuildContext context) {
    if (currentTrack == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final track = currentTrack!;

    return Scaffold(
      appBar: AppBar(title: const Text('Song Recommendations')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromRGBO(253, 181, 130, 1),
              Color.fromRGBO(255, 245, 237, 1.0),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  albumImageUrl ?? 'assets/images/sngly.png',
                  height: 300,
                  width: 300,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 30),
                Text(
                  track.name,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(255, 145, 36, 1.0),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(albumName,
                    style: const TextStyle(fontSize: 18, color: Color.fromRGBO(121, 16, 83, 1.0))),
                Text(artistNames.join(', '),
                    style: const TextStyle(fontSize: 18, color: Color.fromRGBO(121, 16, 83, 1.0))),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // X Button
                    GestureDetector(
                      onTap: () => _handleSwipe(false),
                      child: Container(
                        height: 60,
                        width: 60,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.close, color: Colors.white, size: 30),
                        ),
                      ),
                    ),
                    const SizedBox(width: 50),
                    // Check Button
                    GestureDetector(
                      onTap: () => _handleSwipe(true),
                      child: Container(
                        height: 60,
                        width: 60,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.check, color: Colors.white, size: 30),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}