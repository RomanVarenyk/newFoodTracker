//
//  ShoppingListView.swift
//  newFoodTracker
//
//  Created by Roman Bystriakov on 26/5/25.
//


import SwiftUI

struct ShoppingListView: View {
    let list: [String: Int]

    var body: some View {
        NavigationView {
            List(list.sorted(by: { $0.key < $1.key }), id: \.key) { key, count in
                HStack {
                    Text(key)
                    Spacer()
                    Text("×\(count)")
                }
            }
            .navigationTitle("Shopping List")
        }
    }
}
