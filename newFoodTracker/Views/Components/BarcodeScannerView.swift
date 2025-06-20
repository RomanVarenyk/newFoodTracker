import SwiftUI
import VisionKit

@available(iOS 16.0, *)
struct BarcodeScannerView: UIViewControllerRepresentable {
    var onScan: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let vc = DataScannerViewController(recognizedDataTypes: [.barcode()], isGuidanceEnabled: true)
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let parent: BarcodeScannerView
        init(_ parent: BarcodeScannerView) { self.parent = parent }
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            if case .barcode(let barcode) = item {
                parent.onScan(barcode.payloadStringValue ?? "")
                parent.dismiss()
            }
        }
    }
}

#if !available(iOS 16.0, *)
struct BarcodeScannerView: View {
    var onScan: (String) -> Void
    var body: some View {
        Text("Scanning not supported on this iOS version")
            .padding()
    }
}
#endif

