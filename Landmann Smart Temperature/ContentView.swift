import SwiftUI
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

struct ContentView: View {
    @ObservedObject private var bluetoothManager = BluetoothManager()
    @State private var isMenuOpen = false
    @State private var selectedDevice: ScannedDevice?
    @State private var thresholdP1: Float = 65
    @State private var thresholdP2: Float = 65

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    bluetoothManager.scanForPeripherals()
                    isMenuOpen.toggle()
                }) {
                    Image(systemName: "ellipsis.circle")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                .padding()
            }

            Spacer()

            GaugeView(value: $bluetoothManager.temperatureP1, maxValue: 100, threshold: $thresholdP1, color: .blue)
                .frame(width: 200, height: 200)
                .padding()
            HStack {
                Slider(value: $thresholdP1, in: 0...100, step: 1)
                Text("\(Int(thresholdP1))°")
                    .foregroundColor(.white)
                    .padding(5)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(5)
            }
            .padding(.horizontal)

            GaugeView(value: $bluetoothManager.temperatureP2, maxValue: 100, threshold: $thresholdP2, color: .green)
                .frame(width: 200, height: 200)
                .padding()
            HStack {
                Slider(value: $thresholdP2, in: 0...100, step: 1)
                Text("\(Int(thresholdP2))°")
                    .foregroundColor(.white)
                    .padding(5)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(5)
            }
            .padding(.horizontal)

            Spacer()
        }
        .popover(isPresented: $isMenuOpen, arrowEdge: .top) {
            VStack {
                List {
                    ForEach(bluetoothManager.scannedDevices, id: \.self) { device in
                        Button(action: {
                            selectedDevice = device
                            bluetoothManager.connectToDevice(device.peripheral)
                            isMenuOpen.toggle()
                        }) {
                            Text(device.peripheral.name ?? "Unknown Device")
                        }
                    }
                }
                .frame(width: 200)
            }
        }
        .onChange(of: bluetoothManager.temperatureP1) {
            bluetoothManager.updateThreshold()
        }
        .onChange(of: bluetoothManager.temperatureP2) {
        }
    }
}

struct GaugeView: View {
    @Binding var value: Float
    var maxValue: Float
    @Binding var threshold: Float
    var color: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .stroke(Color.gray, lineWidth: 10)
                Circle()
                    .trim(from: 0, to: CGFloat(min(value / maxValue, 1)))
                    .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: value)
                Text("\(Int(value))°")
                    .font(.title)
                    .foregroundColor(value >= threshold ? .red : .white)
                    .padding(5)
                    .background(value >= threshold ? Color.black.opacity(0.7) : Color.clear)
                    .cornerRadius(5)
                    .padding()
                ThresholdMark(threshold: threshold, maxValue: maxValue, radius: geometry.size.width / 2)
                    .foregroundColor(.yellow)
            }
        }
    }
}

struct ThresholdMark: View {
    var threshold: Float
    var maxValue: Float
    var radius: CGFloat

    var body: some View {
        let angle = Double(threshold / maxValue) * 360.0 - 90

        return Circle()
            .frame(width: 10, height: 10)
            .foregroundColor(.yellow)
            .offset(x: radius * CGFloat(cos(angle * .pi / 180)), y: radius * CGFloat(sin(angle * .pi / 180)))
    }
}
