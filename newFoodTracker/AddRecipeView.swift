import SwiftUI
import PhotosUI

struct AddRecipeView: View {
    @EnvironmentObject var recipeService: RecipeService
    @State private var mode = 0
    @State private var name = ""
    @State private var ingredientsText = ""
    @State private var instructions = ""
    @State private var freeform = ""
    @State private var pickedImage: UIImage?
    @State private var imageDescription = ""
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            Form {
                Picker("Mode", selection: $mode) {
                    Text("Manual").tag(0)
                    Text("From Text").tag(1)
                    Text("From Image").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())

                if mode == 0 {
                    Section("Manual Entry") {
                        TextField("Name", text: $name)
                        TextField("Ingredients (comma-sep)", text: $ingredientsText)
                        TextEditor(text: $instructions)
                            .frame(height: 120)
                        Button("Save") { saveManual() }
                    }

                } else if mode == 1 {
                    Section("Paste your recipe text") {
                        TextEditor(text: $freeform)
                            .frame(height: 150)
                        Button {
                            isLoading = true
                            recipeService.addFromText(freeform) { _ in
                                isLoading = false
                            }
                        } label: {
                            Label(isLoading ? "Parsing…" : "Parse & Save",
                                  systemImage: isLoading ? "hourglass" : "arrow.turn.up.right")
                        }
                    }

                } else {
                    Section("Pick an Image") {
                        PhotosPicker(
                            selection: $pickedImage,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            Text(pickedImage == nil ? "Select Photo" : "Change Photo")
                        }
                        if let img = pickedImage {
                            Image(uiImage: img).resizable()
                                .scaledToFit().frame(height: 150)
                        }
                        TextField("Description (optional)", text: $imageDescription)
                        Button("Analyze & Save") {
                            guard let img = pickedImage else { return }
                            isLoading = true
                            recipeService.addFromImage(img, description: imageDescription) { _ in
                                isLoading = false
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Recipe")
        }
    }

    private func saveManual() {
        let ingr = ingredientsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        recipeService.addManual(
            name: name,
            ingredients: ingr,
            instructions: instructions
        ) { _ in }
    }
}
