import Foundation

struct MenuItem: Identifiable, Codable {
    let id: String
    let name: String
    let imageUrl: String
    let price: String
    let rating: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case imageUrl = "image_url"
        case price
        case rating
    }
}

struct CuisineModel: Identifiable, Codable {
    let cuisineId: String
    let cuisineName: String
    let cuisineImageUrl: String
    let items: [MenuItem]
    
    var id: String { cuisineId }
    
    enum CodingKeys: String, CodingKey {
        case cuisineId = "cuisine_id"
        case cuisineName = "cuisine_name"
        case cuisineImageUrl = "cuisine_image_url"
        case items
    }
}

struct APIResponse: Codable {
    let responseCode: Int
    let outcomeCode: Int
    let responseMessage: String
    let page: Int
    let count: Int
    let totalPages: Int
    let totalItems: Int
    let cuisines: [CuisineModel]
    
    enum CodingKeys: String, CodingKey {
        case responseCode = "response_code"
        case outcomeCode = "outcome_code"
        case responseMessage = "response_message"
        case page
        case count
        case totalPages = "total_pages"
        case totalItems = "total_items"
        case cuisines
    }
}