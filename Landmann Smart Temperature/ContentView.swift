import SwiftUI

struct ContentView: View {
    @ObservedObject private var bluetoothManager = BluetoothManager()
    @State private var isMenuOpen = false
    @State private var selectedDevice: ScannedDevice?
    @State private var thresholdP1: Float = 65
    @State private var thresholdP2: Float = 65
    
    struct ContentView: View {
        var body: some View {
            VStack {
                Text(
                    "Some really long text. Some really long text. Some really long text."
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                Image("backgroundimage")
                .resizable()
                .aspectRatio(contentMode: .fill)
                    .edgesIgnoringSafeArea(
                        .all
                    )
            )
        }
    }
    
    
    var body: some View {
                VStack {
                    HStack {
                        Button(action: {
                            bluetoothManager.scanForPeripherals()
                            isMenuOpen.toggle()
                        }) {
                            Image(systemName: "ellipsis.circle")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white)
                        }
                        .padding()
                    }
                    
                    GaugeView(current: bluetoothManager.temperatureP1, color: .blue, minValue: -10, maxValue: 120)
                        .frame(width: 200, height: 200)
                        .padding()
                    
                        HStack {
                            Slider(value: $thresholdP1, in: 0...100, step: 1)
                            Text("\(Int(thresholdP1))°")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(5)
                        }
                        .frame(height: 50)
                    
                  /*  GaugeView(value: $bluetoothManager.temperatureP2, maxValue: 100, threshold: $thresholdP2, color: .blue, title: "P2")
                        .frame(width: 200, height: 200)
                        .padding()
                    */
                        HStack {
                            Slider(value: $thresholdP2, in: 0...100, step: 1)
                            Text("\(Int(thresholdP2))°")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(5)
                        }
                        .frame(height: 50)
                    
                    Spacer()
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            bluetoothManager.scanForPeripherals()
                            isMenuOpen.toggle()
                        }) {
                            Image(systemName: "ellipsis.circle")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white)
                        }
                    }
                }
                .sheet(isPresented: $isMenuOpen) {
                    DeviceSelectionView(bluetoothManager: bluetoothManager, isMenuOpen: $isMenuOpen)
                }
#if os(macOS)
                .onChange(of: bluetoothManager.temperatureP1) { _ in bluetoothManager.updateThreshold() }
                .onChange(of: bluetoothManager.temperatureP2) { _ in bluetoothManager.updateThreshold() }
#else
                .onChange(of: bluetoothManager.temperatureP1) { bluetoothManager.updateThreshold() }
                .onChange(of: bluetoothManager.temperatureP2) { bluetoothManager.updateThreshold() }
#endif
                .background(
                Image("barbecue_background")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            )
            }
}
