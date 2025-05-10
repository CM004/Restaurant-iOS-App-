import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case dataError(String)
    case serverError(String)
    case noCuisinesFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .dataError(let message):
            return "Data error: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .noCuisinesFound:
            return "No cuisines found"
        }
    }
}

class APIService {
    static let shared = APIService()
    private let baseURL = "https://uat.onebanc.ai"
    private let apiKey = "uonebancservceemultrS3cg8RaL30"
    private let maxRetries = 3
    private var currentLanguage: String = "en"
    
    private init() {}
    
    func setLanguage(_ language: String) {
        self.currentLanguage = language
        print("API language set to: \(language)")
    }
    
    private func createRequest(endpoint: String, action: String) -> URLRequest? {
        guard let url = URL(string: baseURL + endpoint) else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Partner-API-Key")
        request.setValue(action, forHTTPHeaderField: "X-Forward-Proxy-Action")
        request.setValue(currentLanguage, forHTTPHeaderField: "Accept-Language")
        request.timeoutInterval = 30
        return request
    }
    
    private func handleAPIResponse<T: Decodable>(_ data: Data, _ response: HTTPURLResponse) throws -> T {
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response data: \(responseString)")
            
            // Check for specific error messages
            if responseString.contains("No Cuisines Found") {
                throw APIError.noCuisinesFound
            }
        }
        
        guard (200...299).contains(response.statusCode) else {
            throw APIError.serverError("Server returned status code: \(response.statusCode)")
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
    
    private func executeWithRetry<T>(retries: Int = 0, maxRetries: Int = 3, operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch {
            if retries < maxRetries {
                // Exponential backoff: wait longer between each retry
                let delay = Double(pow(2.0, Double(retries))) * 0.5
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await executeWithRetry(retries: retries + 1, maxRetries: maxRetries, operation: operation)
            }
            throw error
        }
    }
    
    func getItemList(page: Int = 1, count: Int = 10, language: String? = nil) async throws -> [CuisineModel] {
        // If language is provided, use it for this request
        if let language = language {
            setLanguage(language)
        }
        
        return try await executeWithRetry { [weak self] in
            guard let self = self else { throw APIError.dataError("Service not available") }
            guard let request = createRequest(endpoint: "/emulator/interview/get_item_list", action: "get_item_list") else {
                throw APIError.invalidURL
            }
            
            var urlRequest = request
            urlRequest.httpMethod = "POST"
            
            // Create a proper Codable struct for the request body
            struct ItemListRequest: Codable {
                let page: Int
                let count: Int
                let language: String
            }
            
            let requestBody = ItemListRequest(
                page: page,
                count: count,
                language: currentLanguage
            )
            
            urlRequest.httpBody = try JSONEncoder().encode(requestBody)
            
            print("Making API request to: \(urlRequest.url?.absoluteString ?? "")")
            print("Headers: \(urlRequest.allHTTPHeaderFields ?? [:])")
            print("Request body: \(String(data: urlRequest.httpBody ?? Data(), encoding: .utf8) ?? "")")
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            print("Response status code: \(httpResponse.statusCode)")
            
            let apiResponse: APIResponse = try handleAPIResponse(data, httpResponse)
            
            if apiResponse.responseCode != 200 || apiResponse.outcomeCode != 200 {
                if apiResponse.responseMessage.contains("No Cuisines Found") {
                    throw APIError.noCuisinesFound
                }
                throw APIError.serverError(apiResponse.responseMessage)
            }
            
            return apiResponse.cuisines
        }
    }
    
    func getItemById(itemId: String) async throws -> MenuItem {
        guard let request = createRequest(endpoint: "/emulator/interview/get_item_by_id", action: "get_item_by_id") else {
            throw APIError.invalidURL
        }
        
        var urlRequest = request
        urlRequest.httpMethod = "POST"
        
        struct ItemRequest: Codable {
            let item_id: String
            let language: String
        }
        
        let requestBody = ItemRequest(item_id: itemId, language: currentLanguage)
        urlRequest.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            throw APIError.serverError("Server returned status code: \(httpResponse.statusCode)")
        }
        
        struct ItemResponse: Codable {
            let responseCode: Int
            let outcomeCode: Int
            let responseMessage: String
            let itemId: String
            let itemName: String
            let itemPrice: String
            let itemRating: String
            let itemImageUrl: String
            
            enum CodingKeys: String, CodingKey {
                case responseCode = "response_code"
                case outcomeCode = "outcome_code"
                case responseMessage = "response_message"
                case itemId = "item_id"
                case itemName = "item_name"
                case itemPrice = "item_price"
                case itemRating = "item_rating"
                case itemImageUrl = "item_image_url"
            }
        }
        
        let itemResponse = try JSONDecoder().decode(ItemResponse.self, from: data)
        
        if itemResponse.responseCode != 200 || itemResponse.outcomeCode != 200 {
            throw APIError.serverError(itemResponse.responseMessage)
        }
        
        return MenuItem(
            id: itemResponse.itemId,
            name: itemResponse.itemName,
            imageUrl: itemResponse.itemImageUrl,
            price: itemResponse.itemPrice,
            rating: itemResponse.itemRating
        )
    }
    
