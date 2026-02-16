import Foundation

struct PasswordEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var username: String
    var password: String
    var url: String
    var notes: String
    var category: Category
    var createdAt: Date
    var modifiedAt: Date
    var isFavorite: Bool
    
    enum Category: String, Codable, CaseIterable, Identifiable {
        case login = "Login"
        case wifi = "Wi-Fi"
        case creditCard = "Credit Card"
        case secureNote = "Secure Note"
        case other = "Other"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .login: return "person.circle"
            case .wifi: return "wifi"
            case .creditCard: return "creditcard"
            case .secureNote: return "note.text"
            case .other: return "folder"
            }
        }
    }
    
    init(
        id: UUID = UUID(),
        title: String = "",
        username: String = "",
        password: String = "",
        url: String = "",
        notes: String = "",
        category: Category = .login,
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.username = username
        self.password = password
        self.url = url
        self.notes = notes
        self.category = category
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.isFavorite = isFavorite
    }
}
