import 'package:flutter/material.dart';
import '../services/spotify_auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool setupCompleted = false;
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
      appBar: AppBar(title: const Text('Songly')),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!setupCompleted)
                    ElevatedButton(
                      onPressed: () async {
                        if (spotifyAuth.retryAfter != null) {
                          setState(() {}); // Show retry screen if needed
                          return;
                        }
                        String? name = await spotifyAuth.getUserName();
                        setState(() => isLoading = true);
                        await spotifyAuth.preRecommend(); // Await setup
                        setState(()  {
                          setupCompleted = true;
                          isLoading = false;
                          userDisplayName = name;
                        });
                      },
                      child: const Text('Setup'),
                    ),
                  if (setupCompleted && userDisplayName != null) ...[
                    Text(
                      'Welcome, $userDisplayName!',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  ElevatedButton(
                    onPressed: setupCompleted
                        ? () async {
                            if (spotifyAuth.retryAfter != null) {
                              setState(() {}); // Show retry screen if needed
                              return;
                            }
                            await spotifyAuth.recommend();
                          }
                        : null,
                    child: const Text('Recommend'),
                  ),
                ],
              ),
      ),
    );
  }
}