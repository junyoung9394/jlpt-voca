# 🇯🇵 JLPT Voca — Japanese Vocabulary & Grammar Learning App

A comprehensive Flutter app for learning Japanese, covering JLPT N1–N5 vocabulary, grammar, kanji, and kana. Built to make Japanese study more efficient and enjoyable.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)](https://flutter.dev)

---

## ✨ Features

| Category | Features |
|----------|----------|
| **Vocabulary** | JLPT N1–N5 word lists with meanings, readings, and example sentences |
| **Grammar** | Grammar explanations with quizzes and bookmarks |
| **Kanji** | Grade 1–6 kanji study with stroke order and readings |
| **Kana** | Hiragana & Katakana learning with pronunciation practice |
| **Quiz Modes** | Random quiz, listening quiz, exam mode |
| **Study Tools** | Favorites, wrong-answer notes, handwriting practice |
| **Daily Word** | Daily vocabulary notification to build study habits |
| **Dark Mode** | Full light/dark theme support |

---

## 📱 Screenshots

> Coming soon

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.3.0`
- Dart SDK `>=3.3.0`
- Android Studio or Xcode (for device deployment)

### Installation

```bash
git clone https://github.com/junyoung9394/jlpt-voca.git
cd jlpt-voca
flutter pub get
flutter run
```

### Firebase Setup

This project uses Firebase for analytics. To run locally:

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add Android/iOS apps and download the config files
3. Place `google-services.json` in `android/app/`
4. Place `GoogleService-Info.plist` in `ios/Runner/`

---

## 🛠 Tech Stack

- **Framework**: Flutter / Dart
- **State Management**: Provider
- **Storage**: SharedPreferences
- **Analytics**: Firebase Analytics
- **Ads**: Google Mobile Ads
- **Audio**: audioplayers (TTS & sound effects)
- **Notifications**: Local push notifications for daily word reminders

---

## 📂 Project Structure

```
lib/
├── data/          # JLPT N1–N5 word data, kanji, kana datasets
├── models/        # Data models (Word, Kanji, Grammar, etc.)
├── providers/     # State management
├── screens/       # UI screens (home, quiz, study, settings...)
├── services/      # Business logic (storage, ads, analytics, TTS...)
└── utils/         # Utility functions
```

---

## 🤝 Contributing

Contributions are welcome! Feel free to open issues or pull requests.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgements

- Japanese word data sourced from open JLPT study materials
- Built with [Flutter](https://flutter.dev) — one codebase, Android + iOS
