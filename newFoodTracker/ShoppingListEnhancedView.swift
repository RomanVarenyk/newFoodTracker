//
//  ShoppingListEnhancedView.swift
//  newFoodTracker
//
//  Created by Roman Bystriakov on 26/5/25.
//


import SwiftUI

struct ShoppingListEnhancedView: View {
    let list: [String: Int]
    @State private var boughtItems: Set<String> = []
    @State private var showShare = false

    var body: some View {
        NavigationView {
            List {
                ForEach(list.sorted(by: { $0.key < $1.key }), id: \.key) { ingredient, count in
                    HStack {
                        Button(action: {
                            toggleBought(ingredient)
                        }) {
                            Image(systemName: boughtItems.contains(ingredient)
                                  ? "checkmark.circle.fill"
                                  : "circle")
                                .foregroundColor(.green)
                        }
                        Text("\(ingredient) ×\(count)")
                            .strikethrough(boughtItems.contains(ingredient))
                    }
                }
            }
            .navigationTitle("Shopping List")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showShare = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showShare) {
                ActivityView(activityItems: [exportText])
            }
        }
    }

    private func toggleBought(_ item: String) {
        if boughtItems.contains(item) { boughtItems.remove(item) }
        else { boughtItems.insert(item) }
    }

    private var exportText: String {
        list.map { "\($0.key) x\($0.value)" }
            .joined(separator: "\n")
    }
}

/// Wraps UIActivityViewController for sharing text.
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
    }
    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}
