#  Nyayara — Your Shield. Your Voice. Your Rights.

> *"Justice delayed is justice denied. But justice inaccessible is justice nonexistent."*

---

##  The Story: Why Nyayara Exists

Every single day, countless women face harassment—in workplaces, on the streets, or within their own homes. The fear is real, but the confusion is worse:
- *"Is what happened actually illegal?"*
- *"Who do I tell?"*
- *"Will anyone believe me?"*
- *"How do I write a formal complaint without a lawyer?"*

Most incidents go unreported not because of a lack of courage, but because of a **lack of clarity and support.**

**Nyayara** was built to bridge this gap. We believe legal knowledge shouldn't be a privilege; it should be a right. By combining compassionate AI with legally sound frameworks (like the POSH Act 2013 and BNS 2023), Nyayara empowers women to:
1.  **Understand** their situation instantly.
2.  **Report** it formally and professionally.
3.  **Secure** evidence safely.
4.  **Connect** with help immediately.

We are not just an app; we are your digital legal ally.

---

##  Key Features & The "Magic" Behind It

### 1.  AI Legal Consultant (The Brain)
- **What happens:** You chat with our AI just like a friend. "My boss made an inappropriate joke..."
- **The Magic:** Our finetuned LLM (Groq) analyzes your story against **Indian Laws (IPC/BNS, POSH Act)**.
- **The Result:** It tells you exactly what legal category this falls under (e.g., *Sexual Harassment under Section 354A*), how severe it is, and what to do next. **No legalese, just clear advice.**

### 2.  Instant FIR & Complaint Generator
- **What happens:** Writing a police complaint is scary.
- **The Magic:** Based on your chat, Nyayara **automatically generates** a professional, legally-structured FIR draft or Internal Committee (IC) complaint.
- **The Result:** A PDF/Text ready to be printed and submitted. You sound like you have a lawyer by your side.

### 3.  One-Click automated Reporting (The Action)
- **What happens:** You hit "File Complaint".
- **The Magic:** The app packages your evidence and generated complaint and **automatically emails the HR department** or relevant authority using a secure client-side email service (EmailJS).
- **Privacy:** You can choose to remain **Anonymous**. We strip your identity but keep the evidence valid.

### 4.  Secure Evidence Vault
- **What happens:** You have screenshots, audio, or photos.
- **The Magic:** Upload them to our **Encrypted Cloud Vault**. Even if you lose your phone, your evidence is safe.
- **Chain of Custody:** We timestamp every upload, making it stronger in court.

### 5.  Panic Mode (The Shield)
- **What happens:** You are in danger. You press the SOS button.
- **The Magic:**
    -   Your **Live Location** is captured.
    -   **SMS Alerts** are sent to your trusted contacts immediately.
    -   A **Phone Call** is initiated to your primary contact.
    -   Nearby Police/Hospitals are shown instantly.

---

<img width="1843" height="968" alt="image" src="https://github.com/user-attachments/assets/40f966c8-32a5-4910-a024-a46daf098c4c" />

<img width="1832" height="1030" alt="image" src="https://github.com/user-attachments/assets/81041ada-5842-4b79-8ec5-714b1b8e40c8" />

<img width="994" height="858" alt="image" src="https://github.com/user-attachments/assets/f2bf1bf2-408b-4519-8169-437c4b7e91d0" />



##  Tech Stack ("The Disclosed Stuff")

We used cutting-edge tech to make this fast, secure, and accessible:
-   **Frontend:** Flutter (Web & Mobile) — for a beautiful, smooth UI.
-   **AI Model:** Llama-3 70B via **Groq API** — for lightning-fast legal reasoning.
-   **Database:** Firebase Firestore — for real-time secure data sync.
-   **Authentication:** Firebase Auth — ensuring only *you* access your data.
-   **Email Service:** EmailJS — for serverless, automated email dispatch.
-   **State Management:** Provider Architecture — for a bug-free, robust app state.

---

##  How to Run This Project

### Prerequisites
-   [Flutter SDK](https://flutter.dev/docs/get-started/install) installed.
-   Chrome Browser (for Web) or Android Emulator (for App checking).

### Steps
1.  **Clone the Repo:**
    ```bash
    git clone https://github.com/KeerthisreeJ/Nyayara.git
    cd saheli_ai
    ```

2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run on Web (Development):**
    ```bash
    flutter run -d chrome
    ```

4.  **Build for Production (Live Website):**
    ```bash
    flutter build web --release
    firebase deploy
    ```



---
