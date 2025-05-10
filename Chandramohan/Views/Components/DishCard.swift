import SwiftUI

struct DishCard: View {
    let item: MenuItem
    let cuisineId: String
    @ObservedObject var cartModel: CartModel
    
    // Compute the current quantity from the cart
    private var quantity: Int {
        cartModel.items.first(where: { $0.itemId == item.id })?.quantity ?? 0
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Image section
                AsyncImage(url: URL(string: item.imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.secondary))
                }
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .clipped()
                .padding(.vertical, 12)
                .padding(.leading, 12)
                
                // Details section
                VStack(alignment: .leading, spacing: 8) {
                    // Name row
                    Text(item.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(2)
                        .padding(.bottom, 2)
                    
                    // Rating row
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(AppColors.star)
                            .imageScale(.small)
                        Text(item.rating)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
                    
                    // Price row
                    Text("₹\(item.price)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.secondary)
                        .padding(.top, 2)
                    
                    // Add to Cart controls
                    if quantity > 0 {
                        HStack(spacing: 8) {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    cartModel.updateQuantity(for: item.id, quantity: quantity - 1)
                                }
                            }) {
                                Image(systemName: "minus")
                                    .foregroundColor(AppColors.textOnColor)
                                    .frame(width: 24, height: 24)
                                    .background(AppColors.primary)
                                    .clipShape(Circle())
                            }
                            
                            Text("\(quantity)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .frame(minWidth: 25)
                                .multilineTextAlignment(.center)
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    cartModel.updateQuantity(for: item.id, quantity: quantity + 1)
                                }
                            }) {
                                Image(systemName: "plus")
                                    .foregroundColor(AppColors.textOnColor)
                                    .frame(width: 24, height: 24)
                                    .background(AppColors.primary)
                                    .clipShape(Circle())
                            }
                        }
                    } else {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                cartModel.addItem(item, cuisineId: cuisineId)
                            }
                        }) {
                            Text("add".localized)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.textOnColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(AppColors.primary)
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: geometry.size.width - 13)
            .background(AppColors.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.secondary, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .frame(height: 144) // Maintain the same height as before
    }
}

// Preview with a sample cart model for testing
#Preview {
    DishCard(
        item: MenuItem(
            id: "1",
            name: "Sweet and Sour Chicken",
            imageUrl: "https://example.com/image.jpg",
            price: "250",
            rating: "4.5"
        ),
        cuisineId: "1",
        cartModel: CartModel()
    )
    .frame(height: 144)
    .padding()
    .background(AppColors.background)
} 
