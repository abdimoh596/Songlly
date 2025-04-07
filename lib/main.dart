import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'spotify_auth_service.dart';

void main() async{
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spotify API Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Initialize the Spotify auth service
  final spotifyAuth = SpotifyAuthService(
    clientId: dotenv.env['SPOTIFY_CLIENT_ID'], // Replace with your client ID
    clientSecret: dotenv.env['SPOTIFY_CLIENT_SECRET'], // Replace with your client secret
  );
  
  bool isLoading = false;
  String? userName;
  Map<String, dynamic>? featuredPlaylists;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spotify API Demo'),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (userName != null)
                    Text(
                      'Welcome, $userName!',
                      style: const TextStyle(fontSize: 24),
                    ),
                  
                  const SizedBox(height: 20),
                  
                  ElevatedButton(
                    onPressed: _loginAndGetUserInfo,
                    child: const Text('Login with Spotify'),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  ElevatedButton(
                    onPressed: userName != null ? _getFeaturedPlaylists : null,
                    child: const Text('Get Featured Playlists'),
                  ),
                  
                  if (featuredPlaylists != null) ...[
                    const SizedBox(height: 20),
                    const Text('Featured Playlists', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _buildPlaylistsList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
    );
  }
  
  Future<void> _loginAndGetUserInfo() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      // Get access token
      final token = await spotifyAuth.getAccessToken();
      debugPrint('Access Token: $token');
      
      // Check if the widget is still in the tree
      if (!mounted) return;
      
      if (token == null) {
        if (mounted) {  // Check if still mounted before showing SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to authenticate with Spotify')),
          );
        }
        return;
      }
      
      // Get user profile
      final userProfile = await spotifyAuth.getUserProfile();
      
      // Check if the widget is still in the tree
      if (!mounted) return;
      
      if (userProfile != null) {
        setState(() {
          userName = userProfile['display_name'];
        });
      }
    } catch (e) {
      // Check if still mounted before showing SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      // Check if still mounted before updating state
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
  
  Future<void> _getFeaturedPlaylists() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final playlists = await spotifyAuth.getFeaturedPlaylists();
      
      // Check if the widget is still in the tree
      if (!mounted) return;
      
      if (playlists != null) {
        setState(() {
          featuredPlaylists = playlists;
        });
      }
    } catch (e) {
      // Check if still mounted before showing SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      // Check if still mounted before updating state
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
  
  Widget _buildPlaylistsList() {
    final items = featuredPlaylists?['playlists']?['items'] as List?;
    
    if (items == null || items.isEmpty) {
      return const Center(child: Text('No playlists found'));
    }
    
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final playlist = items[index];
        return ListTile(
          leading: playlist['images'] != null && (playlist['images'] as List).isNotEmpty
            ? Image.network(playlist['images'][0]['url'])
            : const Icon(Icons.music_note),
          title: Text(playlist['name']),
          subtitle: Text('${playlist['tracks']['total']} tracks'),
          onTap: () {
            // Use context directly here is fine since this isn't async
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Selected: ${playlist['name']}')),
            );
          },
        );
      },
    );
  }
}