import Foundation

struct CartItem: Identifiable, Codable {
    let id = UUID()
    let cuisineId: String
    let itemId: String
    let name: String
    let price: Double
    var quantity: Int
    let imageUrl: String
    
    var totalPrice: Double {
        price * Double(quantity)
    }
    
    var priceAsInt: Int {
        Int(round(price))
    }
    
    var totalPriceAsInt: Int {
        Int(round(totalPrice))
    }
}

class CartModel: ObservableObject {
    @Published var items: [CartItem] = []
    private let cartKey = "savedCart"
    
    init() {
        loadCart()
    }
    
    var netTotal: Double {
        items.reduce(0) { $0 + $1.totalPrice }
    }
    
    var netTotalAsInt: Int {
        Int(round(netTotal))
    }
    
    var cgst: Double {
        netTotal * 0.025 // 2.5%
    }
    
    var cgstAsInt: Int {
        Int(round(cgst))
    }
    
    var sgst: Double {
        netTotal * 0.025 // 2.5%
    }
    
    var sgstAsInt: Int {
        Int(round(sgst))
    }
    
    var grandTotal: Double {
        netTotal + cgst + sgst
    }
    
    var grandTotalAsInt: Int {
        Int(round(grandTotal))
    }
    
    func addItem(_ item: MenuItem, cuisineId: String) {
        // First check if item already exists by comparing both ID and name (in case of language change)
        if let index = items.firstIndex(where: { $0.itemId == item.id || $0.name == item.name }) {
            items[index].quantity += 1
            print("Increased quantity for item: \(item.name) (ID: \(item.id)) to \(items[index].quantity)")
            saveCart()
            return
        }
        
        print("Adding new item to cart: \(item.name) (ID: \(item.id)) in cuisine \(cuisineId)")
        
        // Clean and parse the price string
        let priceString = item.price
            .replacingOccurrences(of: "₹", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        // Try parsing the price
        if let price = Double(priceString) {
            let cartItem = CartItem(
                cuisineId: cuisineId,
                itemId: item.id,
                name: item.name,
                price: price,
                quantity: 1,
                imageUrl: item.imageUrl
            )
            items.append(cartItem)
            print("Successfully added item to cart with price: \(price)")
            saveCart()
        } else {
            // Fallback: Try removing all non-numeric characters except decimal point
            let cleanedPrice = priceString.components(separatedBy: CharacterSet.decimalDigits.union(CharacterSet(charactersIn: ".")).inverted).joined()
            
            if let price = Double(cleanedPrice) {
                let cartItem = CartItem(
                    cuisineId: cuisineId,
                    itemId: item.id,
                    name: item.name,
                    price: price,
                    quantity: 1,
                    imageUrl: item.imageUrl
                )
                items.append(cartItem)
                print("Used fallback method to add item with price: \(price)")
                saveCart()
            } else {
                print("Failed to parse price: \(item.price) - Cleaned attempt: \(cleanedPrice)")
            }
        }
    }
    
    func removeItem(_ itemId: String) {
        items.removeAll { $0.itemId == itemId }
        saveCart()
    }
    
    func updateQuantity(for itemId: String, quantity: Int) {
        if let index = items.firstIndex(where: { $0.itemId == itemId }) {
            if quantity <= 0 {
                // Remove item if quantity is zero or less
                items.remove(at: index)
                print("Removed item \(itemId) from cart")
            } else {
                // Update quantity
                items[index].quantity = quantity
                print("Updated quantity for item \(itemId) to \(quantity)")
            }
            saveCart()
        } else if quantity > 0 {
            // If the item isn't in the cart but we're trying to add it with a quantity > 0
            // This shouldn't happen normally but provides a fallback
            print("Warning: Tried to update quantity for non-existent item: \(itemId)")
        }
    }
    
    // Helper function to format price as string with rupee symbol
    func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: price)) ?? "₹0.00"
    }
    
    // MARK: - Persistence Methods
    
    func saveCart() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: cartKey)
        }
    }
    
    private func loadCart() {
        if let data = UserDefaults.standard.data(forKey: cartKey),
           let savedItems = try? JSONDecoder().decode([CartItem].self, from: data) {
            items = savedItems
        }
    }
} 