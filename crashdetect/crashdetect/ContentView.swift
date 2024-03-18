import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject var bleManager = BLEManager()

    var body: some View {
        ZStack(alignment: .bottom) {
            MapView()
                .edgesIgnoringSafeArea(.all) // Make map full-screen
            
            // Overlay for BLE data
            if bleManager.isBluetoothEnabled {
                VStack(spacing: 4) {
                    Text(bleManager.xAxisAngle).bold()
                    Text(bleManager.yAxisAngle).bold()
                    Text("Crash Detected: \(bleManager.crashDetected)").bold()
                }
                .padding()
                .background(Color.black.opacity(0.5))
                .cornerRadius(12)
                .foregroundColor(.white)
                .padding()
            } else {
                Text("Bluetooth is not enabled. Please enable Bluetooth in the settings.")
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(12)
                    .foregroundColor(.white)
                    .padding()
            }
        }
    }
}

struct MapView: UIViewRepresentable {
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
