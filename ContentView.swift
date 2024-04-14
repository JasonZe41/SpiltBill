//
//  ContentView.swift
//  SpiltBill
//
//  Created by Jason Ze on 2024/4/12.
//

import SwiftUI

struct ContentView: View {
    
    // used to track whether the user is authenticated or not
    @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
    
    
    var body: some View {
        NavigationView {
            if isAuthenticated {
                VStack {
                    Image(systemName: "globe")
                        .imageScale(.large)
                        .foregroundStyle(.tint)
                    Text("Hello, world!")
                }
                .padding()
            } else {
                        AuthenticationView(isAuthenticated: $isAuthenticated)
                    }
                }
        

    }
}

#Preview {
    ContentView()
}
