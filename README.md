A Flutter app for Safari park management. It includes live GPS tracking, wildlife logging, and reporting for drivers and admins.


##  Key Features

### Driver Portal
- **Wildlife Logging**: Record sightings with GPS coordinates.
- **GPS Tracking**: Background location tracking with speeding detection.
- **Live Map**: View active drivers and incidents.
- **Support for English, Sinhala, and Tamil.**
- **Emergency Button**: Broadcasts alerts to nearby drivers and HQ.
- **Incident reporting**: Report road blocks or breakdowns with photos.


### Admin Portal
- **Dashboard**: View incident trends and fleet metrics.
- **PDF Reports**: Generate weekly reports.
- **Fleet Monitoring**: Track driver status and location.
- **Messaging**: Contact drivers in the field.
- **Audit Logs**: Track admin actions.


##  Architecture & Tech Stack
- **Frontend**: Flutter (Dart) with `Provider` for reactive state management.
- **Backend**: Supabase (PostgreSQL) for Relational Data & Real-time Subscriptions.
- **Storage**: Supabase Storage for high-speed media hosting.
- **Maps**: `flutter_map` with OSM & `geolocator` for precision telemetry.
- **Theming**: Custom "Gold & Green" design system.


##  Security & Performance
- **RLS (Row Level Security)**: Granular PostgreSQL policies ensuring data privacy between drivers and administrative roles.
- **Offline Resilience**: Offline-first incident caching ensures SOS packets are stored locally until cellular signal is regained.
- **Keyboard Resilience**: Adaptive UI layouts that respond gracefully to keyboard overlays and varying screen densities.
