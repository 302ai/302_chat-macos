//
//  OnboardingView.swift
//  Chat302AI-Mac
// 
import SwiftUI

struct OnboardingView: View {
    
    @Environment(CoordinatorModel.self) private var coordinator
    @AppStorage("userLoggedIn") private var userLoggedIn: Bool = false
    
    var body: some View {
        if !userLoggedIn {
            LogInView()
                .environment(coordinator)
        } else {
            SuccessView()
        }
    }
}

#Preview {
    OnboardingView()
        .frame(width: 300, height: 400)
        .environment(CoordinatorModel())
}