    func getItemsByFilter(cuisineTypes: [String]? = nil, minPrice: Int? = nil, maxPrice: Int? = nil, minRating: Double? = nil) async throws -> [CuisineModel] {
        guard let request = createRequest(endpoint: "/emulator/interview/get_item_by_filter", action: "get_item_by_filter") else {
            throw APIError.invalidURL
        }
        
        var urlRequest = request
        urlRequest.httpMethod = "POST"
        
        // Use JSONSerialization for this more complex body with optional fields
        var body: [String: Any] = ["language": currentLanguage]
        
        if let cuisineTypes = cuisineTypes {
            body["cuisine_type"] = cuisineTypes
        }
        
        if let minPrice = minPrice, let maxPrice = maxPrice {
            body["price_range"] = [
                "min_amount": minPrice,
                "max_amount": maxPrice
            ]
        }
        
        if let minRating = minRating {
            body["min_rating"] = minRating
        }
        
        urlRequest.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            throw APIError.serverError("Server returned status code: \(httpResponse.statusCode)")
        }
        
        let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
        
        if apiResponse.responseCode != 200 || apiResponse.outcomeCode != 200 {
            throw APIError.serverError(apiResponse.responseMessage)
        }
        
        return apiResponse.cuisines
    }
    
    func makePayment(items: [CartItem]) async throws -> String {
        print("Starting payment process...")
        
        guard !items.isEmpty else {
            print("Error: Cart is empty")
            throw APIError.dataError("Cart is empty")
        }
        
        print("Processing payment for \(items.count) items")
        
        let url = URL(string: "https://uat.onebanc.ai/emulator/interview/make_payment")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("uonebancservceemultrS3cg8RaL30", forHTTPHeaderField: "X-Partner-API-Key")
        request.setValue("make_payment", forHTTPHeaderField: "X-Forward-Proxy-Action")
        
        // Calculate total items
        let totalItems = items.reduce(0) { $0 + $1.quantity }
        
        // Calculate total amount (with taxes)
        let subtotal = items.reduce(0.0) { $0 + $1.totalPrice }
        let cgst = subtotal * 0.025  // 2.5% CGST
        let sgst = subtotal * 0.025  // 2.5% SGST
        let grandTotal = subtotal + cgst + sgst
        let totalAmount = String(format: "%.2f", grandTotal)
        
        print("Payment calculation:")
        print("Subtotal: \(subtotal)")
        print("CGST (2.5%): \(cgst)")
        print("SGST (2.5%): \(sgst)")
        print("Grand Total: \(grandTotal)")
        print("Rounded Total Amount: \(totalAmount)")
        
        // Create data array with exact format
        var dataArray: [[String: Any]] = []
        for item in items {
            let itemDict: [String: Any] = [
                "cuisine_id": Int(item.cuisineId) ?? 0,
                "item_id": Int(item.itemId) ?? 0,
                "item_price": item.priceAsInt,
                "item_quantity": item.quantity
            ]
            dataArray.append(itemDict)
            print("Added item to request: \(itemDict)")
        }
        
        // Create request dictionary with exact format
        let requestDict: [String: Any] = [
            "total_amount": totalAmount,
            "total_items": totalItems,
            "data": dataArray
        ]
        
        print("Final payment request: \(requestDict)")
        
        // Convert to JSON data
        let jsonData = try JSONSerialization.data(withJSONObject: requestDict)
        request.httpBody = jsonData
        
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("Request body JSON: \(jsonString)")
        }
        
        print("Sending request to server...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Error: Invalid HTTP response")
            throw APIError.invalidResponse
        }
        
        print("Response status code: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response body: \(responseString)")
        }
        
        // Parse the response
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let responseCode = json["response_code"] as? Int ?? 0
            let outcomeCode = json["outcome_code"] as? Int ?? 0
            let responseMessage = json["response_message"] as? String ?? "Unknown error"
            let errorDetails = json["error_details"] as? String
            
            // If we have a specific error detail, use that
            if httpResponse.statusCode != 200 {
                if let errorDetails = errorDetails {
                    throw APIError.serverError(errorDetails)
                } else {
                    throw APIError.serverError(responseMessage)
                }
            }
            
            // Check for successful response
            if responseCode == 200 && outcomeCode == 200,
               let txnRefNo = json["txn_ref_no"] as? String {
                print("Payment successful with transaction reference: \(txnRefNo)")
                return txnRefNo
            } else {
                throw APIError.serverError(responseMessage)
            }
        } else {
            throw APIError.dataError("Failed to parse server response")
        }
    }
}
