import SwiftUI
import CoreImage.CIFilterBuiltins
import FirebaseAuth

struct QRCodeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var userName: String {
        authManager.user?.displayName ?? "User"
    }

    var userId: String {
        authManager.user?.uid ?? ""
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Profile photo placeholder
                Circle()
                    .fill(Color(.systemGray4))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                    )

                // Scan to follow text
                Text("Scan to follow\n\(userName)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                // QR code
                if let qrImage = generateQRCode(from: "riverlog://profile/\(userId)") {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                } else {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(width: 200, height: 200)
                }

                // Copy Link button
                Button(action: {
                    UIPasteboard.general.string = "riverlog://profile/\(userId)"
                }) {
                    HStack {
                        Image(systemName: "link")
                        Text("Copy Link")
                    }
                    .font(.body.weight(.semibold))
                    .foregroundColor(Theme.primaryBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Theme.primaryBlue, lineWidth: 1.5)
                    )
                }
                .padding(.horizontal, 40)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("QR Code")
                        .font(.headline)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.primaryBlue)
                }
            }
        }
    }

    private func generateQRCode(from string: String) -> UIImage? {
        guard let data = string.data(using: .utf8) else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let outputImage = filter.outputImage else { return nil }

        let scale = 200.0 / outputImage.extent.width
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        let coloredImage = scaledImage.applyingFilter("CIFalseColor", parameters: [
            "inputColor0": CIColor(red: 0.2, green: 0.5, blue: 0.7),
            "inputColor1": CIColor.white
        ])

        guard let cgImage = context.createCGImage(coloredImage, from: coloredImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}
