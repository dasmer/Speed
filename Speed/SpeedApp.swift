import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color.gray.opacity(0.3)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 30) {
                    Spacer()

                    // Speed display
                    VStack(spacing: 10) {
                        Text(String(format: "%.0f", locationManager.speed))
                            .font(.system(size: min(geometry.size.width * 0.3, 120), weight: .heavy, design: .default))
                            .foregroundColor(Color(hex: "00D632"))
                            .shadow(color: Color(hex: "00D632").opacity(0.3), radius: 10, x: 0, y: 0)

                        Text(locationManager.speedUnit)
                            .font(.system(size: 24, weight: .bold, design: .default))
                            .foregroundColor(.white)
                            .opacity(0.8)
                    }

                    // Speed bar indicator
                    SpeedBar(speed: locationManager.speed, maxSpeed: locationManager.maxSpeed)
                        .frame(height: 20)
                        .padding(.horizontal, 40)

                    Spacer()

                    // Status info
                    VStack(spacing: 8) {
                        HStack {
                            Circle()
                                .fill(locationManager.isLocationAuthorized ? Color(hex: "00D632") : .red)
                                .frame(width: 12, height: 12)

                            Text(locationManager.statusMessage)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }

                        // Settings button when location is denied
                        if !locationManager.isLocationAuthorized && locationManager.showSettingsButton {
                            Button(action: {
                                locationManager.openAppSettings()
                            }) {
                                HStack {
                                    Image(systemName: "gear")
                                    Text("Open Settings")
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color(hex: "00D632"))
                                .cornerRadius(25)
                            }
                            .padding(.top, 10)
                        }
                    }

                    Spacer()
                }
                .padding()
            }
        }
        .onAppear {
            locationManager.requestLocationPermission()
        }
    }
}

struct SpeedBar: View {
    let speed: Double
    let maxSpeed: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background bar
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.2))

                // Speed indicator bar
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "00D632"),
                                speed > maxSpeed * 0.7 ? .orange : Color(hex: "00D632"),
                                speed > maxSpeed * 0.9 ? .red : Color(hex: "00D632")
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * min(speed / maxSpeed, 1.0))
                    .animation(.easeInOut(duration: 0.3), value: speed)
            }
        }
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()

    @Published var speed: Double = 0.0
    @Published var speedUnit: String = "MPH"
    @Published var isLocationAuthorized = false
    @Published var statusMessage = "Requesting location..."
    @Published var showSettingsButton = false

    var maxSpeed: Double {
        return isMetricSystem ? 200.0 : 120.0
    }

    private var isMetricSystem: Bool {
        // Check the iOS Measurement System setting directly
        let locale = Locale.current
        let measurementSystem = locale.measurementSystem

        // Returns true for metric, false for US/Imperial
        return measurementSystem == .metric
    }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 1.0 // Update every meter

        updateSpeedUnit()
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }

    private func updateSpeedUnit() {
        speedUnit = isMetricSystem ? "KPH" : "MPH"
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        let speedInMPS = max(location.speed, 0) // Speed in meters per second, don't show negative

        if isMetricSystem {
            // Convert to KPH
            speed = speedInMPS * 3.6
        } else {
            // Convert to MPH
            speed = speedInMPS * 2.237
        }

        statusMessage = speedInMPS > 0 ? "Tracking speed" : "Speed: 0"
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        statusMessage = "Location error"
        speed = 0.0
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            statusMessage = "Location permission pending"
            isLocationAuthorized = false
            showSettingsButton = false
        case .denied, .restricted:
            statusMessage = "Location access denied"
            isLocationAuthorized = false
            showSettingsButton = true
        case .authorizedWhenInUse, .authorizedAlways:
            statusMessage = "Getting location..."
            isLocationAuthorized = true
            showSettingsButton = false
            locationManager.startUpdatingLocation()
        @unknown default:
            statusMessage = "Unknown location status"
            isLocationAuthorized = false
            showSettingsButton = false
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

@main
struct SpeedometerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
