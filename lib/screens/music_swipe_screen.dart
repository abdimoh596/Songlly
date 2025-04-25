import 'package:flutter/material.dart';
import '../models/global_music_data.dart';
import '../models/track.dart';
import '../services/spotify_auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'home_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  bool isMuted = false;

  final spotifyAuth = SpotifyAuthService(
    clientId: dotenv.env['SPOTIFY_CLIENT_ID'],
    clientSecret: dotenv.env['SPOTIFY_CLIENT_SECRET'],
  );

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _getNextTrack();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<String?> fetchPreviewUrl(String trackId) async {
    final response = await http.get(
      Uri.parse('https://spotify-preview-api-5f88.onrender.com/preview/$trackId'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['preview_url'];
    } else {
      return null;
    }
  }

  void _getNextTrack() async {
    await _audioPlayer.stop();

    if (GlobalMusicData.instance.recommendedTracks.isNotEmpty) {
      final track = GlobalMusicData.instance.recommendedTracks.first;

      if (await spotifyAuth.isAlreadySaved(track)) {
        GlobalMusicData.instance.recommendedTracks.remove(track);
        _getNextTrack();
        return;
      }
      GlobalMusicData.instance.recommendedTracks.remove(track);

      final imageUrl = await spotifyAuth.fetchAlbumImageUrl(track.albumId);
      final trackArtists = await spotifyAuth.getArtistName(track);
      final trackAlbum = await spotifyAuth.getAlbumName(track);

      final previewUrl = await fetchPreviewUrl(track.id);
      if (previewUrl != null && previewUrl.isNotEmpty) {
        await _audioPlayer.play(UrlSource(previewUrl));
      }

      setState(() {
        currentTrack = track;
        albumImageUrl = imageUrl;
        artistNames = trackArtists;
        albumName = trackAlbum;
      });
    } else {
      Navigator.pushAndRemoveUntil(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  void _toggleMute() {
    setState(() {
      isMuted = !isMuted;
      _audioPlayer.setVolume(isMuted ? 0.0 : 1.0);
    });
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
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(255, 130, 4, 1),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(albumName,
                    style: const TextStyle(fontSize: 20, color: Color.fromRGBO(121, 16, 83, 1.0)), textAlign: TextAlign.center, softWrap: true, maxLines: 1),
                const SizedBox(height: 5),
                Text(artistNames.join(', '),
                    style: const TextStyle(fontSize: 25, color: Color.fromRGBO(121, 16, 83, 1.0)), textAlign: TextAlign.center, softWrap: true, maxLines: 1),
                const SizedBox(height: 45),

                // Swipe buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => _handleSwipe(false),
                      child: Container(
                        height: 80,
                        width: 80,
                        decoration: const BoxDecoration(
                          color: Color.fromRGBO(121, 16, 83, 1.0),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.close, color: Colors.white, size: 45),
                        ),
                      ),
                    ),
                    const SizedBox(width: 30),
                    IconButton(
                      icon: Icon(isMuted ? Icons.volume_off : Icons.volume_up, size: 40, color: Color.fromRGBO(255, 130, 4, 1)),
                      onPressed: _toggleMute,
                    ),
                    const SizedBox(width: 30),
                    GestureDetector(
                      onTap: () => _handleSwipe(true),
                      child: Container(
                        height: 80,
                        width: 80,
                        decoration: const BoxDecoration(
                          color: Color.fromRGBO(255, 130, 4, 1),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.check, color: Colors.white, size: 45),
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