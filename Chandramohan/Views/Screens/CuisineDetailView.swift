import SwiftUI

struct CuisineDetailView: View {
    let cuisine: CuisineModel
    @ObservedObject var cartModel: CartModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 26) {
                ForEach(cuisine.items) { item in
                    DishCard(
                        item: item,
                        cuisineId: cuisine.cuisineId,
                        cartModel: cartModel
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle(cuisine.cuisineName)
        .accentColor(AppColors.primary)
        .background(AppColors.background)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: CartView(cartModel: cartModel)) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "cart")
                            .font(.system(size: 22))
                            .foregroundColor(.black)
                        
                        if cartModel.items.count > 0 {
                            Text("\(cartModel.items.count)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(5)
                                .background(AppColors.primary)
                                .clipShape(Circle())
                                .offset(x: 10, y: -10)
                                .animation(.spring(), value: cartModel.items.count)
                        }
                    }
                    .frame(width: 44, height: 44)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        CuisineDetailView(
            cuisine: CuisineModel(
                cuisineId: "1",
                cuisineName: "Chinese",
                cuisineImageUrl: "https://example.com/image.jpg",
                items: [
                    MenuItem(
                        id: "1",
                        name: "Sweet and Sour Chicken",
                        imageUrl: "https://example.com/image.jpg",
                        price: "250",
                        rating: "4.5"
                    ),
                    MenuItem(
                        id: "2",
                        name: "Chowmein",
                        imageUrl: "https://example.com/image.jpg",
                        price: "150",
                        rating: "4.0"
                    )
                ]
            ),
            cartModel: CartModel()
        )
    }
    .accentColor(AppColors.primary)
    .background(AppColors.background)
} 
