# 💰 PayPal Live Setup Guide - Ready for Real Money!

## 🎯 Current Status
- ✅ PayPal integration is complete
- ✅ Currently in **SANDBOX** (test) mode
- 🚀 Ready to switch to **LIVE** mode for real payments

---

## 📋 Step 1: PayPal Business Account

### Option A: Create New Business Account
1. **Go to**: https://paypal.com/bizsignup
2. **Select**: Business Account
3. **Business Details**:
   - Business Name: `Aurenna AI`
   - Business Type: `Individual/Sole Proprietorship`
   - Business Email: Your email
   - Business Phone: Your phone
4. **Verify Account**:
   - Upload valid government ID
   - Link your bank account (for receiving payments)
   - Confirm email and phone

### Option B: Upgrade Existing Personal Account
1. **Login** to PayPal
2. **Go to**: Settings → Account Settings
3. **Click**: "Upgrade to Business Account"
4. **Complete** business verification steps

---

## 🔑 Step 2: Get Live PayPal API Credentials

1. **Go to**: https://developer.paypal.com/dashboard/
2. **Login** with your PayPal Business account
3. **Switch** to "Live" mode (top right corner)
4. **Create App**:
   - App Name: `Aurenna AI Production`
   - Merchant: Select your business account
   - Features: ✅ Accept Payments
5. **Copy Your Live Credentials**:
   ```
   Client ID: AXxxxxxxxxxxxxxxxxxxxxxxx
   Secret: EXxxxxxxxxxxxxxxxxxxxxxxx
   ```

---

## ⚙️ Step 3: Update Your App Configuration

**Replace the values in your `.env` file:**

```bash
# Change these to your LIVE credentials:
PAYPAL_CLIENT_ID=AXxxxxxxxxxxxxxxxxxxxxxxx
PAYPAL_SECRET_KEY=EXxxxxxxxxxxxxxxxxxxxxxxx
PAYPAL_ENVIRONMENT=live  # ← Change from 'sandbox' to 'live'

# Keep these the same:
SUPABASE_URL=https://oxenjuugxsazvhtpcbkf.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## 🧪 Step 4: Test Real Payment (Small Amount First)

**Before going live, test with a small amount:**

1. **Build your app**: `flutter build apk --release`
2. **Install on your phone**
3. **Make a ₱1 test payment** using your own PayPal account
4. **Verify**:
   - Payment goes through
   - Money appears in your PayPal account
   - Premium features unlock in app
   - Database records payment

---

## 💸 Step 5: Money Flow (How You Get Paid)

```
Customer pays ₱179 → PayPal takes fee → You receive money
```

### **PayPal Fees (Philippines):**
- **Domestic**: 3.9% + ₱15 = **₱22** fee
- **International**: 4.4% + ₱15 = **₱23** fee  
- **You receive**: **₱156-157** from ₱179 payment

### **Payout Options:**
- **Bank Transfer**: 3-5 business days (₱50 fee)
- **PayPal Balance**: Instant, use for online purchases
- **PayPal Card**: Get a PayPal debit card (if available in PH)

---

## ✅ Go-Live Checklist

### Before Switching to Live:
- [ ] PayPal Business account verified
- [ ] Bank account linked to PayPal
- [ ] Live API credentials obtained
- [ ] App tested with sandbox mode
- [ ] Small real payment test completed

### Update App:
- [ ] Replace `.env` with live credentials
- [ ] Change `PAYPAL_ENVIRONMENT=live`
- [ ] Build release version: `flutter build apk --release`
- [ ] Test one more time with real payment

### Legal/Business:
- [ ] Terms of Service mentions subscription billing
- [ ] Privacy Policy mentions payment data handling
- [ ] Clear refund policy stated
- [ ] Business name consistent everywhere

---

## 🚀 Deployment Options

### Google Play Store:
1. **Build**: `flutter build appbundle --release`
2. **Upload** to Play Console
3. **Declare**: In-app products (subscription)
4. **Test** with internal testing first
5. **Release** to production

### Direct APK Distribution:
1. **Build**: `flutter build apk --release`
2. **Host** APK file on your website
3. **Users** download and install directly
4. **Note**: Users need to enable "Unknown Sources"

---

## 📊 Monitoring Your Payments

### PayPal Dashboard:
- **Activity**: See all transactions
- **Reports**: Monthly/yearly summaries  
- **Disputes**: Handle refund requests
- **Settings**: Update business info

### Your App Database:
- Check Supabase `payments` table
- Monitor subscription status
- Track coupon usage
- Analyze user behavior

---

## 🛡️ Security Best Practices

### Never Expose:
- ❌ PayPal Secret Key in client code
- ❌ Database credentials in app
- ❌ API keys in version control

### Always Use:
- ✅ Environment variables (.env file)
- ✅ HTTPS for all API calls
- ✅ Input validation
- ✅ Error handling

---

## 🆘 Troubleshooting

### "Payment Declined":
- Check PayPal account limits
- Verify business account is approved
- Ensure sufficient balance for fees

### "API Error":
- Confirm Live credentials are correct
- Check PayPal Developer Dashboard for issues
- Verify app permissions

### "Database Not Updated":
- Check Supabase logs
- Verify internet connection
- Test payment flow in sandbox first

---

## 📞 Support Contacts

- **PayPal Developer Support**: developer.paypal.com/support
- **PayPal Business Support**: paypal.com/businesshelp
- **Emergency**: Your PayPal account → Help & Contact

---

## 💰 Expected Revenue

With ₱179/month subscription:
- **10 users**: ₱1,560/month (₱18,720/year)
- **50 users**: ₱7,850/month (₱94,200/year)  
- **100 users**: ₱15,700/month (₱188,400/year)
- **500 users**: ₱78,500/month (₱942,000/year)

*After PayPal fees (3.9% + ₱15 per transaction)*

---

## 🎉 You're Ready to Make Money!

Once you update those 3 lines in your `.env` file:
1. Replace Client ID with live version
2. Replace Secret Key with live version  
3. Change environment to 'live'

**Your app will start accepting real PayPal payments!** 💰

---

*Remember: Start with small test payments, then gradually scale up as you gain confidence.*