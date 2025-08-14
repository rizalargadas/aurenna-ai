# 🔐 Fix App Signing - Create Release Keystore

## The Issue
Google Play Store requires apps to be signed with a **release keystore**, not debug mode. Let's fix this step by step.

## Step 1: Create Release Keystore

Open Command Prompt in your project directory and run:

```bash
keytool -genkey -v -keystore android/app/aurenna-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias aurenna
```

**You'll be prompted for information. Use these values:**

- **Keystore password**: `aurenna2025!` (write this down!)
- **Key password**: `aurenna2025!` (same as keystore password)
- **First and last name**: `Aurenna AI`
- **Organizational unit**: `Development`
- **Organization**: `Aurenna`
- **City**: Your city
- **State**: Your state/province
- **Country code**: Your 2-letter country code (e.g., US, CA, PH)

## Step 2: Create Key Properties File

Create file: `android/key.properties`

```properties
storePassword=aurenna2025!
keyPassword=aurenna2025!
keyAlias=aurenna
storeFile=aurenna-release-key.jks
```

## Step 3: Update Gradle Configuration

The build.gradle.kts file will be updated automatically in the next step.

## Step 4: Build Signed Release

After setup, run:
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

## ⚠️ IMPORTANT SECURITY NOTES

1. **NEVER commit your keystore or key.properties to git**
2. **Backup your keystore file** - losing it means you can never update your app
3. **Store passwords securely** - write them down in a safe place

## Files Created:
- `android/app/aurenna-release-key.jks` (your keystore - keep this safe!)
- `android/key.properties` (signing configuration - don't commit to git)

Let's proceed with the automated setup...