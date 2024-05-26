import SwiftUI

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
