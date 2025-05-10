import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @StateObject private var orderManager = OrderManager.shared
    @State private var selectedCuisineIndex = 0
    
    init(cartModel: CartModel) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(cartModel: cartModel))
    }
    
    var body: some View {
        NavigationView {
            contentView
                .navigationTitle("app_name".localized)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        cartButton
                    }
                    
                    ToolbarItem(placement: .navigationBarLeading) {
                        languageButton
                    }
                }
                .background(AppColors.background)
        }
        .accentColor(AppColors.primary)
        .task {
            if viewModel.cuisines.isEmpty {
                await viewModel.loadData()
            }
        }
    }
    
    // MARK: - Main Content View
    private var contentView: some View {
        Group {
            if viewModel.isLoading && viewModel.cuisines.isEmpty {
                loadingView
            } else if viewModel.cuisines.isEmpty {
                errorView
            } else {
                mainScrollView
            }
        }
        .background(AppColors.background)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        ProgressView("loading".localized)
            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.secondary))
            .foregroundColor(AppColors.textPrimary)
            .background(AppColors.background)
    }
    
    // MARK: - Error View
    private var errorView: some View {
        VStack {
            Text("error_loading_data".localized)
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            if let error = viewModel.error {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
            Button("retry".localized) {
                Task {
                    await viewModel.loadData(forceRefresh: true)
                }
            }
            .padding()
            .foregroundColor(AppColors.textOnColor)
            .background(AppColors.primary)
            .cornerRadius(8)
        }
        .padding()
        .background(AppColors.background)
    }
    
    // MARK: - Main Scroll View
    private var mainScrollView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                cuisineCategoriesSection
                
                // Loading indicator for pagination
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.secondary))
                        Spacer()
                    }
                    .padding()
                }
                
                // Top Dishes section
                if !viewModel.topDishes.isEmpty {
                    topDishesSection
                }
                
                // Previous Orders section
                if !orderManager.orders.isEmpty {
                    previousOrdersSection
                }
            }
            .padding(.vertical)
        }
        .background(AppColors.background)
    }
    
    // MARK: - Cuisine Categories Section
    private var cuisineCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("cuisine_categories".localized)
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
            }
            .padding(.horizontal, 6)
            
            cuisineCategoriesTabView
        }
    }
    
    private var cuisineCategoriesTabView: some View {
        TabView(selection: $selectedCuisineIndex) {
            ForEach(0..<(viewModel.cuisines.count * 3), id: \.self) { virtualIndex in
                let actualIndex = virtualIndex % viewModel.cuisines.count
                let cuisine = viewModel.cuisines[actualIndex]
                
                NavigationLink(destination: CuisineDetailView(cuisine: cuisine, cartModel: viewModel.cartModel)) {
                    CuisineCard(cuisine: cuisine)
                        .padding(.horizontal, 6)
                }
                .buttonStyle(PlainButtonStyle())
                .tag(virtualIndex)
            }
        }
        .frame(height: 280)
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .onAppear {
            if !viewModel.cuisines.isEmpty {
                selectedCuisineIndex = viewModel.cuisines.count
            }
        }
        .onChange(of: selectedCuisineIndex) { oldValue, newValue in
            handleTabViewIndexChange(newValue)
        }
        .animation(.easeInOut, value: selectedCuisineIndex)
    }
    
    private func handleTabViewIndexChange(_ newIndex: Int) {
        if viewModel.cuisines.isEmpty { return }
        
        let count = viewModel.cuisines.count
        
        // Reset to middle section if scrolled too far
        if newIndex < count/2 || newIndex >= count * 5/2 {
            let actualIndex = ((newIndex % count) + count) % count
            let middleSectionIndex = actualIndex + count
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(nil) {
                    selectedCuisineIndex = middleSectionIndex
                }
            }
        }
        
        // Load more content if needed
        let actualIndex = ((newIndex % count) + count) % count
        if actualIndex >= count - 2 {
            Task {
                await viewModel.loadMoreIfNeeded(currentItem: viewModel.cuisines[actualIndex])
            }
        }
    }
    
    // MARK: - Top Dishes Section
    private var topDishesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("top_rated_dishes".localized)
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal, 6)
            
            VStack(spacing: 26) {
                ForEach(viewModel.topDishes) { dish in
                    let cuisineId = findCuisineId(for: dish)
                    
                    DishCard(
                        item: dish,
                        cuisineId: cuisineId,
                        cartModel: viewModel.cartModel
                    )
                }
                .padding(.horizontal, 6)
            }
        }
    }
    
    private func findCuisineId(for dish: MenuItem) -> String {
        // Find cuisine ID or use fallback
        return viewModel.cuisines.first(where: { $0.items.contains(where: { $0.id == dish.id }) })?.cuisineId 
            ?? viewModel.cuisines.first?.cuisineId 
            ?? ""
    }
    
    // MARK: - Previous Orders Section
    private var previousOrdersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("previous_orders".localized)
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal, 6)
            
            LazyVStack(spacing: 20) {
                ForEach(orderManager.orders) { order in
                    orderCard(for: order)
                }
            }
            .padding(.horizontal, 6)
        }
    }
    
    private func orderCard(for order: Order) -> some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 12) {
                // Order items
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(order.items) { item in
                            orderItemCard(for: item)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(height: 120)
                
                Divider()
                
                // Total amount
                HStack {
                    Text("total".localized)
                        .font(.subheadline)
                    
                    Text("₹\(String(format: "%.2f", order.totalAmount))")
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }
            .padding(12)
            .frame(width: geometry.size.width - 13)
            .background(AppColors.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.secondary, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
            .position(x: geometry.size.width / 2, y: 90)
        }
        .frame(height: 180)
    }
    
    private func orderItemCard(for item: OrderItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
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
            .clipped()
            
            Text(item.name)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(1)
            
            Text("₹\(item.price) × \(item.quantity)")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(width: 80)
    }
    
    // MARK: - Toolbar Buttons
    private var cartButton: some View {
        NavigationLink(destination: CartView(cartModel: viewModel.cartModel)) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "cart")
                    .font(.system(size: 22))
                    .foregroundColor(.black)
                
                if viewModel.cartModel.items.count > 0 {
                    Text("\(viewModel.cartModel.items.count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(5)
                        .background(AppColors.primary)
                        .clipShape(Circle())
                        .offset(x: 10, y: -10)
                        .animation(.spring(), value: viewModel.cartModel.items.count)
                }
            }
            .frame(width: 44, height: 44)
        }
    }
    
    private var languageButton: some View {
        Menu {
            Button(action: {
                if viewModel.currentLanguage != .english {
                    withAnimation(.spring()) {
                        viewModel.toggleLanguage()
                    }
                }
            }) {
                HStack {
                    Text("English")
                    if viewModel.currentLanguage == .english {
                        Image(systemName: "checkmark")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            
            Button(action: {
                if viewModel.currentLanguage != .hindi {
                    withAnimation(.spring()) {
                        viewModel.toggleLanguage()
                    }
                }
            }) {
                HStack {
                    Text("हिंदी")
                    if viewModel.currentLanguage == .hindi {
                        Image(systemName: "checkmark")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "text.bubble.fill")
                    .imageScale(.small)
                
                Text(viewModel.currentLanguage == .english ? "English" : "हिंदी")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(AppColors.primary)
                    .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HomeView(cartModel: CartModel())
}
