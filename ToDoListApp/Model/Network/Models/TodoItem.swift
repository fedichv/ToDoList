import Foundation

struct TodoItem: Decodable {
    let id: Int
    let todo: String
    let completed: Bool
    let userId: Int
}
