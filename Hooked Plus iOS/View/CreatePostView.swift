import SwiftUI
import PhotosUI
import Combine
import Alamofire
import CoreLocation
import MapKit

struct CreatePostView: View {
    @State private var description: String = ""
    @State private var weight: String = ""
    @State private var depth: String = ""
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var showingSpeciesSearch = false
    @State private var showLunkerConfirmation = false
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
                weight: $weight,
                depth: $depth,
                selectedItems: $selectedItems,
                selectedImages: $selectedImages,
                showingSpeciesSearch: $showingSpeciesSearch,
                showLunkerConfirmation: $showLunkerConfirmation,
                selectedSpecies: $selectedSpecies,
                showingCamera: $showingCamera,
                isUploading: $isUploading,
                isCatch: $isCatch,
                maxImages: maxImages,
                viewModel: viewModel,
                onCancel: { dismiss() },
                onPost: { _ in
                    viewModel.createPost(
                        isCatch: isCatch,
                        description: description,
                        photos: selectedItems,
                        species: selectedSpecies,
                        depth: depth,
                        weight: weight
                    )
                    dismiss()
                }
            )
            .navigationTitle("Create Post")
            .background(ColorToken.backgroundSecondary.color)
        }
    }
}

// Extracted content view to simplify the main view hierarchy
struct PostContentView: View {
    @Binding var description: String
    @Binding var weight: String
    @Binding var depth: String
    @Binding var selectedItems: [PhotosPickerItem]
    @Binding var selectedImages: [UIImage]
    @Binding var showingSpeciesSearch: Bool
    @Binding var showLunkerConfirmation: Bool
    @Binding var selectedSpecies: SpeciesData?
    @Binding var showingCamera: Bool
    @Binding var isUploading: Bool
    @Binding var isCatch: Bool
    let maxImages: Int
    let viewModel: FeedViewModel
    let onCancel: () -> Void
    let onPost: (Bool) -> Void // Bool represents submit for review
    
    
    // Computed property to safely parse the weight string
    private var parsedWeight: Double? {
        // Use a NumberFormatter for localized decimal parsing or a simple Double() conversion
        Double(weight.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    // Check if the parsed weight is 5.0 or greater
    private var isLunker: Bool {
        guard let w = parsedWeight else { return false }
        return w >= 5.0
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Is this a catch? question
                Toggle(isOn: $isCatch) {
                    Text("Is this a catch?")
                        .font(.headline)
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
                    LocationView(
                        depth: $depth,
                        weight: $weight,
                        location: viewModel.state.currentLocation,
                        authStatus: viewModel.state.locationAuthorization,
                        onRequestLocationPermission: viewModel.onRequestLocationPermission)
                    
                    SelectedSpeciesView(showSelectSpeciesView: $showingSpeciesSearch, selectedSpecies: $selectedSpecies)
                }
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post", action: {
                        if isLunker {
                            dismissKeyboard()
                            showLunkerConfirmation = true
                        } else {
                            onPost(false)
                        }
                    })
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
                .background(ColorToken.backgroundSecondary.color)
            }
            .sheet(isPresented: $showLunkerConfirmation) {
                HalfSheetView {
                    VStack(alignment: .center, spacing: 10) {
                        Text("Submit for review to be officially recognized")
                            .hookedText(font: .title2)
                        
                        ScrollView {
                            HStack(spacing: 10) {
                                buildImage("https://texassharelunker.com/media/images/SL_-_Required_Photo_1.width-500.jpg")
                                
                                buildImage("https://texassharelunker.com/media/images/SL_-_Required_Photo_2.width-500.jpg")
                                
                                buildImage("https://texassharelunker.com/media/images/SL_-_Optional_Photo_3.width-500.jpg")
                            }.frame(height: 140)
                        }
                        
                        // TODO: add pictures and scrolling HStack to show photo angles
                        Spacer()
                        
                        Button("Post for Review") {
                            onPost(true)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        
                        Button("Post Without Review") {
                            onPost(false)
                        }
                        .buttonStyle(OutlineButtonStyle())
                    }
                    .padding(16)
                }
            }
            .loading(isLoading: viewModel.state.loading)
            .background(ColorToken.backgroundSecondary.color)
        }
    }
    
    @ViewBuilder
    func buildImage(_ url: String) -> some View {
        GeometryReader { geo in
            CachedAsyncImage(url: URL(string: url)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                    
                case .failure(_):
                    Color.gray
                        .overlay(
                            Image(systemName: "photo.fill")
                                .font(.title)
                                .foregroundColor(.white)
                        )
                    
                case .empty:
                    // Keeps same layout even before loading
                    Color.gray
                        .overlay(ProgressView())
                }
            }
        }
    }
}

// Extracted description input view
struct DescriptionInputView: View {
    @Binding var description: String
    @Binding var isCatch: Bool
    
