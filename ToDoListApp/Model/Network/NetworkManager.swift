import Foundation

// MARK: - NetworkManager

final class NetworkManager {

    // MARK: - Singleton

    static let shared = NetworkManager()

    private init() {}

    // MARK: - Public Methods

    func fetchTodos(completion: @escaping (Result<[TodoItem], Error>) -> Void) {
        guard let url = URL(string: "https://dummyjson.com/todos") else {
            let error = NetworkError.invalidURL
            print("Network error: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }

        let request = URLRequest(url: url)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let data = data else {
                let error = NetworkError.noData
                print("Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(TodoResponse.self, from: data)
                completion(.success(decoded.todos))
            } catch {
                print("Decoding error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - NetworkError

enum NetworkError: LocalizedError {
    case invalidURL
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL недопустим."
        case .noData:
            return "Сервер вернул пустой ответ."
        }
    }
}
