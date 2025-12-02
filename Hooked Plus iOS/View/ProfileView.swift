import SwiftUI
import FirebaseFirestore
import PhotosUI

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    @State private var handleNameInput: String = ""
    @State private var firstNameInput: String = ""
    @State private var lastNameInput: String = ""
    @State private var showFindFriendsSheet: Bool = false
    @State private var showFriendsSheet: Bool = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    
    
    init(viewModel: ProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center) {
                if let userData = viewModel.state.data {
                    VStack(spacing: 10) {
                        // Profile Icon
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Group {
                                ProfileIconView(profileIconUrl: userData.profileIcon, size: 100)
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
                        .padding(16)
                        
                        Text(userData.email).hookedText(font: .title2)
                        
                        Text(userData.handleName).hookedText(color: ColorToken.textTertiary.color).padding(.horizontal, 8)
                    
                    }
                }
                
                VStack(spacing: 16) {
                    
                    buildNameCard()
                    
                    // Find friends
                    Button("Find Friends") {
                        showFindFriendsSheet = true
                    }.buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 8)
                    
                    Button("My Friends") {
                        showFriendsSheet = true
                    }.buttonStyle(OutlineButtonStyle())
                        .padding(.horizontal, 8)
                    
                    Button("Sign Out") {
                        viewModel.signout()
                    }.buttonStyle(OutlineButtonStyle(backgroundColor: ColorToken.buttonDanger.color))
                        .padding(.horizontal, 8)
                }
            }
        }
        .onChange(of: viewModel.state.data) { newUserData in
            // Check if the new data is successful and present
            if let userData = newUserData {
                // Only update the local @State if the values are different
                // to prevent potential infinite loops or unnecessary view updates.
                if firstNameInput != userData.firstName {
                    firstNameInput = userData.firstName
                }
                if lastNameInput != userData.lastName {
                    lastNameInput = userData.lastName
                }
            }
        }
        .loading(isLoading: viewModel.state.isLoading())
        .sheet(isPresented: $showFindFriendsSheet) {
            FindFriendsView()
        }
        .sheet(isPresented: $showFriendsSheet) {
            FriendHubView()
        }
        .refreshable {
            viewModel.refreshProfile()
        }
        .background(ColorToken.backgroundSecondary.color)
    }
    
    @ViewBuilder
    func buildNameCard() -> some View {
        // Use a ZStack or simply apply modifiers to the container (VStack)
        // to create the card effect.
        VStack(spacing: 12) {
            // --- First Name Field ---
            TextField("First Name", text: $firstNameInput)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 8) // Inner padding for the text itself
                .onChange(of: firstNameInput) { newValue in
                    viewModel.setFirstName(firstName: newValue)
                }
            
            // Optional: A divider for better visual separation
            Divider()
            
            // --- Last Name Field ---
            TextField("Last Name", text: $lastNameInput)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 8) // Inner padding for the text itself
                .onChange(of: lastNameInput) { newValue in
                    viewModel.setLastName(lastName: newValue)
                }
        }
        // --- Card Modifiers (Applied to the whole VStack) ---
        .padding(16) // Padding inside the card content
        .background(ColorToken.backgroundPrimary.color) // The card's background color
        .cornerRadius(10) // Rounded corners for the card
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2) // Subtle shadow
        .padding(.horizontal)
    }
}

struct ProfileIconView: View {
    var profileIconUrl: String?
    var size: CGFloat

    var body: some View {
        if let profileIconUrl = profileIconUrl, let url = URL(string: profileIconUrl) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    // Placeholder while loading
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                        .foregroundColor(.gray)

                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(ColorToken.buttonSecondary.color, lineWidth: 2))

                case .failure(_):
                    // Error placeholder
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                        .foregroundColor(.gray)
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            // Default placeholder if no URL
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundColor(.gray)
        }
    }
}

