//
//  SpiltBillApp.swift
//  SpiltBill
//
//  Created by Jason Ze on 2024/4/12.
//

import SwiftUI
import FirebaseCore
import FirebaseAppCheck


class AppDelegate: NSObject, UIApplicationDelegate {

    
    func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
    let providerFactory = AppCheckDebugProviderFactory()
    AppCheck.setAppCheckProviderFactory(providerFactory)

    FirebaseApp.configure()
        
//    AppCheck.setAppCheckProviderFactory(CustomAppCheckProviderFactory())


    return true
  }
}


@main
struct SpiltBillApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    

    @StateObject var dataStore = DataStore()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataStore)
        }
    }
}
