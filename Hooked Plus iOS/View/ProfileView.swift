import SwiftUI
import FirebaseFirestore

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    @State private var firstNameInput: String = ""
    @State private var lastNameInput: String = ""

    init(viewModel: ProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack {
            Text("Profile")
                .font(.title)
                .foregroundColor(ColorToken.backgroundPrimary.color)
            
            if let userData = viewModel.state.data {
                VStack(spacing: 10) {
                    Text("Email: \(userData.email)")
                    Text("Name: \(userData.firstName) \(userData.lastName)")
//                    Text("Joined: \((userData.createdAt ?? Timestamp()).dateValue(), format: .dateTime)")
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
            }.buttonStyle(OutlineButtonStyle())
        }
        .padding()
        .onAppear {
            if case .success(let userData) = viewModel.state {
                firstNameInput = userData.firstName
                lastNameInput = userData.lastName
            }
        }
        .loading(isLoading: viewModel.state.isLoading())
        .background(ColorToken.backgroundPrimary.color)
//        .onChange(of: viewModel.state) { newState in
//            if case .success(let userData) = newState {
//                firstNameInput = userData.firstName ?? ""
//                lastNameInput = userData.lastName ?? ""
//            }
//        }
    }
}
