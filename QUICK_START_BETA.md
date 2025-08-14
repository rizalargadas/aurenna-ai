# 🚀 Quick Start: Beta Testing Setup

## 📱 Immediate Action Items

### 1. Build Your App (5 minutes)
```bash
# Run the deployment script
./deploy.bat

# Or manually:
flutter clean
flutter pub get
flutter build appbundle --release
```

### 2. Google Play Store Setup (30 minutes)

#### Prerequisites:
- Google account
- $25 for Google Play Console account
- Screenshots of your app

#### Steps:
1. **Sign up for Google Play Console**: https://play.google.com/console
2. **Pay $25 one-time fee** (takes a few minutes to process)
3. **Create new app** with these details:
   - **App name**: Aurenna AI
   - **Package name**: com.aurenna.aurennaai
   - **Category**: Lifestyle
   - **Content rating**: Everyone (after questionnaire)

4. **Upload your AAB**: 
   - File location: `build/app/outputs/bundle/release/app-release.aab`
   - Go to "Release" > "Testing" > "Internal testing"
   - Create new release and upload AAB file

### 3. App Store Assets Needed

#### Screenshots (Take these from your running app):
- **Android**: 1080x1920 (portrait mode)
- **iPhone**: 1290x2796 (iPhone 14 Pro size)
- Take 3-5 screenshots showing:
  1. Home screen with services
  2. Premium upgrade screen with pricing
  3. Tarot reading in progress
  4. Settings screen showing subscription
  5. Card reading result

#### App Icon:
- **512x512 PNG** for Google Play
- **1024x1024 PNG** for App Store
- Should represent tarot/mystical theme

### 4. Store Descriptions

#### Short Description (80 characters max):
"AI-powered tarot readings for spiritual guidance and cosmic insights"

#### Full Description:
```
Discover your cosmic destiny with Aurenna AI, the revolutionary tarot reading app powered by artificial intelligence.

✨ FEATURES:
• Unlimited premium tarot readings with AI interpretations
• Multiple spreads: Celtic Cross, Love, Career, Yes/No
• Daily Card of the Day feature with 24-hour cooldown
• Complete reading history for premium subscribers
• Secure PayPal payment integration

🔮 SUBSCRIPTION PLANS:
• Monthly: $6.99 for 30 days
• Quarterly: $17.99 for 90 days (Save 14%)
• Yearly: $59.99 for 365 days (Save 28%)

🎁 BETA TESTING PERKS:
Use coupon codes for massive discounts:
• BETA100: 100% FREE subscription
• AURENNA90: 90% off any plan
• WELCOME50: 50% off your first subscription

Experience the wisdom of ancient tarot cards combined with modern AI technology. Your spiritual journey awaits!

🔒 PRIVACY & SECURITY:
• Secure OTP-based authentication
• No personal readings stored without permission
• PayPal secure payment processing
• GDPR compliant data handling

Download Aurenna AI now and unlock the mysteries of your future!
```

## 🎯 Beta Testing Strategy

### Phase 1: Internal Testing (Week 1)
- **Test with friends/family** (5-10 people)
- **Focus areas**: Core functionality, payment flow, UI/UX
- **Use Google Play Internal Testing**

### Phase 2: Closed Beta (Week 2-3)
- **Expand to 20-50 testers**
- **Test all subscription tiers**
- **Collect feedback via Google Forms/email**

### Phase 3: Open Beta (Week 4)
- **Public beta testing**
- **Monitor crash reports and analytics**
- **Final bug fixes before launch**

## 🔧 Pre-Launch Checklist

### App Configuration:
- [x] Updated package name to `com.aurenna.aurennaai`
- [x] Set proper app name "Aurenna AI"
- [x] Version set to 1.0.0+1
- [ ] Test PayPal integration in sandbox mode
- [ ] Verify all coupon codes work
- [ ] Test subscription expiration logic
- [ ] Check app permissions in manifest

### Legal Documents (Required):
- [ ] **Privacy Policy** (create at privacypolicies.com)
- [ ] **Terms of Service** (create template online)
- [ ] Add links to these in your app settings

### Store Assets:
- [ ] App icon (512x512 for Android, 1024x1024 for iOS)
- [ ] Screenshots (5 minimum for each platform)
- [ ] Feature graphic for Google Play (1024x500)
- [ ] Store descriptions ready

## ⚡ Quick Commands

### Build for Testing:
```bash
# Debug build for testing
flutter build apk --debug

# Release build for distribution
flutter build appbundle --release
```

### Test Installation:
```bash
# Install debug APK on connected device
flutter install

# Or manually install APK
adb install build/app/outputs/flutter-apk/app-debug.apk
```

## 📞 Need Help?

### Common Issues:
1. **Build fails**: Run `flutter doctor` to check setup
2. **Signing errors**: Use Play Console app signing
3. **Package name conflicts**: Make sure com.aurenna.aurennaai is unique
4. **PayPal not working**: Check .env file has correct keys

### Resources:
- Flutter docs: https://docs.flutter.dev/deployment
- Google Play Help: https://support.google.com/googleplay/android-developer/
- PayPal Developer: https://developer.paypal.com/

## 🎉 Ready to Launch?

1. **Run `deploy.bat`** and choose option 3 (AAB for Play Store)
2. **Upload AAB to Google Play Console**
3. **Add screenshots and descriptions**
4. **Set up beta testing track**
5. **Invite your first testers!**

Your app is configured and ready for beta testing! 🚀