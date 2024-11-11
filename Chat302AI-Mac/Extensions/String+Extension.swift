//
//  String+Extension.swift
//  Chat302AI-Mac
//


import Foundation

extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}
