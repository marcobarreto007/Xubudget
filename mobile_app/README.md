# Xubudget Mobile App

Flutter-based mobile application for personal budget management with OCR receipt scanning and AI categorization.

## Features

- 📱 Cross-platform mobile app (Android/iOS)
- 📸 OCR receipt scanning using ML Kit
- 🤖 Expense categorization
- 💾 Local data storage
- 📊 Export to CSV/XLSX
- 🔒 Secure data handling

## Memory Optimization

This app is optimized to run on devices with **2GB RAM**:

- Minimized APK size with ProGuard/R8
- Optimized resource configurations
- Efficient memory usage patterns
- Reduced background processing

## Setup & Running

### Prerequisites

- Flutter SDK 3.35.3+
- Android Studio with Android SDK 
- Device/Emulator with minimum 2GB RAM

### Quick Start

```bash
# Get dependencies
flutter pub get

# Generate app icons
dart run flutter_launcher_icons

# Run on device (with memory optimization)
flutter run --debug --shrink
```

### For 2GB Memory Devices

See [Android Emulator Setup Guide](../docs/android_emulator_2gb_setup.md) for detailed instructions on configuring a 2GB emulator.

```bash
# Build optimized APK for 2GB devices
flutter build apk --shrink --target-platform android-arm,android-arm64

# Install on device
flutter install
```

## Project Structure

```
lib/
├── main.dart              # App entry point
├── models/               # Data models
│   └── expense.dart      # Expense model
├── providers/            # State management
│   └── expense_provider.dart
├── services/             # Business logic
│   ├── ocr_service.dart      # ML Kit OCR
│   ├── expense_parser.dart   # Text parsing
│   ├── export_service.dart   # CSV/XLSX export
│   └── database_service.dart # SQLite operations
├── ui/                   # User interface
│   ├── budget_dashboard_page.dart  # Main dashboard
│   ├── manual_entry_page.dart      # Manual entry
│   ├── capture_receipt_page.dart   # OCR capture
│   └── barcode_scanner_page.dart   # Barcode scanning
└── db/                   # Database configuration
    └── database_service.dart

android/                  # Android platform configuration
├── app/
│   ├── build.gradle     # Build configuration (2GB optimized)
│   ├── proguard-rules.pro  # Code shrinking rules
│   └── src/main/
│       ├── AndroidManifest.xml  # App permissions
│       └── kotlin/com/example/mobile_app/
│           └── MainActivity.kt
├── build.gradle         # Root build configuration
└── settings.gradle      # Project settings

ios/                     # iOS platform configuration
web/                     # Web platform configuration
test/                    # Unit and widget tests
```

## Memory Usage Monitoring

### Development
```bash
# Monitor memory during development
flutter logs

# Use Flutter DevTools for detailed analysis
flutter pub global activate devtools
flutter pub global run devtools
```

### Production
```bash
# Monitor app memory on device
adb shell dumpsys meminfo com.example.mobile_app

# System memory info
adb shell cat /proc/meminfo
```

## Building for Production

### Android APK (2GB optimized)
```bash
flutter build apk --shrink --target-platform android-arm,android-arm64
```

### Android Bundle
```bash
flutter build appbundle --shrink
```

## Troubleshooting

### Memory Issues
- Reduce image quality in OCR processing
- Clear app cache regularly
- Monitor background app usage
- Use `flutter build apk --shrink` for smaller APK

### Build Issues
- Run `flutter clean && flutter pub get`
- Check Android SDK and Flutter versions
- Verify Gradle configuration

### Performance
- Test on actual 2GB device, not just emulator
- Monitor frame rates with `flutter run --profile`
- Use DevTools for performance profiling

## Development Notes

- All services are designed to work locally (no cloud dependencies)
- OCR uses Google ML Kit for offline text recognition
- Database uses SQLCipher for encrypted local storage
- Export functionality creates files in device storage