//
//  RecordingOverlayContainer.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 11/2/25.
//

import SwiftUI

struct RecordingOverlayContainer<Content: View>: View {
    @ViewBuilder let content: () -> Content
    
    @State private var dragOffset: CGFloat = 0
    @State private var isRecordingShown = false
    
    private let maxDrag: CGFloat = 300
    private let threshold: CGFloat = 100
    
    var body: some View {
        ZStack {
            RecordingCameraView(camera: HookedAssembly.resolver.resolve(CameraManager.self)!)
            .animation(.easeOut(duration: 0.2), value: isRecordingShown)
            .opacity(isRecordingShown ? 1 : 0)
            // ←←← INVISIBLE LEFT EDGE GRABBER (so you can start swipe from edge)
            .overlay(alignment: .leading) {
                Color.clear
                    .frame(width: 40)
                    .contentShape(Rectangle())
                    .allowsHitTesting(isRecordingShown)
            }.onChange(of: isRecordingShown, { oldValue, newValue in
                HookedAssembly.resolver.resolve(CameraManager.self)?.checkPermission()
            })
            
            // MARK: - FOREGROUND TAB BAR
            content()
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
                        if width > threshold { isRecordingShown = true }
                    }
                    
                    // LEFT swipe (close)
                    if width < 0 && isRecordingShown {
                        dragOffset = UIScreen.main.bounds.width + width
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
                                dragOffset = UIScreen.main.bounds.width
                            }
                        } else {
                            // Opening
                            if width > threshold || velocity > 500 {
                                dragOffset = UIScreen.main.bounds.width
                                isRecordingShown = true
                            } else {
                                dragOffset = 0
                            }
                        }
                    }
                }
        )
        .ignoresSafeArea()
    }
}
