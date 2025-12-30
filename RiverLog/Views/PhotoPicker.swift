import SwiftUI
import PhotosUI

struct PhotoPicker: View {
    @Binding var selectedPhotos: [UIImage]
    @State private var photoPickerItems: [PhotosPickerItem] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PhotosPicker(selection: $photoPickerItems, maxSelectionCount: 10, matching: .images) {
                Label("Add Photos", systemImage: "photo.on.rectangle.angled")
            }
            
            if !selectedPhotos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(selectedPhotos.indices, id: \.self) { index in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: selectedPhotos[index])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                Button(action: {
                                    selectedPhotos.remove(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .padding(4)
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: photoPickerItems) { newItems in
            Task {
                selectedPhotos.removeAll()
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedPhotos.append(image)
                    }
                }
            }
        }
    }
}
