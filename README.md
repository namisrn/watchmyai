# ..::(SOON)::..


# WatchMyAI - Your AI Chatbot for Apple Watch ⌚️



WatchMyAI is a powerful chatbot designed exclusively for the Apple Watch. Powered by OpenAI's API, it provides quick and intelligent responses right on your wrist. Perfect for on-the-go use without needing your iPhone or iPad.

---

## Features 🎉
- **Quick and intuitive interactions**: Chat effortlessly via your Apple Watch.
- **AI-Powered**: Smart, dynamic responses powered by OpenAI technology.
- **Archive Functionality**: Save past conversations for future reference.
- **Minimalistic Design**: Optimized for WatchOS 10 with SwiftUI.

---

## Requirements 🚀
- An **Apple Watch** running **WatchOS 10** or later.
- Xcode 16 for development and customization.
- Swift 6 and SwiftUI 6 for the codebase.

---

## Project Structure 📂
The project follows a modular structure to simplify maintenance and extension:

WatchMyAI Watch App
├── 📂 App
│   └── AppState.swift
│   └── WatchAIApp.swift
├── 📂 Core
│   ├── 📂 Constants
│   │   └── Constants.swift
│   ├── 📂 ErrorHandling
│   │   └── ErrorHandler.swift
│   ├── 📂 Helpers
│   │   └── Logger.swift
│   └── 📂 Managers
│       └── APIKeyManager.swift
├── 📂 Data
│   ├── 📂 Models
│   │   ├── Chat.swift
│   │   ├── Conversations.swift
│   │   └── Message.swift
├── 📂 Views
│ ├── Menu.swift
│   ├── 📂 Chat
│   │   ├── NewChat.swift
│   │   ├── ConversationDetailView.swift
│   ├── 📂 Archive
│   │   ├── Archive.swift
│   └── 📂 Settings
│       ├── Setting.swift
├── 📂 Networking
│   └── OpenAIResponse.swift
│   └── OpenAIService.swift
├── 📂 Resources
│   ├── Secrets.plist
│   └── Assets.xcassets

---

## Installation 🛠
### 1. Clone the repository
```bash
git clone https://github.com/your-username/WatchMyAI.git
cd WatchMyAI

2. Add your API Key

Add your OpenAI API key to the Secrets.plist file:

<key>OpenAI_API_Key</key>
<string>YOUR_API_KEY</string>

3. Run the app on your Apple Watch
	•	Open the project in Xcode 16.
	•	Select your target device (Apple Watch).
	•	Press ⌘ + R to run the app.

License 📜

This project is licensed under the MIT License. Feel free to use, modify, and distribute it.

Contributing 🤝

Contributions are welcome! Open an issue or submit a pull request to share your ideas or improvements.

Contact 📧

For questions or support:
	•	Email: your.email@example.com
	•	GitHub: @your-username

Enjoy using WatchMyAI! 🚀
