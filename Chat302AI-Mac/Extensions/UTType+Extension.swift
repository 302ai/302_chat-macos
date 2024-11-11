//
//  UTType+Extension.swift
//  Chat302AI-Mac
//


import UniformTypeIdentifiers

extension UTType {
    static let mlpackage = UTType(filenameExtension: "mlpackage", conformingTo: .item)!
    static let mlmodelc = UTType(filenameExtension: "mlmodelc", conformingTo: .item)!
    static let gguf = UTType(filenameExtension: "gguf", conformingTo: .data)!
}


