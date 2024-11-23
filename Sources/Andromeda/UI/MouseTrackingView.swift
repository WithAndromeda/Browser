//
//  MouseTrackingView.swift
//  Andromeda
//
//  Created by WithAndromeda on 11/23/24.
//

import SwiftUI
import AppKit

class MouseTrackingView: NSView {
    var onMouseEntered: (() -> Void)?
    var onMouseExited: (() -> Void)?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupTracking()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTracking()
    }
    
    private func setupTracking() {
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways]
        let trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea)
    }
    
    override func mouseEntered(with event: NSEvent) {
        onMouseEntered?()
    }
    
    override func mouseExited(with event: NSEvent) {
        onMouseExited?()
    }
}

struct MouseTrackingViewRepresentable: NSViewRepresentable {
    var onMouseEntered: () -> Void
    var onMouseExited: () -> Void
    
    func makeNSView(context: Context) -> MouseTrackingView {
        let view = MouseTrackingView(frame: .zero)
        view.onMouseEntered = onMouseEntered
        view.onMouseExited = onMouseExited
        return view
    }
    
    func updateNSView(_ nsView: MouseTrackingView, context: Context) {}
}

