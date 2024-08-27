import CoreBluetooth
import Foundation


let serviceUUID = CBUUID(string: "12345678-1234-5678-1234-56789abcdef0")
let characteristicUUID = CBUUID(string: "abcdef12-3456-7890-abcd-ef1234567890")

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var isBluetoothEnabled = false
    @Published var xAxisAngle: String = "N/A"
    @Published var yAxisAngle: String = "N/A"
    @Published var crashDetected: String = "No"

    var centralManager: CBCentralManager!
    var esp32Peripheral: CBPeripheral?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            isBluetoothEnabled = true

            centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        } else {
            isBluetoothEnabled = false
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        esp32Peripheral = peripheral
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self

        peripheral.discoverServices([serviceUUID])
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {

            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        let dataString = String(decoding: data, as: UTF8.self)
        let dataComponents = dataString.split(separator: ",").map(String.init)
        
        for component in dataComponents {
            let parts = component.split(separator: ":").map(String.init)
            if parts.count == 2 {
                switch parts[0] {
                case "x":
                    self.xAxisAngle = "X Axis: \(parts[1])°"
                case "y":
                    self.yAxisAngle = "Y Axis: \(parts[1])°"
                case "crash":
                    self.crashDetected = parts[1] == "1" ? "Yes" : "No"
                default:
                    break
                }
            }
        }
    }
}
