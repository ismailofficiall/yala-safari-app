# Yala Safari Driver App & Admin Ecosystem

A comprehensive Flutter application for Safari park management in Yala National Park. It includes live GPS tracking, wildlife logging, and emergency reporting for drivers and HQ administrators.

## Key Features

### Driver Portal (Mobile)
- **Live Wildlife Logging**: Drivers can record animal sightings (species, count, behavior) with GPS stubs for biodiversity tracking.
- **Real-Time GPS Telemetry**: Background location tracking with speed violation detection to ensure park safety.
- **Interactive Live Map**: View fellow drivers and active incidents on a high-performance OpenStreetMap layer.
- **Multilingual Support**: Full support for **English, Sinhala, and Tamil**, allowing for a localized experience across the entire Sri Lankan workforce.
- **Safety SOS Cluster**: High-priority panic button that broadcasts an emergency alert to all drivers within a 5km radius and HQ instantly.
- **Incident reporting**: Detailed reporting of road blocks, animal attacks, or vehicle breakdowns with media (photo/video) upload capabilities.

### Admin Portal (HQ Control)
- **Executive Analytics**: Professional dashboard featuring incident trend charts (last 7 days) and fleet performance metrics.
- **Professional PDF Reports**: Generate and export executive-level "Weekly Operational Reports" in PDF format directly from the dashboard.
- **Live Fleet Supervision**: Monitor all active drivers, their ratings, and current statuses (Active/Suspended/Away).
- **Direct Communication**: Built-in chat system to relay instructions to specific drivers in the field.
- **Audit Logging**: Comprehensive system-wide audit logs tracking all administrative actions for transparency.

## Architecture & Tech Stack
- **Frontend**: Flutter (Dart) with `Provider` for reactive state management.
- **Backend**: Supabase (PostgreSQL) for Relational Data & Real-time Subscriptions.
- **Storage**: Supabase Storage for high-speed media hosting.
- **Maps**: `flutter_map` with OSM & `geolocator` for precision telemetry.
- **Theming**: Custom "Gold & Green" design system.

## Security & Performance
- **RLS (Row Level Security)**: Granular PostgreSQL policies ensuring data privacy between drivers and administrative roles.
- **Offline Resilience**: Offline-first incident caching ensures SOS packets are stored locally until cellular signal is regained.
- **Keyboard Resilience**: Adaptive UI layouts that respond gracefully to keyboard overlays and varying screen densities.

## Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Dart SDK
- Android Studio / VS Code with Flutter extension
- Supabase Project (for backend)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/your-repo/yala-safari-app.git
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```
