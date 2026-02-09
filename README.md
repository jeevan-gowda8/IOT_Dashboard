# 🌱 Campus Monitor – IoT Dashboard

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Thingsay API](https://img.shields.io/badge/Thingsay_API-00C853?style=for-the-badge&logo=api&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)

A modern, cross-platform **IoT monitoring and control dashboard** built with Flutter. Manage your **Greenhouse**, **Home Automation**, and **Street Lighting** systems in one place using the Thingsay API.

https://github.com/user-attachments/assets/8b9e4d5a-3f1c-4f8a-9c0a-1e3b5e8f7d2a

> **Note**: Replace the screenshot above with actual images from your app!

---

## ✨ Features

- **Real-time Monitoring**  
  View live sensor data: temperature, humidity, CO₂, soil conditions, water levels & more.
  
- **Remote Control**  
  Toggle devices instantly:
  - 🌿 **Greenhouse**: Fogger, Drip Irrigation, Exhaust Fan
  - 🏠 **Home**: Lights, Fans
  - 💡 **Street Lights**: On/Off control

- **Adaptive UI**  
  - Light & Dark mode support
  - Responsive design for phones & tablets
  - Smooth animations & haptic feedback

- **Reliable & Optimistic**  
  - Optimistic UI updates (instant response)
  - Automatic retries on failure
  - 5-second auto-refresh

- **Clean Architecture**  
  - Modular screens
  - Shared API service
  - Theme-consistent design

---


## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (v3.19+)
- **Language**: Dart
- **State Management**: StatefulWidget + Optimistic Updates
- **Networking**: `http` package + custom `ApiService`
- **UI**: Material 3, Google Fonts (Poppins)
- **API**: [Thingsay](https://thingsay.com) (custom IoT platform)

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.19 or higher)
- A Thingsay API account with valid endpoints

### Installation
1. Clone the repo:
   ```bash
   git clone https://github.com/your-username/iot_dashboard.git
   cd iot_dashboard

