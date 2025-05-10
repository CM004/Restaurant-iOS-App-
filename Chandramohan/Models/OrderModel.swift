import Foundation

struct OrderItem: Identifiable, Codable {
    let id: String
    let name: String
    let price: String
    let quantity: Int
    let imageUrl: String
}

struct Order: Identifiable, Codable {
    let id: String
    let orderDate: Date
    let items: [OrderItem]
    let totalAmount: Double
}

enum OrderStatus: String, Codable {
    case pending = "Pending"
    case confirmed = "Confirmed"
    case preparing = "Preparing"
    case readyForPickup = "Ready for Pickup"
    case delivered = "Delivered"
    case cancelled = "Cancelled"
    
    var color: String {
        switch self {
        case .pending: return "yellow"
        case .confirmed: return "blue"
        case .preparing: return "orange"
        case .readyForPickup: return "green"
        case .delivered: return "gray"
        case .cancelled: return "red"
        }
    }
} 