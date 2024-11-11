//
//  AI302Model.swift
//  Chat302AI-Mac
//


import Foundation





final class AI302Model: Codable, Identifiable {
    
    let id: String
    let object: String
//    var preprompt: String
//    let unlisted: Bool
    
    
    init(
        id: String, object: String //, preprompt:String, unlisted: Bool
    ) {
        self.id = id
        self.object = object
//        self.preprompt = preprompt
//        self.unlisted = unlisted
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.object = try container.decode(String.self, forKey: .object) 
//        self.preprompt = try container.decode(String.self, forKey: .preprompt)
//        self.unlisted = try container.decode(Bool.self, forKey: .unlisted)
    }

}
 

extension AI302Model {
    
//    func toNewConversation() -> (AnyObject&Codable) {
        //return NewConversationFromModelRequestBody(model: id, preprompt: preprompt)
//    }
}
