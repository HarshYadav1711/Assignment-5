# Smart Trip Planner - Flutter Frontend

This is the Flutter frontend for the Smart Trip Planner application.

## Setup

1. **Install Flutter** (if not already installed):
   - Visit https://flutter.dev/docs/get-started/install
   - Follow platform-specific instructions

2. **Verify installation:**
   ```bash
   flutter doctor
   ```

3. **Install dependencies:**
   ```bash
   flutter pub get
   ```

4. **Configure API endpoint:**
   - Edit `lib/core/config/api_config.dart`
   - Set `baseUrl` to your backend URL (e.g., `http://localhost:8000`)

5. **Run the app:**
   ```bash
   flutter run
   ```

## Project Structure

See [FLUTTER_ARCHITECTURE.md](./FLUTTER_ARCHITECTURE.md) for detailed architecture documentation.

## Development

- **Run tests:** `flutter test`
- **Analyze code:** `flutter analyze`
- **Build APK:** `flutter build apk`
- **Build iOS:** `flutter build ios`

## Documentation

- [Architecture](./FLUTTER_ARCHITECTURE.md)
- [BLoC Lifecycle](./BLOC_LIFECYCLE.md)
- [Offline Strategy](./OFFLINE_FIRST_STRATEGY.md)
- [UI/UX Design](./UI_UX_DESIGN.md)
- [Testing Strategy](./TESTING_STRATEGY.md)
