# bionic_soul_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.



# 🦾 Bionic Soul - AI-Driven Tele-Rehabilitation

An intelligent mobile tele-monitoring application designed to support patients equipped with bionic prosthetics. This project replaces traditional clinical paper forms with a conversational agent powered by Generative AI.

Developed by **Saif Allah Aouini**.

## ✨ Key Features

### 📱 Patient Workspace
* **Empathetic Chatbot:** Natural language interaction allowing patients to easily express pain levels and comfort.
* **Cognitive Analysis:** The AI seamlessly transforms the conversation into a structured clinical report (JSON format).
* **Fluid UI/UX:** Asynchronous state management ensures the screen never freezes during cloud processing.

### 🩺 Prosthetist (Doctor) Workspace
* **Real-Time Dashboard:** Instant synchronization of new medical reports using WebSockets.
* **Automated Triage:** AI-driven detection and visual highlighting of medical emergencies (critical pain levels).
* **NoSQL Optimization:** Denormalized database architecture ensuring ultra-fast read times and efficient querying.

## 🛠️ Tech Stack

* **Frontend:** Flutter & Dart
* **Backend:** Firebase (Authentication, Cloud Firestore)
* **Artificial Intelligence:** Google Gemini 2.5 Flash API
* **Architecture:** MVC, Serverless, Asynchronous Programming

## ⚙️ How to run this project locally

1. Clone this repository: `git clone https://github.com/your-username/bionic-soul.git`
2. Install dependencies: `flutter pub get`
3. **Important Configuration:** * This project uses Firebase. You must add your own `google-services.json` file inside the `android/app/` directory.
   * You must provide your own Google AI Studio API Key in the codebase where indicated (`"YOUR_GEMINI_API_KEY_HERE"`).
4. Run the app: `flutter run`