//
//  SpiltBillApp.swift
//  SpiltBill
//
//  Created by Jason Ze on 2024/4/12.
//

import SwiftUI
import FirebaseCore
import FirebaseAppCheck

/// AppDelegate is the custom class that handles the app's lifecycle events. It configures Firebase and sets up Firebase App Check.
class AppDelegate: NSObject, UIApplicationDelegate {
    
    /// Called when the application has finished launching. Configures Firebase and sets up Firebase App Check with a debug provider.
    /// - Parameters:
    ///   - application: The singleton app object.
    ///   - launchOptions: A dictionary indicating the reason the app was launched (if any).
    /// - Returns: A Boolean value indicating whether the app successfully handled the launch request.
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Set up Firebase App Check with a debug provider factory for testing.
        let providerFactory = AppCheckDebugProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)

        // Configure Firebase.
        FirebaseApp.configure()
        
        // Uncomment the following line to use a custom App Check provider factory if needed.
        // AppCheck.setAppCheckProviderFactory(CustomAppCheckProviderFactory())

        return true
    }
}

/// SpiltBillApp is the main entry point of the application, setting up the SwiftUI environment and providing the main content view.
@main
struct SpiltBillApp: App {
    
    // Connect the AppDelegate to handle app lifecycle events.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Create an instance of DataStore to be shared across the app.
    @StateObject var dataStore = DataStore()
    
    /// The body property defines the main scene of the application.
    var body: some Scene {
        WindowGroup {
            // Set up the main content view and inject the dataStore environment object.
            ContentView()
                .environmentObject(dataStore)
        }
    }
}
