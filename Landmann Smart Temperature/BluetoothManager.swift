import CoreBluetooth

struct ScannedDevice: Equatable, Hashable {
    let peripheral: CBPeripheral
    let advertisementData: [String: Any]
    let rssi: NSNumber

    static func ==(lhs: ScannedDevice, rhs: ScannedDevice) -> Bool {
        return lhs.peripheral.identifier == rhs.peripheral.identifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(peripheral.identifier)
    }
}

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager!
    private var selectedPeripheral: CBPeripheral?
    @Published var scannedDevices: [ScannedDevice] = []
    @Published var temperatureP1: Float = 0
    @Published var temperatureP2: Float = 0
    @Published var thresholdP1: Float = 65
    @Published var thresholdP2: Float = 65

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func scanForPeripherals() {
        scannedDevices.removeAll()
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            scanForPeripherals()
        } else {
            print("Bluetooth not available.")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let scannedDevice = ScannedDevice(peripheral: peripheral, advertisementData: advertisementData, rssi: RSSI)
        if !scannedDevices.contains(scannedDevice) {
            scannedDevices.append(scannedDevice)
        }
    }

    func connectToDevice(_ peripheral: CBPeripheral) {
        selectedPeripheral = peripheral
        selectedPeripheral?.delegate = self
        centralManager.connect(selectedPeripheral!)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([CBUUID(string: "1000")])
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                if service.uuid == CBUUID(string: "1000") {
                    peripheral.discoverCharacteristics([CBUUID(string: "1002")], for: service)
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == CBUUID(string: "1002") {
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == CBUUID(string: "1002"), let temperatureData = characteristic.value, temperatureData.count >= 6 {
            
            let temperatureP1Celsius = Float(Int16(temperatureData[3]) * 10 + (Int16(temperatureData[4]) >> 4))
            let temperatureP2Celsius = Float(Int16(temperatureData[5]) * 10 + (Int16(temperatureData[6]) >> 4))
        
            DispatchQueue.main.async {
                if peripheral == self.selectedPeripheral {
                    self.temperatureP1 = (temperatureP1Celsius == 1440.0 ? 0.0 : temperatureP1Celsius)
                    self.temperatureP2 = (temperatureP2Celsius == 1440.0 ? 0.0 : temperatureP2Celsius)
                }
            }
        }
    }

    func updateThreshold() {
        // Implement threshold update logic here
    }
}

