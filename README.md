# 💸 Expense Tracker (Flutter + Firebase)

🚀 **Live APK:** https://tinyurl.com/dzpjxvfd
👉 Download and try the application directly on your Android device.

---

## 📱 Overview

A production-style **Expense Tracker** app built using **Flutter**, **Provider**, **Firebase Authentication**, and **Cloud Firestore**.

Designed with a focus on:

* Clean architecture (beginner-friendly)
* Real-world fintech features
* Scalable and secure data handling

---

## 🔐 Authentication (Firebase Auth)

* Email & Password **Sign up**
* Email & Password **Login**
* **Persistent session** (auto-login)
* Secure **Logout**

---

## 💰 Transactions (Firestore - User Private)

* Add **Income / Expense** transactions
* Fields:

  * title
  * amount
  * type (income / expense)
  * category
  * date
* Edit / Delete transactions
* User-specific data storage:

  ```
  users/{uid}/transactions
  ```

---

## 📊 Analytics (Fintech-Level)

* Balance summary:

  * Total Balance
  * Total Income
  * Total Expenses

* Charts:

  * Weekly expense (bar chart)
  * Category spending (pie chart with Weekly/Monthly toggle)
  * Monthly expense trends (last 6 months)

* Smart Insights:

  * Spending change vs last week
  * Highest spending category
  * Savings change vs last month

---

## 🎯 Budgeting System

* Set **monthly budget** per user

* Real-time tracking:

  * Progress bar
  * Remaining balance

* Alerts:

  * ⚠ 80% usage warning
  * 🚨 100% budget exceeded

* Stored at:

  ```
  users/{uid}/profile/budget
  ```

---

## 🎨 User Experience

* Filters:

  * Date range
  * Category
  * Transaction type

* Light / Dark mode toggle (saved locally)

* Smooth UI with loading & empty states

---

## 🛠 Tech Stack

* **Flutter** (latest stable)
* **Provider** (state management)
* **Firebase Authentication**
* **Cloud Firestore**
* **fl_chart** (data visualization)

---

## 📂 Project Structure

```
lib/
  models/
    insight_result.dart
    transaction_model.dart
  providers/
    auth_provider.dart
    budget_provider.dart
    theme_provider.dart
    transaction_provider.dart
  screens/
    add_transaction_screen.dart
    budget_screen.dart
    home_screen.dart
    login_screen.dart
    signup_screen.dart
  services/
    auth_service.dart
    budget_service.dart
    firestore_service.dart
    insights_service.dart
  theme/
    app_theme.dart
  widgets/
    chart_section.dart
    empty_state.dart
    summary_card.dart
    transaction_card.dart
```

---

## 🔐 Firestore Data Model

```
users/
  {userId}/
    transactions/
      {transactionId}:
        title: string
        amount: number
        type: "income" | "expense"
        category: string
        date: timestamp
    profile/
      budget:
        budget: number
```

---

## 🛡 Firestore Security Rules (Production-Ready)

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /users/{userId}/transactions/{docId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    match /users/{userId}/profile/{docId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## ⚙️ Firebase Setup

### 1. Create Firebase Project

* Enable:

  * Authentication (Email/Password)
  * Firestore Database

### 2. Configure Flutter

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

---

## ▶️ Run Locally

```bash
flutter pub get
flutter run
```

---

## 📦 Build APK

```bash
flutter clean
flutter pub get
flutter build apk --release
```

---

## 🌟 Recruiter Highlights

* 🔐 Secure **user-specific data isolation** using Firestore rules
* 🧠 **Smart financial insights** using data analysis
* 📊 Advanced **analytics dashboard (charts + trends)**
* 💸 Real-time **budget tracking with alerts**
* 🧩 Clean architecture using **Provider (scalable design)**

---

## 📌 Final Note

This project demonstrates the ability to build a **real-world fintech application** with authentication, analytics, and scalable backend integration using Firebase.
