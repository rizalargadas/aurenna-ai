# Aurenna.ai - AI Tarot Reading App 🔮

A mystical tarot reading app that combines ancient wisdom with modern AI to provide insightful, personalized readings.

## 🌟 Overview

Aurenna.ai delivers concise, empowering tarot insights with a warm, witty touch to guide self-discovery. Built with Flutter and powered by OpenAI GPT-4.

**Tagline:** _Your cards. My code. No judgment. No fluff._

## 🎨 Brand Identity

### Visual Style

-   **Dark Cosmic Theme** - Deep space-inspired with electric accents
-   **Mystical & Modern** - Sleek interface with ethereal gradients
-   **Premium Feel** - Rich colors with sophisticated shadows

### Color Palette

-   **Electric Violet (#6366F1)** - Primary mystical purple
-   **Crystal Blue (#3B82F6)** - Secondary celestial blue  
-   **Void Black (#0F0F23)** - Deep cosmic background
-   **Mystic Blue (#1E1B4B)** - Surface color for cards
-   **Silver Mist (#F1F5F9)** - Primary text color
-   **Amber Glow (#F59E0B)** - Warm accent for highlights
-   **Cosmic Purple (#8B5CF6)** - Gradient accent
-   **Ethereal Indigo (#312E81)** - Deep accent color

### Gradients

-   **Primary:** Electric Violet → Cosmic Purple
-   **Secondary:** Crystal Blue → Deep Blue
-   **Background:** Void Black → Mystic Blue

### Typography

-   **Display Font:** Cinzel - Elegant and magical for titles
-   **Headings & Body:** Outfit - Modern yet mystical, clean readability

## 🛠 Tech Stack

-   **Frontend:** Flutter (Dart)
-   **Backend:** Supabase (PostgreSQL)
-   **AI:** OpenAI GPT-4
-   **Authentication:** Supabase Auth
-   **Payments:** PayPal + Google Pay (Phase 2)

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── config/
│   ├── theme.dart           # Aurenna brand theme
│   ├── supabase.dart        # Supabase configuration
│   └── openai.dart          # OpenAI configuration
├── models/
│   ├── tarot_card.dart      # Tarot card model
│   ├── reading.dart         # Reading model
│   └── user_model.dart      # User model
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── reading/
│   │   ├── question_screen.dart
│   │   ├── card_drawing_screen.dart
│   │   └── reading_result_screen.dart
│   └── settings/
│       └── settings_screen.dart
├── services/
│   ├── auth_service.dart    # Authentication logic
│   └── tarot_service.dart   # Tarot & AI logic
├── data/
│   └── tarot_deck.dart      # All 78 tarot cards
└── widgets/
    └── custom_button.dart   # Reusable components
```

## 🚀 Setup Instructions

### Prerequisites

-   Flutter SDK (3.0+)
-   Supabase account
-   OpenAI API key
-   VS Code or Android Studio

### Installation

1. **Clone the repository**

    ```bash
    git clone [your-repo-url]
    cd aurenna_ai
    ```

2. **Install dependencies**

    ```bash
    flutter pub get
    ```

3. **Configure Supabase**

    - Create a new Supabase project
    - Run the database schema (see Database Setup below)
    - Update `lib/config/supabase.dart` with your credentials:

    ```dart
    static const String supabaseUrl = 'YOUR_SUPABASE_URL';
    static const String supabaseAnonKey = 'YOUR_ANON_KEY';
    ```

4. **Configure OpenAI**

    - Get your API key from OpenAI
    - Update `lib/config/openai.dart`:

    ```dart
    static const String apiKey = 'YOUR_OPENAI_API_KEY';
    ```

5. **Run the app**
    ```bash
    flutter run
    ```

## 💾 Database Setup

Run this SQL in your Supabase SQL editor:

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE IF NOT EXISTS public.users (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  free_questions_remaining INTEGER DEFAULT 3,
  subscription_status TEXT DEFAULT 'free',
  payment_provider TEXT,
  subscription_id TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Readings table
CREATE TABLE IF NOT EXISTS public.readings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  question TEXT NOT NULL,
  cards JSONB NOT NULL,
  ai_reading TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.readings ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own profile" ON public.users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can view own readings" ON public.readings
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own readings" ON public.readings
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Auto-create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, free_questions_remaining, subscription_status)
  VALUES (new.id, new.email, 3, 'free')
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

## 🎯 Core Features

### Phase 1: Foundation ✅

-   User authentication (email/password)
-   Basic navigation structure
-   Supabase integration
-   3 free questions for new users

### Phase 2: Core Tarot ✅

-   78 tarot cards with meanings
-   3-card spread (Past, Present, Future)
-   AI-powered readings (GPT-4)
-   Question input and validation
-   Animated card drawing
-   Reading history storage

### Phase 3: Polish (Coming Soon)

-   Card flip animations
-   Reading history view
-   Social sharing
-   Push notifications

### Phase 4: Monetization (Coming Soon)

-   PayPal integration
-   Google Pay integration
-   Unlimited questions for subscribers

## 🤖 AI Configuration

The app uses GPT-4 for readings with these characteristics:

-   **Direct & Clear** - No fluff, straight answers
-   **Premium Quality** - Feels like a $100 reading
-   **Personalized** - Relates specifically to user's question
-   **Warm & Witty** - Appropriate humor when it fits

## 🧪 Testing

For development testing, give yourself unlimited questions:

```sql
UPDATE public.users
SET subscription_status = 'paypal_active',
    free_questions_remaining = 999
WHERE email = 'your-test-email@gmail.com';
```

## 📱 Deployment

### Android

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```

## 🐛 Common Issues

1. **Email confirmation error**: Disable email confirmation in Supabase during development
2. **OpenAI timeout**: Increase timeout in `tarot_service.dart`
3. **Free questions not showing**: Check database trigger is created correctly

## 🎴 Tarot Data

All 78 cards are defined in `lib/data/tarot_deck.dart`:

-   22 Major Arcana (The Fool through The World)
-   14 Cups (Ace through King)
-   14 Wands (Ace through King)
-   14 Swords (Ace through King)
-   14 Pentacles (Ace through King)

Each card includes:

-   Upright meaning
-   Reversed meaning
-   Keywords
-   Description

## 🔮 Future Enhancements

-   [ ] Card images (Rider-Waite deck)
-   [ ] Multiple spread types (Celtic Cross, etc.)
-   [ ] Daily card feature
-   [ ] Offline mode
-   [ ] Multiple languages
-   [ ] Voice readings
-   [ ] AR card visualization

## 📄 License

[Your License]

## 👨‍💻 Developer Notes

Created with love and a bit of cosmic magic ✨

**Remember:** The cards offer guidance, but you always have the power to choose your own path.
