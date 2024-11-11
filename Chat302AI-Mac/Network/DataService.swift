//
//  DataService.swift
//  Chat302AI-Mac
//
//  Created by Cyril Zakka on 8/23/24.
//

import Combine
import Foundation

final class ActiveModel: Codable {
    var id: String
    var isAssistant: Bool
    
    init(id: String, isAssistant: Bool) {
        self.id = id
        self.isAssistant = isAssistant
    }
    
    init(model: LLMModel) {
        self.id = model.id
        self.isAssistant = false
    }
    
    init(assistant: Assistant) {
        self.id = assistant.id
        self.isAssistant = true
    }
}

final class ActiveAI302Model: Codable {
    var id: String
    var isAssistant: Bool
    
    init(id: String, isAssistant: Bool) {
        self.id = id
        self.isAssistant = isAssistant
    }
    
    init(model: AI302Model) {
        self.id = model.id
        self.isAssistant = false
    }
    
    init(assistant: Assistant) {
        self.id = assistant.id
        self.isAssistant = true
    }
}




final class DataService {
    static let shared: DataService = DataService()

    private var conversations: [Conversation]?
    private(set) var activeModel: ActiveModel?
    private(set) var activeAI302Model: ActiveAI302Model?
    
    private var cancellables = [AnyCancellable]()

    init() {
        getModels(shouldForceRefresh: true).sink(
            receiveCompletion: { _ in }, receiveValue: { _ in }
        ).store(in: &cancellables)
        
        self.activeAI302Model = DataService.getLocalActiveAI302Model()
    }

    func setActiveModel(_ activeModel: ActiveModel) {
        self.activeModel = activeModel
        DataService.saveActiveModel(activeModel)
    }
    
    func setActiveAI302Model(_ activeModel: ActiveAI302Model) {
        self.activeAI302Model = activeModel
        DataService.saveActiveAI302Model(activeModel)
    }
    
    
    func saveModels(models: [LLMModel]) {
        DataService.saveModels(models)
    }

    func getModel(id: String) -> AnyPublisher<LLMModel, HFError> {
        return getModels().tryMap({ models in
            if let model = models.first(where: { $0.id == id }) {
                return model
            } else {
                throw HFError.modelNotFound
            }
        })
        .mapError({ error in
            guard let error = error as? HFError else {
                return HFError.unknown
            }
            return error
        })
        .eraseToAnyPublisher()
    }

    func getModels(shouldForceRefresh: Bool = false) -> AnyPublisher<[LLMModel], HFError> {
        if let models = DataService.getLocalModels(), !shouldForceRefresh {
            return Just(models).setFailureType(to: HFError.self).eraseToAnyPublisher()
        }

        return NetworkService.getModels().handleEvents(receiveOutput: { models in
            let localModels = DataService.getLocalModels()
            if let locals = localModels {
                for model in models {
                    guard let local = locals.first(where: { $0.id == model.id }) else { continue }
                    model.preprompt = local.preprompt
                }
            }

            DataService.saveModels(models)
        }).eraseToAnyPublisher()
    }
    
    func getAI302Models(shouldForceRefresh: Bool = false) -> AnyPublisher<[AI302Model], HFError> {
//        if let models = DataService.getLocalAI302Models(), !shouldForceRefresh {
//            return Just(models).setFailureType(to: HFError.self).eraseToAnyPublisher()
//        }

        return NetworkService.getAI302Models().handleEvents(receiveOutput: { models in
            let localModels = DataService.getLocalAI302Models()
            if let locals = localModels {
                for model in models {
                    //guard let local = locals.first(where: { $0.id == model.id }) else { continue }
                }
            }

            DataService.saveAI302Models(models)
        }).eraseToAnyPublisher()
    }
    
    func getActiveModel() -> AnyPublisher<AnyObject, HFError> {
        guard let activeModel = activeModel else {
            return getModels(shouldForceRefresh: false).tryMap { models in
                guard let model = models.first else {
                    throw HFError.unknown
                }
                
                return model
            }.mapError({ error in
                if let error = error as? HFError {
                    return error
                } else {
                    return HFError.unknown
                }
            }).eraseToAnyPublisher()
        }
        
        if activeModel.isAssistant {
            return NetworkService.getAssistant(id: activeModel.id).map { $0 as AnyObject }.eraseToAnyPublisher()
        } else if let model = DataService.getLocalModels()?.first(where: {$0.id == activeModel.id}) {
            return Just(model).setFailureType(to: HFError.self).eraseToAnyPublisher()
        } else {
            return Fail(outputType: AnyObject.self, failure: HFError.unknown).eraseToAnyPublisher()
        }
    }