    var body: some View {
        TextField(isCatch ? "Describe your catch" : "What's on your mind?", text: $description, axis: .vertical)
            .textFieldStyle(RoundedBorderTextFieldStyle())
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
            Text("\(weather.formattedTemperature) \(weather.formattedWind)").font(.title2)
        }
    }
}

struct LocationView: View {
    @State private var placeName: String = "Fetching location..."
    @State private var isRequestingPermission = false
    
    // Bindings from parent PostContentView
    @Binding var depth: String
    @Binding var weight: String
    
    // Data passed from parent
    let location: CLLocation?
    let authStatus: CLAuthorizationStatus?
    var onRequestLocationPermission: () -> Void
    
    // MARK: - Initializer (For clarity, though not strictly required in modern SwiftUI)
    init(depth: Binding<String>, weight: Binding<String>, location: CLLocation?, authStatus: CLAuthorizationStatus?, onRequestLocationPermission: @escaping () -> Void) {
        _depth = depth
        _weight = weight
        self.location = location
        self.authStatus = authStatus
        self.onRequestLocationPermission = onRequestLocationPermission
    }
    
    // MARK: - Authorization Computed Properties
    private var shouldRequestPermission: Bool {
        authStatus == .notDetermined
    }
    
    private var shouldShowSettings: Bool {
        [CLAuthorizationStatus.denied, .restricted].contains(authStatus ?? .authorizedAlways)
    }
    
    private var authorizationMessage: String {
        switch authStatus {
        case .notDetermined: return "Tap to enable location"
        case .denied, .restricted: return "Location access denied"
        case .authorizedWhenInUse, .authorizedAlways: return "Fetching location..."
        default: return "Location unavailable"
        }
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            // Map, Depth, and Weight Input Fields
            HStack {
                locationContent
                VStack(alignment: .leading) {
                    locationInfo
                    TextField("Depth in feet", text: $depth)
                        .keyboardType(.decimalPad)
                        .textContentType(.none)
                    TextField("Weight in pounds", text: $weight)
                        .keyboardType(.decimalPad)
                        .textContentType(.none)
                }
            }
        }
        .onAppear {
            updatePlaceNameIfPossible()
        }
    }
    
    // MARK: - Location Content
    @ViewBuilder
    private var locationContent: some View {
        if let coordinate = location?.coordinate {
            Map(coordinateRegion: .constant(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )), annotationItems: [LocationPin(coordinate: coordinate)]) { pin in
                MapMarker(coordinate: pin.coordinate, tint: .red)
            }
            .frame(height: 100)
            .cornerRadius(8)
        } else if shouldRequestPermission {
            permissionRequestView
        } else if shouldShowSettings {
            settingsView
        } else {
            ProgressView()
                .frame(height: 100)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Permission Request View
    private var permissionRequestView: some View {
        Button(action: requestLocationPermission) {
            VStack {
                Image(systemName: "location.circle")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text(authorizationMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .disabled(isRequestingPermission)
    }
    
    // MARK: - Settings View
    private var settingsView: some View {
        Button(action: openSettings) {
            VStack {
                Image(systemName: "location.slash")
                    .font(.title2)
                    .foregroundColor(.orange)
                Text(authorizationMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Tap to enable in Settings")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Location Info
    @ViewBuilder
    private var locationInfo: some View {
        Group {
            if shouldRequestPermission || shouldShowSettings {
                Text(authorizationMessage)
                    .foregroundColor(.secondary)
            } else {
                Text(placeName)
                    .lineLimit(2)
            }
        }
    }
    
    // MARK: - Actions
    private func requestLocationPermission() {
        guard !isRequestingPermission else { return }
        isRequestingPermission = true
        onRequestLocationPermission()
        isRequestingPermission = false
    }
    
    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func updatePlaceNameIfPossible() {
        guard let coordinate = location?.coordinate,
              authStatus == .authorizedWhenInUse || authStatus == .authorizedAlways else {
            return
        }
        fetchPlaceName(for: coordinate)
    }
    
    // MARK: - Geocoding
    private func fetchPlaceName(for coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Geocoding error: \(error.localizedDescription)")
                    self.placeName = "Unknown location"
                    return
                }
                
                if let placemark = placemarks?.first {
                    let name = placemark.name ?? placemark.locality ?? placemark.administrativeArea ?? "Unknown location"
                    self.placeName = name
                } else {
                    self.placeName = "Unknown location"
                }
            }
        }
    }
}

struct SelectedSpeciesView: View {
    @Binding var showSelectSpeciesView: Bool
    @Binding var selectedSpecies: SpeciesData?
    
    var body: some View {
        Button(selectedSpecies?.englishName ?? "No species selected") {
            showSelectSpeciesView = true
        }.buttonStyle(OutlineButtonStyle())
            .padding(.horizontal, 8)
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
