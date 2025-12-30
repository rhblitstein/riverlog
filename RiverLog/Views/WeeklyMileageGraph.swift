import SwiftUI

struct WeeklyMileageGraph: View {
    let activities: [RiverActivity]
    
    var weeklyData: [Double] {
        let calendar = Calendar.current
        let today = Date()
        
        var data: [Double] = []
        
        // Get last 12 weeks of data
        for weekOffset in (0..<12).reversed() {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today),
                  let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
                data.append(0)
                continue
            }
            
            let weekActivities = activities.filter { activity in
                guard let date = activity.date else { return false }
                return date >= weekStart && date < weekEnd
            }
            
            let totalMiles = weekActivities.reduce(0.0) { $0 + $1.mileage }
            data.append(totalMiles)
        }
        
        return data
    }
    
    var maxMiles: Double {
        let max = weeklyData.max() ?? 10
        return max > 0 ? max : 10
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Past 12 weeks")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                VStack(spacing: 4) {
                    GeometryReader { geometry in
                        ZStack(alignment: .bottomLeading) {
                            // Grid lines
                            VStack(spacing: 0) {
                                ForEach(0..<3) { _ in
                                    Divider()
                                    Spacer()
                                }
                                Divider()
                            }
                            
                            // Line graph
                            Path { path in
                                let width = geometry.size.width
                                let height = geometry.size.height
                                let stepX = width / CGFloat(weeklyData.count - 1)
                                
                                for (index, miles) in weeklyData.enumerated() {
                                    let x = CGFloat(index) * stepX
                                    let y = height - (CGFloat(miles) / CGFloat(maxMiles) * height)
                                    
                                    if index == 0 {
                                        path.move(to: CGPoint(x: x, y: y))
                                    } else {
                                        path.addLine(to: CGPoint(x: x, y: y))
                                    }
                                }
                            }
                            .stroke(Theme.primaryBlue, lineWidth: 2)
                            
                            // Data points
                            ForEach(weeklyData.indices, id: \.self) { index in
                                let width = geometry.size.width
                                let height = geometry.size.height
                                let stepX = width / CGFloat(weeklyData.count - 1)
                                let x = CGFloat(index) * stepX
                                let y = height - (CGFloat(weeklyData[index]) / CGFloat(maxMiles) * height)
                                
                                Circle()
                                    .fill(Theme.primaryBlue)
                                    .frame(width: 6, height: 6)
                                    .position(x: x, y: y)
                            }
                        }
                    }
                    .frame(height: 120)
                    
                    // X-axis labels
                    HStack {
                        Text("NOV")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("DEC")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("JAN")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Y-axis labels on the right
                VStack {
                    Text(String(format: "%.0f mi", maxMiles))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.0f mi", maxMiles / 2))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("0 mi")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(width: 40, height: 120)
            }
        }
    }
}
