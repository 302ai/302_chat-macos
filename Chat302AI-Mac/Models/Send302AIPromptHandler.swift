//
//  Send302AIPromptHandler.swift
//  Chat302AI-Mac
//
//  Created by Adswave on 2024/10/29.
//

import Combine
import SwiftUI
import Foundation
import AppKit
 
 
typealias AssistanContentBlock = (String) -> Void



final class Send302AIPromptHandler {
    
    var isDarkMode: Bool {
        guard let window = NSApp.keyWindow else {
            return NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        }
        return window.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }

    private static let throttleTime: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(100)
    private var privateUpdate: PassthroughSubject<StreamMessageType, HFError> = PassthroughSubject<
        StreamMessageType, HFError
    >()
    
    private var private302AIUpdate: PassthroughSubject<Stream302AIMessageType, HFError> = PassthroughSubject<
        Stream302AIMessageType, HFError
    >()
     
    
    var assistanContentBlock: (_ result: String)->Void = { (_ result: String)->Void in }
    
    private var responseMessage: String = ""
    private var currentTextCount: Int = 0
    private let conversationId: String

    private let parserThresholdTextCount = 0
    private var currentOutput: AttributedOutput?
    
    private var cancellables: [AnyCancellable] = []

    var messageRow: MessageRow
    
    private var postPrompt: PostStream? = PostStream()

    var update: AnyPublisher<MessageRow, HFError> {
        return private302AIUpdate
            .map({ [weak self] (messageType: Stream302AIMessageType) -> MessageRow? in
                guard let self else { fatalError() }
                return self.updateMessageRow(with: messageType)
            })
            .compactMap({  $0 })
            .eraseToAnyPublisher()
    }

    init(conversationId:String) {
        self.conversationId = conversationId
        self.messageRow = MessageRow(
            type: .assistant, isInteracting: true, contentType: .rawText(" "))
    }
    
    var tmpMessage: String = ""
    
    private let decoder: JSONDecoder = JSONDecoder()
    
    func sendPromptReq(reqBody: Prompt302AIRequestBody) {
        
        var req = reqBody
        let activeModel = DataService.getLocalActiveAI302Model()
        req.model = activeModel?.id
        req.assistantContent = self.tmpMessage 

        
        let userMsg = Stream302AIMessage(role:"user",content: req.inputs!)
        DataService.saveMessageHistory([userMsg])
        
        self.tmpMessage = ""
        postPrompt?.post302AIPrompt(reqBody: req, conversationId: conversationId).sink(receiveCompletion: { [weak self] completion in
            switch completion {
            case .finished:
                self?.private302AIUpdate.send(completion: .finished)
            case .failure(let error):
                print("error \(error)")
                self?.private302AIUpdate.send(completion: .failure(error))
            }
        }, receiveValue: { [weak self] (data: Data) in
             
            guard let self = self, let message = String(data: data, encoding: .utf8) else {
                return
            }
            let messages = message.split(separator: "\n\n")
            for m in messages {
                
                //去除字符--> data:
                let formattedString1 = m.replacingOccurrences(of: "data:", with: "")
                // 去除转义字符
                //let formattedString2 = formattedString1.replacingOccurrences(of: "\\\"", with: "\"")
 
                guard let mData = formattedString1.data(using: .utf8) else {
                    continue
                }
                
                guard let msg = try? self.decoder.decode(AI302Message.self, from: mData) else {
                    //print("\n decoder失败 \n ")
                    continue
                }
                
                // 访问 delta 字段
                if let firstChoice = msg.choices.first,
                   let delta = firstChoice.delta {
                    
                    if let content = delta.content,content != "" {
                        //print("Delta Content: \(content)")
                        
                        self.private302AIUpdate.send(Stream302AIMessageType.messageType(from: content)! )
                        self.tmpMessage = self.tmpMessage + content
                        //print("content:---->\(self.tmpMessage)")
                        
                    }else{
                        self.private302AIUpdate.send(Stream302AIMessageType.messageType(from: "")! )
                    }
                } else {
                    //print("会话结束")
                }
                  
            }
            self.assistanContentBlock(self.tmpMessage)
              
        }).store(in: &cancellables)
    }

    lazy var parsingTask = ResponseParsingTask(isDarkMode: isDarkMode)
    var attributedSend: AttributedOutput = AttributedOutput(string: "", results: [])

    private func updateMessageRow(with message: Stream302AIMessageType) -> MessageRow? {
        switch message {
        case .started:
            return messageRow
        case .webSearch(let update):
            if messageRow.webSearch == nil {
                messageRow.webSearch = WebSearch(message: "", sources: [])
            }
            switch update {
            case .message(let message):
                messageRow.webSearch?.message = message
            case .sources(let sources):
                messageRow.webSearch?.sources = sources
            }
            return messageRow
        case .token(let token):
            messageRow.webSearch?.message = "Completed"
            return updateMessage(with: token)
        case .skip:
            return nil
        }
    }
    
    private func updateMessage(with token: String) -> MessageRow {
        attributedSend = parsingTask.parse(text: token)
        responseMessage += token
        currentTextCount += token.count

        if currentTextCount >= parserThresholdTextCount || token.contains("```") {
            currentOutput = parsingTask.parse(text: responseMessage)
            currentTextCount = 0
        }

        if let currentOutput = currentOutput, !currentOutput.results.isEmpty {
            let suffixText = responseMessage.deletingPrefix(currentOutput.string)
            var results = currentOutput.results
            let lastResult = results[results.count - 1]
            let lastAttrString = lastResult.attributedString
            if case .codeBlock(_) = lastResult.resultType {
                lastAttrString.append(
                    NSMutableAttributedString(string:
                                            String(suffixText),
                                            attributes: .init([
                                                .font: NSFont.systemFont(ofSize: 12).apply(newTraits: .monoSpace),
                                                .foregroundColor: NSColor.white,
                                            ])))
            } else {
                lastAttrString.append(NSMutableAttributedString(string: String(suffixText)))
            }
            results[results.count - 1] = ParserResult(
                attributedString: lastAttrString, resultType: lastResult.resultType)
            messageRow.contentType = .attributed(.init(string: responseMessage, results: results))
        } else {
            messageRow.contentType = .attributed(
                .init(
                    string: responseMessage,
                    results: [
                        ParserResult(
                            attributedString: NSMutableAttributedString(string: responseMessage),
                            resultType: .text)
                    ]))
        }

        if let currentString = currentOutput?.string, currentString != responseMessage {
            let output = parsingTask.parse(text: responseMessage)
            messageRow.contentType = .attributed(output)
        }

        return messageRow
    }
    
    func cancel() {
        cancellables = []
        postPrompt = nil
    }

}

