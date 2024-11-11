//
//  BaseConversation.swift
//  Chat302AI-Mac
//


import Foundation

protocol BaseConversation {
    var id: String { get }
    func toNewConversation() -> (AnyObject&Codable)
}
