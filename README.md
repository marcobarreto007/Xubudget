# Xubudget - Personal Budget Management App

A Flutter-based personal budget management application with OCR receipt scanning, AI-powered categorization, and local data storage.

## Features

- 📱 **Mobile App**: Flutter-based cross-platform app
- 📸 **OCR Receipt Scanning**: Extract data from receipt images using ML Kit
- 🤖 **AI Categorization**: Automatic expense categorization using local Ollama models
- 🔒 **Secure Storage**: Encrypted SQLite database with secure key management
- 📊 **Export**: CSV/XLSX export functionality
- 🏠 **Local-First**: All processing happens locally, no cloud dependencies

## Quick Start

### Prerequisites

- Flutter SDK 3.35.3+
- Android Studio with Android SDK
- Git

### Running the Android App

1. **Clone and setup**:
   ```bash
   git clone <repository-url>
   cd Xubudget/mobile_app
   flutter pub get
   ```

2. **Generate app icons**:
   ```bash
   dart run flutter_launcher_icons
   ```

3. **Run on Android device/emulator**:
   ```bash
   flutter run -d android
   ```

### App Icon Setup

The app uses a custom icon located at `mobile_app/assets/icon/app_icon.png`. To regenerate icons:

```bash
cd mobile_app
dart run flutter_launcher_icons
```

This will update icons for Android, iOS, and Web platforms.

### CI/CD

The project includes GitHub Actions CI that:
- Runs `flutter analyze` for code quality
- Executes tests with `flutter test`
- Builds debug APK
- Uploads APK as artifact for download

Workflow file: `.github/workflows/android_build.yml`

### Project Structure

```
mobile_app/           # Flutter mobile application
├── lib/
│   ├── db/          # Database services (SQLCipher)
│   ├── models/      # Data models
│   ├── providers/   # State management
│   ├── services/    # Business logic (OCR, parser, etc.)
│   └── ui/          # User interface screens
├── assets/icon/     # App icon source
└── test/           # Unit and widget tests

services/pi2_assistant/  # FastAPI backend for AI categorization
├── pi2_server.py       # Main server
├── requirements.txt    # Python dependencies
└── .env               # Environment configuration

data/exports/          # Export files (CSV/XLSX)
```

### Development Scripts

- `xubudget_android_run.bat` - Run Android app with backend connection
- `xubudget_backend_run.bat` - Start FastAPI backend server
- `ollama_install_and_pull.ps1` - Install and setup Ollama for AI categorization

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run `flutter analyze` and `flutter test`
5. Submit a pull request

The CI will automatically build and test your changes.
