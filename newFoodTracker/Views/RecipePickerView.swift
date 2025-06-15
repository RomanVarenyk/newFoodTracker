struct RecipePickerView: View {
    @EnvironmentObject var recipeService: RecipeService
    @Environment(\.dismiss) var dismiss

    let slot: MealPlanService.MealSlot
    let dayIndex: Int
    let onSelect: (Recipe) -> Void

    var body: some View {
        NavigationView {
            List {
                ForEach(recipeService.recipes) { recipe in
                    Button(recipe.name) {
                        onSelect(recipe)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Pick Recipe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}


// Helper struct for dynamic ingredient rows
struct IngredientEntry: Identifiable {
    let id = UUID()
    var name: String = ""
    var amount: String = ""
    var unit: String = ""
}

// ImagePicker for camera integration
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Font.subhead)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.brandPurple)
            .foregroundColor(.white)
            .cornerRadius(8)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

// MARK: - Add Recipe View

