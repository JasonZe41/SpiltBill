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

import FirebaseAppCheck

class CustomAppCheckProvider: NSObject, AppCheckProvider {
    func getToken(completion: @escaping (AppCheckToken?, Error?) -> Void) {
        generateDeviceToken { tokenString, error in
            if let error = error {
                completion(nil, error)
            } else if let tokenString = tokenString {
                let expirationDate = Date().addingTimeInterval(60 * 60)
                let appCheckToken = AppCheckToken(token: tokenString, expirationDate: expirationDate)
                completion(appCheckToken, nil)
            }
        }
    }
    

    func generateDeviceToken(completion: @escaping (String?, Error?) -> Void) {
        guard DCDevice.current.isSupported else {
            completion(nil, NSError(domain: "DeviceCheckError", code: -1, userInfo: [NSLocalizedDescriptionKey: "DeviceCheck not supported"]))
            return
        }

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

class CustomAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        return CustomAppCheckProvider()
    }
}
