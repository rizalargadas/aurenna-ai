# 🔧 OTP Verification Code Not Received - Troubleshooting

## 🚨 Common Causes & Solutions

### 1. **Supabase Email Rate Limiting** (Most Common)
**Problem**: Supabase free tier has email sending limits
**Solution**: Check Supabase dashboard for email quota

#### Check in Supabase Dashboard:
1. Go to https://supabase.com/dashboard
2. Select your project
3. Go to **Settings** → **Usage** 
4. Check **Auth emails sent** counter
5. Free tier limit: **30 emails/hour, 100/day**

### 2. **Email Provider Blocking** 
**Problem**: Gmail/Yahoo may block automated emails
**Solutions**:
- Check **Spam/Junk folder**
- Try different email providers (Gmail, Outlook, Yahoo)
- Use a custom domain email if available

### 3. **Supabase Auth Configuration**
**Problem**: Email templates or SMTP settings misconfigured
**Solution**: Verify Supabase email settings

#### Check Supabase Auth Settings:
1. Go to **Authentication** → **Settings** 
2. Check **SMTP Settings**:
   - Should show "Supabase SMTP" if using default
   - Or your custom SMTP if configured
3. Check **Email Templates**:
   - Confirm templates are enabled
   - Test with different template

### 4. **Network/Firewall Issues**
**Problem**: Corporate/school networks blocking emails
**Solutions**:
- Try different network (mobile data vs WiFi)
- Use personal device instead of work device
- Try from different location

## 🔍 Quick Debugging Steps

### Step 1: Check Supabase Logs
```
Supabase Dashboard → Logs → Auth logs
Look for:
- "Email sent successfully" 
- Error messages about email delivery
- Rate limiting warnings
```

### Step 2: Test Different Email Addresses
```
Try these email providers:
✅ Gmail: yourname@gmail.com
✅ Outlook: yourname@outlook.com  
✅ Yahoo: yourname@yahoo.com
✅ Apple: yourname@icloud.com
```

### Step 3: Check Email Folders
```
✅ Inbox
✅ Spam/Junk folder
✅ Promotions tab (Gmail)
✅ Social tab (Gmail)
```

## 🛠️ Immediate Fix Options

### Option 1: Reset Email Rate Limit (If Hit Limit)
1. Wait 1 hour for rate limit reset
2. Or upgrade Supabase plan temporarily
3. Or use different test email addresses

### Option 2: Alternative Testing Method
**Use Supabase Dashboard for Testing:**
1. Go to **Authentication** → **Users**
2. Click **"Invite user"** 
3. Enter email address
4. They'll get invitation email instead of OTP

### Option 3: Temporary Password Authentication
**Quick Fix for Beta Testing:**
```dart
// In your auth service, temporarily add password auth
await _supabase.auth.signInWithPassword(
  email: email,
  password: 'temp_beta_password'
);
```

## 📧 Check Supabase Email Configuration

### Default Configuration Should Show:
```
SMTP Host: smtp.supabase.com
From Address: noreply@mail.app.supabase.com
Status: Active
```

### If Using Custom SMTP:
- Verify SMTP credentials are correct
- Test SMTP connection in dashboard
- Check DNS/domain verification

## 🔄 Alternative Authentication Options

### Temporary Workaround for Beta:
1. **Pre-create test accounts** in Supabase dashboard
2. **Share login credentials** with beta testers
3. **Skip OTP verification** for beta testing
4. **Fix OTP after beta** for production launch

### Creating Test Accounts:
```
Supabase Dashboard → Authentication → Users → Invite User
Email: betauser1@gmail.com
(They get direct invite link, no OTP needed)
```

## 📱 App-Side Debugging

### Add Debug Logging:
```dart
// In your OTP verification code
try {
  await _supabase.auth.signInWithOtp(email: email);
  print('✅ OTP request sent successfully');
} catch (e) {
  print('❌ OTP request failed: $e');
  // Show specific error to user
}
```

### Show Better Error Messages:
```dart
// Instead of generic "Check your email"
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('OTP sent! Check inbox and spam folder. May take 1-2 minutes.'),
    duration: Duration(seconds: 5),
  ),
);
```

## 🎯 Most Likely Solutions

### 1st Try: **Check Spam Folder**
- 80% of missing OTPs are in spam
- Add noreply@mail.app.supabase.com to contacts

### 2nd Try: **Different Email Provider**
- Gmail sometimes blocks, try Outlook
- Use email you haven't tested with before

### 3rd Try: **Check Supabase Quotas**
- Free tier: 30 emails/hour
- May need to wait or upgrade temporarily

### 4th Try: **Network Switch**
- Try mobile data instead of WiFi
- Corporate networks sometimes block

## 🚀 Quick Beta Testing Workaround

### For Immediate Beta Testing:
1. **Create test accounts** in Supabase dashboard
2. **Email credentials** to beta testers:
   ```
   Email: betauser1@example.com
   Password: BetaTest123!
   ```
3. **Add password sign-in option** temporarily
4. **Fix OTP delivery** for production launch

### Temporary Sign-In Code:
```dart
// Add this button for beta testing
ElevatedButton(
  onPressed: () async {
    await _supabase.auth.signInWithPassword(
      email: 'betauser1@example.com',
      password: 'BetaTest123!',
    );
  },
  child: Text('Beta Test Sign In'),
)
```

## 📞 When to Contact Support

### Contact Supabase Support if:
- Email quota shows under limit
- SMTP settings look correct  
- Multiple email providers don't work
- Supabase logs show delivery errors

### Include This Info:
- Project ID
- Email addresses tested
- Error messages from logs
- Timeline of when issue started

## ✅ Expected Resolution

### Most Common Fix:
- **Check spam folder** (80% success rate)
- **Wait 5-10 minutes** for email delivery
- **Try different email provider**

### Timeline:
- **Immediate**: Check spam, try different email
- **1 hour**: Rate limits reset if that's the issue
- **24 hours**: Supabase support typically responds

**Let me know which email provider you're testing with and I can help narrow down the specific issue! 📧**