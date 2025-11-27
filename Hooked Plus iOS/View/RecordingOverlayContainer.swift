//
//  RecordingOverlayContainer.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 11/2/25.
//

import SwiftUI

struct RecordingOverlayContainer<Content: View>: View {
    @ViewBuilder let content: () -> Content
    
    @State private var dragOffset: CGFloat = 0
    @State private var isRecordingShown = false
    
    private let maxDrag: CGFloat = 300
    private let threshold: CGFloat = 100
    
    // Calculate the full width of the screen once
    private let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        ZStack {
            // MARK: - BACKGROUND CAMERA VIEW
            RecordingCameraView(camera: HookedAssembly.resolver.resolve(CameraManager.self)!, onDismiss: hideCamera)
            .animation(.easeOut(duration: 0.2), value: isRecordingShown)
            .opacity(isRecordingShown ? 1 : 0)
            
            // ←←← INVISIBLE LEFT EDGE GRABBER
            .overlay(alignment: .leading) {
                Color.clear
                    .frame(width: 40)
                    .contentShape(Rectangle())
                    .allowsHitTesting(isRecordingShown)
            }
            .onChange(of: isRecordingShown, { oldValue, newValue in
                // Only check permission when the view is about to be shown
                if newValue {
                    HookedAssembly.resolver.resolve(CameraManager.self)?.checkPermission()
                }
            })
            
            // MARK: - FOREGROUND CONTENT (e.g., Tab Bar View)
            content()
                // Inject the closure into the environment for the content to use
                .environment(\.addStoryAction, showCamera) // <-- NEW: Allows content to call showCamera()
                .offset(x: dragOffset)
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: dragOffset)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    let width = value.translation.width
                    
                    // RIGHT swipe (open)
                    if width > 0 && !isRecordingShown {
                        dragOffset = width
                    }
                    
                    // LEFT swipe (close)
                    if width < 0 && isRecordingShown {
                        // The translation is negative, so we subtract its absolute value from the full width
                        dragOffset = screenWidth + width
                    }
                }
                .onEnded { value in
                    let width = value.translation.width
                    let velocity = value.predictedEndTranslation.width
                    
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        if isRecordingShown {
                            // Closing
                            if width < -threshold || velocity < -500 {
                                dragOffset = 0
                                isRecordingShown = false
                            } else {
                                dragOffset = screenWidth
                            }
                        } else {
                            // Opening
                            if width > threshold || velocity > 500 {
                                showCamera() // Use the helper function for consistency
                            } else {
                                dragOffset = 0
                            }
                        }
                    }
                }
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Helper function to open the camera view
    private func showCamera() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            dragOffset = screenWidth
            isRecordingShown = true
        }
    }
    
    private func hideCamera() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            dragOffset = 0
            isRecordingShown = false
        }
    }
}

// MARK: - Environment Key for Add Story Action
// This allows any subview within the content() to access the showCamera function.
struct AddStoryActionKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var addStoryAction: () -> Void {
        get { self[AddStoryActionKey.self] }
        set { self[AddStoryActionKey.self] = newValue }
    }
}
