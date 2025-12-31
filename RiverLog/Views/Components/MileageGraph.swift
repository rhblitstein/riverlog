import SwiftUI

struct MileageGraph: View {
    let activities: [RiverActivity]
    let timePeriod: ProgressFilters.TimePeriod
    
    private struct DataPoint {
        let date: Date
        let miles: Double
    }
    
    private struct DataBucket {
        let startDate: Date
        let endDate: Date
        let miles: Double
    }
    
    // For 1M, plot individual activities
    private var dataPoints: [DataPoint] {
        guard timePeriod == .month else { return [] }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        
        return activities.compactMap { activity in
            guard let date = activity.date,
                  date >= startOfMonth && date < nextMonth else { return nil }
            return DataPoint(date: date, miles: activity.section?.mileage ?? 0)
        }.sorted(by: { $0.date < $1.date })
    }
    
    // For everything else, use bucketed data
    private var buckets: [DataBucket] {
        let calendar = Calendar.current
        let now = Date()
        var result: [DataBucket] = []
        
        switch timePeriod {
        case .week:
            // Last 7 days
            for dayOffset in 0..<7 {
                let dayStart = calendar.date(byAdding: .day, value: -(6 - dayOffset), to: calendar.startOfDay(for: now))!
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
                
                let dayActivities = activities.filter { activity in
                    guard let date = activity.date else { return false }
                    let activityDay = calendar.startOfDay(for: date)
                    return activityDay >= dayStart && activityDay < dayEnd
                }
                
                let miles = dayActivities.reduce(0.0) { $0 + ($1.section?.mileage ?? 0) }
                result.append(DataBucket(startDate: dayStart, endDate: dayEnd, miles: miles))
            }
            
        case .month:
            // Not used - dataPoints instead
            break
            
        case .threeMonths:
            // Last 3 calendar months, weekly buckets
            let startDate = calendar.date(byAdding: .month, value: -2, to: now)!
            let startOfPeriod = calendar.date(from: calendar.dateComponents([.year, .month], from: startDate))!
            let endOfPeriod = calendar.date(byAdding: .day, value: 1, to: now)!
            
            var weekStart = startOfPeriod
            while weekStart < endOfPeriod {
                let weekEnd = min(calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!, endOfPeriod)
                
                let weekActivities = activities.filter { activity in
                    guard let date = activity.date else { return false }
                    return date >= weekStart && date < weekEnd
                }
                
                let miles = weekActivities.reduce(0.0) { $0 + ($1.section?.mileage ?? 0) }
                result.append(DataBucket(startDate: weekStart, endDate: weekEnd, miles: miles))
                weekStart = weekEnd
            }
            
        case .sixMonths:
            // Last 6 calendar months, weekly buckets
            let startDate = calendar.date(byAdding: .month, value: -5, to: now)!
            let startOfPeriod = calendar.date(from: calendar.dateComponents([.year, .month], from: startDate))!
            let endOfPeriod = calendar.date(byAdding: .day, value: 1, to: now)!
            
            var weekStart = startOfPeriod
            while weekStart < endOfPeriod {
                let weekEnd = min(calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!, endOfPeriod)
                
                let weekActivities = activities.filter { activity in
                    guard let date = activity.date else { return false }
                    return date >= weekStart && date < weekEnd
                }
                
                let miles = weekActivities.reduce(0.0) { $0 + ($1.section?.mileage ?? 0) }
                result.append(DataBucket(startDate: weekStart, endDate: weekEnd, miles: miles))
                weekStart = weekEnd
            }
            
        case .year:
            // Last 12 months
            for monthOffset in 0..<12 {
                let monthStart = calendar.date(byAdding: .month, value: -(11 - monthOffset), to: now)!
                let monthStartNormalized = calendar.date(from: calendar.dateComponents([.year, .month], from: monthStart))!
                let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStartNormalized)!
                
                let monthActivities = activities.filter { activity in
                    guard let date = activity.date else { return false }
                    return date >= monthStartNormalized && date < monthEnd
                }
                
                let miles = monthActivities.reduce(0.0) { $0 + ($1.section?.mileage ?? 0) }
                result.append(DataBucket(startDate: monthStartNormalized, endDate: monthEnd, miles: miles))
            }
            
        case .lifetime:
            // All time - monthly buckets from first activity to now
            guard let earliest = activities.compactMap({ $0.date }).min() else { break }
            
            let earliestMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: earliest))!
            let currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let monthsCount = calendar.dateComponents([.month], from: earliestMonth, to: currentMonth).month! + 1
            
            for monthOffset in 0..<monthsCount {
                let monthStart = calendar.date(byAdding: .month, value: monthOffset, to: earliestMonth)!
                let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!
                
                let monthActivities = activities.filter { activity in
                    guard let date = activity.date else { return false }
                    return date >= monthStart && date < monthEnd
                }
                
                let miles = monthActivities.reduce(0.0) { $0 + ($1.section?.mileage ?? 0) }
                result.append(DataBucket(startDate: monthStart, endDate: monthEnd, miles: miles))
            }
        }
        
        return result
    }
    
    private var xAxisLabels: [String] {
        let calendar = Calendar.current
        let now = Date()
        let formatter = DateFormatter()
        
        switch timePeriod {
        case .week:
            formatter.dateFormat = "E"
            return buckets.map { String(formatter.string(from: $0.startDate).prefix(1)) }
            
        case .month:
            // DEC 8, DEC 15, DEC 22
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
            
            formatter.dateFormat = "MMM d"
            var labels: [String] = []
            var weekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: startOfMonth)!
            
            while weekStart < nextMonth {
                labels.append(formatter.string(from: weekStart).uppercased())
                weekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
            }
            return labels
            
        case .threeMonths:
            // OCT, NOV, DEC
            formatter.dateFormat = "MMM"
            var labels = Array(repeating: "", count: buckets.count)
            var lastMonth = -1
            
            for (i, bucket) in buckets.enumerated() {
                let month = calendar.component(.month, from: bucket.startDate)
                let day = calendar.component(.day, from: bucket.startDate)
                if day <= 7 && month != lastMonth {
                    labels[i] = formatter.string(from: bucket.startDate).uppercased()
                    lastMonth = month
                }
            }
            return labels
            
        case .sixMonths:
            // Show month labels, skip the last one
            formatter.dateFormat = "MMM"
            var labels = Array(repeating: "", count: buckets.count)
            var lastLabeledMonth = -1
            
            for (i, bucket) in buckets.enumerated() {
                let month = calendar.component(.month, from: bucket.startDate)
                let day = calendar.component(.day, from: bucket.startDate)
                
                // Label unique months, but skip the very last bucket
                if day <= 7 && month != lastLabeledMonth && i < buckets.count - 1 {
                    labels[i] = formatter.string(from: bucket.startDate).uppercased()
                    lastLabeledMonth = month
                }
            }
            
            return labels
            
        case .year:
            // FEB, APR, JUN, AUG, OCT, DEC
            formatter.dateFormat = "MMM"
            var labels = Array(repeating: "", count: buckets.count)
            for (i, bucket) in buckets.enumerated() {
                let month = calendar.component(.month, from: bucket.startDate)
                if month % 2 == 0 {
                    labels[i] = formatter.string(from: bucket.startDate).uppercased()
                }
            }
            return labels
            
        case .lifetime:
            // Show 4-5 labels evenly spaced
            formatter.dateFormat = "MMM"
            var labels = Array(repeating: "", count: buckets.count)
            
            if buckets.count > 0 {
                let step = max(buckets.count / 4, 1)
                for i in stride(from: 0, to: buckets.count, by: step) {
                    if i < buckets.count {
                        labels[i] = formatter.string(from: buckets[i].startDate).uppercased()
                    }
                }
                labels[buckets.count - 1] = formatter.string(from: buckets[buckets.count - 1].startDate).uppercased()
            }
            return labels
        }
    }
    
    private var maxMiles: Double {
        if timePeriod == .month {
            let max = dataPoints.map({ $0.miles }).max() ?? 10
            return max > 0 ? max : 10
        } else {
            let max = buckets.map({ $0.miles }).max() ?? 10
            return max > 0 ? max : 10
        }
    }
    
    private var showDots: Bool {
        [.week, .month, .threeMonths, .sixMonths].contains(timePeriod)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                VStack(spacing: 4) {
                    if timePeriod == .month {
                        monthGraph
                    } else {
                        bucketGraph
                    }
                    
                    // X-axis labels - absolute positioning
                    ZStack(alignment: .leading) {
                        Color.clear.frame(height: 20)
                        
                        GeometryReader { geo in
                            let bucketCount = timePeriod == .month ? xAxisLabels.count : buckets.count
                            let width = geo.size.width
                            
                            ForEach(xAxisLabels.indices, id: \.self) { index in
                                if !xAxisLabels[index].isEmpty {
                                    let stepX = width / CGFloat(max(bucketCount - 1, 1))
                                    let xPos = CGFloat(index) * stepX
                                    
                                    Text(xAxisLabels[index])
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .frame(width: 50, alignment: .center)
                                        .offset(x: xPos - 25) // Center the 50pt wide text on the position
                                }
                            }
                        }
                    }
                    .frame(height: 20)
                }
                
                // Y-axis
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
                .frame(width: 40, height: 200)
            }
        }
    }
    
    // 1M: Individual activities with line from edge to edge
    private var monthGraph: some View {
        GeometryReader { geometry in
            let calendar = Calendar.current
            let now = Date()
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
            let totalDays = calendar.dateComponents([.day], from: startOfMonth, to: nextMonth).day!
            
            ZStack(alignment: .bottomLeading) {
                // Grid
                VStack(spacing: 0) {
                    ForEach(0..<3) { _ in
                        Divider().background(Color(.systemGray4))
                        Spacer()
                    }
                    Divider().background(Color(.systemGray4))
                }
                
                // Gradient fill
                if !dataPoints.isEmpty {
                    Path { path in
                        let w = geometry.size.width
                        let h = geometry.size.height
                        
                        path.move(to: CGPoint(x: 0, y: h))
                        
                        for point in dataPoints {
                            let day = calendar.dateComponents([.day], from: startOfMonth, to: point.date).day!
                            let x = (CGFloat(day) / CGFloat(totalDays)) * w
                            let y = h - (CGFloat(point.miles) / CGFloat(maxMiles) * h)
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                        
                        path.addLine(to: CGPoint(x: w, y: h))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Theme.primaryBlue.opacity(0.3),
                                Theme.primaryBlue.opacity(0.05)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                
                // Line from left to right
                Path { path in
                    let w = geometry.size.width
                    let h = geometry.size.height
                    
                    path.move(to: CGPoint(x: 0, y: h))
                    
                    for point in dataPoints {
                        let day = calendar.dateComponents([.day], from: startOfMonth, to: point.date).day!
                        let x = (CGFloat(day) / CGFloat(totalDays)) * w
                        let y = h - (CGFloat(point.miles) / CGFloat(maxMiles) * h)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    
                    path.addLine(to: CGPoint(x: w, y: h))
                }
                .stroke(Theme.primaryBlue, lineWidth: 2)
                
                // Dots
                ForEach(dataPoints.indices, id: \.self) { i in
                    let point = dataPoints[i]
                    let day = calendar.dateComponents([.day], from: startOfMonth, to: point.date).day!
                    let x = (CGFloat(day) / CGFloat(totalDays)) * geometry.size.width
                    let y = geometry.size.height - (CGFloat(point.miles) / CGFloat(maxMiles) * geometry.size.height)
                    
                    Circle()
                        .fill(Theme.primaryBlue)
                        .frame(width: 6, height: 6)
                        .position(x: x, y: y)
                }
            }
        }
        .frame(height: 200)
    }
    
    // All other periods: bucketed data
    private var bucketGraph: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                // Grid
                VStack(spacing: 0) {
                    ForEach(0..<3) { _ in
                        Divider().background(Color(.systemGray4))
                        Spacer()
                    }
                    Divider().background(Color(.systemGray4))
                }
                
                // Gradient
                if !buckets.isEmpty {
                    Path { path in
                        let w = geometry.size.width
                        let h = geometry.size.height
                        let stepX = w / CGFloat(max(buckets.count - 1, 1))
                        
                        path.move(to: CGPoint(x: 0, y: h))
                        
                        for (i, bucket) in buckets.enumerated() {
                            let x = CGFloat(i) * stepX
                            let y = h - (CGFloat(bucket.miles) / CGFloat(maxMiles) * h)
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                        
                        let lastX = CGFloat(buckets.count - 1) * stepX
                        path.addLine(to: CGPoint(x: lastX, y: h))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Theme.primaryBlue.opacity(0.3),
                                Theme.primaryBlue.opacity(0.05)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                
                // Line
                if !buckets.isEmpty {
                    Path { path in
                        let w = geometry.size.width
                        let h = geometry.size.height
                        let stepX = w / CGFloat(max(buckets.count - 1, 1))
                        
                        for (i, bucket) in buckets.enumerated() {
                            let x = CGFloat(i) * stepX
                            let y = h - (CGFloat(bucket.miles) / CGFloat(maxMiles) * h)
                            
                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Theme.primaryBlue, lineWidth: 2)
                }
                
                // Dots
                if showDots {
                    ForEach(buckets.indices, id: \.self) { i in
                        let w = geometry.size.width
                        let h = geometry.size.height
                        let stepX = w / CGFloat(max(buckets.count - 1, 1))
                        let x = CGFloat(i) * stepX
                        let y = h - (CGFloat(buckets[i].miles) / CGFloat(maxMiles) * h)
                        
                        Circle()
                            .fill(Theme.primaryBlue)
                            .frame(width: 6, height: 6)
                            .position(x: x, y: y)
                    }
                }
            }
        }
        .frame(height: 200)
    }
}
