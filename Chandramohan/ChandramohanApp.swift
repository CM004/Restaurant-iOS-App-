import SwiftUI

@main
struct ChandramohanApp: App {
    @StateObject private var cartModel = CartModel()
    
    init() {
        // Initialize localization system
        _ = LocalizationManager.shared
        
        // Apply custom theme to UI components
        applyCustomAppearance()
        
        // Print debug info
        print("App initialized with cart model: \(cartModel)")
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView(cartModel: cartModel)
                .onAppear {
                    print("HomeView appeared with cart items: \(cartModel.items.count)")
                }
                .preferredColorScheme(.light)
        }
    }
    
    // Apply custom colors to standard UI components
    private func applyCustomAppearance() {
        // Navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColors.background)
        appearance.titleTextAttributes = [.foregroundColor: UIColor(AppColors.textPrimary)]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(AppColors.textPrimary)]
        
        // Set the back button colors
        let orangeColor = UIColor(AppColors.primary)
        appearance.setBackIndicatorImage(
            UIImage(systemName: "chevron.left")?.withTintColor(orangeColor, renderingMode: .alwaysOriginal),
            transitionMaskImage: UIImage(systemName: "chevron.left")?.withTintColor(orangeColor, renderingMode: .alwaysOriginal)
        )
        
        // Set button appearance for all navigation bar buttons
        let buttonAppearance = UIBarButtonItemAppearance()
        buttonAppearance.normal.titleTextAttributes = [.foregroundColor: orangeColor]
        appearance.buttonAppearance = buttonAppearance
        appearance.backButtonAppearance = buttonAppearance
        
        // Apply appearance settings
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = orangeColor
        
        // Force back button title color
        UIBarButtonItem.appearance().setTitleTextAttributes([.foregroundColor: orangeColor], for: .normal)
        UIBarButtonItem.appearance().setTitleTextAttributes([.foregroundColor: orangeColor], for: .highlighted)
        
        // Tab bar appearance
        UITabBar.appearance().backgroundColor = UIColor(AppColors.background)
        
        // Table view appearance
        UITableView.appearance().backgroundColor = UIColor(AppColors.background)
    }
} 
