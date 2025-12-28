# Tiler App

A Flutter application for managing and organizing your daily activities and schedules.

## Prerequisites

Before running this project, make sure you have the following installed:

- **Flutter SDK**: Version 3.27.0 (specified in `.fvmrc`)
- **Dart SDK**: Version 3.0.0 or higher
- **Android Studio** (for Android development)
- **Xcode** (for iOS development, macOS only)
- **VS Code** (recommended IDE)

## Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd tiler_app
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Generate Code

This project uses code generation for JSON serialization and other features. Run the following command to generate the necessary code:

```bash
flutter packages pub run build_runner build
```

### 4. Environment Setup

The app requires a `.env` file for configuration. Create a `.env` file in the root directory with the necessary environment variables.

## Running the App

### Development Mode

To run the app in development mode:

```bash
flutter run
```

### Platform-Specific Commands

#### Android
```bash
flutter run -d android
```

#### iOS (macOS only)
```bash
flutter run -d ios
```

#### Web
```bash
flutter run -d chrome
```

#### Windows
```bash
flutter run -d windows
```

### Build for Production

#### Android APK
```bash
flutter build apk --release
```

#### Android App Bundle
```bash
flutter build appbundle --release
```

#### iOS
```bash
flutter build ios --release
```

## Project Structure

The project follows a clean architecture pattern with clear separation of concerns:

```
lib/
├── bloc/                    # State management using BLoC pattern
│   ├── calendarTiles/      # Calendar tile state management
│   ├── deviceSetting/      # Device settings state
│   ├── forecast/           # Forecast functionality state
│   ├── location/           # Location services state
│   ├── monthlyUiDateManager/ # Monthly UI date management
│   ├── onBoarding/         # Onboarding flow state
│   ├── previewSummary/     # Preview summary state
│   ├── schedule/           # Schedule management state
│   ├── scheduleSummary/    # Schedule summary state
│   ├── SubCalendarTiles/   # Sub-calendar tiles state
│   ├── tilelistCarousel/   # Tile list carousel state
│   ├── uiDateManager/      # UI date management
│   └── weeklyUiDateManager/ # Weekly UI date management
│
├── components/              # Reusable UI components
│   ├── datePickers/        # Date picker components
│   │   ├── monthlyDatePicker/ # Monthly date picker
│   │   └── weeklyDatePicker/  # Weekly date picker
│   ├── elapsedTiles/       # Elapsed tiles components
│   ├── forecastTemplate/   # Forecast template components
│   ├── onBoarding/         # Onboarding UI components
│   │   ├── bottmNavigatorBar/ # Bottom navigation bar
│   │   └── subWidgets/     # Sub-widgets for onboarding
│   ├── ribbons/            # Ribbon components
│   │   ├── dayRibbon/      # Day ribbon components
│   │   ├── monthRibbon/    # Month ribbon components
│   │   └── weekRibbon/     # Week ribbon components
│   ├── summaryPage/        # Summary page components
│   ├── template/           # Template components
│   ├── tilelist/           # Tile list components
│   │   ├── dailyView/      # Daily view components
│   │   ├── monthlyView/    # Monthly view components
│   │   └── weeklyView/     # Weekly view components
│   └── tileUI/             # Individual tile UI components
│
├── data/                   # Data models and business logic
│   ├── adHoc/             # Ad-hoc data models
│   ├── request/            # API request models
│   │   ├── addressModel.dart
│   │   ├── clusterTemplateTileModel.dart
│   │   └── ...            # Other request models
│   ├── calendarEvent.dart  # Calendar event data model
│   ├── contact.dart        # Contact data model
│   ├── location.dart       # Location data model
│   ├── prediction.dart     # Prediction data model
│   ├── repetition.dart     # Repetition data model
│   ├── tilerEvent.dart     # Main event data model
│   ├── timeline.dart       # Timeline data model
│   ├── userProfile.dart    # User profile data model
│   └── ...                # Other data models
│
├── routes/                 # App screens and navigation
│   ├── authentication/     # Authentication screens
│   │   ├── onBoarding.dart
│   │   ├── signin.dart
│   │   └── ...            # Other auth screens
│   └── authenticatedUser/  # Main app screens
│       ├── analysis/       # Analysis screens
│       ├── calendarGrid/   # Calendar grid screens
│       ├── editTile/       # Tile editing screens
│       ├── forecast/       # Forecast screens
│       ├── newTile/        # New tile creation screens
│       ├── preview/        # Preview screens
│       ├── settings/       # Settings screens
│       ├── tileDetails.dart/ # Tile details screens
│       ├── tileShare/      # Tile sharing screens
│       └── ...            # Other main screens
│
├── services/               # Business logic and external services
│   ├── api/               # API service layer
│   │   ├── appApi.dart    # Main app API
│   │   ├── authorization.dart # Authorization service
│   │   ├── calendarEventApi.dart # Calendar API
│   │   ├── locationApi.dart # Location API
│   │   ├── scheduleApi.dart # Schedule API
│   │   ├── settingsApi.dart # Settings API
│   │   ├── tileShareClusterApi.dart # Tile sharing API
│   │   └── ...            # Other API services
│   ├── notifications/     # Notification services
│   ├── accessManager.dart # Access management
│   ├── analyticsSignal.dart # Analytics service
│   ├── localAuthentication.dart # Local auth service
│   ├── storageManager.dart # Storage management
│   └── themerHelper.dart  # Theme management
│
├── l10n/                  # Localization files
│   ├── app_en.arb         # English translations
│   └── app_es.arb         # Spanish translations
│
├── constants.dart          # App constants
├── executionConstants.dart # Execution constants
├── firebase_options.dart   # Firebase configuration
├── main.dart              # App entry point
├── styles.dart            # App styling
└── util.dart              # Utility functions
```

