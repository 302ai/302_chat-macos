//
//  IntroView.swift
//  Chat302AI-Mac
// 
import AuthenticationServices
import SwiftUI

struct LogInView: View {

    @State private var appleSignInSize = CGRect.zero
    
    @Environment(CoordinatorModel.self) private var coordinator
    @AppStorage("userLoggedIn") private var userLoggedIn: Bool = false
    
    var body: some View {
        ZStack {
            Color.white
            LinearGradient(gradient: Gradient(colors: [Color.yellow.opacity(0.4), Color.yellow.opacity(0.1), Color.yellow.opacity(0)]), startPoint: UnitPoint(x: 0.5, y: 0), endPoint: UnitPoint(x: 0.5, y: 1))
            VStack {
                HStack {
                    Image("huggy.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .symbolRenderingMode(.multicolor)
                        .background(Circle().fill(.black).frame(width: 20))
                        .frame(width: 32, height: 32)
                    Text("302.AI")
                        .font(.largeTitle)
                        .fontDesign(.rounded)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
                .padding(.top, 50)
                
                Text("Making the community's best AI chat models available to everyone.")
                    .font(.callout)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                Spacer()
                Button(action: {
                    coordinator.signin()
                }, label: {
                    Text("Sign up with HuggingFace 🤗")
                        .fontWeight(.medium)
                })
                .controlSize(.small)
                .buttonStyle(.plain)
                .frame(height: 45)
                .frame(maxWidth: .infinity)
                .foregroundStyle(.white)
                .background(RoundedRectangle(cornerRadius: 8).fill(.black))
                .padding(.top, 50)
                 
                
                Text("AI models can make mistakes. Please double-check responses.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
            }
            .padding()
        }
        .ignoresSafeArea(.container, edges: .top)
    }
    
    private func generateURL(from location: String, appleToken: String? = nil) -> URL? {
        var s_url = location
        if appleToken != nil {
            s_url = location.replacingOccurrences(of: "/oauth/authorize", with: "/login/apple")
            s_url = location.replacingOccurrences(of: "/oauth/authorize", with: "/login/apple")
        }
        guard var component = URLComponents(string: s_url) else { return nil }
        var queryItems = component.queryItems ?? []
        queryItems.append(URLQueryItem(name: "prompt", value: "login"))
        if let appleToken = appleToken {
            queryItems.append(URLQueryItem(name: "id_token", value: appleToken))
        }
        component.queryItems = queryItems

        return component.url
    }
}

#Preview {
    LogInView()
        .frame(width: 300, height: 400)
        .environment(CoordinatorModel())
}

