# Daleel — Backend & Workflow Documentation

> **Project:** Daleel Travel Planning App
> **Date:** April 2026
> **Stack:** Flutter · Firebase · n8n · OpenAI GPT-4o

---

## Table of Contents

1. [System Architecture](#1-system-architecture)
2. [n8n Workflow](#2-n8n-workflow)
3. [Webhook Request — Flutter to n8n](#3-webhook-request--flutter-to-n8n)
4. [AI Agent](#4-ai-agent)
5. [Code Node — Response Parser](#5-code-node--response-parser)
6. [Firestore Write — n8n to Firebase](#6-firestore-write--n8n-to-firebase)
7. [Firestore Data Schema](#7-firestore-data-schema)
8. [Itinerary Output Schema](#8-itinerary-output-schema)
9. [Field Reference](#9-field-reference)
10. [Real-time Delivery](#10-real-time-delivery)

---

## 1. System Architecture

The backend follows an **event-driven, asynchronous** design. Firestore acts as the shared state between the Flutter app and the n8n automation engine — neither communicates directly with the AI; all AI logic is encapsulated inside n8n.

```
┌──────────────────────────────────────────────────────────┐
│                      Flutter App                         │
│                                                          │
│  ① Write trip document to Firestore  (status=pending)   │
│  ② POST to n8n webhook               (tripId + prefs)   │
│  ③ Open real-time stream             (trips/{tripId})    │
└──────────────┬───────────────────────────▲──────────────┘
               │ HTTP POST                 │ Firestore stream
               ▼                           │
┌──────────────────────────┐               │
│       n8n Cloud          │               │
│                          │               │
│  [Webhook]               │               │
│      ↓                   │               │
│  [AI Agent + GPT-4o]     │               │
│      ↓                   │               │
│  [Code: Parse JSON]      │               │
│      ↓                   │               │
│  [HTTP Request]          │               │
│      │                   │               │
└──────┼───────────────────┘               │
       │ PATCH                             │
       ▼                                   │
┌──────────────────────────────────────────┴──────────────┐
│                   Cloud Firestore                        │
│               trips/{tripId}                             │
│         status = 'completed'                             │
│         itinerary = { ...full JSON... }                  │
└─────────────────────────────────────────────────────────┘
```

> **Core Rule:** n8n is the **only writer** of the `itinerary` field. The Flutter app is strictly read-only on itinerary content. All generation logic is self-contained within n8n.

---

## 2. n8n Workflow

### Endpoint

```
POST https://REDACTED.n8n.cloud/webhook/generate-trip
```

### Node Pipeline

```
[Webhook] ──► [AI Agent] ──► [Code: Parse Response] ──► [HTTP Request: Firestore]
                  ▲
        [OpenAI GPT-4o Model]
```

### Node Descriptions

| # | Node | Type | Responsibility |
|:---:|---|---|---|
| 1 | **Webhook** | Trigger | Receives POST from Flutter; exposes `tripId` and `preferences` to downstream nodes |
| 2 | **AI Agent** | LangChain Agent | Constructs the prompt, calls GPT-4o, and returns the raw itinerary text |
| 3 | **OpenAI Chat Model** | Sub-node | GPT-4o model attached to the AI Agent as its reasoning engine |
| 4 | **Code (JavaScript)** | Transform | Sanitizes AI output, parses JSON, and builds the Firestore PATCH body |
| 5 | **HTTP Request** | Action | PATCHes the Firestore REST API to write the itinerary and set `status = 'completed'` |

---

## 3. Webhook Request — Flutter to n8n

Sent immediately after the trip document is created in Firestore. n8n responds with `200 OK` at once; generation continues asynchronously.

```json
{
  "tripId": "abc123xyz",
  "userId": "firebase_uid",
  "preferences": {
    "city": "Jeddah",
    "travelers": {
      "adults": 2,
      "children": 1
    },
    "dateRange": {
      "startDate": "2026-04-09",
      "endDate": "2026-04-12",
      "numberOfDays": 4
    },
    "activities": [
      "Cultural & Historical",
      "Shopping"
    ],
    "restaurants": [
      "Saudi Traditional",
      "International"
    ],
    "budget": {
      "tier": "mid-range",
      "range": "300-600",
      "currency": "SAR"
    }
  }
}
```

---

## 4. AI Agent

### Model
**OpenAI GPT-4o** — connected to the n8n AI Agent node as its language model.

### System Prompt
```
You are a Saudi Arabia travel planner.
Generate a detailed day-by-day itinerary in valid JSON only —
no explanation, no markdown, just raw JSON.
```

The user prompt injects all preference fields from the webhook: city, travel dates, number of days, traveler counts, selected activities, restaurant types, and budget tier with SAR range.

### Design Decision — Agent over Direct API Call

Using n8n's AI Agent node (rather than a plain HTTP call to OpenAI) provides a structured foundation for future tool use. Additional capabilities — such as real-time attraction search, Google Maps validation, or weather-aware scheduling — can be added as agent tools without redesigning the workflow.

---

## 5. Code Node — Response Parser

Runs immediately after the AI Agent. Handles three responsibilities:

1. **Sanitize** — strips markdown code fences (` ```json `) that the model occasionally wraps around output
2. **Parse** — converts the cleaned string to a structured JSON object
3. **Build** — constructs the Firestore-compatible PATCH request body

```javascript
const raw = $input.first().json.output;

// Strip markdown fences if present
const cleaned = raw
  .replace(/```json\n?/g, '')
  .replace(/```\n?/g, '')
  .trim();

const itinerary = JSON.parse(cleaned);
const tripId = $('Webhook').first().json.body.tripId;

const firestoreBody = {
  fields: {
    status:    { stringValue:    "completed" },
    itinerary: { stringValue:    JSON.stringify(itinerary) },
    updatedAt: { timestampValue: new Date().toISOString() }
  }
};

return [{ json: { tripId, firestoreBody } }];
```

---

## 6. Firestore Write — n8n to Firebase

### Request

```
PATCH https://firestore.googleapis.com/v1/projects/daleel-497be/databases/(default)/documents/trips/{tripId}
```

### Authentication

Google Service Account API credential stored in n8n. Tokens are rotated automatically — no manual key management required.

### Request Body

```json
{
  "fields": {
    "status":    { "stringValue":    "completed" },
    "itinerary": { "stringValue":    "<serialized JSON string>" },
    "updatedAt": { "timestampValue": "2026-04-06T14:30:00Z" }
  }
}
```

> The `itinerary` field is stored as a serialized JSON **string** (not a Firestore map) to preserve the exact structure returned by the AI without Firestore type-mapping complications.

---

## 7. Firestore Data Schema

### Collection: `trips/{tripId}`

```json
{
  "tripId":       "auto-generated by Firestore",
  "userId":       "firebase_uid",
  "status":       "pending | generating | completed | failed",
  "saved":        false,
  "createdAt":    "Firestore Timestamp",
  "updatedAt":    "Firestore Timestamp",

  "preferences": {
    "city": "Jeddah",
    "travelers": {
      "adults":   2,
      "children": 1
    },
    "dateRange": {
      "startDate":    "2026-04-09",
      "endDate":      "2026-04-12",
      "numberOfDays": 4
    },
    "activities":  ["Cultural & Historical", "Shopping"],
    "restaurants": ["Saudi Traditional", "International"],
    "budget": {
      "tier":     "mid-range",
      "range":    "300-600",
      "currency": "SAR"
    }
  },

  "itinerary":     "<JSON string — written exclusively by n8n>",
  "errorMessage":  null
}
```

### `status` Lifecycle

| Status | Meaning |
|---|---|
| `pending` | Trip document created; waiting for n8n to begin processing |
| `generating` | n8n is actively querying the AI model |
| `completed` | Itinerary generated and written to Firestore successfully |
| `failed` | An error occurred; details available in `errorMessage` |

### `saved` Field

Set to `true` by the Flutter app when the user explicitly taps **Save Plan** on the Itinerary Screen. Only trips with `saved = true` appear on the Home Screen.

---

## 8. Itinerary Output Schema

Written by n8n into `trips/{tripId}.itinerary` upon successful generation.

```json
{
  "title":   "4-Day Cultural Family Trip in Jeddah",
  "summary": "A balanced mix of cultural heritage and family-friendly attractions.",

  "totalEstimatedCost": {
    "amount":   4500,
    "currency": "SAR",
    "note":     "Includes all activities and meals for the family"
  },

  "days": [
    {
      "dayNumber": 1,
      "date":      "2026-04-09",
      "theme":     "Cultural Immersion",

      "slots": [
        {
          "period":    "morning",
          "timeRange": "09:00 - 11:00",
          "type":      "activity",
          "name":      "King Fahd's Fountain",
          "description": "See the world's tallest fountain along the Corniche.",

          "location": {
            "name":       "King Fahd's Fountain",
            "area":       "Corniche, Jeddah",
            "mapsQuery":  "King Fahd Fountain Jeddah"
          },

          "estimatedCost": {
            "amount":    0,
            "currency":  "SAR",
            "perPerson": true,
            "note":      "Free entry"
          },

          "duration": "2 hours",
          "tips": [
            "Best viewed in the morning for photographs"
          ]
        },
        {
          "period":    "afternoon",
          "timeRange": "12:00 - 14:00",
          "type":      "restaurant",
          "name":      "Magal Restaurant",
          "description": "Traditional Saudi hospitality in a heritage setting.",

          "location": {
            "name":      "Magal Restaurant",
            "area":      "Al Hamra, Jeddah",
            "mapsQuery": "Magal Restaurant Jeddah"
          },

          "estimatedCost": {
            "amount":    200,
            "currency":  "SAR",
            "perPerson": false,
            "note":      "Average for the group"
          },

          "duration": "2 hours",
          "tips": [
            "Reservations recommended on weekends"
          ]
        }
      ]
    }
  ],

  "generatedAt": "2026-04-06T14:30:00Z",
  "modelUsed":   "gpt-4o",
  "version":     1
}
```

---

## 9. Field Reference

| Field | Type | Allowed Values | Notes |
|---|---|---|---|
| `status` | `string` | `pending` · `generating` · `completed` · `failed` | Streamed in real-time by Flutter |
| `saved` | `boolean` | `true` · `false` | Toggled by user action; controls Home Screen visibility |
| `budget.tier` | `string` | `economy` · `mid-range` · `comfort` · `luxury` | Normalized from UI label before transmission |
| `slot.period` | `string` | `morning` · `afternoon` · `evening` | Maximum 3 slots per day |
| `slot.type` | `string` | `activity` · `restaurant` · `transport` | Determines icon and accent color in the UI |
| `estimatedCost.perPerson` | `boolean` | `true` · `false` | When `true`, UI multiplies displayed cost by traveler count |
| `version` | `integer` | Starts at `1` | Incremented on each regeneration of the same trip |

---

## 10. Real-time Delivery

Once the trip is submitted, Flutter opens a **Firestore snapshot stream** on the trip document. No polling is used — the app reacts the instant n8n writes the result.

```dart
FirebaseFirestore.instance
  .collection('trips')
  .doc(tripId)
  .snapshots()
  .listen((snapshot) {
    final status = snapshot.data()?['status'];

    if (status == 'completed') {
      // Navigate to Itinerary Screen
    } else if (status == 'failed') {
      // Show error dialog with errorMessage
    }
  });
```

### Delivery Timeline

```
t=0s    User taps "Create My Plan"
t=0s    Firestore write (status = pending)
t=0s    n8n webhook called
t=1s    n8n begins building AI prompt
t=5-20s OpenAI returns itinerary
t=20s   n8n writes to Firestore (status = completed)
t=20s   Flutter stream fires → Itinerary Screen appears
```

> The entire flow from submission to displayed itinerary typically completes in **under 30 seconds**, with no user action required after the initial submission.
