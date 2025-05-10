import SwiftUI

struct CuisineCard: View {
    let cuisine: CuisineModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Image
                AsyncImage(url: URL(string: cuisine.cuisineImageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.secondary))
                }
                .frame(width: geometry.size.width - 13, height: 280)
                .clipped()
                
                // Gradient overlay for better text visibility
                LinearGradient(
                    gradient: Gradient(colors: [
                        .black.opacity(0.6),
                        .clear
                    ]),
                    startPoint: .bottom,
                    endPoint: .center
                )
                .frame(height: 280)
                
                // Cuisine name
                Text(cuisine.cuisineName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
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
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

#Preview {
    CuisineCard(cuisine: CuisineModel(
        cuisineId: "1",
        cuisineName: "North Indian Cuisine",
        cuisineImageUrl: "https://example.com/image.jpg",
        items: []
    ))
    .frame(height: 280)
    .padding()
    .background(AppColors.background)
} 
