//
//  Prompt302AIRequestBody.swift
//  Chat302AI-Mac
//
//  Created by Adswave on 2024/10/29.
//

import Foundation

struct Prompt302AIRequestBody: Encodable {
    var model : String?
    var inputs: String?
    var assistantContent : String?
    
    init(model:String? = nil, inputs: String? = nil,assistantContent:String? = nil) {
        self.inputs = inputs
        self.model = model
        self.assistantContent = assistantContent
    }
}
