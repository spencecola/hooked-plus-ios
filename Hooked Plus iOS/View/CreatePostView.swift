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
    @State private var showingSpeciesSearch = false
    @State private var selectedSpecies: SpeciesData?
    @State private var showingCamera = false
    @State private var isUploading = false
    @State private var isCatch = true
    @StateObject private var viewModel: FeedViewModel
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
                showingSpeciesSearch: $showingSpeciesSearch,
                selectedSpecies: $selectedSpecies,
                showingCamera: $showingCamera,
                isUploading: $isUploading,
                isCatch: $isCatch,
                maxImages: maxImages,
                viewModel: viewModel,
                onCancel: { dismiss() },
                onPost: {
                    let location = viewModel.state.currentLocation?.coordinate
                    viewModel.createPost(
                        isCatch: isCatch,
                        description: description,
                        photos: selectedItems,
                        species: selectedSpecies
                    )
                    dismiss()
                }
            )
            .navigationTitle("Create Post")
        }
    }
}

// Extracted content view to simplify the main view hierarchy
struct PostContentView: View {
    @Binding var description: String
    @Binding var selectedItems: [PhotosPickerItem]
    @Binding var selectedImages: [UIImage]
    @Binding var showingSpeciesSearch: Bool
    @Binding var selectedSpecies: SpeciesData?
    @Binding var showingCamera: Bool
    @Binding var isUploading: Bool
    @Binding var isCatch: Bool
    let maxImages: Int
    let viewModel: FeedViewModel
    let onCancel: () -> Void
    let onPost: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Is this a catch? question
                VStack(alignment: .leading, spacing: 8) {
                    Text("Is this a catch?")
                        .font(.headline)
                    Picker("Is this a catch?", selection: $isCatch) {
                        Text("Yes").tag(true)
                        Text("No").tag(false)
                    }
                    .pickerStyle(.segmented)
                }
                
                DescriptionInputView(description: $description, isCatch: $isCatch)
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
                
                // Conditionally show views based on isCatch
                if isCatch {
                    WeatherView(weather: viewModel.state.currentWeather)
                    LocationView(location: viewModel.state.currentLocation)
                    SelectedSpeciesView(showSelectSpeciesView: $showingSpeciesSearch, selectedSpecies: $selectedSpecies)
                }
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
            .sheet(isPresented: $showingSpeciesSearch) {
                SpeciesSearchView(vm: SpeciesViewModel()) { species in
                    selectedSpecies = species
                    showingSpeciesSearch = false
                }
            }
            .loading(isLoading: viewModel.state.loading)
        }
    }
}

// Extracted description input view
struct DescriptionInputView: View {
    @Binding var description: String
    @Binding var isCatch: Bool
    
    var body: some View {
        TextField(isCatch ? "Describe your catch" : "What's on your mind?", text: $description, axis: .vertical)
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

struct WeatherView: View {
    var weather: WeatherData?
    
    var body: some View {
        if let weather {
            Text("\(weather.formattedTemperature) \(weather.formattedWind)")
        }
    }
}

// Extracted location map view
struct LocationView: View {
    @State private var placeName: String = "Fetching location..."
    @State private var depth: String = ""
    let location: CLLocation?
    
    var body: some View {
        HStack {
            if let coordinate = location?.coordinate {
                Map(coordinateRegion: .constant(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )), annotationItems: [LocationPin(coordinate: coordinate)]) { pin in
                    MapMarker(coordinate: pin.coordinate, tint: .red)
                }
                .frame(height: 100)
                .cornerRadius(8)
            } else {
                Text("Fetching location...")
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading) {
                Text(placeName)
                    .lineLimit(2)
                    .onAppear {
                        if let coordinate = location?.coordinate {
                            fetchPlaceName(for: coordinate)
                        }
                    }
                TextField("Depth", text: $depth)
                    .keyboardType(.numberPad)
                    .textContentType(.none)
            }
        }
    }
    
    private func fetchPlaceName(for coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                placeName = "Unknown location"
                return
            }
            
            if let placemark = placemarks?.first {
                let name = placemark.name ?? placemark.locality ?? placemark.administrativeArea ?? "Unknown location"
                placeName = name
            } else {
                placeName = "Unknown location"
            }
        }
    }
}

struct SelectedSpeciesView: View {
    @Binding var showSelectSpeciesView: Bool
    @Binding var selectedSpecies: SpeciesData?
    
    var body: some View {
        HStack {
            Text(selectedSpecies?.englishName ?? "No species selected")
                .font(.body)
                .foregroundColor(selectedSpecies != nil ? .primary : .gray)
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .onTapGesture {
            showSelectSpeciesView = true
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
