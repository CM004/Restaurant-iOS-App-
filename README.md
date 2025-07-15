# 🍽️ Restaurant iOS App

Welcome to the **Restaurant iOS App**! This is a modern, multilingual food ordering app built with SwiftUI. Browse cuisines, add dishes to your cart, and place orders—all with a beautiful, intuitive interface.

---

## 👋 About This Project

The Restaurant iOS App is designed to deliver a seamless, delightful food ordering experience. Users can:
- 🍛 **Browse Cuisines & Dishes** – Effortlessly browse a variety of cuisines and and their top-rated dishes
- 🛒 **Smart Cart** – Add items to a smart cart with real-time price and tax calculations.Add, remove, and update dish quantities. Taxes (CGST/SGST) are calculated automatically.
- 📦 **Order History** - Place orders and view their recent order history
- 🌐 **Multilingual** - Instantly switch between English 🇬🇧 and Hindi 🇮🇳
- ☁️ **API Powered** – Fetches menu and processes orders via a secure backend.

**My Role:**
> I was responsible for the entire app: architecture, UI/UX, API integration, localization, and animations. My focus was on building a robust, maintainable codebase with a clean architecture, smooth navigation, and delightful user interactions.

---

## ✨ Features I Loved Building

- 🏗️ **Clean Architecture:**
  - MVVM pattern for clear separation of concerns
  - Modular structure: Views, ViewModels, Models, Services, and Resources
- 🧭 **Smooth Navigation Flows:**
  - Intuitive transitions between Home, Cuisine Details, Cart, and Order History
  - Deep linking between cuisines and dishes
- 💫 **Delightful Animations:**
  - Animated cart updates and transitions
  - Springy button effects and smooth loading indicators
  - Subtle UI feedback for actions (adding/removing items, placing orders)
- 🌐 **Multilingual & Localized:**
  - Instant language switching with no app restart
  - All strings managed in a single JSON file for easy extension
- 🛡️ **Robust API Integration:**
  - Async/await networking with error handling and retry logic
  - Secure API key management
- 💾 **Persistence:**
  - Cart and order history saved locally for a consistent user experience

---

## 🗂️ Project Structure

```
Chandramohan/
├── Views/           # Screens & UI components
├── ViewModels/      # Business logic (MVVM)
├── Models/          # Data models (Cart, Cuisine, Order, etc.)
├── Services/        # API integration
├── Resources/       # Localization files
└── ChandramohanApp.swift  # App entry point
```

---

## 🚀 Getting Started

1. **Clone the repo:**
   ```sh
   git clone <your-repo-url>
   cd Restaurant-iOS-App-
   ```
2. **Open in Xcode:**
   - Open `Chandramohan.xcodeproj`.
3. **Run the app:**
   - Choose a simulator or device and hit ▶️ Run.

---

## 🛠️ Usage Guide

- **Home:** Browse cuisines and top dishes. Tap a cuisine for details.
- **Cart:** Add/remove dishes, adjust quantities, and checkout.
- **Order History:** View your last 3 orders.
- **Language:** Tap the 🌐 button to switch between English and Hindi.

---

## 🌏 Localization

- All app text is managed in `Resources/Localizations.json`.
- Supported: English (`en`), Hindi (`hi`).
- Add more languages by extending the JSON and updating the `Language` enum.

---

## 🏗️ Architecture & Implementation Details

- **MVVM:** Clean separation of UI, logic, and data for testability and scalability.
- **Navigation:** Uses SwiftUI's `NavigationView` and `NavigationLink` for smooth, context-aware transitions.
- **Animations:**
  - Cart and button actions use `withAnimation` and spring effects
  - Loading states use animated `ProgressView`
- **APIService:** Handles all network requests, error handling, and retries with async/await.
- **Persistence:** Cart & orders saved with `UserDefaults` for a seamless user experience.
- **Localization:** Language switching is instant and app-wide, powered by a singleton manager and JSON resource.

---

## 📁 Key Files

- `ChandramohanApp.swift` – App entry, theme, root view
- `HomeView.swift` – Main screen
- `CartView.swift` – Cart & checkout
- `APIService.swift` – API calls
- `LocalizationManager.swift` – Language switching

---

## 💡 Customization

- Add cuisines/dishes via backend or mock API.
- Change theme in `ColorTheme.swift`.
- Extend order logic in `OrderManager.swift`.

---

## 📜 License

MIT License. See [LICENSE](LICENSE) for details.

---

> Made with ❤️ for foodies and developers! 
