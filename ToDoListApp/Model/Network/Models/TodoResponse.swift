//
//  TodoResponse.swift
//  ToDoListApp
//
//  Created by Владимир Федичев on 8/3/25.
//
import Foundation

struct TodoResponse: Decodable {
    let todos: [TodoItem]
}
