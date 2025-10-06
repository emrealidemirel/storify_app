
# 📖 Storify - AI-Powered Interactive Storytelling App

**Storify** is an innovative Flutter mobile application that lets users create and progress stories using artificial intelligence.  
The app begins with a theme selection, and the storyline evolves based on the user's choices, delivering a unique interactive experience every time.

---

## 🚀 Features

- 🧠 AI-powered interactive storytelling (via ChatGPT API)
- 🎭 Theme-based story initiation
- 🌙 Light/Dark theme support
- 🌍 Multi-language support with `easy_localization`
- 🔐 Firebase Authentication (Email, Google, Guest)
- 🖼️ Profile photo upload (camera or gallery)
- 💾 Cloud data sync with Firebase
- 📱 Fully responsive with `responsive_sizer`

---

## 🛠️ Tech Stack

- **Framework:** Flutter (Dart)
- **State Management:** Bloc / Cubit
- **Backend:** Firebase Auth & Storage
- **Localization:** easy_localization
- **Responsive Layout:** responsive_sizer
- **AI Integration:** ChatGPT API (OpenAI)

---

## 📦 Environment Setup

This project uses an `.env` file to store private environment variables, such as API tokens.
The `.env` file is ignored by Git for security reasons and should never be shared publicly.

### ⚙️ Setup `.env`

1. Copy the example environment file:
   ```bash
   cp .env.example .env      # macOS / Linux
   copy .env.example .env    # Windows PowerShell
   ```

2. Open the `.env` file and insert your OpenAI token:
   ```env
   GPT_TOKEN=sk-xxxx
   ```

⚠️ **Important:** Keep your `.env` file secret. Never commit it to the repository.

---

## 📬 Contact

Developed by **Emre Ali Demirel**  
📧 emrealidemirel@gmail.com  
💼 [LinkedIn](https://www.linkedin.com/in/emrealidemirel)  
💻 [GitHub](https://github.com/emrealidemirel)

---

⭐️ If you enjoy using this project, please give it a star on GitHub! Your support helps me grow as a developer.
