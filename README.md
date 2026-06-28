# Ambulance Booking Platform

A comprehensive ambulance booking and tracking platform built with a robust microservice-inspired architecture. This system features real-time tracking, vendor management, automated dispatcher queuing, and responsive frontends for both web (admin/patients) and mobile (drivers/patients).

## 🏗️ Architecture & Tech Stack

### Backend (`/src` & `/`)
Built with **NestJS**, following Clean Architecture principles for maintainability and scalability.
* **Core**: NestJS, TypeScript, Node.js
* **Database**: PostgreSQL with TypeORM
* **Realtime**: WebSockets (`socket.io`) for live ambulance tracking
* **Background Jobs**: BullMQ and Redis for queue management, asynchronous tasks, and retry mechanisms
* **Authentication**: Passport.js with JWT
* **API Documentation**: Swagger / OpenAPI integration

### Web Frontend (`/web`)
A modern, responsive web application for the admin dashboard, dispatcher control, and patient booking.
* **Framework**: React 19, Vite, TypeScript
* **Styling**: Material UI (MUI), Emotion
* **State & Data**: React Query (`@tanstack/react-query`), React Router
* **Maps**: Leaflet (`react-leaflet`) for live ambulance tracking integration
* **Realtime**: `socket.io-client`

### Mobile App (`/mobile`)
A cross-platform mobile app for patients and drivers.
* **Framework**: Flutter (Dart)
* **State Management**: Riverpod
* **Networking**: Dio
* **Maps**: Google Maps Flutter
* **Charts & Analytics**: `fl_chart`
* **Realtime**: `socket_io_client`

## 🚀 Key Features

* **Intelligent Dispatch System**: Automatic driver assignment and queue health monitoring using BullMQ.
* **Live GPS Tracking**: Real-time websocket-based location sync between drivers and patients.
* **Vendor Integration**: Extensible architecture to plug into various 3rd party ambulance fleet providers.
* **Admin Dashboard**: Live metrics, system audit logs, and granular user/driver management.
* **Role-based Access Control**: Secured endpoints with granular permissions for Admin, Dispatcher, Driver, and Patient roles.

## 📁 Project Structure

```text
├── mobile/                  # Flutter application
├── web/                     # React / Vite web frontend
├── src/
│   ├── common/              # Shared guards, interceptors, filters
│   ├── config/              # Configuration loaders
│   ├── domain/              # Domain entities, value objects
│   ├── gateway/             # WebSocket gateways for realtime
│   ├── infrastructure/      # DB, Redis, HTTP clients, BullMQ
│   ├── modules/             # Feature modules (admin, ambulance, auth, etc.)
│   └── workers/             # Background job processors
├── docker-compose.yml       # Container orchestration (DB, Redis)
└── ambulance-api-spec...    # OpenAPI specifications
```

## 🛠️ Getting Started

### Prerequisites
* Node.js (v20+)
* PostgreSQL
* Redis (for BullMQ)
* Flutter SDK (for mobile app development)

### Running the Backend
1. Install dependencies: `npm install`
2. Start infrastructure (Postgres, Redis) using Docker: `docker-compose up -d`
3. Start the dev server: `npm run start:dev`

### Running the Web App
1. Navigate to web directory: `cd web`
2. Install dependencies: `npm install`
3. Start the dev server: `npm run dev`

### Running the Mobile App
1. Navigate to mobile directory: `cd mobile`
2. Get packages: `flutter pub get`
3. Run on device or emulator: `flutter run`
