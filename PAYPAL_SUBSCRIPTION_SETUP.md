# 🔄 PayPal Subscription Setup Guide - Recurring Billing for US Market

## 🎯 New Subscription Model
- **Target Market**: United States
- **Currency**: USD
- **Plans**: Monthly ($6.99), Quarterly ($17.99), Annual ($59.99)
- **Billing**: Automatic recurring subscriptions

---

## 📋 Step 1: PayPal Business Account Setup

### Create/Upgrade to Business Account:
1. **Go to**: https://paypal.com/bizsignup
2. **Business Details**:
   - Business Name: `Aurenna AI`
   - Business Type: `Individual/Sole Proprietorship`
   - Business Country: `United States`
   - Business Category: `Entertainment/Digital Content`
3. **Verify Account**:
   - Upload US government ID
   - Link US bank account
   - Confirm email and phone

---

## 🔑 Step 2: PayPal Developer Dashboard Setup

1. **Go to**: https://developer.paypal.com/dashboard/
2. **Login** with your PayPal Business account
3. **Switch** to "Live" mode (top right corner)
4. **Create App**:
   - App Name: `Aurenna AI Subscriptions`
   - Merchant: Select your business account
   - Features: ✅ Subscriptions

---

## 📦 Step 3: Create Subscription Products & Plans

### A. Create Product First:
```bash
POST https://api.paypal.com/v1/catalogs/products
{
  "name": "Aurenna AI Premium Tarot Readings",
  "description": "Premium tarot reading subscription with unlimited access",
  "type": "SERVICE",
  "category": "SOFTWARE"
}
```

### B. Create Subscription Plans:

**Monthly Plan ($6.99):**
```bash
POST https://api.paypal.com/v1/billing/plans
{
  "product_id": "PROD-aurenna-tarot-readings",
  "name": "Aurenna AI Monthly Subscription",
  "description": "Premium tarot readings - Monthly billing",
  "billing_cycles": [{
    "frequency": {
      "interval_unit": "MONTH",
      "interval_count": 1
    },
    "tenure_type": "REGULAR",
    "sequence": 1,
    "total_cycles": 0,
    "pricing_scheme": {
      "fixed_price": {
        "value": "6.99",
        "currency_code": "USD"
      }
    }
  }]
}
```

**Quarterly Plan ($17.99):**
```bash
POST https://api.paypal.com/v1/billing/plans
{
  "product_id": "PROD-aurenna-tarot-readings",
  "name": "Aurenna AI Quarterly Subscription",
  "description": "Premium tarot readings - 3 months • Save 15%",
  "billing_cycles": [{
    "frequency": {
      "interval_unit": "MONTH",
      "interval_count": 3
    },
    "tenure_type": "REGULAR",
    "sequence": 1,
    "total_cycles": 0,
    "pricing_scheme": {
      "fixed_price": {
        "value": "17.99",
        "currency_code": "USD"
      }
    }
  }]
}
```

**Annual Plan ($59.99):**
```bash
POST https://api.paypal.com/v1/billing/plans
{
  "product_id": "PROD-aurenna-tarot-readings",
  "name": "Aurenna AI Annual Subscription",
  "description": "Premium tarot readings - 12 months • Save 28%",
  "billing_cycles": [{
    "frequency": {
      "interval_unit": "YEAR",
      "interval_count": 1
    },
    "tenure_type": "REGULAR",
    "sequence": 1,
    "total_cycles": 0,
    "pricing_scheme": {
      "fixed_price": {
        "value": "59.99",
        "currency_code": "USD"
      }
    }
  }]
}
```

---

## ⚙️ Step 4: Update App Configuration

**Update your `.env` file:**
```bash
# PayPal Configuration for US Market
PAYPAL_CLIENT_ID=your-live-client-id-here
PAYPAL_SECRET_KEY=your-live-secret-key-here
PAYPAL_ENVIRONMENT=live  # Change from 'sandbox' to 'live'

# Keep Supabase the same
SUPABASE_URL=https://oxenjuugxsazvhtpcbkf.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## 🗄️ Step 5: Database Schema Updates

Create `subscriptions` table in Supabase:
```sql
CREATE TABLE subscriptions (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  paypal_subscription_id TEXT UNIQUE NOT NULL,
  plan_type TEXT NOT NULL, -- 'monthly', 'quarterly', 'annual'
  status TEXT NOT NULL, -- 'CREATED', 'ACTIVE', 'CANCELLED', 'SUSPENDED'
  amount DECIMAL(10,2) NOT NULL,
  currency TEXT DEFAULT 'USD',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  activated_at TIMESTAMP WITH TIME ZONE,
  cancelled_at TIMESTAMP WITH TIME ZONE,
  next_billing_date TIMESTAMP WITH TIME ZONE
);

