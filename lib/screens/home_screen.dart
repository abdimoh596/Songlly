import 'package:flutter/material.dart';
import 'package:songlly/screens/music_swipe_screen.dart';
import '../services/spotify_auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool setup1Completed = false;
  bool setup2Completed = false;
  bool isLoading = false;
  String? userDisplayName;

  final spotifyAuth = SpotifyAuthService(
    clientId: dotenv.env['SPOTIFY_CLIENT_ID'],
    clientSecret: dotenv.env['SPOTIFY_CLIENT_SECRET'],
  );

  @override
  Widget build(BuildContext context) {
    final retryAfter = spotifyAuth.retryAfter;

    if (retryAfter != null) {
      return Scaffold(
        body: Center(
          child: Text(
            spotifyAuth.retryAfterTime(retryAfter),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromRGBO(253, 181, 130, 1), Color.fromRGBO(255, 245, 237, 1.0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.music_note, color: Color.fromRGBO(121, 16, 83, 1.0), size: 100),
                    const SizedBox(height: 25),
                    if (!setup1Completed)
                      ElevatedButton(
                        onPressed: () async {
                          if (spotifyAuth.retryAfter != null) {
                            setState(() {});
                            return;
                          }
                          setState(() => isLoading = true);
                          String? name = await spotifyAuth.getUserName();
                          await spotifyAuth.preRecommend();
                          setState(() {
                            setup1Completed = true;
                            isLoading = false;
                            userDisplayName = name;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromRGBO(255, 162, 69, 1),
                          foregroundColor: Color.fromRGBO(121, 16, 83, 1.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        ),
                        child: const Text('Setup 1', style: TextStyle(fontSize: 20)),
                      ),
                    if (setup1Completed && userDisplayName != null) ...[
                      const SizedBox(height: 15),
                      Text(
                        'Hi, $userDisplayName!',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                          color: Color.fromRGBO(121, 16, 83, 1.0),
                        ),
                      ),
                      const SizedBox(height: 20),
                    if (!setup2Completed)
                      ElevatedButton(
                        onPressed: () async {
                          setState(() => isLoading = true);
                          await spotifyAuth.recommend();
                          setState(() {
                            setup2Completed = true;
                            isLoading = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromRGBO(255, 145, 36, 1.0),
                          foregroundColor: Color.fromRGBO(121, 16, 83, 1.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        ),
                        child: const Text('Setup 2', style: TextStyle(fontSize: 20)),
                      ),
                    if (setup2Completed) ...[
                      const SizedBox(height: 15),
                      Text(
                        'Setup Complete!',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color.fromRGBO(121, 16, 83, 1.0),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: (setup1Completed && setup2Completed)
                          ? () {
                            spotifyAuth.shuffleRecommendedTracks();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MusicSwipeScreen(),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromRGBO(255, 132, 9, 1),
                        foregroundColor: Color.fromRGBO(121, 16, 83, 1.0),
                        disabledBackgroundColor: Colors.grey[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                      child: const Text('Recommend', style: TextStyle(fontSize: 20)),
                    ),
                  ],
                  ],
                ),
        ),
      ),
    );
  }
}