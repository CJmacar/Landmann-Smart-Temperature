import SwiftUI
import CoreBluetooth

struct GaugeView: View {
    @Binding var value: Float
    var maxValue: Float
    @Binding var threshold: Float
    let color: Color
    
    @State private var isAboveThreshold = false
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2
            let thresholdAngle = Double(threshold / maxValue) * 360 - 90
            let thresholdPoint = CGPoint(x: center.x + radius * cos(thresholdAngle * .pi / 180),
                                         y: center.y + radius * sin(thresholdAngle * .pi / 180))
            
            ZStack {
                Circle()
                    .stroke(Color.gray, lineWidth: 10)
                Circle()
                    .trim(from: 0, to: CGFloat(value / maxValue))
                    .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.none) // No animation for gauge
                Circle()
                    .stroke(Color.black, lineWidth: 2)
                    .frame(width: 10, height: 10)
                    .foregroundColor(Color.yellow)
                    .position(thresholdPoint)
                Text(String(format: "%.1f°C", value))
                    .foregroundColor(.black)
                    .font(.body)
                    .offset(x: 0, y: 10)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                self.isAboveThreshold = value > threshold
            }
            if isAboveThreshold {
                Text("Temperature is above threshold")
                    .foregroundColor(.red)
                    .font(.headline)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(20)
                    .transition(.move(edge: .bottom))
            }
        }
    }
}



class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    let centralManager = CBCentralManager()
    var peripheral: CBPeripheral?
    
    let deviceUUIDString = "CD44507B-063E-506B-2FFE-215D8F2D3554"
    let temperatureServiceUUID = CBUUID(string: "1000")
    let temperatureCharacteristicUUID = CBUUID(string: "1002")
    
    @Published var temperatureP1: Float = 0
    @Published var temperatureP2: Float = 0
    @Published var thresholdP1: Float = 0
    @Published var thresholdP2: Float = 0
    
    override init() {
        super.init()
        centralManager.delegate = self
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: [temperatureServiceUUID], options: nil)
        } else {
            print("Bluetooth not available.")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let deviceUUID = UUID(uuidString: deviceUUIDString),
           peripheral.identifier == deviceUUID {
            self.peripheral = peripheral
            peripheral.delegate = self
            centralManager.stopScan()
            centralManager.connect(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([temperatureServiceUUID])
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            if service.uuid == temperatureServiceUUID {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid == temperatureCharacteristicUUID {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == temperatureCharacteristicUUID {
            if let temperatureData = characteristic.value {
                // Assuming temperature data is represented as a single float value
                let temperature: Float = temperatureData.withUnsafeBytes { $0.load(as: Float.self) }
                // Assuming temperature data is for P1 and P2 sensors
                if characteristic.value?.count ?? 0 >= 17 {
                    temperatureP1 = Float(temperatureData[3]*10 + temperatureData[4] >> 4)
                    temperatureP2 = Float(temperatureData[5]*10 + temperatureData[6] >> 4)
                }
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothManager()
    
    var body: some View {
        VStack {
            GaugeView(value: $bluetoothManager.temperatureP1, maxValue: 100, threshold: $bluetoothManager.thresholdP1, color: .blue)
                .padding()
            HStack {
                Text("Temperature P1:")
                Slider(value: $bluetoothManager.thresholdP1, in: 0...100)
                    .padding(.horizontal)
                    .accentColor(.blue) // Optional: Set the slider color to match the gauge
                Text("\(bluetoothManager.thresholdP1, specifier: "%.1f")°C")
            }
            GaugeView(value: $bluetoothManager.temperatureP2, maxValue: 100, threshold: $bluetoothManager.thresholdP2, color: .red)
                .padding()
            HStack {
                Text("Temperature P2:")
                Slider(value: $bluetoothManager.thresholdP2, in: 0...100)
                    .padding(.horizontal)
                    .accentColor(.red) // Optional: Set the slider color to match the gauge
                Text("\(bluetoothManager.thresholdP2, specifier: "%.1f")°C")
            }
        }
        .padding()
    }
}
