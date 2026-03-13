# Yala Safari Driver App

A Flutter app built for managing safari jeep operations in Yala National Park. Covers driver GPS tracking, wildlife sighting logs, incident reporting, and an admin dashboard for HQ staff.

## Features

### Driver App
- **Wildlife Logging**: Log animal sightings with species, count, and behaviour, plus optional photo/video.
- **GPS Tracking**: Background location updates with automatic speed violation detection.
- **Live Map**: See other drivers and open incidents on an OpenStreetMap view.
- **Multilingual**: Supports English, Sinhala, and Tamil.
- **SOS Button**: Long-press panic button that sends an emergency alert to HQ and nearby drivers.
- **Incident Reports**: Report road blocks, animal encounters, or breakdowns with media attachments.
- **Offline Mode**: Incidents queued locally if no signal and auto-synced when connection returns.

### Admin Dashboard
- **Analytics**: Charts for incident trends over the last 7 days and driver performance stats.
- **PDF Export**: Generate a weekly operational summary as a PDF.
- **Driver Management**: View and manage all drivers, their status and ratings.
- **Messaging**: Send messages directly to individual drivers.
- **Audit Logs**: Track admin actions across the system.

## Tech Stack
- **Flutter** (Dart) with Provider for state management
- **Supabase** (PostgreSQL) for the main database and real-time subscriptions
- **Firebase Realtime Database** for live GPS telemetry
- **flutter_map** + OpenStreetMap for the map view
- **SharedPreferences** for offline incident queuing

## Setup

### Requirements
- Flutter SDK
- Android Studio or VS Code
- A Supabase project with the required tables

### Run Locally
```bash
git clone https://github.com/ismailofficiall/yala-safari-app.git
cd yala-safari-app
flutter pub get
flutter run
```