### Key Architectural Patterns

- **BLoC Pattern**: State management using flutter_bloc for reactive UI updates
- **Repository Pattern**: Data access through service layer
- **Dependency Injection**: Services are injected where needed
- **Clean Architecture**: Separation of UI, business logic, and data layers
- **Feature-based Organization**: Code organized by features rather than types

## Key Features

- **State Management**: Uses BLoC pattern for state management
- **Localization**: Supports multiple languages (English, Spanish)
- **Authentication**: Google Sign-In integration
- **Notifications**: Local notification support
- **Maps Integration**: Google Maps for location services
- **Analytics**: Firebase Analytics integration
- **OneSignal**: Push notification service

## Dependencies

The app uses several key dependencies:

- `flutter_bloc`: State management
- `dio`: HTTP client
- `google_sign_in`: Authentication
- `firebase_core` & `firebase_analytics`: Firebase services
- `onesignal_flutter`: Push notifications
- `google_maps_flutter`: Maps integration
- `flutter_local_notifications`: Local notifications
- `geolocator`: Location services

## Troubleshooting

### Common Issues

1. **Flutter version mismatch**: Make sure you're using Flutter 3.27.0
   ```bash
   flutter --version
   ```

2. **Dependencies not found**: Run
   ```bash
   flutter clean
   flutter pub get
   ```

3. **Code generation issues**: Run
   ```bash
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

4. **iOS build issues**: Make sure you have the latest Xcode and run
   ```bash
   cd ios
   pod install
   cd ..
   ```

### Platform-Specific Setup

#### Android
- Ensure Android SDK is properly configured
- Set up Android emulator or connect physical device
- Enable USB debugging on physical devices

#### iOS (macOS only)
- Install Xcode from App Store
- Accept Xcode license: `sudo xcodebuild -license accept`
- Install iOS Simulator or connect physical device
- Run `cd ios && pod install` to install iOS dependencies

## Development

### Code Generation

The project uses code generation for:
- JSON serialization (`json_serializable`)
- Freezed classes for immutable data classes
- Secure environment variable handling

Run code generation after making changes to models:
```bash
flutter packages pub run build_runner build
```

### Testing

Run tests with:
```bash
flutter test
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and ensure code quality
5. Submit a pull request

## License

This project is private and not intended for publication to pub.dev.

## Support

For support and questions, please refer to the project documentation or contact the development team.