# PayPal Integration Setup Guide

## Overview
The PayPal integration is now configured for ₱179/month subscription to Aurenna Premium.

## Setup Steps

### 1. Install Dependencies
Run the following command to install the new dependencies:
```bash
flutter pub get
```

### 2. PayPal Developer Account Setup

1. Go to [PayPal Developer Dashboard](https://developer.paypal.com/dashboard/)
2. Create or login to your PayPal Developer account
3. Navigate to "My Apps & Credentials"
4. Create a new app:
   - App Name: "Aurenna AI"
   - Choose "Merchant" account type
   - Select appropriate features (Subscriptions, Payments)

### 3. Get Your Credentials

From the PayPal Developer Dashboard:
1. Click on your app
2. Note down:
   - **Client ID** (for sandbox and live)
   - **Secret Key** (for sandbox and live)

### 4. Configure Environment Variables

1. Create a `.env` file in your project root (copy from `.env.example`):
```bash
cp .env.example .env
```

2. Edit `.env` and add your PayPal credentials:
```env
# For testing (Sandbox)
PAYPAL_CLIENT_ID=your_sandbox_client_id_here
PAYPAL_SECRET_KEY=your_sandbox_secret_key_here
PAYPAL_ENVIRONMENT=sandbox

# For production (switch when ready)
# PAYPAL_CLIENT_ID=your_live_client_id_here
# PAYPAL_SECRET_KEY=your_live_secret_key_here
# PAYPAL_ENVIRONMENT=live
```

### 5. Database Setup (Supabase)

Ensure your Supabase database has the following:

#### Users table should include:
- `subscription_status` (text) - values: 'free', 'paypal_active', 'google_pay_active'
- `subscription_start_date` (timestamp)
- `subscription_end_date` (timestamp)
- `subscription_plan` (text)
- `payment_method` (text)
- `paypal_payment_id` (text)
- `paypal_payer_id` (text)

#### Create a payments table:
```sql
CREATE TABLE payments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  amount DECIMAL(10,2),
  original_amount DECIMAL(10,2),
  discount_amount DECIMAL(10,2) DEFAULT 0,
  coupon_code VARCHAR(50),
  currency VARCHAR(3),
  payment_method VARCHAR(50),
  payment_id VARCHAR(255),
  payer_id VARCHAR(255),
  status VARCHAR(50),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Create a coupon_usage table (optional but recommended):
```sql
CREATE TABLE coupon_usage (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  coupon_code VARCHAR(50),
  discount_amount DECIMAL(10,2),
  used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, coupon_code)
);
```

### 6. Testing

#### Sandbox Testing:
1. Use PayPal sandbox test accounts
2. Create test buyer account at [PayPal Sandbox](https://developer.paypal.com/dashboard/accounts)
3. Test the subscription flow with sandbox credentials

#### Test Flow:
1. User clicks "Subscribe with PayPal" (₱179/month)
2. Redirected to PayPal checkout
3. Login with sandbox buyer account
4. Complete payment
5. Redirected back to app
6. User status updated to premium

### 7. Production Deployment

When ready for production:
1. Get live PayPal credentials
2. Update `.env` file with live credentials
3. Set `PAYPAL_ENVIRONMENT=live`
4. Test with small amount first
5. Monitor PayPal dashboard for transactions

## Important Notes

- **Currency**: Set to PHP (Philippine Peso)
- **Amount**: ₱179.00 per month
- **Subscription Model**: Monthly recurring
- **Payment Methods**: PayPal (Google Pay integration pending)

## Available Coupon Codes

The following coupon codes are pre-configured in the system:

1. **BETA100** - 100% FREE for beta testers (One-time use, expires Dec 31, 2025)
2. **AURENNA90** - 90% off monthly subscription (₱17.90/month, expires Dec 31, 2026)
3. **WELCOME50** - 50% off first month (New users only, expires Dec 31, 2025)
4. **FRIEND30** - 30% friend referral discount (One-time use, expires Dec 31, 2025)
5. **AURENNA20** - 20% off monthly subscription (Expires Dec 31, 2025)

**Note**: The BETA100 coupon provides complete free access without requiring PayPal payment processing.

To add more coupon codes, edit the `_coupons` map in `lib/services/paypal_service.dart`

## Troubleshooting

### Common Issues:

1. **"Client Authentication Failed"**
   - Check if credentials are correct
   - Ensure you're using the right environment (sandbox vs live)

2. **Payment not reflecting**
   - Check Supabase database connection
   - Verify user ID is being passed correctly
   - Check PayPal webhook configuration

3. **Redirect issues**
   - Ensure URL schemes are configured correctly in Android/iOS

## Support

For PayPal integration issues:
- [PayPal Developer Support](https://developer.paypal.com/support/)
- [Flutter PayPal Package Issues](https://pub.dev/packages/flutter_paypal_checkout)

## Next Steps

- [ ] Set up PayPal webhooks for subscription management
- [ ] Implement subscription cancellation flow
- [ ] Add subscription renewal notifications
- [ ] Implement Google Pay integration