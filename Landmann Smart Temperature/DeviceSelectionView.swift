import SwiftUI

struct DeviceSelectionView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @Binding var isMenuOpen: Bool

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(bluetoothManager.scannedDevices, id: \.self) { device in
                        Button(action: {
                            bluetoothManager.connectToDevice(device.peripheral)
                            isMenuOpen = false
                        }) {
                            Text(device.peripheral.name ?? "Unknown Device")
                        }
                    }
                }
                .navigationBarTitle("Select Device", displayMode: .inline)
                .navigationBarItems(trailing: Button("Cancel") {
                    isMenuOpen = false
                })
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    isMenuOpen = false
                }
            }
        }
    }
}
