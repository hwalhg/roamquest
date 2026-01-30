# RoamQuest - Skills & Context

## Project Overview

**RoamQuest** is a city exploration app that generates personalized "must-do" checklists for travelers. Users can discover curated experiences, capture memories through photo check-ins, and share beautiful reports of their urban adventures.

## Tech Stack

- **Frontend**: Flutter 3.x (Dart)
- **Backend**: Supabase (PostgreSQL + Storage + Auth)
- **AI**: Claude API (generate city checklists)
- **Maps**: Mapbox GL
- **Payments**: Apple In-App Purchase (subscription)
- **State**: Provider
- **i18n**: flutter_localizations

## Core Features

1. **Auto Location Detection** - Uses geolocation to identify user's city
2. **AI-Generated Checklists** - 20 curated items per city (landmarks, food, experiences, hidden gems)
3. **Photo Check-ins** - Capture and store memories for each checklist item
4. **Visual Reports** - Beautiful map-based reports with photo collages
5. **Subscription Model** - Free tier (5 check-ins) + Premium (unlimited)
6. **Multi-language** - English and Chinese support

## Business Model

- **Free**: 5 photo check-ins per checklist
- **Premium**: Unlimited check-ins + full reports
- **Pricing**: $4.99/month or $29.99/year

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
│   └── services/                # External services (AI, storage, etc.)
└── features/                    # Feature modules
    ├── home/                    # Home screen
    ├── checklist/               # Checklist display
    ├── checkin/                 # Photo check-in
    ├── report/                  # Report generation
    └── subscription/            # Subscription management
```

## Key Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  dio: ^5.4.0                    # HTTP client
  supabase_flutter: ^2.0.0       # Backend
  mapbox_gl: ^0.16.0             # Maps
  in_app_purchase: ^3.1.0        # Payments
  image_picker: ^1.0.0           # Camera/gallery
  geolocator: ^10.1.0            # Location
  geocoding: ^2.1.0              # Geocoding
  cached_network_image: ^3.3.0   # Image caching
  provider: ^6.1.0               # State management
  flutter_localizations:
    sdk: flutter                 # i18n
  intl: any                      # i18n
  shared_preferences: ^2.2.0     # Local storage
  package_info_plus: ^4.2.0      # Package info
  screenshot: ^2.1.0             # Screenshot
  flutter_dotenv: ^5.1.0         # Environment variables
```

## Environment Variables

```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
CLAUDE_API_KEY=your_claude_api_key
MAPBOX_ACCESS_TOKEN=your_mapbox_token
```

## Development Guidelines

### Code Style
- Use `camelCase` for variables and methods
- Use `PascalCase` for classes and types
- Use `snake_case` for files and directories
- Add documentation comments for public APIs

### Git Workflow
- `main` - Production branch
- `develop` - Development branch
- `feature/*` - Feature branches

### Commit Messages
- `feat:` - New feature
- `fix:` - Bug fix
- `refactor:` - Code refactoring
- `style:` - Code style changes
- `docs:` - Documentation
- `test:` - Tests
- `chore:` - Maintenance tasks

## API Integration

### Claude API
Generate city checklists with structured JSON output:

```dart
final response = await _dio.post(
  'https://api.anthropic.com/v1/messages',
  data: {
    'model': 'claude-3-5-sonnet-20241022',
    'max_tokens': 1024,
    'messages': [{
      'role': 'user',
      'content': prompt,
    }],
  },
);
```

### Supabase
- Tables: `checklists`, `checkins`, `subscriptions`
- Storage: `photos` bucket for user images
- Real-time subscriptions for live updates

## Current Development Status

- [x] Project structure created
- [ ] Core models implemented
- [ ] Services layer (AI, Location, Storage)
- [ ] Feature pages (Home, Checklist, Check-in, Report)
- [ ] Subscription integration
- [ ] i18n support
- [ ] Testing & deployment

## Next Steps

1. Implement core data models
2. Build AI service for checklist generation
3. Create location service
4. Build home page with city detection
5. Implement checklist display
6. Add photo check-in functionality
7. Design and build report generation
8. Integrate Apple IAP
9. Add multi-language support
10. Polish UI/UX
11. Testing
12. App Store submission

## Contact & Resources

- **GitHub**: [Project repository]
- **Documentation**: [Project wiki]
- **Design**: [Figma link]
