# TypeZen macOS

A refined, single-file Chinese typing practice application designed for macOS and iPad. Features real-time AI content generation via Google Gemini, history tracking, and a native-like typing experience.

## Live Demo
👉 **[Click here to open your App](https://tjzhuhg7258.github.io/TypeZen/)**

## ⚠️ Important Deployment Step

If you see a **404 error** or **White/Black screen**:

1. Make sure your `index.html` file is in the **Root** (main) folder of your repository.
2. If it is inside a folder like `components/`, **move it out** to the top level.
3. Delete any other conflicting files like `index.tsx` or `App.tsx`.

## Features

- **AI-Powered Content**: Standard modes (Words, Idioms, Sentences) and Custom topics are generated in real-time using Google Gemini API.
- **Native Experience**: Simulates macOS IME behavior with Pinyin composition underlining.
- **iPad Ready**: Optimized touch controls and viewport settings for full-screen iPad usage.
- **Progress Tracking**: Local storage saves your history, stats (WPM/Accuracy), and favorite texts.
- **Zero Backend**: Runs entirely in the browser.

## How to Activate (One-Time Setup)

Since you have already uploaded the files to GitHub, follow these steps to make the link work:

1. Go to your repository settings: [Settings > Pages](https://github.com/tjzhuhg7258/TypeZen/settings/pages)
2. Under **Build and deployment** > **Branch**, select `main` (or `master`) and `/ (root)`.
3. Click **Save**.
4. Wait about 60 seconds, then click the **Live Demo** link above.

## How to Use on iPad

1. Open `https://tjzhuhg7258.github.io/TypeZen/` in **Safari**.
2. Tap the **Share** button (square with arrow).
3. Select **Add to Home Screen**.
4. Launch from your home screen for a full-screen app experience.

## API Key

This app requires a **Google Gemini API Key** for AI features.
- When you first use an AI feature, the app will prompt you to enter your key.
- The key is stored locally in your browser (`localStorage`). It is **never** sent to any server other than Google's API.
- If you don't have a key, the app includes a fallback offline mode with a limited set of words.