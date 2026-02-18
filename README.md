# CalH2O

A Flutter-based nutrition and hydration tracking app powered by Firebase and AI. Users can log meals via text or photo, track water intake, and receive personalized daily nutrition recommendations through an animated character companion.

## Preview

### Onboarding 
![Login](assets/screen_shots/login.jpg)

### Home
![Main](assets/screen_shots/main.jpg)

### Record
![Record 1](assets/screen_shots/record_1.jpg)
![Record 2](assets/screen_shots/record_2.jpg)

### History
![History](assets/screen_shots/history.jpg)
![History Graph](assets/screen_shots/history_graph.jpg)

## Features

- **AI-Powered Meal Logging** - Record meals by text description or photo; AI extracts nutritional data automatically
- **Water Tracking** - Log daily water intake with visual progress and analytics
- **Daily Nutrition Analysis** - View calorie, protein, fat, and carb breakdowns with charts
- **Personalized Goals** - Set fitness goals (gain, lose, maintain) and get tailored daily needs
- **Animated Companion** - Interactive character that changes appearance based on your nutrition habits
- **Meal History** - Browse past records and nutrition details
- **Chat-Style Input** - Conversational interface for natural meal logging

## Tech Stack

- **Frontend**: Flutter (Dart) with Provider state management
- **Backend**: Firebase (Firestore, Cloud Functions)
- **AI**: Firebase Genkit flows for nutrition extraction and daily recommendations
- **Platforms**: iOS, Android

## Project Structure

```
lib/
  main.dart                  # App entry point and routing
  firebase_options.dart      # Firebase configuration
  model/                     # Data models (message, nutrition)
  pages/                     # Screen pages (main, record, startup, analyze, history)
  services/                  # Cloud function calls, camera, image upload
  widgets/                   # Reusable UI components
functions/
  src/                       # Firebase Cloud Functions (TypeScript)
    flow/                    # Genkit AI flows (nutrition, daily needs, photo analysis)
assets/
  animation/                 # Character animation frames
  fonts/                     # Mononoki font family
```

## Getting Started

### Prerequisites

- Flutter SDK (>=3.7.0)
- Firebase CLI
- Node.js (for Cloud Functions)

### Setup

1. Clone the repository
2. Configure Firebase:
   ```bash
   flutterfire configure
   ```
3. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```
4. Install Cloud Functions dependencies:
   ```bash
   cd functions && npm install
   ```
5. Run the app:
   ```bash
   flutter run
   ```

## Known Issues & Future Improvements

This was a sophomore-year project. Revisiting it as a junior, I've identified several architectural decisions that should be improved:

| Area | Current Approach | Better Approach |
|------|-----------------|-----------------|
| Authentication | Plaintext credentials stored directly in Firestore | Migrate to Firebase Authentication for secure, token-based auth with password hashing |
| Image Storage | Photos encoded as Base64 strings in Firestore | Use Cloud Storage for Firebase with download URL references |
| Document Size | Base64 images inflate Firestore document size (1 MiB limit risk) | Cloud Storage has no practical per-file size constraint |
| Security Rules | No Firestore Security Rules; any client can read/write any user's data | Add per-user rules based on Firebase Auth UID |
| API Endpoints | Cloud Function URLs hardcoded in client code | Use environment config or Firebase SDK callable functions |

## License

See [LICENSE](LICENSE) for details.
