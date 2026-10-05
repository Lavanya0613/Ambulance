# Mobile Development & Physical Android Device Setup

This guide explains how to run the CallHealth Ambulance Flutter application on a physical Android phone connected to your local development machine (laptop).

---

## 1. Backend Port & Binding Configuration

- **Backend Port**: `3000` (configurable via `PORT` environment variable).
- **Binding Address**: `0.0.0.0` (accepts connections from local network devices as well as localhost).

### Start the Backend
From the project root directory, run:
```bash
npm run start:dev
```
Or for production build mode:
```bash
npm run start
```

---

## 2. Finding Your Laptop's Local IPv4 Address

Your physical Android phone and laptop must be connected to the **same Wi-Fi network**.

On Windows:
1. Open PowerShell or Command Prompt.
2. Run:
   ```cmd
   ipconfig
   ```
3. Look for **Wireless LAN adapter Wi-Fi** or **Ethernet adapter**.
4. Note your **IPv4 Address** (e.g., `192.168.1.15`).

---

## 3. Launching Flutter on Physical Android Phone

Connect your Android phone to your laptop via USB and enable **USB Debugging**.

### Option A: Direct Local Network Connection (Recommended for Wi-Fi)
Run Flutter with `--dart-define=API_BASE_URL`:
```bash
cd mobile
flutter run --dart-define=API_BASE_URL=http://<LAPTOP_IP>:<BACKEND_PORT>
```

**Example:**
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.15:3000
```

---

### Option B: USB Port Forwarding / Reverse Tunnel (Recommended for USB Cable)
If your phone is plugged in via USB, you can forward the backend port over ADB:
```bash
adb reverse tcp:<BACKEND_PORT> tcp:<BACKEND_PORT>
```
Then launch Flutter pointing to `localhost`:
```bash
cd mobile
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

---

## 4. Android Cleartext HTTP Configuration

The local development server runs over HTTP (unencrypted). Android 9+ (API 28+) disables cleartext HTTP traffic by default.

To enable HTTP communication with your local server during development:
- `android:usesCleartextTraffic="true"` has been added to `<application>` in `mobile/android/app/src/main/AndroidManifest.xml`.
- `<uses-permission android:name="android.permission.INTERNET"/>` is configured in `mobile/android/app/src/main/AndroidManifest.xml`.

---

## 5. Troubleshooting & Error Messages

If the phone cannot connect to the server:
- Ensure laptop and phone are on the exact same Wi-Fi network or connected via USB ADB reverse.
- Ensure your Windows Firewall allows inbound connections to Node.js / Port `3000`.
- If connection fails, the app will display:  
  `"Unable to connect to server. Please check your network and server URL."`
