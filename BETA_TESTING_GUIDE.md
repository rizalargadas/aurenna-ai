# 🚀 Aurenna AI Beta Testing Deployment Guide

## 📱 Google Play Store Beta Testing

### Prerequisites
1. **Google Play Console Account** ($25 one-time fee)
2. **App Signing Key** (Google manages this now)
3. **Beta Testing Content**

### Step 1: Prepare Your App Bundle
```bash
# Clean and get dependencies
flutter clean
flutter pub get

# Build release AAB (Android App Bundle)
flutter build appbundle --release

# The AAB file will be at: build/app/outputs/bundle/release/app-release.aab
```

### Step 2: Google Play Console Setup
1. **Go to Google Play Console**: https://play.google.com/console
2. **Create New App**:
   - Click "Create app"
   - App name: "Aurenna AI"
   - Default language: English
   - App category: Lifestyle
   - Select "App" (not game)
   - Accept Play Console Developer Policy

### Step 3: App Information Setup
1. **App Details**:
   - Short description: "AI-powered tarot card readings for spiritual guidance"
   - Full description: 
   ```
   Discover your cosmic destiny with Aurenna AI, the revolutionary tarot reading app powered by artificial intelligence.

   ✨ FEATURES:
   • Unlimited premium tarot readings
   • Multiple spreads: Celtic Cross, Love, Career, Yes/No
   • Daily Card of the Day feature
   • Complete reading history
   • Multiple subscription tiers

   🔮 PRICING:
   • Monthly: $6.99 for 30 days
   • Quarterly: $17.99 for 90 days (14% savings)
   • Yearly: $59.99 for 365 days (28% savings)

   Experience the wisdom of the cards with modern AI interpretation. Your spiritual journey awaits!
   ```

2. **Screenshots** (Required - 2-8 screenshots):
   - Take screenshots of key screens: Home, Reading, Premium, Settings
   - Use a phone in portrait mode
   - Resolution: 1080x1920 (16:9 ratio)

3. **App Icon**:
   - 512x512 PNG
   - High quality, represents your brand

### Step 4: Content Rating
1. **Complete Content Rating Questionnaire**:
   - App category: Reference/Entertainment
   - Does your app contain user-generated content? No
   - Does your app contain violence? No
   - Does your app contain sexual/adult content? No
   - This will likely result in "Everyone" or "Teen" rating

### Step 5: Upload App Bundle
1. **Go to Release > Testing > Internal testing**
2. **Create new release**:
   - Upload your `app-release.aab` file
   - Release name: "Beta v1.0.0"
   - Release notes: "Initial beta release with multi-tier subscription system"

### Step 6: Set Up Beta Testing
1. **Create Test Track**:
   - Go to "Testing" > "Internal testing"
   - Or "Testing" > "Closed testing" for external users
   
2. **Add Testers**:
   - Create email list of beta testers
   - Send them opt-in link
   - They can install via Play Store

---

## 🍎 Apple App Store Beta Testing (TestFlight)

### Prerequisites
1. **Apple Developer Account** ($99/year)
2. **Xcode** (on macOS)
3. **iOS Device** for testing

### Step 1: Prepare iOS Build
```bash
# Clean and get dependencies
flutter clean
flutter pub get

# Build iOS release
flutter build ios --release

# Open iOS project in Xcode
open ios/Runner.xcworkspace
```

### Step 2: Xcode Configuration
1. **In Xcode**:
   - Select your development team
   - Set Bundle Identifier: `com.aurenna.aurennaai`
   - Set Version: `1.0.0`
   - Set Build: `1`
   
2. **Signing & Capabilities**:
   - Enable "Automatically manage signing"
   - Select your Apple Developer Team

3. **App Store Connect Configuration**:
   - Product > Archive
   - Upload to App Store Connect

### Step 3: App Store Connect Setup
1. **Go to App Store Connect**: https://appstoreconnect.apple.com
2. **Create New App**:
   - Name: "Aurenna AI"
   - Primary Language: English
   - Bundle ID: `com.aurenna.aurennaai`
   - SKU: `AURENNA_AI_2025`

