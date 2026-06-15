Ambulance Mobile App (Flutter)

Architecture:
- State management: Riverpod (hooks optional)
- Networking: Dio with centralized `DioClient`
- Real-time: Socket.IO client wrapped in `WebSocketService`
- Maps: Google Maps interaction wrapped in `GoogleMapsService`
- Layers:
  - features/* : feature folders (request, tracking, home)
  - core/* : shared services (network, websocket, maps)
  - models/* : DTOs and JSON (json_serializable)
  - providers/* : Riverpod providers

Notes:
- This scaffold contains service and provider stubs but not UI code (screens will be added separately).
- Use `flutter pub get` to install dependencies.
