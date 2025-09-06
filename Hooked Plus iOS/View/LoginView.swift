import SwiftUI
import GoogleSignIn
import FirebaseAuth

struct LoginView: View {
    @StateObject private var authManager = AuthManager()
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var errorMessage = ""
    @State private var showEmailFields = false // Controls email/password fields visibility

    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Welcome to Hooked Plus")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 20)

            // Authentication method buttons
            if !showEmailFields {
                VStack(spacing: 15) {
                    Button(action: {
                        showEmailFields = true // Show email/password fields
                    }) {
                        Text("Sign up with Email")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button(action: {
                        Task {
                            do {
                                try await authManager.signInWithGoogle()
                                errorMessage = ""
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    }) {
                        HStack {
                            Image("google_logo") // Add Google logo asset to your project
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                            Text("Sign in with Google")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal)
            } else {
                // Email/Password fields
                VStack(spacing: 15) {
                    TextField("First Name", text: $firstName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    TextField("Last Name", text: $lastName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .autocapitalization(.none)
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    HStack(spacing: 10) {
                        Button(action: {
                            Task {
                                do {
                                    try await authManager.signUp(email: email, password: password, firstName: firstName, lastName: lastName)
                                    errorMessage = ""
                                    showEmailFields = false // Reset view after success
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
                            }
                        }) {
                            Text("Sign Up")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                        Button(action: {
                            Task {
                                do {
                                    try await authManager.signIn(email: email, password: password)
                                    errorMessage = ""
                                    showEmailFields = false // Reset view after success
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
                            }
                        }) {
                            Text("Sign In")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)

                    Button(action: {
                        showEmailFields = false // Back to auth method selection
                        email = ""
                        password = ""
                        firstName = ""
                        lastName = ""
                        errorMessage = ""
                    }) {
                        Text("Back to Sign-In Options")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 10)
                }
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            Spacer()
        }
        .padding()
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
