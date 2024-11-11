//
//  URL+Extension.swift
//  Chat302AI-Mac
//


import UniformTypeIdentifiers

extension URL {
    
    var mimeType: String {
        return UTType(filenameExtension: self.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
    }
    
    func contains(_ uttype: UTType) -> Bool {
        return UTType(mimeType: self.mimeType)?.conforms(to: uttype) ?? false
    }

}
