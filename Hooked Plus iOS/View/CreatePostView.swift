//
//  CreatePostView.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 9/14/25.
//

import SwiftUI
import PhotosUI

struct CreatePostView: View {
    @State private var description: String = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showingCamera = false
    @StateObject private var locationManager = LocationManager()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    TextField("What's on your mind?", text: $description, axis: .vertical)
                        .font(.body)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .cornerRadius(8)
                    }
                    
                    PhotosPicker("Select from Gallery", selection: $selectedItem, matching: .images)
                    
                    Button("Take Photo") {
                        showingCamera = true
                    }
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
                        // Placeholder for posting logic
                        print("Posting: \(description)")
                        if let location = locationManager.location {
                            print("Latitude: \(location.coordinate.latitude), Longitude: \(location.coordinate.longitude)")
                        }
                        if selectedImage != nil {
                            print("Image attached")
                        }
                        dismiss()
                    }
                    .disabled(description.isEmpty)
                }
            }
            .onAppear {
                locationManager.requestPermission()
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        selectedImage = UIImage(data: data)
                    }
                }
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(sourceType: .camera, selectedImage: $selectedImage)
                    .ignoresSafeArea()
            }
        }
    }
}

struct CreatePostView_Previews: PreviewProvider {
    static var previews: some View {
        CreatePostView()
    }
}
