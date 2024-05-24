//
//  DeviceCheckProvider.swift
//  SpiltBill
//
//  Created by Jason Ze on 2024/4/19.
//

import Foundation
import DeviceCheck
import FirebaseAppCheck
import FirebaseCore

/// CustomAppCheckProvider is a custom class that implements the AppCheckProvider protocol to provide Firebase App Check tokens using Apple's DeviceCheck.
class CustomAppCheckProvider: NSObject, AppCheckProvider {
    
    /// Generates a Firebase App Check token using DeviceCheck and passes it to the completion handler.
    /// - Parameter completion: A closure to be called with the generated App Check token or an error if token generation fails.
    func getToken(completion: @escaping (AppCheckToken?, Error?) -> Void) {
        generateDeviceToken { tokenString, error in
            if let error = error {
                completion(nil, error)
            } else if let tokenString = tokenString {
                let expirationDate = Date().addingTimeInterval(60 * 60) // Token valid for 1 hour
                let appCheckToken = AppCheckToken(token: tokenString, expirationDate: expirationDate)
                completion(appCheckToken, nil)
            }
        }
    }
    
    /// Generates a device token using Apple's DeviceCheck and passes it to the completion handler.
    /// - Parameter completion: A closure to be called with the generated device token as a Base64 encoded string or an error if token generation fails.
    func generateDeviceToken(completion: @escaping (String?, Error?) -> Void) {
        // Ensure DeviceCheck is supported on the current device
        guard DCDevice.current.isSupported else {
            completion(nil, NSError(domain: "DeviceCheckError", code: -1, userInfo: [NSLocalizedDescriptionKey: "DeviceCheck not supported"]))
            return
        }

        // Generate the device token
        DCDevice.current.generateToken { token, error in
            if let error = error {
                completion(nil, error)
            } else if let token = token {
                let tokenString = token.base64EncodedString()
                completion(tokenString, nil)
            } else {
                completion(nil, NSError(domain: "DeviceCheckError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Token generation failed without error"]))
            }
        }
    }
}

/// CustomAppCheckProviderFactory is a custom class that implements the AppCheckProviderFactory protocol to create instances of CustomAppCheckProvider.
class CustomAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    
    /// Creates an instance of CustomAppCheckProvider.
    /// - Parameter app: The Firebase app for which the App Check provider is being created.
    /// - Returns: An instance of CustomAppCheckProvider.
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        return CustomAppCheckProvider()
    }
}
