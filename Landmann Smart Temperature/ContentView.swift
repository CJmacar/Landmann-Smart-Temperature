import SwiftUI

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

