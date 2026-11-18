# ExamGuardQR

A new Flutter project.

## Installation & Setup
### 1. Download or Extract the Project
Extract the zip file to your preferred local directory (e.g., `C:\Coding\ExamGuard`).

### 2. Fetch Dependencies
Open a terminal in the project root directory and install all required Dart packages (run the following in your teminal):

    flutter clean
    flutter pub get

### 3. Verify Firebase Configuration
Ensure the following Firebase configuration files are present in your project tree:

    android/app/google-services.json
    lib/firebase_options.dart

    Note: If re-linking to your own Firebase project, run 
        firebase login 
    followed by 
        dart pub global run flutterfire_cli:flutterfire configure

### 4. Build and Launch the Application
Connect an Android physical device via USB (Developer Option, with USB Debugging enabled) or start an Android Emulator at bottom right corner, then run:

    flutter clean
    flutter pub get
    flutter run
