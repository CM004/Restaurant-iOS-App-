import SwiftUI

struct CartView: View {
    @ObservedObject var cartModel: CartModel
    @State private var isLoading = false
    @State private var error: String?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isOrderSuccess = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Cart Items
                ForEach(cartModel.items) { item in
                    HStack {
                        AsyncImage(url: URL(string: item.imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.secondary))
                        }
                        .frame(width: 80, height: 80)
                        .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name)
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            Text(cartModel.formatPrice(item.price))
                                .foregroundColor(AppColors.textSecondary)
                            Text("\("total".localized) \(cartModel.formatPrice(item.totalPrice))")
                                .foregroundColor(AppColors.textSecondary)
                                .font(.subheadline)
                        }
                        
                        Spacer()
                        
                        // Quantity Stepper
                        HStack {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    cartModel.updateQuantity(for: item.itemId, quantity: item.quantity - 1)
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(AppColors.primary)
                                    .font(.system(size: 22))
                            }
                            
                            Text("\(item.quantity)")
                                .frame(width: 30)
                                .foregroundColor(AppColors.textPrimary)
                                .fontWeight(.medium)
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    cartModel.updateQuantity(for: item.itemId, quantity: item.quantity + 1)
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(AppColors.primary)
                                    .font(.system(size: 22))
                            }
                        }
                    }
                    .padding()
                    .background(AppColors.cardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.secondary, lineWidth: 2)
                    )
                    .shadow(radius: 2)
                }
                
                // Bill Details
                if !cartModel.items.isEmpty {
                    VStack(spacing: 12) {
                        HStack {
                            Text("subtotal".localized)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            Text(cartModel.formatPrice(cartModel.netTotal))
                                .foregroundColor(AppColors.textPrimary)
                        }
                        
                        HStack {
                            Text("cgst".localized)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            Text(cartModel.formatPrice(cartModel.cgst))
                                .foregroundColor(AppColors.textPrimary)
                        }
                        
                        HStack {
                            Text("sgst".localized)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            Text(cartModel.formatPrice(cartModel.sgst))
                                .foregroundColor(AppColors.textPrimary)
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("grand_total".localized)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            Text(cartModel.formatPrice(cartModel.grandTotal))
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.secondary)
                        }
                        
                        Button(action: placeOrder) {
                            Text(isLoading ? "loading".localized : "place_order".localized)
                                .font(.headline)
                                .foregroundColor(AppColors.textOnColor)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.primary)
                                .cornerRadius(12)
                        }
                        .disabled(isLoading)
                    }
                    .padding()
                    .background(AppColors.cardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.secondary, lineWidth: 2)
                    )
                    .shadow(radius: 2)
                } else {
                    Text("empty_cart".localized)
                        .font(.headline)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.top, 40)
                }
            }
            .padding()
        }
        .navigationTitle("cart".localized)
        .background(AppColors.background)
        .accentColor(AppColors.primary)
        .alert(isOrderSuccess ? NSLocalizedString("order_success_title", comment: "") : NSLocalizedString("order_failed_title", comment: ""), isPresented: $showingAlert) {
            Button("OK", role: .cancel) {
                if isOrderSuccess {
                    // The cart is already cleared in the placeOrder function
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func placeOrder() {
        guard !cartModel.items.isEmpty else { return }
        
        isLoading = true
        Task {
            do {
                print("Starting order placement...")
                print("Cart items: \(cartModel.items.count), Grand total: \(cartModel.grandTotal)")
                
                let transactionId = try await APIService.shared.makePayment(items: cartModel.items)
                print("Order placed successfully with transaction ID: \(transactionId)")
                
                // Order was successful
                isOrderSuccess = true
                alertMessage = String(format: NSLocalizedString("order_success_message", comment: ""), transactionId)
                
                // Save order to OrderManager
                OrderManager.shared.addOrder(items: cartModel.items, totalAmount: cartModel.grandTotal)
                print("Order saved to history")
                
                // Clear cart and save the empty cart to persistence
                cartModel.items.removeAll()
                cartModel.saveCart()
                print("Cart cleared and saved")
                
            } catch let error as APIError {
                // Order failed
                isOrderSuccess = false
                print("Order placement failed: \(error)")
                
                switch error {
                case .serverError(let message):
                    alertMessage = message
                case .dataError(let message):
                    alertMessage = message
                case .invalidResponse:
                    alertMessage = NSLocalizedString("invalid_response", comment: "")
                case .invalidURL:
                    alertMessage = NSLocalizedString("invalid_url", comment: "")
                case .noCuisinesFound:
                    alertMessage = NSLocalizedString("no_cuisines_found", comment: "")
                }
            } catch {
                isOrderSuccess = false
                alertMessage = error.localizedDescription
                print("Unexpected error: \(error)")
            }
            
            isLoading = false
            showingAlert = true
        }
    }
}

#Preview {
    NavigationView {
        CartView(cartModel: {
            let model = CartModel()
            model.addItem(
                MenuItem(
                    id: "1",
                    name: "Butter Chicken",
                    imageUrl: "https://example.com/image.jpg",
                    price: "299",
                    rating: "4.5"
                ),
                cuisineId: "1"
            )
            return model
        }())
        .background(AppColors.background)
    }
    .accentColor(AppColors.primary)
} 