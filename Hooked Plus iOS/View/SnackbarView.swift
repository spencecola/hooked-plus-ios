import SwiftUI

enum SnackBarType {
    case success, error, info
    
    var backgroundColor: Color {
        switch self {
        case .success: return Color.green.opacity(0.85)
        case .error: return Color.red.opacity(0.85)
        case .info: return Color.blue.opacity(0.85)
        }
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.octagon.fill"
        case .info: return "info.circle.fill"
        }
    }
}

struct SnackBar: View {
    let message: String
    let type: SnackBarType
    var duration: TimeInterval
    var autoDismiss: Bool
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack {
            Spacer()
            if isShowing {
                HStack(spacing: 12) {
                    Image(systemName: type.icon)
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(type.backgroundColor)
                .cornerRadius(12)
                .shadow(radius: 4)
                .padding(.horizontal, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    // Auto-dismiss logic based on autoDismiss flag
                    if autoDismiss {
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            withAnimation {
                                isShowing = false
                            }
                        }
                    }
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isShowing)
    }
}

extension View {
    func snackBar(
        isPresented: Binding<Bool>,
        type: SnackBarType,
        message: String,
        duration: TimeInterval = 2.5,
        autoDismiss: Bool = true
    ) -> some View {
        ZStack {
            self
            SnackBar(message: message, type: type, duration: duration, autoDismiss: autoDismiss, isShowing: isPresented)
        }
    }
}
