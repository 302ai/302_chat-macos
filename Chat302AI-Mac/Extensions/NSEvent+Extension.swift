//
//  NSEvent+Extension.swift
//  Chat302AI-Mac
//

import Foundation
import AppKit

extension NSEvent {
    var isRightClickUp: Bool {
        let rightClick = (self.type == .rightMouseUp)
        let controlClick = self.modifierFlags.contains(.control)
        return rightClick || controlClick
    }
}
