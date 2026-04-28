# RoamQuest

> Discover cities, one adventure at a time.

RoamQuest is a city exploration app that generates personalized "must-do" checklists for travelers. Users can discover curated experiences, capture memories through photo check-ins, and share beautiful reports of their urban adventures.

## Features

- 🌍 **Auto Location Detection** - Automatically detects your city to generate relevant checklists
- 🤖 **AI-Powered Checklists** - City-specific checklists across landmarks, food, experiences, and hidden gems
- 📸 **Photo Check-ins** - Capture and store memories for each checklist item
- 📊 **Visual Reports** - Beautiful map-based reports with photo collages
- 💰 **Subscription Model** - Free tier preview + Premium subscription for unlimited access
- 🌐 **Multi-language** - English and Chinese support

## Tech Stack

- **Frontend**: Flutter 3.x (Dart)
- **Backend**: Supabase (PostgreSQL + Storage + Auth)
- **AI**: DeepSeek API (generate city checklists)
- **Payments**: Apple In-App Purchase (subscription)
- **State**: Provider
- **i18n**: flutter_localizations

## Getting Started

### Prerequisites

- Flutter SDK 3.0+
- Xcode (for iOS development)
- Android Studio (for Android development)
- Supabase account
- DeepSeek API key

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/roam_quest.git
cd roam_quest
```

2. Install dependencies
```bash
flutter pub get
```

3. Configure environment variables
```bash
cp .env.example .env
# Edit .env with your API keys
```

4. Run the app
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── core/                        # Core utilities
│   ├── constants/               # App constants
│   ├── theme/                   # Theming
│   ├── config/                  # Configuration
│   └── utils/                   # Helper functions
├── data/                        # Data layer
│   ├── models/                  # Data models
│   ├── repositories/            # Data repositories
│   └── services/                # External services
└── features/                    # Feature modules
    ├── home/                    # Home screen
    ├── checklist/               # Checklist display
    ├── checkin/                 # Photo check-in
    ├── report/                  # Report generation
    └── subscription/            # Subscription management
```

## Environment Variables

Create a `.env` file in the project root:

```env
# Supabase Configuration
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key

# DeepSeek AI API
DEEPSEEK_API_KEY=your_deepseek_api_key
```

## App Store Subscription Verification

RoamQuest now verifies iOS subscriptions through a Supabase Edge Function instead of trusting local purchase duration.

### Database update

Run the migration before using the new verification flow:

```sql
\i database/migrations/20260426_add_subscription_verification_fields.sql
```

Or copy the SQL into the Supabase SQL editor.

### Edge Function

The verification function lives at:

```text
supabase/functions/verify-app-store-subscription/index.ts
```

Deploy it with the Supabase CLI in your backend workspace:

```bash
supabase functions deploy verify-app-store-subscription
```

### Required Supabase Function secrets

Set these as server-side function secrets, not in the Flutter `.env` file:

```bash
supabase secrets set APP_STORE_ISSUER_ID=your_issuer_id
supabase secrets set APP_STORE_KEY_ID=your_key_id
supabase secrets set APP_STORE_BUNDLE_ID=com.roamquest.roamQuest
supabase secrets set APP_STORE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
```

The function uses the App Store Server API production endpoint first, then falls back to the sandbox endpoint when Apple reports the transaction is not found in production.

## Database Setup

### Supabase Tables

Run these SQL commands in your Supabase SQL editor:

```sql
-- Checklists table
CREATE TABLE checklists (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  city_name VARCHAR(100) NOT NULL,
  country VARCHAR(100) NOT NULL,
  country_code VARCHAR(10) NOT NULL,
  latitude DECIMAL NOT NULL,
  longitude DECIMAL NOT NULL,
  language VARCHAR(10) NOT NULL,
  items JSONB NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Checkins table
CREATE TABLE checkins (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  checklist_id UUID REFERENCES checklists(id) ON DELETE CASCADE,
  item_id VARCHAR(100) NOT NULL,
  photo_url TEXT NOT NULL,
  latitude DECIMAL,
  longitude DECIMAL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Storage bucket for photos
INSERT INTO storage.buckets (id, name, public)
VALUES ('photos', 'photos', true);

-- Row Level Security
ALTER TABLE checklists ENABLE ROW LEVEL SECURITY;
ALTER TABLE checkins ENABLE ROW LEVEL SECURITY;
```

## Development

### Code Style

- Use `camelCase` for variables and methods
- Use `PascalCase` for classes and types
- Use `snake_case` for files and directories
- Add documentation comments for public APIs

### Running Tests

```bash
flutter test
```

### Building for Production

**iOS:**
```bash
flutter build ios --release
```

**Android:**
```bash
flutter build apk --release
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Built with [Flutter](https://flutter.dev)
- Backend powered by [Supabase](https://supabase.com)
- AI by [Anthropic](https://www.anthropic.com)
- Maps by [Mapbox](https://www.mapbox.com)
