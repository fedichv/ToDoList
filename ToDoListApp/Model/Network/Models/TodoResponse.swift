import Foundation

struct TodoResponse: Decodable {
    let todos: [TodoItem]
}
