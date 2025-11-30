# TypeZen macOS

A refined, single-file Chinese typing practice application designed for macOS and iPad. Features real-time AI content generation via Google Gemini, history tracking, and a native-like typing experience.

## Features

- **AI-Powered Content**: Standard modes (Words, Idioms, Sentences) and Custom topics are generated in real-time using Google Gemini API.
- **Native Experience**: Simulates macOS IME behavior with Pinyin composition underlining.
- **iPad Ready**: Optimized touch controls and viewport settings for full-screen iPad usage.
- **Progress Tracking**: Local storage saves your history, stats (WPM/Accuracy), and favorite texts.
- **Zero Backend**: Runs entirely in the browser.

## How to Deploy (Free via GitHub Pages)

1. **Fork or Create Repo**: Create a new public repository on GitHub.
2. **Upload**: Upload the `index.html` file to the root of your repository.
3. **Enable Pages**:
   - Go to **Settings** > **Pages**.
   - Under **Build and deployment** > **Branch**, select `main` (or `master`) and `/ (root)`.
   - Click **Save**.
4. **Access**: Wait a minute, then visit the URL provided by GitHub (e.g., `https://yourusername.github.io/your-repo/`).

## How to Use on iPad

1. Open the deployed GitHub Pages URL in **Safari**.
2. Tap the **Share** button (square with arrow).
3. Select **Add to Home Screen**.
4. Launch from your home screen for a full-screen app experience.

## API Key

This app requires a **Google Gemini API Key** for AI features.
- When you first use an AI feature, the app will prompt you to enter your key.
- The key is stored locally in your browser (`localStorage`). It is **never** sent to any server other than Google's API.
- If you don't have a key, the app includes a fallback offline mode with a limited set of words.
