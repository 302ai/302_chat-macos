//
//  Chat302AI-Mac
//

import SwiftUI
import Combine
import Sparkle


@main
struct HuggingChat_MacApp: App {
    
    @State var coordinatorModel = CoordinatorModel()
    @State var hfChatSession = HuggingChatSession()
    @State var modelDownloader = ModelDownloader()
    
    @Environment(\.openWindow) private var openWindow
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("userLoggedIn") private var userLoggedIn: Bool = false
    @AppStorage("onboardingDone") private var onboardingDone: Bool = false
    @AppStorage("appearance") private var appearance: Appearance = .auto
    
    private let updaterController: SPUStandardUpdaterController
    
    init() {
        // If you want to start the updater manually, pass false to startingUpdater and call .startUpdater() later
        // This is where you can also pass an updater delegate if you need one
        updaterController = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: nil, userDriverDelegate: nil)
    }
    
    var body: some Scene {
  
        
        Window("Setting", id: "setting", content: {
            SettingsView()
                .environment(hfChatSession)
                .environment(appDelegate.themeEngine)
                .environment(appDelegate.conversationModel)
                .environment(appDelegate.modelManager)
                .environment(modelDownloader)
                .environment(appDelegate.audioModelManager)
                .preferredColorScheme(colorScheme(for: appearance))
        })
        .windowResizability(.contentSize)
        
        
        
        
        // About
        Window("About", id: "about", content: {
            AboutView()
                .frame(width: 450, height: 175)
            
                .toolbarBackground(.hidden, for: .windowToolbar)
            
                .preferredColorScheme(colorScheme(for: appearance))
        })
        .windowResizability(.contentSize)
        
        
        // Settings
        Settings {
            SettingsView()
                .environment(hfChatSession)
                .environment(appDelegate.themeEngine)
                .environment(appDelegate.conversationModel)
                .environment(appDelegate.modelManager)
                .environment(modelDownloader)
                .environment(appDelegate.audioModelManager)
                .preferredColorScheme(colorScheme(for: appearance))
            
        }
        .windowResizability(.contentSize)
        
        
        // Command Bar
        .commands {
            CommandGroup(after: .appSettings) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
            
            CommandGroup(replacing: CommandGroupPlacement.appInfo) {
                Button(action: {
                    for window in NSApplication.shared.windows {
                        if window.identifier?.rawValue == "about" {
                            window.makeKeyAndOrderFront(nil)
                            return
                        }
                        
                    }
                    openWindow(id: "about")
                    
                }) {
                    Text("About \(Bundle.main.appName)")
                }
            }
            
            CommandGroup(replacing: .help) {
                Button(action: {
                    openWindow(id: "login")
                }) {
                    Text("Open Login")
                }
            }
        }
    }
    
    private func colorScheme(for appearance: Appearance) -> ColorScheme? {
        switch appearance {
        case .light:
            return .light
        case .dark:
            return .dark
        case .auto:
            return nil
        }
    }
}
