import SwiftUI
import PhotosUI

import Combine
import Alamofire

struct CreatePostView: View {
    @State private var description: String = ""
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var showingCamera = false
    @StateObject private var viewModel: FeedViewModel
    @Environment(\.dismiss) private var dismiss
    
    private let maxImages = 5
    
    init(viewModel: FeedViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    TextField("What's on your mind?", text: $description, axis: .vertical)
                        .font(.body)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    if !selectedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(selectedImages, id: \.self) { image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 150, height: 150)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    PhotosPicker(
                        selectedImages.count < maxImages ? "Select from Gallery (\(maxImages - selectedImages.count) remaining)" : "Max images selected",
                        selection: $selectedItems,
                        maxSelectionCount: maxImages,
                        matching: .images
                    )
                    .disabled(selectedImages.count >= maxImages)
                    
                    Button("Take Photo") {
                        showingCamera = true
                    }
                    .disabled(selectedImages.count >= maxImages)
                }
                .padding()
            }
            .navigationTitle("Create Post")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        viewModel.createPost(description: description, photos: selectedItems)
                        dismiss()
                    }
                    .disabled(description.isEmpty || isUploading)
                }
            }
            .onChange(of: selectedItems) { newItems in
                Task {
                    selectedImages.removeAll()
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            selectedImages.append(image)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(sourceType: .camera, selectedImage: Binding(
                    get: { selectedImages.last },
                    set: { newImage in
                        if let newImage = newImage, selectedImages.count < maxImages {
                            selectedImages.append(newImage)
                        }
                    }
                ))
                .ignoresSafeArea()
            }
        }.loading(isLoading: viewModel.state.loading)
    }
    
    @State private var isUploading = false
    
}

//struct CreatePostView_Previews: PreviewProvider {
//    static var previews: some View {
//        CreatePostView()
//    }
//}
