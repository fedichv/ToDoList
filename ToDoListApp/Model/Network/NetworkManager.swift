//
//  NetworkManager.swift
//  ToDoListApp
//
//  Created by Владимир Федичев on 8/3/25.
//

import Foundation


final class NetworkManager {
    static let shared = NetworkManager()

    private init() {}

    func fetchTodos(completion: @escaping (Result<[TodoItem], Error>) -> Void) {
        guard let url = URL(string: "https://dummyjson.com/todos") else {
            completion(.failure(NSError(domain: "InvalidURL", code: 0)))
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: 0)))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(TodoResponse.self, from: data)
                completion(.success(decoded.todos))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
