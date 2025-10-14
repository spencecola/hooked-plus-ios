import SwiftUI
import PhotosUI
import Combine
import Alamofire
import CoreLocation
import MapKit

struct CreatePostView: View {
    @State private var description: String = ""
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var showingCamera = false
    @State private var isUploading = false
    @StateObject private var viewModel: FeedViewModel
    @StateObject private var locationManager = LocationManager()
    @Environment(\.dismiss) private var dismiss
    
    private let maxImages = 5
    
    init(viewModel: FeedViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            PostContentView(
                description: $description,
                selectedItems: $selectedItems,
                selectedImages: $selectedImages,
                showingCamera: $showingCamera,
                isUploading: $isUploading,
                maxImages: maxImages,
                viewModel: viewModel,
                locationManager: locationManager,
                onCancel: { dismiss() },
                onPost: {
                    let location = locationManager.currentLocation?.coordinate
                    viewModel.createPost(
                        description: description,
                        photos: selectedItems,
                        latitude: location?.latitude,
                        longitude: location?.longitude
                    )
                    dismiss()
                }
            )
            .navigationTitle("Create Post")
            .onAppear {
                locationManager.requestLocationPermission()
            }
        }
    }
}

// Extracted content view to simplify the main view hierarchy
struct PostContentView: View {
    @Binding var description: String
    @Binding var selectedItems: [PhotosPickerItem]
    @Binding var selectedImages: [UIImage]
    @Binding var showingCamera: Bool
    @Binding var isUploading: Bool
    let maxImages: Int
    let viewModel: FeedViewModel
    let locationManager: LocationManager
    let onCancel: () -> Void
    let onPost: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                DescriptionInputView(description: $description)
                ImagePreviewView(selectedImages: $selectedImages)
                PhotosPickerView(
                    selectedItems: $selectedItems,
                    maxImages: maxImages,
                    selectedImagesCount: selectedImages.count
                )
                CameraButtonView(
                    showingCamera: $showingCamera,
                    isDisabled: selectedImages.count >= maxImages
                )
                LocationMapView(locationManager: locationManager)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post", action: onPost)
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
            .loading(isLoading: viewModel.state.loading)
        }
    }
}

// Extracted description input view
struct DescriptionInputView: View {
    @Binding var description: String
    
    var body: some View {
        TextField("What's on your mind?", text: $description, axis: .vertical)
            .font(.body)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }
}

// Extracted image preview view
struct ImagePreviewView: View {
    @Binding var selectedImages: [UIImage]
    
    var body: some View {
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
    }
}

// Extracted photos picker view
struct PhotosPickerView: View {
    @Binding var selectedItems: [PhotosPickerItem]
    let maxImages: Int
    let selectedImagesCount: Int
    
    var body: some View {
        PhotosPicker(
            selectedImagesCount < maxImages ? "Select from Gallery (\(maxImages - selectedImagesCount) remaining)" : "Max images selected",
            selection: $selectedItems,
            maxSelectionCount: maxImages,
            matching: .images
        )
        .disabled(selectedImagesCount >= maxImages)
    }
}

// Extracted camera button view
struct CameraButtonView: View {
    @Binding var showingCamera: Bool
    let isDisabled: Bool
    
    var body: some View {
        Button("Take Photo") {
            showingCamera = true
        }
        .disabled(isDisabled)
    }
}

// Extracted location map view
struct LocationMapView: View {
    let locationManager: LocationManager
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Your Location")
                .font(.headline)
            if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
                if let coordinate = locationManager.currentLocation?.coordinate {
                    Map(coordinateRegion: .constant(MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )), annotationItems: [LocationPin(coordinate: coordinate)]) { pin in
                        MapMarker(coordinate: pin.coordinate, tint: .red)
                    }
                    .frame(height: 200)
                    .cornerRadius(8)
                } else {
                    Text("Fetching location...")
                        .foregroundColor(.gray)
                }
            } else if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                Text("Location access denied. Please enable in Settings.")
                    .foregroundColor(.red)
            } else {
                Button("Allow Location Access") {
                    locationManager.requestLocationPermission()
                }
            }
        }
    }
}

// Extend FeedViewModel to handle location in createPost (assuming it exists)
extension FeedViewModel {
    func createPost(description: String, photos: [PhotosPickerItem], latitude: Double? = nil, longitude: Double? = nil) {
        // Placeholder for actual implementation
    }
}

// Preview
struct CreatePostView_Previews: PreviewProvider {
    static var previews: some View {
        CreatePostView(viewModel: FeedViewModel(locationManager: LocationManager()))
            .frame(width: 300)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
