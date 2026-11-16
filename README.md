# Sınavgram

**Sınavgram** is a mobile educational platform designed to help students prepare for exams through an interactive learning environment.

This repository contains the latest version of the Sınavgram mobile application, developed using Flutter and Dart.

The project is being released as open-source software as part of the application's retirement. Its source code is made publicly available for educational purposes, software preservation, and developers interested in exploring or reusing its implementation.

<details>
<summary><strong>Project status</strong></summary>

**Archived – Retirement planned**

Sınavgram is being retired, and this repository is published as a source-code archive.

- No active development is planned.
- No ongoing maintenance or support is guaranteed.
- Original production infrastructure is not included.
- Application data and user information are not distributed with this repository.

</details>

## Overview

Sınavgram was developed to provide students with a centralized platform for exam preparation and educational content.

The application uses Flutter to deliver a consistent mobile experience across Android and iOS.

Its architecture integrates Firebase services for backend functionality, authentication, and data management.

## Supported Platforms

Sınavgram was specifically developed for mobile devices.

| Platform | Support |
|---|---|
| Android | Supported |
| iOS | Supported |
| Windows | Not supported |
| macOS | Not supported |
| Linux | Not supported |
| Web | Not supported |

Although Flutter supports multiple platforms, Sınavgram is intended exclusively for Android and iOS.

## Technology Stack

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform mobile development |
| Dart | Primary programming language |
| Firebase Core | Firebase initialization |
| Firebase Authentication | User authentication |
| Cloud Firestore | Database services |
| Firebase Storage | File and media storage |
| Provider | State management |
| Google Sign-In | Google authentication |
| Sign in with Apple | Apple authentication |
| Google Mobile Ads | Advertisement integration |
| Shared Preferences | Local data persistence |
| App Links | Deep linking |
| Flutter Markdown | Markdown rendering |
| Flutter Math Fork | Mathematical expression rendering |
| PDF Viewer | PDF document rendering |
| AudioPlayers | Audio playback |
| Flutter SVG | SVG rendering |

## Features

The application includes integrations and components for:

### Authentication
- Firebase Authentication integration.
- Google Sign-In support.
- Sign in with Apple.
- User authentication and account management.

### Educational Content
- Educational content presentation.
- Mathematical expression rendering.
- Markdown-based content.
- PDF document viewing.
- Audio content playback.

### Application Services
- Cloud-based data integration.
- Firebase Storage integration.
- Image selection and caching.
- Local preferences.
- Deep linking.
- External URL handling.
- Advertisement integration.
- Timezone-aware functionality.

### User Experience
- Provider-based state management.
- Native mobile platform integrations.
- Content sharing.
- Local application resources and assets.

## Project Structure

```text
sinavgram/
│
├── android/          # Android application configuration
├── ios/              # iOS application configuration
│
├── assets/
│   ├── icons/
│   └── sounds/
│
├── lib/              # Main Dart application source
│
├── test/             # Application tests
│
├── pubspec.yaml      # Dependencies and project configuration
├── pubspec.lock      # Locked dependency versions
│
├── firebase.json     # Firebase tooling configuration
└── README.md
```

## Getting Started

### Requirements

- Flutter SDK
- Dart SDK (Flutter SDK includes Dart)
- Android Studio or Xcode
- Git
- A Firebase project for restoring Firebase functionality

The project specifies the following Dart SDK constraint:

```yaml
environment:
  sdk: ^3.11.3
```

### Installation

**1. Clone the repository**

```bash
git clone https://github.com/Sinavgram/sinavgram.git

cd sinavgram
```

**2. Install dependencies**

```bash
flutter pub get
```

**3. Configure Firebase**

Firebase configuration files and project-specific credentials have intentionally been removed from this repository.

To restore Firebase functionality, you must:

1. Create your own Firebase project.
2. Register your Android and iOS applications.
3. Configure Firebase Authentication.
4. Configure Cloud Firestore.
5. Configure Firebase Storage.
6. Generate and provide the required platform-specific Firebase configuration.

The original production Firebase project and its configuration are not included.

**4. Run the application**

```bash
flutter run
```

A properly configured Android or iOS device or emulator is required.

## Firebase Configuration & Data Availability

<details>
<summary><strong>Important: Firebase configuration has been removed</strong></summary>

This repository intentionally excludes the original Firebase project configuration and environment-specific credentials.

The following Firebase-related components are not provided as part of this source-code release:

- Original Firebase project configuration.
- Original production credentials and environment variables.
- Production Firestore database contents.
- Original Firebase Storage files.
- Production user accounts and authentication data.

Firebase dependencies may still exist in `pubspec.yaml`, and application code may reference Firebase services. However, their presence does not mean that the original backend infrastructure is available.

Developers wishing to experiment with the application must configure their own Firebase environment.

</details>

### User Data and Privacy

**No production user data is included in this repository.**

This public release contains application source code and the resources intentionally included in the repository.

It does not distribute:

- User accounts or personal information.
- Production database records.
- Private user-generated content.
- Original uploaded media.
- Production backend data.

The publication of this repository does not grant access to Sınavgram's original production data or infrastructure.

## Building

Once the required dependencies and platform configurations are available, the application can be built using Flutter.

**Android APK**

```bash
flutter build apk --release
```

**Android App Bundle**

```bash
flutter build appbundle --release
```

**iOS**

```bash
flutter build ios --release
```

An appropriate macOS development environment and Apple development tools are required for iOS builds.

## Legacy Repositories

Earlier implementations of Sınavgram are also available:

- [Legacy Flutter Application](https://github.com/mehmetalper04/sinavgram.old)
- [Legacy Backend](https://github.com/mehmetalper04/sinavgram.backend.old)

These repositories represent earlier stages of the project's development and are provided for historical reference.

## Open Source & Project Retirement

Sınavgram is being retired, and its source code is being made publicly available to preserve the development work behind the project.

The purpose of this release is to make the implementation accessible to developers, students, and anyone interested in exploring the codebase.

Please keep in mind:

- This repository is not an actively maintained product.
- Existing integrations may require additional configuration.
- Original production services are not guaranteed to remain available.
- No production data is included.
- Contributions and issue reports may not receive a response.

## License

No explicit open-source license has been specified for this repository.

Making source code publicly accessible does not automatically grant permission to redistribute, modify, or commercially use it. Please refer to the repository's license information before reusing the code.

## Author

**Mehmet Alper Kocaoğlu**

- GitHub: [@mehmetalper04](https://github.com/mehmetalper04)
- Organization: [Sinavgram](https://github.com/Sinavgram)

---

*Thank you to everyone who was part of the Sınavgram journey.*

*This repository preserves the source code of the final generation of the Sınavgram application.*
