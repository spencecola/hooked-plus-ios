import SwiftUI
import FirebaseFirestore
import PhotosUI

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    @State private var firstNameInput: String = ""
    @State private var lastNameInput: String = ""
    @State private var showFriendsSheet: Bool = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    
    init(viewModel: ProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack {
            if let userData = viewModel.state.data {
                VStack(spacing: 10) {
                    // Profile Icon
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Group {
                            if let profileIcon = userData.profileIcon, let url = URL(string: profileIcon) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                                } placeholder: {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.gray)
                                }
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.gray)
                            }
                        }
                        .overlay(
                            Image(systemName: "pencil.circle.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.7)))
                                .offset(x: 35, y: 35)
                        )
                    }
                    .onChange(of: selectedPhotoItem) { newItem in
                        if let newItem = newItem {
                            Task {
                                await viewModel.setProfileIcon(selectedItem: newItem)
                            }
                        }
                    }
                    
                    // Find friends
                    Button("Find Friends") {
                        showFriendsSheet = true
                    }.buttonStyle(PrimaryButtonStyle())
                    
                    Text("Email: \(userData.email)")
                    Text("Name: \(userData.firstName) \(userData.lastName)")
                    TextField("First Name", text: $firstNameInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .onChange(of: firstNameInput) { newValue in
                            viewModel.setFirstName(firstName: newValue)
                        }
                    TextField("Last Name", text: $lastNameInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .onChange(of: lastNameInput) { newValue in
                            viewModel.setLastName(lastName: newValue)
                        }
                }
            }
            
            Button("Sign Out") {
                viewModel.signout()
            }.buttonStyle(OutlineButtonStyle(backgroundColor: ColorToken.buttonDanger.color))
        }
        .padding()
        .onAppear {
            if case .success(let userData) = viewModel.state {
                firstNameInput = userData.firstName
                lastNameInput = userData.lastName
            }
        }
        .navigationTitle("Profile")
        .loading(isLoading: viewModel.state.isLoading())
        .sheet(isPresented: $showFriendsSheet) {
            FindFriendsView()
        }
    }
}