-- Enable Row Level Security
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- Create policy for users to see only their own subscriptions
CREATE POLICY "Users can view own subscriptions" ON subscriptions
  FOR SELECT USING (auth.uid() = user_id);
```

Update `users` table:
```sql
-- Add subscription columns to users table if they don't exist
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_plan TEXT;
-- subscription_status should already exist from previous implementation
```

---

## 🔄 Step 6: Subscription Flow

### User Subscription Process:
1. **User selects plan** → App calls `PayPalSubscriptionService.createSubscription()`
2. **PayPal returns approval URL** → App launches external PayPal flow
3. **User approves in PayPal** → PayPal redirects to your success URL
4. **App handles success** → Calls `activateSubscription()` to update database
5. **Premium unlocked** → User gets full access

### Automatic Billing:
- PayPal handles all recurring billing
- Webhooks notify your app of payment events
- No manual payment collection needed

---

## 🎣 Step 7: Webhook Setup (Recommended)

Set up PayPal webhooks to handle:
- `BILLING.SUBSCRIPTION.ACTIVATED`
- `BILLING.SUBSCRIPTION.CANCELLED` 
- `PAYMENT.SALE.COMPLETED`
- `BILLING.SUBSCRIPTION.PAYMENT.FAILED`

**Webhook URL**: `https://your-domain.com/api/paypal-webhooks`

---

## 🧪 Step 8: Testing

### Sandbox Testing:
1. Use sandbox credentials in `.env`
2. Test all three subscription plans
3. Verify database updates
4. Test cancellation flow

### Live Testing:
1. Update to live credentials
2. Test with small amounts first
3. Verify real money flow
4. Monitor PayPal dashboard

---

## 💰 Revenue Projections (US Market)

### Monthly Pricing:
- **Monthly**: $6.99/month
- **Quarterly**: $17.99 ($5.99/month - 15% discount)
- **Annual**: $59.99 ($4.99/month - 28% discount)

### PayPal Fees (US Domestic):
- **Rate**: 2.9% + $0.30 per transaction
- **Monthly**: You receive ~$6.49
- **Quarterly**: You receive ~$17.17
- **Annual**: You receive ~$57.25

### Revenue Targets:
- **100 subscribers**: $649-725/month
- **500 subscribers**: $3,245-3,625/month  
- **1,000 subscribers**: $6,490-7,250/month
- **5,000 subscribers**: $32,450-36,250/month

---

## 🚀 Go-Live Checklist

### Before Launch:
- [ ] PayPal Business account verified (US)
- [ ] US bank account linked
- [ ] Live API credentials obtained
- [ ] Subscription plans created in PayPal
- [ ] Database schema updated
- [ ] App tested in sandbox mode
- [ ] Legal compliance (US sales tax, terms)

### Launch Steps:
- [ ] Update `.env` with live credentials
- [ ] Build production app
- [ ] Test with real payment (small amount)
- [ ] Monitor PayPal dashboard
- [ ] Set up webhook handling

---

## 🛡️ Legal & Compliance (US Market)

### Required Disclosures:
- Clear subscription terms
- Auto-renewal disclosure
- Cancellation policy
- Refund policy (if any)
- Sales tax handling (varies by state)

### Terms to Include:
```
"Your subscription automatically renews at the end of each billing 
period unless cancelled. You can cancel anytime through PayPal. 
No refunds for partial periods."
```

---

## 🆘 Troubleshooting

### Common Issues:

**"Plan not found":**
- Verify plan IDs match between app and PayPal
- Check if plans are active in PayPal dashboard

**"Subscription creation failed":**
- Verify API credentials
- Check business account verification status
- Ensure proper permissions in PayPal app

**"Payment failed":**
- User's PayPal account issues
- Insufficient funds
- Payment method declined

---

## 📊 PayPal Dashboard Monitoring

### Key Metrics to Track:
- **Active Subscriptions**: Number of paying users
- **Churn Rate**: Subscription cancellations
- **Revenue**: Monthly recurring revenue
- **Failed Payments**: Payment issues to resolve

### Reports Available:
- Transaction history
- Subscription overview
- Revenue analytics
- Dispute management

---

## 🎉 Success! You're Ready for Recurring Revenue

Once you complete this setup:

✅ **Automatic monthly billing** - No manual payment collection  
✅ **Three pricing tiers** - Options for different user budgets  
✅ **US market focus** - Optimized for American customers  
✅ **Scalable revenue** - Predictable recurring income  
✅ **PayPal management** - Users can self-manage subscriptions  

Your app will now generate true recurring subscription revenue with automatic billing! 💰

---

*Note: This replaces the previous one-time payment system with proper subscription billing.*