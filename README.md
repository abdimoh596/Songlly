# Welcome to Songly

I love music. I love listening to music, making music, and discovering new music. I am also very passionate about building software and wanted to explore what it is like to build a phone app. Introducing Songly, my first phone app, helps users discover new music based on their listening habits. I hope you enjoy, keep reading to learn more!

---

# 🎵 Songly – Tinder for Songs

**Songly** is a cross-platform Flutter app that helps users discover new music by swiping through Spotify tracks, just like Tinder! Connect your Spotify account, set your preferences, and swipe left to skip or right to like — all liked tracks are automatically added to your Spotify library.

---

## 🚀 Features

- 🎧 **Spotify Login via OAuth**
- 🤖 **Smart Recommendations** based on:
  - Saved tracks
  - Top artists
  - Top tracks
- 🔀 Swipe-based UI to like or skip songs
- 💾 Liked songs are saved directly to your Spotify account
- 🔊 30-second previews using a custom [Spotify Preview API](https://spotify-preview-api-5f88.onrender.com)
- 📱 Built with Flutter for iOS and Android

---

## 🎥 Demo Video

- https://youtube.com/shorts/KjQzz_Ne67U?feature=share

---

## 📸 Screenshots

<img width="299" alt="Screenshot 2025-04-25 214937" src="https://github.com/user-attachments/assets/259af036-231e-4c3c-aaeb-759753658b43" />
<img width="298" alt="Screenshot 2025-04-25 215331" src="https://github.com/user-attachments/assets/49bd3348-088c-4e94-9403-bc0ce0dcd3f8" />
<img width="298" alt="Screenshot 2025-04-25 215007" src="https://github.com/user-attachments/assets/d7b7270f-c68f-4936-a798-21db657eba89" />
<img width="299" alt="Screenshot 2025-04-25 215248" src="https://github.com/user-attachments/assets/cb432354-6bf6-4ae0-946f-1a6f02ef5d3e" />

---

## 🛠️ Tech Stack

- **Flutter** (Dart)
- **Spotify Web API** (OAuth, track & artist data)
- **Node.js + Express** (Custom backend for preview audio)
- **Cheerio + Axios** for HTML scraping
- **Render** for backend hosting
- **Custom REST API** checkout this repo for the custom spotify web audio preview scrape API: https://github.com/abdimoh596/spotify_preview_api 

---

## 🔐 Spotify Authentication

- Uses **Authorization Code Flow with PKCE**
- Retrieves user profile, saved tracks, top artists/tracks
- Manages access and refresh tokens locally

---

## 🧠 Smart Recommendation Engine

- Songly uses an adaptive recommendation engine that curates music based on each user's Spotify profile. It analyzes:
  - Saved tracks
  - Top artists and songs
  - Related albums and genres

From this data, Songly builds a dynamic pool of recommendations, enriched with top tracks and similar songs. As users swipe, their choices refine future suggestions in real time.
While currently rule-based, the system is designed to evolve into a machine learning–powered engine for deeper personalization.

---

## 🧪 Testing

- Test song previews by visiting your deployed Spotify Preview API
- Test OAuth login with multiple Spotify accounts
- Swipe behavior should reflect saved preferences and avoid duplicates

---

## ⏰ Future Enhancements

- User onboarding with genre preferences
- Mood-based recommendations (e.g. chill, workout, party)
- Daily discovery streaks
- Save songs to a custom Songly playlist
- Web version using Flutter Web or React

---

## 📱 Try It Out Locally
  Since Songly is still in development and not on the App Store or Google Play yet, here's how you can try it out:
  
  ✅ **Requirements**
    - Flutter SDK: Install Flutter
    - Spotify Developer account: developer.spotify.com
    - A physical Android/iOS device or emulator
  
  ⚙️ **Setup Steps**
    - Clone the Repo:
      - git clone https://github.com/abdimoh596/songlly.git
      - cd songlly
      - flutter pub get
  
  **Run on Device or Emulator:**
  - flutter run
  - You may need to allow camera/audio permissions for previews
  - If you're on iOS, you may need to run from Xcode and set up signing

---
