import 'package:flutter/material.dart';
import '../services/spotify_auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/global_music_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final spotifyAuth = SpotifyAuthService(
    clientId: dotenv.env['SPOTIFY_CLIENT_ID'],
    clientSecret: dotenv.env['SPOTIFY_CLIENT_SECRET'],
  );

  String? userName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(255, 221, 197, 1.0),
      body: SafeArea(
        child: Stack(
          children: [
            // Welcome message in top-left
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Welcome, ${userName ?? 'user'}!',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            // Center button
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  print(GlobalMusicData.instance.savedTracks.length);
                  print(GlobalMusicData.instance.artists.length);
                  spotifyAuth.getArtistAlbums();
                  spotifyAuth.getArtistsTopTracks();
                  print(GlobalMusicData.instance.recommendedTracks.length);
                  print(GlobalMusicData.instance.albums.length);                  
                  String? name = await spotifyAuth.getUserName();
                  setState(() {
                    userName = name;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(103, 8, 99, 1.0),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'get',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}