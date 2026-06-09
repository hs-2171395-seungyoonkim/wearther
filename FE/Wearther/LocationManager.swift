import CoreLocation
import Combine

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var latitude: Double?
    @Published var longitude: Double?
    @Published var displayName = "서울, 마포구"

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func request() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        DispatchQueue.main.async {
            self.latitude = location.coordinate.latitude
            self.longitude = location.coordinate.longitude
        }
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            if let placemark = placemarks?.first {
                let locality = placemark.locality ?? ""
                let subLocality = placemark.subLocality ?? ""
                DispatchQueue.main.async {
                    self?.displayName = subLocality.isEmpty ? locality : "\(locality), \(subLocality)"
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
