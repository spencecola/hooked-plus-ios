import SwiftUI
import GoogleSignIn
import FirebaseAuth

// Main Login View
struct LoginView: View {
    @StateObject private var authManager = AuthManager()
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var errorMessage: String?
    @State private var currentView: ViewState = .signIn // Default to Sign In
    @State private var showEmailFields = false

    private enum ViewState {
        case signUp, signIn
    }

    var body: some View {
        VStack(spacing: 20) {
            switch currentView {
            case .signIn:
                SignInView(
                    email: $email,
                    password: $password,
                    errorMessage: $errorMessage,
                    authManager: authManager,
                    onSwitchToSignUp: {
                        currentView = .signUp
                        resetFields()
                    },
                    onSignIn: {
                        resetFields()
                    }
                )
            case .signUp:
                SignUpView(
                    firstName: $firstName,
                    lastName: $lastName,
                    email: $email,
                    password: $password,
                    errorMessage: $errorMessage,
                    showEmailFields: $showEmailFields,
                    authManager: authManager,
                    onSwitchToSignIn: {
                        currentView = .signIn
                        resetFields()
                    },
                    onSignUp: {
                        resetFields()
                    }
                )
            }

            Spacer()
        }
        .padding()
        .background(ColorToken.backgroundSecondary.color)
        .snackBar(isPresented: Binding(get: {
            errorMessage != nil
        }, set: { _ in
            // no op
        }), type: .error, message: errorMessage ?? "Something went wrong. Please try again.")
        .customNavBar(title: "Welcome")
    }

    private func resetFields() {
        email = ""
        password = ""
        firstName = ""
        lastName = ""
        errorMessage = nil
        showEmailFields = false
    }
}

// Sign Up View
struct SignUpView: View {
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var email: String
    @Binding var password: String
    @Binding var errorMessage: String?
    @Binding var showEmailFields: Bool
    let authManager: AuthManager
    let onSwitchToSignIn: () -> Void
    let onSignUp: () -> Void

    var body: some View {
        VStack(spacing: 15) {
            if !showEmailFields {
                signUpOptionsView
            } else {
                emailSignUpView
            }

            Button("Sign In") {
                onSwitchToSignIn()
            }
            .buttonStyle(TextButtonStyle())
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var signUpOptionsView: some View {
        VStack(spacing: 15) {
            Text("Sign Up")
                .font(.title2)
                .fontWeight(.semibold)

            TextField("First Name", text: $firstName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .autocapitalization(.words)
            TextField("Last Name", text: $lastName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .autocapitalization(.words)

            Divider()
            
            GoogleSignInButton(
                action: {
                    if firstName.isEmpty || lastName.isEmpty {
                        errorMessage = "Please enter your first and last name."
                    } else {
                        Task {
                            do {
                                try await authManager.signUpWithGoogle(firstName: firstName, lastName: lastName)
                                errorMessage = nil
                                onSignUp()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    }
                }
            )
            
            Button("Sign Up with Email") {
                if firstName.isEmpty || lastName.isEmpty {
                    errorMessage = "Please enter your first and last name."
                } else {
                    showEmailFields = true
                }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }

    @ViewBuilder
    private var emailSignUpView: some View {
        VStack(spacing: 15) {
            Text("Complete Sign Up")
                .font(.title2)
                .fontWeight(.semibold)

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button("Complete Sign Up") {
                if email.isEmpty || password.isEmpty {
                    errorMessage = "Please enter your email and password."
                } else {
                    Task {
                        do {
                            try await authManager.signUp(email: email, password: password, firstName: firstName, lastName: lastName)
                            errorMessage = nil
                            onSignUp()
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle())

            Button("Back to Sign Up Options") {
                showEmailFields = false
                email = ""
                password = ""
                errorMessage = nil
            }
            .buttonStyle(OutlineButtonStyle())
        }
    }
}

// Sign In View
struct SignInView: View {
    @Binding var email: String
    @Binding var password: String
    @Binding var errorMessage: String?
    let authManager: AuthManager
    let onSwitchToSignUp: () -> Void
    let onSignIn: () -> Void

    var body: some View {
        VStack(spacing: 15) {
            Text("Sign In")
                .font(.title2)
                .fontWeight(.semibold)
            
            GoogleSignInButton(
                action: {
                    Task {
                        do {
                            try await authManager.signInWithGoogle()
                            errorMessage = nil
                            onSignIn()
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            )
            
            Divider()

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .autocapitalization(.none)
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button("Sign In with Email") {
                if email.isEmpty || password.isEmpty {
                    errorMessage = "Please enter your email and password."
                } else {
                    Task {
                        do {
                            try await authManager.signIn(email: email, password: password)
                            errorMessage = nil
                            onSignIn()
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(PrimaryButtonStyle())

            Button("Sign Up") {
                onSwitchToSignUp()
            }
            .buttonStyle(TextButtonStyle())
        }
        .padding(.horizontal)
    }
}

// Reusable Google Sign-In Button
struct GoogleSignInButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image("google_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)

                Text("Continue with Google")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))        // ← Important!
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
            )
            .foregroundColor(.black)
        }
    }
}


struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .previewDevice("iPhone 14")
            .preferredColorScheme(.light)
    }
}
