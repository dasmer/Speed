# Speed

**Speed** is a SwiftUI-based iOS application that displays your real-time travel speed using Core Location. It features a clean, dark-themed interface with a prominent speed readout and a dynamic, color-coded bar that reflects your current velocity relative to a predefined maximum. The app adapts to your device's locale, presenting speed in either miles per hour (MPH) or kilometers per hour (KPH). If location permissions are denied, a clear status message appears along with a button that directs you to the app's settings to enable location access.

---

## 🚀 Features

- **Real-Time Speed Tracking**: Utilizes Core Location to provide frequent location updates and calculates instantaneous speed.
- **Locale-Aware Units**: Automatically detects your device's measurement system and displays speed in MPH or KPH accordingly.
- **Dynamic Speed Bar**: A horizontal bar visualizes your current speed as a percentage of a configurable maximum, changing color from green to orange to red as speed increases.
- **Dark-Themed Interface**: A vertical gradient from black to semi-transparent gray ensures high contrast for the speed readout and bar.
- **Location Authorization Handling**: Requests location access on launch and provides clear feedback and options if access is denied.

---

## 📱 Installation

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/yourusername/Speed.git
