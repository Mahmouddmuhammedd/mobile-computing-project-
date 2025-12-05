
# Mobile Chat App (Flutter + Firebase)

This project is a minimal chat application using **Firebase Authentication**, **Realtime Database** (for presence), and **Cloud Firestore** (for messages).

**This ZIP is prepared so you can download and open it directly in Visual Studio Code.**

Required (you must do these before running):
1. Create a Firebase project at https://console.firebase.google.com
2. Add an Android app (package name: `com.example.mobile_chat_app`) and/or iOS app to the Firebase project.
3. Download **google-services.json** (Android) and put it under `android/app/`.  
   Download **GoogleService-Info.plist** (iOS) and put it under `ios/Runner/`.
4. Enable **Email/Password** sign-in in Firebase Authentication.
5. In Firestore, create a collection `chats/{chatId}/messages`.
6. In Realtime Database, set a simple rules for presence or open for testing.
7. Run:
   ```
   flutter pub get
   flutter run
   ```

Notes:
- The sample includes placeholders for `google-services.json` and `GoogleService-Info.plist` (empty). Add your real files to run Firebase services.
- For details and a sample report, see `REPORT.md`.

Reference: Project requirements provided by instructor. fileciteturn0file0
