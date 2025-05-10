import Foundation
import SwiftUI
import Combine

enum Language: String {
    case english = "en"
    case hindi = "hi"
    
    var code: String {
        switch self {
        case .english: return "US"
        case .hindi: return "IN"
        }
    }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .hindi: return "हिंदी"
        }
    }
}

@MainActor
class HomeViewModel: ObservableObject {
    @Published var cuisines: [CuisineModel] = []
    @Published var topDishes: [MenuItem] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentPage = 1
    @Published var hasMorePages = true
    @Published var dishQuantities: [String: Int] = [:]
    private var loadingTask: Task<Void, Never>?
    private var hasLoadedTopDishes = false
    private var cancellables = Set<AnyCancellable>()
    
    // Use LocalizationManager for current language
    var currentLanguage: Language {
        LocalizationManager.shared.currentLanguage
    }
    
    let cartModel: CartModel
    let orderManager = OrderManager.shared
    
    init(cartModel: CartModel) {
        self.cartModel = cartModel
        
        // Subscribe to language changes
        LocalizationManager.shared.$currentLanguage
            .dropFirst() // Skip initial value
            .sink { [weak self] _ in
                Task {
                    await self?.refreshDataOnLanguageChange()
                }
            }
            .store(in: &cancellables)
            
        // Subscribe to cart changes
        cartModel.$items
            .sink { [weak self] _ in
                // Trigger UI update when cart changes
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    private func refreshDataOnLanguageChange() async {
        cuisines = []
        topDishes = []
        currentPage = 1
        hasMorePages = true
        hasLoadedTopDishes = false
        dishQuantities = [:]
        
        await loadData(forceRefresh: true)
    }
    
    func toggleLanguage() {
        let newLanguage = currentLanguage == .english ? Language.hindi : Language.english
        LocalizationManager.shared.setLanguage(newLanguage)
    }
    
    func loadData(forceRefresh: Bool = false) async {
        // Cancel any existing loading task
        loadingTask?.cancel()
        
        if forceRefresh {
            currentPage = 1
            cuisines.removeAll()
            hasMorePages = true
            
            // Only reset top dishes on explicit force refresh
            if forceRefresh {
                topDishes.removeAll()
                hasLoadedTopDishes = false
            }
        }
        
        guard hasMorePages && !isLoading else { return }
        
        isLoading = true
        error = nil
        
        // Create a new loading task
        loadingTask = Task {
            do {
                print("Fetching cuisine data for page \(currentPage) in \(currentLanguage.rawValue)...")
                let newCuisines = try await APIService.shared.getItemList(
                    page: currentPage, 
                    count: 10, 
                    language: currentLanguage.rawValue
                )
                print("Received \(newCuisines.count) cuisines in \(currentLanguage.displayName)")
                
                guard !Task.isCancelled else { return }
                
                // Append new cuisines to existing list
                if !newCuisines.isEmpty {
                    // Filter out duplicates based on cuisineId
                    let existingIds = Set(cuisines.map { $0.cuisineId })
                    let uniqueNewCuisines = newCuisines.filter { !existingIds.contains($0.cuisineId) }
                    
                    if !uniqueNewCuisines.isEmpty {
                        cuisines.append(contentsOf: uniqueNewCuisines)
                        currentPage += 1
                        
                        // Only select top dishes once when we first load data
                        if !hasLoadedTopDishes {
                            await loadTopDishes()
                        }
                    } else {
                        hasMorePages = false
                    }
                } else {
                    hasMorePages = false
                }
                
            } catch APIError.noCuisinesFound {
                if cuisines.isEmpty {
                    error = "no_cuisines".localized
                } else {
                    // If we already have cuisines, just stop pagination
                    hasMorePages = false
                }
            } catch {
                print("Error loading data: \(error.localizedDescription)")
                if cuisines.isEmpty {
                    self.error = "connection_error".localized
                }
            }
            
            isLoading = false
        }
    }
    
    private func loadTopDishes() async {
        do {
            // First, fetch more cuisines to ensure we have a broad sample
            var allCuisines: [CuisineModel] = []
            
            // Load several pages to get diverse cuisine types - use current language
            for page in 1...5 {
                let pageCuisines = try await APIService.shared.getItemList(
                    page: page, 
                    count: 10, 
                    language: currentLanguage.rawValue
                )
                allCuisines.append(contentsOf: pageCuisines)
                
                // Break after getting a good number of cuisines
                if allCuisines.count >= 20 {
                    break
                }
            }
            
            // Also try using filter API with a high rating threshold
            // Since we don't know the exact max rating yet, try a high value
            if let filteredCuisines = try? await APIService.shared.getItemsByFilter(minRating: 4.8) {
                allCuisines.append(contentsOf: filteredCuisines)
            }
            
            // Remove duplicate cuisines by ID
            let uniqueCuisines = Dictionary(grouping: allCuisines, by: { $0.cuisineId })
                .compactMap { $0.value.first }
            
            print("Analyzing dishes across \(uniqueCuisines.count) unique cuisines")
            
            // Start with all dishes from all cuisines
            var allDishes: [MenuItem] = []
            for cuisine in uniqueCuisines {
                print("Cuisine: \(cuisine.cuisineName) has \(cuisine.items.count) dishes")
                allDishes.append(contentsOf: cuisine.items)
            }
            
            // Add dishes from our existing cuisines array as well
            allDishes.append(contentsOf: cuisines.flatMap { $0.items })
            
            // Remove duplicates based on item ID
            let uniqueDishes = Dictionary(grouping: allDishes, by: { $0.id })
                .compactMap { $0.value.first }
            
            print("Total unique dishes found: \(uniqueDishes.count)")
            
            // Sort by rating (highest first)
            let sortedDishes = uniqueDishes
                .sorted { (Double($0.rating) ?? 0) > (Double($1.rating) ?? 0) }
            
            // Print highest ratings for analysis
            if let highestRated = sortedDishes.first {
                print("Highest rating found: \(highestRated.rating) for dish: \(highestRated.name)")
            }
            
            // Log some top rated dishes
            if !sortedDishes.isEmpty {
                print("Top 10 dishes by rating:")
                for (index, dish) in sortedDishes.prefix(10).enumerated() {
                    print("\(index + 1). \(dish.name): \(dish.rating) stars")
                }
            }
            
            // Take top 3 dishes
            let top3Dishes = Array(sortedDishes.prefix(3))
            
            // Update the published property
            if !top3Dishes.isEmpty {
                print("Selected top dishes:")
                for dish in top3Dishes {
                    print("- \(dish.name) (Rating: \(dish.rating))")
                }
                topDishes = top3Dishes
                hasLoadedTopDishes = true
            } else {
                print("Warning: No top dishes found!")
            }
        } catch {
            print("Error loading top dishes: \(error.localizedDescription)")
            
            // Fallback to existing cuisines if fetching fails
            let allDishes = cuisines.flatMap { $0.items }
            let sortedDishes = allDishes
                .sorted { (Double($0.rating) ?? 0) > (Double($1.rating) ?? 0) }
            let top3Dishes = Array(sortedDishes.prefix(3))
            
            if !top3Dishes.isEmpty {
                topDishes = top3Dishes
                hasLoadedTopDishes = true
            }
        }
    }
    
    func loadMoreIfNeeded(currentItem item: CuisineModel) async {
        // Only trigger load more if we're near the end and not already loading
        let thresholdIndex = cuisines.index(cuisines.endIndex, offsetBy: -1)
        if let currentIndex = cuisines.firstIndex(where: { $0.id == item.id }),
           currentIndex >= thresholdIndex,
           !isLoading && hasMorePages {
            await loadData()
        }
    }
    
    func addToCart(item: MenuItem, cuisineId: String) {
        print("HomeViewModel: Adding to cart - Item: \(item.name) (ID: \(item.id)), Cuisine: \(cuisineId)")
        cartModel.addItem(item, cuisineId: cuisineId)
        print("HomeViewModel: Current cart has \(cartModel.items.count) items")
    }
    
    deinit {
        loadingTask?.cancel()
    }
} 