### Step 4: App Information
1. **App Information**:
   - Subtitle: "AI Tarot Card Readings"
   - Category: Lifestyle
   - Content Rights: You own or have licensed all rights
   
2. **Version Information**:
   - Description: (Same as Google Play)
   - Keywords: "tarot, cards, spiritual, AI, readings, fortune"
   - Support URL: Your website
   - Marketing URL: Your website

3. **Screenshots** (Required):
   - iPhone screenshots: 1290x2796 (iPhone 14 Pro)
   - Take 3-5 screenshots of key features

### Step 5: Pricing and Availability
1. **Pricing**: Free with In-App Purchases
2. **In-App Purchases** (Set these up first):
   - Monthly Premium: $6.99
   - Quarterly Premium: $17.99  
   - Yearly Premium: $59.99

### Step 6: TestFlight Beta
1. **Upload Build via Xcode**
2. **In App Store Connect**:
   - Go to TestFlight tab
   - Select your uploaded build
   - Add Internal/External testers
   - Provide test information

---

## 🔧 Pre-Launch Checklist

### App Preparation
- [ ] Update version in `pubspec.yaml`
- [ ] Test all subscription tiers
- [ ] Test all coupon codes
- [ ] Verify PayPal integration works
- [ ] Test on different screen sizes
- [ ] Check app performance
- [ ] Verify Supabase connection

### Legal & Compliance
- [ ] Create Privacy Policy
- [ ] Create Terms of Service
- [ ] Add GDPR compliance (if targeting EU)
- [ ] Verify payment processing compliance

### Marketing Materials
- [ ] App icon (1024x1024 for iOS, 512x512 for Android)
- [ ] Screenshots (both platforms)
- [ ] Feature graphic (Android)
- [ ] App description
- [ ] Keywords for ASO

---

## 📋 Beta Testing Commands

### Android Build Commands
```bash
# Debug build for testing
flutter build apk --debug

# Release build for Play Store
flutter build appbundle --release

# Install on connected device
flutter install
```

### iOS Build Commands
```bash
# Debug build
flutter build ios --debug

# Release build  
flutter build ios --release

# Run on iOS simulator
flutter run -d "iPhone Simulator"
```

---

## 🎯 Beta Testing Focus Areas

### Core Functionality
1. **Authentication**: OTP signup/signin
2. **Free Questions**: 3 questions limit works
3. **Premium Subscription**: All 3 tiers work
4. **Coupon System**: All codes work with all plans
5. **Card Readings**: All spread types function
6. **Daily Card**: Once per day limitation
7. **Settings**: Days counter accurate

### Payment Testing
1. **PayPal Integration**: Sandbox testing
2. **Subscription Management**: Automatic expiration
3. **Free Trials**: 100% coupons work
4. **Pricing Display**: Correct for all regions

### User Experience  
1. **Onboarding Flow**: Smooth signup process
2. **UI/UX**: Intuitive navigation
3. **Performance**: Fast loading times
4. **Error Handling**: Graceful error messages
5. **Offline Behavior**: Appropriate fallbacks

---

## 🚦 Launch Timeline

### Week 1: Preparation
- [ ] Complete app store assets
- [ ] Set up developer accounts
- [ ] Create privacy policy/terms

### Week 2: Upload & Review
- [ ] Upload to both stores
- [ ] Complete store listings
- [ ] Submit for review

### Week 3: Beta Testing
- [ ] Invite beta testers
- [ ] Collect feedback
- [ ] Fix critical issues

### Week 4: Launch Preparation
- [ ] Marketing materials ready
- [ ] Launch strategy planned
- [ ] Monitor analytics setup

---

## 📞 Support Resources

- **Google Play Console Help**: https://support.google.com/googleplay/android-developer/
- **App Store Connect Help**: https://developer.apple.com/support/app-store-connect/
- **Flutter Deployment Guide**: https://docs.flutter.dev/deployment

Good luck with your beta launch! 🎉