import Foundation
import SwiftUI

class OrderManager: ObservableObject {
    static let shared = OrderManager()
    @Published var orders: [Order] = []
    private let ordersKey = "savedOrders"
    private let maxOrders = 3
    
    private init() {
        loadOrders()
    }
    
    func addOrder(items: [CartItem], totalAmount: Double) {
        let orderItems = items.map { cartItem in
            OrderItem(
                id: cartItem.itemId,
                name: cartItem.name,
                price: String(format: "%.2f", cartItem.price),
                quantity: cartItem.quantity,
                imageUrl: cartItem.imageUrl
            )
        }
        
        let newOrder = Order(
            id: UUID().uuidString,
            orderDate: Date(),
            items: orderItems,
            totalAmount: totalAmount
        )
        
        DispatchQueue.main.async {
            // Add new order at the beginning and keep only the last maxOrders
            self.orders.insert(newOrder, at: 0)
            if self.orders.count > self.maxOrders {
                self.orders = Array(self.orders.prefix(self.maxOrders))
            }
            self.saveOrders()
        }
    }
    
    private func loadOrders() {
        if let data = UserDefaults.standard.data(forKey: ordersKey),
           let savedOrders = try? JSONDecoder().decode([Order].self, from: data) {
            // Keep only the last maxOrders
            orders = Array(savedOrders.prefix(maxOrders))
        }
    }
    
    private func saveOrders() {
        if let encoded = try? JSONEncoder().encode(orders) {
            UserDefaults.standard.set(encoded, forKey: ordersKey)
        }
    }
} 