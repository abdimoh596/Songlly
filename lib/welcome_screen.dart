import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  WelcomeScreenState createState() => WelcomeScreenState();
}

class WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                currentPage = index;
              });
            },
            children: [
              buildPage(
                title: "Welcome to Songly!",
                description: "Discover music tailored just for you.",
                imagePath: 'assets/images/minlogo.png',
                bgImagePath: 'assets/images/bg.png',
              ),
              buildPage(
                title: "Swipe to Like",
                description: "Easily discover and save songs you love.",
                imagePath: 'assets/images/swipe.png',
                bgImagePath: 'assets/images/bg2.png',
              ),
              buildPage(
                title: "Sign in to Get Started",
                description: "Sign in with Spotify to explore more.",
                imagePath: 'assets/images/spot.png',
                bgImagePath: 'assets/images/bg.png',
                isLastPage: true,
              ),
            ],
          ),

          if (currentPage < 2)
            Positioned(
              bottom: 50,
              left: 50,
              child: TextButton(
                onPressed: () {
                  _pageController.jumpToPage(2);
                },
                child: const Text("Skip", style: TextStyle(fontSize: 22, color: Color.fromRGBO(103, 8, 99, 1.0))),
              ),
            ),

          if (currentPage < 2)
            Positioned(
              bottom: 50,
              right: 50,
              child: TextButton(
                onPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Text("Next", style: TextStyle(fontSize: 22, color: Color.fromRGBO(103, 8, 99, 1.0))),
              ),
            ),

          Positioned(
            bottom: 70,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: 3,
                effect: ExpandingDotsEffect(
                  dotHeight: 8,
                  dotWidth: 8,
                  activeDotColor: Color.fromRGBO(255, 144, 35, 1.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPage({
    required String title,
    required String description,
    required String imagePath,
    required String bgImagePath,
    bool isLastPage = false,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          bgImagePath,
          fit: BoxFit.cover,
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 100),
            Text(
              title,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color.fromRGBO(255, 144, 35, 1.0)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold ,color: Color.fromRGBO(103, 8, 99, 1.0)),
              ),
            ),
            const SizedBox(height: 50),
            Image.asset(imagePath, height: 300),
            const SizedBox(height: 30),
            if (isLastPage)
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text("Start Discovering!"),
              ),
          ],
        ),
      ],
    );
  }
}