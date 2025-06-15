import SwiftUI
import PhotosUI

struct AddRecipeView: View {
    @EnvironmentObject private var recipeService: RecipeService    // ← must have this

    @State private var mode = 0
    @State private var name = ""
    @State private var ingredientsText = ""
    @State private var instructions = ""
    @State private var freeform = ""

    @State private var photoPickerItem: PhotosPickerItem? = nil
    @State private var pickedImage: UIImage? = nil
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
                        VStack(spacing: 12) {
                            TextField("Name", text: $name)
                            TextField("Ingredients (comma-sep)", text: $ingredientsText)
                            TextEditor(text: $instructions)
                                .frame(height: 120)

                            Button(action: saveManual) {
                                Text("Save")
                                    .frame(maxWidth: .infinity)
                            }
                            .disabled(
                                name.isEmpty ||
                                ingredientsText.isEmpty ||
                                instructions.isEmpty
                            )
                        }
                    }
                }
                else if mode == 1 {
                    Section("Paste Your Recipe Text") {
                        VStack(spacing: 12) {
                            TextEditor(text: $freeform)
                                .frame(height: 150)

                            Button {
                                isLoading = true
                                recipeService.addFromText(freeform) { _ in
                                    isLoading = false
                                }
                            } label: {
                                Label(
                                    isLoading ? "Parsing…" : "Parse & Save",
                                    systemImage: isLoading
                                        ? "hourglass"
                                        : "arrow.turn.up.right"
                                )
                                .frame(maxWidth: .infinity)
                            }
                            .disabled(freeform.isEmpty)
                        }
                    }
                }
                else {
                    Section("Pick an Image") {
                        VStack(spacing: 12) {
                            PhotosPicker(
                                selection: $photoPickerItem,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                Text(
                                    pickedImage == nil
                                        ? "Select Photo"
                                        : "Change Photo"
                                )
                            }
                            .onChange(of: photoPickerItem) { newItem in
                                Task {
                                    if let data = try?
                                        await newItem?
                                            .loadTransferable(type: Data.self),
                                       let uiImg = UIImage(data: data) {
                                        pickedImage = uiImg
                                    }
                                }
                            }

                            if let img = pickedImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 150)
                            }

                            TextField(
                                "Description (optional)",
                                text: $imageDescription
                            )

                            Button {
                                guard let img = pickedImage else { return }
                                isLoading = true
                                recipeService.addFromImage(
                                    img,
                                    description: imageDescription
                                ) { _ in
                                    isLoading = false
                                }
                            } label: {
                                Text("Analyze & Save")
                                    .frame(maxWidth: .infinity)
                            }
                            .disabled(pickedImage == nil)
                        }
                    }
                }
            }
            .navigationTitle("Add Recipe")
        }
    }

    private func saveManual() {
        let ingredients = ingredientsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }

        recipeService.addManual(
            name: name,
            ingredients: ingredients,
            instructions: instructions
        ) { _ in }
    }
}
