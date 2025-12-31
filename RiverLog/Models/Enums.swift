import Foundation

enum TripType: String, CaseIterable {
    case commercial = "Commercial"
    case `private` = "Private"
    case training = "Training"
    
    var displayName: String {
        return self.rawValue
    }
}

enum CraftType: String, CaseIterable {
    case raft = "Raft"
    case cat = "Cat"
    case kayak = "Kayak"
    case canoe = "Canoe"
    case sup = "SUP"
    case duckie = "Duckie"
    case ik = "IK"
    case custom = "Custom"
    
    var displayName: String {
        return self.rawValue
    }
    
    var availableLapTypes: [LapType] {
        switch self {
        case .raft, .cat:
            return [.r2, .r1, .rowing, .paddleGuide]
        case .kayak:
            return [.solo, .tandem]
        case .canoe:
            return [.c1, .c2, .oc1, .oc2]
        case .duckie:
            return [.solo, .tandem]
        case .sup, .ik:
            return [.solo]
        case .custom:
            return [.solo]
        }
    }
}

enum LapType: String, CaseIterable {
    // Raft/Cat options
    case r2 = "R2"
    case r1 = "R1"
    case rowing = "Rowing"
    case paddleGuide = "Paddle Guide"
    
    // Kayak/Duckie options
    case solo = "Solo"
    case tandem = "Tandem"
    
    // Canoe options
    case c1 = "C1"
    case c2 = "C2"
    case oc1 = "OC1"
    case oc2 = "OC2"
    
    var displayName: String {
        return self.rawValue
    }
}

enum VisibilityType: String, CaseIterable {
    case `public` = "Public"
    case friends = "Friends"
    case `private` = "Private"
    
    var displayName: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .public:
            return "globe"
        case .friends:
            return "person.2"
        case .private:
            return "lock"
        }
    }
}
