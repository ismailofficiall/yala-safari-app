# Yala National Park: Driver Operations Platform
**A Real-time Flutter Application for Wildlife Park Fleet Management**

## 🏆 Project Overview
This platform acts as an intelligent, real-time tracking and incident management suite for Yala National Park. Built entirely with **Flutter**, **Geolocator**, and **Supabase (PostgreSQL)**, it solves a mission-critical domain problem: preserving driver safety and capturing actionable wildlife metadata in zones with intermittent network connectivity.

## 🌟 Key Features
* **Offline-First Synchronization (NVRAM Queueing)**: Drivers can log wildlife sightings using `SharedPreferences`. Once a cellular connection is re-established, the payload is automatically pushed to the cloud.
* **Proximity Zone Alerts (Geofencing)**: Automatically calculates Euclidean distances matching live GPS coordinates against known Supabase polygon boundaries; triggers an alert when a driver approaches a restricted zone (<50m).
* **Automated Speed Audits**: `LocationService` listens to periodic native OS location sensors. If the raw kinetic speed exceeds ~40km/h, an indisputable "Speeding Incident" is autonomously logged into the HQ audit table.
* **Emergency Dispatch**: A highly visible, long-press SOS panic button instantly dumps exact GPS coordinates to an Admin dispatcher's dashboard with real-time WebSocket listening.
* **Live Weather Integration**: Connects via HTTP to the public *Open-Meteo API* to extract live micro-climate wind patterns and localized temperatures directly overriding Yala map coordinates.
* **PDF Export Generation**: Utilizes `pdf` and `printing` to execute client-side rendering of A4-ready statistical analysis, encompassing driver leaderboards and recent wildlife activities.

## 🏗️ Technical Architecture
```mermaid
graph TD
    subgraph Client Application (Flutter)
        A[Driver Dashboard] --> |Location Stream| B(LocationService)
        A --> |UI Layer| C{OfflineSyncService}
        A --> |HTTP GET| F[Open-Meteo REST API]
    end

    subgraph Hardware Persistence
        C --> |JSON Serialization| D[(SharedPreferences)]
    end

    subgraph Backend Configuration (Supabase/Firebase)
        B --> |Coordinates| E[(Firebase Realtime)]
        D -.-> |Network Recovery| G[(PostgreSQL Incidents)]
    end
    
    subgraph Admin View
        H[Admin Dashboard] --> |Listen| G
        H --> |Print/Save| I(PDF Generator)
    end
```

## 🧪 Testing Methodology
A robust separation of concerns allowed the business logic to be mathematically verified.
* **Unit Testing**: Proved that `OfflineSyncService` correctly stringifies `Map<String, dynamic>` JSON structures and gracefully cascades failures without crashing.
* **Widget Testing**: Simulated isolated UI rendering states for components like the `YalaWeatherWidget`, aggressively trapping broken LayoutBuilder structures before compilation.

## 🚀 Execution Instructions
1. Clone this repository locally.
2. Ensure you have the Flutter toolchain linked correctly in your `$PATH`.
3. Overwrite placeholders in `LocationService` linking back to your `Supabase` environment variables.
4. Run `flutter test` to ensure zero logical regressions.
5. Deploy using `flutter run -d chrome` or via Android execution (`flutter run -d android`).
