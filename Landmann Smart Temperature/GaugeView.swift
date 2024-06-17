import SwiftUI

struct ThermoGaugeStyle: GaugeStyle {
    private var purpleGradient = LinearGradient(gradient: Gradient(colors: [ Color(red: 207/255, green: 150/255, blue: 207/255), Color(red: 107/255, green: 116/255, blue: 179/255) ]), startPoint: .trailing, endPoint: .leading)
 
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
 
            Circle()
                .foregroundColor(Color(.systemGray6))
 
            Circle()
                .trim(from: 0, to: 0.75 * configuration.value)
                .stroke(purpleGradient, lineWidth: 20)
                .rotationEffect(.degrees(135))
 
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(Color.black, style: StrokeStyle(lineWidth: 10, lineCap: .butt, lineJoin: .round, dash: [1, 34], dashPhase: 0.0))
                .rotationEffect(.degrees(135))
 
            VStack {
                configuration.currentValueLabel
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundColor(.gray)
                Text("DegC")
                    .font(.system(.body, design: .rounded))
                    .bold()
                    .foregroundColor(.gray)
            }
 
        }
        .frame(width: 300, height: 300)
 
    }
 
}

struct GaugeView: View {
    var current: Float
   // @Binding var threshold: Float
    var color: Color
   // var title: String
    let gradient = Gradient(colors: [.green, .yellow, .orange, .red])
    
    @State var minValue: Float
    @State var maxValue: Float

    var body: some View {
        Gauge(value: current, in: minValue...maxValue ) {
            Image(systemName: "heart.fill")
                .foregroundColor(.red)
        } currentValueLabel: {
            Text("\(Int(current))")
                .foregroundColor(Color.green)
        } minimumValueLabel: {
            Text("\(Int(minValue))")
                .foregroundColor(Color.green)
        } maximumValueLabel: {
            Text("\(Int(maxValue))")
                .foregroundColor(Color.red)
        }
        .gaugeStyle(ThermoGaugeStyle())
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

#Preview {
    GaugeView(
        current: 65.0,
        color: .red, minValue: -10, maxValue: 120
        )
}

