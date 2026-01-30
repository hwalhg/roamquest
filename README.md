# RoamQuest

> Discover cities, one adventure at a time.

RoamQuest is a city exploration app that generates personalized "must-do" checklists for travelers. Users can discover curated experiences, capture memories through photo check-ins, and share beautiful reports of their urban adventures.

## Features

- 🌍 **Auto Location Detection** - Automatically detects your city to generate relevant checklists
- 🤖 **AI-Powered Checklists** - 20 curated items per city (landmarks, food, experiences, hidden gems)
- 📸 **Photo Check-ins** - Capture and store memories for each checklist item
- 📊 **Visual Reports** - Beautiful map-based reports with photo collages
- 💰 **Freemium Model** - Free tier (5 check-ins) + Premium (unlimited)
- 🌐 **Multi-language** - English and Chinese support

## Tech Stack

- **Frontend**: Flutter 3.x (Dart)
- **Backend**: Supabase (PostgreSQL + Storage + Auth)
- **AI**: Claude API (generate city checklists)
- **Maps**: Mapbox GL
- **Payments**: Apple In-App Purchase (subscription)
- **State**: Provider
- **i18n**: flutter_localizations

## Getting Started

### Prerequisites

- Flutter SDK 3.0+
- Xcode (for iOS development)
- Android Studio (for Android development)
- Supabase account
- Claude API key
- Mapbox access token

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

# Claude AI API
CLAUDE_API_KEY=your_claude_api_key

# Mapbox
MAPBOX_ACCESS_TOKEN=your_mapbox_access_token
```

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
