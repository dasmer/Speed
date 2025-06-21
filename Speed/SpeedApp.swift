import SwiftUI
import CoreLocation
import MapKit

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Map as background with dark appearance
                Map(position: .constant(.region(locationManager.region))) {
                    UserAnnotation()
                }
                .mapStyle(.standard(elevation: .realistic, emphasis: .muted))
                .mapControls {
                    // Empty to hide all controls
                }
                .preferredColorScheme(.dark)
                .ignoresSafeArea()

                // Semi-transparent overlay for better text visibility
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .black.opacity(0.6), location: 0),
                        .init(color: .black.opacity(0.2), location: 0.3),
                        .init(color: .black.opacity(0.2), location: 0.7),
                        .init(color: .black.opacity(0.6), location: 1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 30) {
                    // Speed display at top
                    VStack(spacing: 10) {
                        Text(String(format: "%.0f", locationManager.speed))
                            .font(.system(size: min(geometry.size.width * 0.25, 100), weight: .heavy, design: .default))
                            .foregroundColor(Color(red: 0, green: 0.839, blue: 0.196))
                            .shadow(color: .black, radius: 3, x: 0, y: 2)
                            .shadow(color: Color(red: 0, green: 0.839, blue: 0.196).opacity(0.5), radius: 10, x: 0, y: 0)

                        Text(locationManager.speedUnit)
                            .font(.system(size: 20, weight: .bold, design: .default))
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 2, x: 0, y: 1)
                            .opacity(0.9)

                        // Speed bar indicator
                        SpeedBar(speed: locationManager.speed, maxSpeed: locationManager.maxSpeed)
                            .frame(height: 16)
                            .frame(maxWidth: 250)
                    }
                    .padding(.top, 50)

                    Spacer()

                    // Status info at bottom
                    VStack(spacing: 8) {
                        HStack {
                            Circle()
                                .fill(locationManager.isLocationAuthorized ? Color(red: 0, green: 0.839, blue: 0.196) : .red)
                                .frame(width: 10, height: 10)

                            Text(locationManager.statusMessage)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 2, x: 0, y: 1)
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
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(red: 0, green: 0.839, blue: 0.196))
                                .cornerRadius(20)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.bottom, 30)
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
                    .fill(Color.white.opacity(0.3))
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)

                // Speed indicator bar
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0, green: 0.839, blue: 0.196),
                                speed > maxSpeed * 0.7 ? .orange : Color(red: 0, green: 0.839, blue: 0.196),
                                speed > maxSpeed * 0.9 ? .red : Color(red: 0, green: 0.839, blue: 0.196)
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
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default: SF
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

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

        // Update map region to center on user location
        DispatchQueue.main.async {
            self.region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
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

@main
struct SpeedometerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark) // Force dark mode for entire app
        }
    }
}
