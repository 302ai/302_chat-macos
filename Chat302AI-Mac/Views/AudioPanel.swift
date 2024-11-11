//
//  AudioPanel.swift
//  Chat302AI-Mac
//

import Foundation
import AppKit

class ToastPanel: FloatingPanel {
    override init(contentRect: NSRect, backing: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, backing: backing, defer: flag)
        self.setFrameAutosaveName("hfToastPanel")
    }
    
    override func resignMain() {}
    
//    override func windowDidResignKey(_ notification: Notification) { }
}
