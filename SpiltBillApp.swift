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
    FirebaseApp.configure()
        
        if #available(iOS 14, *) {
               let providerFactory = DeviceCheckProviderFactory()
               AppCheck.setAppCheckProviderFactory(providerFactory)
           }

    return true
  }
}


@main
struct SpiltBillApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    

    
    var body: some Scene {
        WindowGroup {
            let dataStore = DataStore()
            ContentView()
                .environmentObject(dataStore)
        }
    }
}
