//
//  TodoItem.swift
//  ToDoListApp
//
//  Created by Владимир Федичев on 8/3/25.
//
import Foundation

struct TodoItem: Decodable {
    let id: Int
    let todo: String
    let completed: Bool
    let userId: Int
}
