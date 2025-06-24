//
//  ErrorAlertViewModifier.swift
//  SupabaseLocalFirst
//
//  Created by Marcus Buexenstein on 6/23/25.
//

import SwiftUI

struct ErrorAlertViewModifier: ViewModifier {
    @Binding var errorMessage: String?
    
    @State private var isPresented = false
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $isPresented) {
                Button("Ok", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .onChange(of: errorMessage) {
                if errorMessage != nil {
                    isPresented.toggle()
                }
            }
    }
}

extension View {
    func errorAlert(errorMessage: Binding<String?>) -> some View {
        modifier(ErrorAlertViewModifier(errorMessage: errorMessage))
    }
}
