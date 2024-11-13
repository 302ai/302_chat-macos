//
//  GeneralSettings.swift
//  Chat302AI-Mac
// 

import SwiftUI
import LaunchAtLogin
import KeyboardShortcuts
import Combine

struct GeneralSettingsView: View {
    
    @Environment(\.openWindow) private var openWindow
    @Environment(ModelManager.self) private var modelManager
    @Environment(ConversationViewModel.self) private var conversationManager
    
    //@State  var apiKey: String = (UserDefaults.standard.string(forKey: "apiKey") ?? "")
    
    @AppStorage("apiKey") private var apiKey: String = UserDefaults.standard.string(forKey: "apiKey") ?? ""
//    @State private var apiKey: String = UserDefaults.standard.string(forKey: "apiKey") ?? ""

    
    
    //@State var externalModels: [LLMModel] = []
    @State var externalAI302Models: [AI302Model] = []
    
    @State var cancellables = [AnyCancellable]()
    
    @State var debounceWorkItem: DispatchWorkItem?
    
    
    @AppStorage("userLoggedIn") private var userLoggedIn: Bool = false
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("hideDock") private var hideDock: Bool = false
    @AppStorage("localModel") private var selectedLocalModel: String = "None"
    @AppStorage("externalModel") private var selectedExternalModel: String = "gpt-4o-mini-2024-07-18"
    @AppStorage("useWebSearch") private var useWebSearch = false
    @AppStorage("chatClearInterval") private var chatClearInterval: String = "never"
    @AppStorage("isLocalGeneration") private var isLocalGeneration: Bool = false
    
    var body: some View {
        Form {
            Section("Account", content: {
                
                TextField("Api Key", text: $apiKey )
                    .textFieldStyle(.squareBorder)
                    .textFieldStyle(.plain)
                    .onChange(of: apiKey) { oldValue, newValue in
                        
                        print("Api Key:\(newValue)")
                        
                        UserDefaults.standard.set(newValue, forKey: "apiKey")
                        UserDefaults.standard.synchronize()
                        
                        fetchModels()
                    }
            })
            
            
            Section(content: {
                LabeledContent("Chat302:", content: {
                    Picker("", selection: $selectedExternalModel) {
                        ForEach(externalAI302Models, id: \.id) { option in
                            Text("\(option.id)")
                                .tag(option.id)
                        }
                    }
                    .disabled(false)
                    .onChange(of: selectedExternalModel) {
                        if let activeModel = externalAI302Models.first(where: { $0.id == selectedExternalModel }) {
                            
                            DataService.shared.setActiveAI302Model(ActiveAI302Model(model: activeModel))
                            
                            // Reset conversation and activate model
                            conversationManager.model = activeModel
                            conversationManager.stopGenerating()
                            conversationManager.reset()
                        }
                    }
                })
                //Toggle("Use web search", isOn: $useWebSearch)
                
                
            }, header: {
                Text("Server-Side Models")
            }, footer: {})
                    /**
                     {
                         Text("Server-side models are more suitable for general usage or complex queries, and will run on an external server. Toggling web search will enable the model to complement its answers with information queried from the web.")
                             .font(.footnote)
                             .frame(maxWidth: .infinity, alignment: .leading)
                             .multilineTextAlignment(.leading)
                             .lineLimit(nil)
                             .foregroundColor(.secondary)
                     })
                     */
            .disabled(false)
             
            
            Section(content: {
                KeyboardShortcuts.Recorder("302.AI Keyboard Shortcut:", name: .showFloatingPanel)
                KeyboardShortcuts.Recorder("Generation Mode Shortcut:", name: .toggleLocalGeneration)
                Toggle(isOn: $hideDock) {
                    Text("Hide dock icon")
                }
                LaunchAtLogin.Toggle {
                    Text("Open automatically at login")
                }
                Picker("Automatically clear chat after:", selection: $chatClearInterval) {
                    Text("15 minutes").tag("15min")
                    Text("1 hour").tag("1hour")
                    Text("1 day").tag("1day")
                    Text("Never").tag("never")
                }
                .onChange(of: hideDock) { oldValue, newValue in
                    if newValue == false {
                        NSApp.setActivationPolicy(.regular)
                    }
                }
            }, header: {
                Text("Miscellaneous")
            })
        }
        .onAppear {
            HuggingChatSession.shared.refreshLoginState()
            fetchModels()
            modelManager.fetchAllLocalModels()
        }
        .formStyle(.grouped)
    }
    
    
    
    // Helper methods
    func fetchModels() {
        
        
            debounceWorkItem?.cancel()
        
            debounceWorkItem = DispatchWorkItem {
                
            }
            // 在主队列中3秒后执行工作项
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: debounceWorkItem!)
        
        
        
        var elementsToRemove = ["dall-e-2",
         "dall-e-3",
         "tts-1",
         "tts-1-1106",
         "tts-1-hd",
         "tts-1-hd-1106",
         "gpt-4-gizmo-*",
         "text-embedding-3-large",
         "text-embedding-3-small",
         "text-embedding-ada-002",
         "Baichuan-Text-Embedding",
         "whisper-1",
         "generalv3.5",
         "4.0Ultra",
         "general",
         "whisper-large-v3",
         "BAAI/bge-large-zh-v1.5",
         "BAAI/bge-large-en-v1.5",
         "gpt-3.5-sonnet-cursor",
         "deepl",
         "gpt-4o-realtime-preview",
         "gpt-4o-realtime-preview-2024-10-01",
         "BAAI/bge-m3",
         "minimaxi_text2voice",
         "gpt-4o-audio-preview",
         "gpt-4o-audio-preview-2024-10-01"]
        
        DataService.shared.getAI302Models(shouldForceRefresh: false)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    print("Did finish fetching models")
                case .failure(let error):
                    print("Did fail fetching models:\n\(error)")
                }
            } receiveValue: { models in
                
                let mArr : [AI302Model] = models
                  
                print("getAI302Models:\(mArr.count)")
                let filteredModels = mArr.filter { model in
                    !elementsToRemove.contains(model.id)
                }
                
                externalAI302Models = filteredModels
                 
            }.store(in: &cancellables)
        
    
    
    }
}

#Preview {
    GeneralSettingsView()
        .environment(ConversationViewModel())
        .environment(ModelManager())
}