    private static func getLocalModels() -> [LLMModel]? {
        guard let data = UserDefaults.standard.data(forKey: "models") else {
            return nil
        }
        do {
            let decoder = JSONDecoder()
            let models = try decoder.decode([LLMModel].self, from: data)
            return models
        } catch {
            print("Unable to Decode [LLModel] (\(error))")
            return nil
        }
    }

    static func getLocalAI302Models() -> [AI302Model]? {
        guard let data = UserDefaults.standard.data(forKey: "ai302models") else {
            return nil
        }
        do {
            let decoder = JSONDecoder()
            let models = try decoder.decode([AI302Model].self, from: data)
            return models
        } catch {
            print("Unable to Decode [AI302Model] (\(error))")
            return nil
        }
    }
    
    static func saveModels(_ models: [LLMModel]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(models)
            UserDefaults.standard.set(data, forKey: "models")
            
        } catch {
            print("Unable to Encode [LLModel] (\(error))")
        }
    }
    
    //MARK: 保存会话历史
    static func saveMessageHistory(_ msgs : [Stream302AIMessage]) {
        do {
            
            var hisArr = getMessageHistory()
            hisArr.append(contentsOf: msgs)
            
            
            let encoder = JSONEncoder()
            let data = try encoder.encode(hisArr)
            UserDefaults.standard.set(data, forKey: "stream_302ai_message")
            UserDefaults.standard.synchronize()
        } catch {
            print("Unable to Encode [LLModel] (\(error))")
        }
    }
    //MARK: 获取会话历史
    static func getMessageHistory() -> [Stream302AIMessage] {
        guard let data = UserDefaults.standard.data(forKey: "stream_302ai_message") else {
            return [Stream302AIMessage]()
        }
        do {
            let decoder = JSONDecoder()
            let models = try decoder.decode([Stream302AIMessage].self, from: data)
            return models
        } catch {
            print("Unable to Decode Active Model (\(error))")
            return  [Stream302AIMessage]()
        }
    }
    
    //MARK: 清除会话历史
    static func resetMessageHistory() {
        UserDefaults.standard.setValue(nil, forKey: "stream_302ai_message")
        UserDefaults.standard.synchronize()
    }
    
    static func saveAI302Models(_ models: [AI302Model]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(models)
            UserDefaults.standard.set(data, forKey: "ai302models")
        } catch {
            print("Unable to Encode [AI302Model] (\(error))")
        }
    }
    
    static func saveActiveModel(_ activeModel: ActiveModel) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(activeModel)
            UserDefaults.standard.set(data, forKey: "active_model")
        } catch {
            print("Unable to Encode Active Model (\(error))")
        }
    }
    
    static func saveActiveAI302Model(_ activeModel: ActiveAI302Model) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(activeModel)
            UserDefaults.standard.set(data, forKey: "active_ai302_model")
        } catch {
            print("Unable to Encode Active Model (\(error))")
        }
    }
    
    private static func getLocalActiveModel() -> ActiveModel? {
        guard let data = UserDefaults.standard.data(forKey: "active_model") else {
            return nil
        }
        do {
            let decoder = JSONDecoder()
            let activeModel = try decoder.decode(ActiveModel.self, from: data)
            return activeModel
        } catch {
            print("Unable to Decode Active Model (\(error))")
            return nil
        }
    }
    
    
    static func getLocalActiveAI302Model() -> ActiveAI302Model? {
        guard let data = UserDefaults.standard.data(forKey: "active_ai302_model") else {
            return nil
        }
        do {
            let decoder = JSONDecoder()
            let activeModel = try decoder.decode(ActiveAI302Model.self, from: data)
            return activeModel
        } catch {
            print("Unable to Decode Active Model (\(error))")
            return nil
        }
    }
    
    

    func resetLocalModels() {
        UserDefaults.standard.setValue(nil, forKey: "models")
        UserDefaults.standard.set(nil, forKey: "active_model")
        activeModel = nil
    }
    
    
    func resetLocalAI302Models() {
        UserDefaults.standard.setValue(nil, forKey: "models")
        UserDefaults.standard.set(nil, forKey: "active_ai302_model")
        activeModel = nil
    }
    
}
