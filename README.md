# Daleel — AI Travel Planner for Saudi Arabia

Daleel is a mobile app that generates personalized day-by-day travel itineraries for destinations across Saudi Arabia using AI.

---

## How It Works

1. User signs in and fills a short preferences form (city, dates, activities, budget)
2. The app sends the preferences to an n8n automation workflow
3. n8n calls OpenAI GPT-4o to generate a structured itinerary
4. The itinerary is written back to Firestore in real time
5. The app displays the full day-by-day plan instantly

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile App | Flutter (Dart) |
| Authentication | Firebase Auth |
| Database | Cloud Firestore |
| Automation | n8n Cloud |
| AI Model | OpenAI GPT-4o |

---

## Features

- Email and phone (OTP) authentication
- 5-step trip preferences wizard
- Real-time itinerary generation via AI
- Day-by-day itinerary view with activities, restaurants, costs, and tips
- Save trips for later viewing
- Saved trips dashboard

---

## Project Structure

```
lib/
├── models/          # Data models
├── screens/         # All app screens
│   └── steps/       # Trip wizard steps
├── services/        # Firebase auth + app config
└── widgets/         # Shared UI components
```

---

## Setup

1. Clone the repo
2. Add your `google-services.json` to `android/app/`
3. Add your n8n webhook URL to `lib/services/app_config.dart`
4. Run `flutter pub get`
5. Run `flutter run`
