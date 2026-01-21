# Old Man Browser 👴🌐

**Old Man Browser** is a powerful, user-friendly browser built with Flutter, specializing in media stream detection and downloading. It empowers users to easily capture M3U8 video streams from the web and download them for offline viewing.

## Notes
- This project is a work in progress and is not yet ready for production.
- Some features are not yet implemented.
- If you have any problems or suggestions, please open an issue.
- This Browser is only for educational purposes, so if you no access some service from big like Google, etc. because of the security policy of them.

## ✨ Key Features

### 📺 Media & Downloading
- **Stream Capture**: Automatically detects M3U8 video streams from websites as you browse.
- **Smart Downloader**: High-performance sequential downloader with progress monitoring.
- **Quality Selection**: Choose your preferred resolution before downloading.
- **Offline Library**: Manage and play your downloaded videos directly within the app.

### 🌐 Browser Experience
- **Chrome-style Tab Switcher**: Manage multiple sessions with a modern, visual grid interface.
- **Incognito Mode**: Browse privately with a dedicated purple-themed stealth mode.
- **Quick Links (Speed Dial)**: Instant access to your most-visited bookmarks.
- **History & Bookmarks**: Robust system to keep track of your favorite sites and browsing history.

### 🎨 Premium Design
- **Dynamic Theming**: Support for Light, Dark, and System Default modes.
- **Modern Aesthetics**: Sleek Slate/Navy dark theme and clean light theme with vibrant blue accents.
- **Rich Interaction**: Smooth animations and scale transitions for a premium feel.

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Stable version)
- Dart SDK
- For Windows: Visual Studio with C++ desktop development.
- For Android: Android Studio or VS Code with Flutter extensions.

### Installation
1.  **Clone the repository:**
    ```bash
    git clone https://github.com/tinryu/oldman-browser.git
    cd oldman-browser
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the application:**
    - **Windows:** `flutter run -d windows`
    - **Android:** `flutter run -d android`

## 🛠 Tech Stack
- **Framework**: [Flutter](https://flutter.dev/)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Networking**: [Dio](https://pub.dev/packages/dio)
- **Video Engine**: [Media Kit](https://pub.dev/packages/media_kit) for high-performance playback.
- **Persistence**: [Shared Preferences](https://pub.dev/packages/shared_preferences) for settings and file-based storage for large data.

## 📁 Project Structure
- `lib/providers/`: State management (Themes, etc.)
- `lib/screens/`: Main UI screens (Home, Video List, Downloads, Settings)
- `lib/widgets/`: Reusable UI components (Modals, Tab Switcher, Speed Dial)
- `lib/models/`: Data structures (VideoItem, BrowserTab)
- `lib/theme/`: Custom design tokens and ThemeData.

## 🛡 License
Distributed under the MIT License. See `LICENSE` for more information.
## 📝 Author
Author: Justin Truong
Email: justintruong1311@gmail.com
