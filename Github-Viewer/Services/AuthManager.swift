//
//  AuthManager.swift
//  Github-Viewer
//
//  Created by Xu Sensheng on 2026-01-14.
//  Copyright © 2026 Sensheng Xu. All rights reserved.
//

import Foundation
import Security
import LocalAuthentication
import Combine
import UIKit

protocol AuthManagerProtocol {
    var isLoggedIn: Bool { get }
    var accessToken: String? { get }
    var username: String? { get }
    var hasTokenSaved: Bool { get }
    
    func loginWithToken(_ token: String, completion: @escaping (Result<GitHubUserProfile, AuthError>) -> Void)
    func loginWithBiometry(completion: @escaping (Result<GitHubUserProfile, AuthError>) -> Void)
    func logout()
    func saveCredentials(userProfile: GitHubUserProfile, token: String, shouldSave: Bool)
    func saveCredentialsQuietly(userProfile: GitHubUserProfile, token: String, shouldSave: Bool)
    func isBiometryAvailable() -> Bool
    func getBiometryType() -> LABiometryType
    func validateCurrentToken(completion: @escaping (Result<GitHubUserProfile, AuthError>) -> Void)
    func checkForSavedToken() -> Bool
    func requestBiometryPermission(completion: @escaping (Result<Bool, AuthError>) -> Void)
}

enum AuthError: Error, LocalizedError {
    case invalidToken
    case tokenExpired
    case networkError(Error)
    case biometryNotAvailable
    case biometryNotEnrolled
    case biometryFailed
    case userCancel
    case keychainError(OSStatus)
    case apiError(String)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidToken:
            return NSLocalizedString("Token invalid or expired", comment: "Error message")
        case .tokenExpired:
            return NSLocalizedString("Token expired, please login again", comment: "Error message")
        case .networkError(let error):
            return String(format: NSLocalizedString("Network error: %@", comment: "Error message with parameter"), error.localizedDescription)
        case .biometryNotAvailable:
            return NSLocalizedString("Biometry not available", comment: "Error message")
        case .biometryNotEnrolled:
            return NSLocalizedString("Biometry not enrolled", comment: "Error message")
        case .biometryFailed:
            return NSLocalizedString("Biometry authentication failed", comment: "Biometry authentication failed")
        case .userCancel:
            return NSLocalizedString("User cancelled", comment: "Error message")
        case .keychainError(let status):
            return String(format: NSLocalizedString("Keychain error: %d", comment: "Error message with parameter"), status)
        case .apiError(let message):
            return message
        case .unknownError:
            return NSLocalizedString("Unknown error", comment: "Error message")
        }
    }
}

class AuthManager: AuthManagerProtocol {
    
    static let shared = AuthManager()
    
    private let keychain = KeychainManager()
    private let apiService = GitHubAPIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private var temporaryToken: String?
    private var hasEverSavedToken: Bool = false
    
    private init() {
        // 初始化时检查是否曾经保存过token
        let tokenSavedFlag = keychain.getString(for: Constants.KeychainKeys.tokenSaved)
        hasEverSavedToken = tokenSavedFlag == "true"
        
        if tokenSavedFlag == "temporary" {
            keychain.delete(for: Constants.KeychainKeys.accessToken)
            keychain.delete(for: Constants.KeychainKeys.username)
            keychain.delete(for: Constants.KeychainKeys.userID)
            keychain.delete(for: Constants.KeychainKeys.tokenSaved)
        }
        
        let deviceType = UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        print("🔍 [AuthManager] init - Device: \(deviceType), hasEverSavedToken: \(hasEverSavedToken)")
    }
    
    // MARK: - Public Properties
    
    var isLoggedIn: Bool {
        return accessToken != nil
    }
    
    var accessToken: String? {
        let keychainToken = keychain.getString(for: Constants.KeychainKeys.accessToken)
        let finalToken = keychainToken ?? temporaryToken
        
        return finalToken
    }
    
    var username: String? {
        return keychain.getString(for: Constants.KeychainKeys.username)
    }
    
    var hasTokenSaved: Bool {
        return keychain.getString(for: Constants.KeychainKeys.tokenSaved) == "true"
    }
    
    // MARK: - Authentication Methods
    
    func loginWithToken(_ token: String, completion: @escaping (Result<GitHubUserProfile, AuthError>) -> Void) {
        // Validate token by fetching user profile
        apiService.validateToken(token)
            .sink(
                receiveCompletion: { completionResult in
                    switch completionResult {
                    case .failure(let error):
                        DispatchQueue.main.async {
                            if let apiError = error as? APIError {
                                switch apiError {
                                case .unauthorized:
                                    completion(.failure(.invalidToken))
                                case .forbidden:
                                    completion(.failure(.apiError(NSLocalizedString("Token permissions insufficient, please check permission settings", comment: "Token permission error"))))
                                case .serverError(let message):
                                    completion(.failure(.apiError(message)))
                                default:
                                    completion(.failure(.networkError(error)))
                                }
                            } else {
                                completion(.failure(.networkError(error)))
                            }
                        }
                    case .finished:
                        break
                    }
                },
                receiveValue: { userProfile in
                    DispatchQueue.main.async {
                        // 登录成功，但不立即保存Token，等待用户选择
                        completion(.success(userProfile))
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func loginWithBiometry(completion: @escaping (Result<GitHubUserProfile, AuthError>) -> Void) {
        let deviceType = UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        print("🔍 [AuthManager] loginWithBiometry called - Device: \(deviceType)")
        
        guard isBiometryAvailable() else {
            print("🔍 [AuthManager] Biometry not available - Device: \(deviceType)")
            completion(.failure(.biometryNotAvailable))
            return
        }
        
        let tokenSavedFlag = keychain.getString(for: Constants.KeychainKeys.tokenSaved)
        guard hasEverSavedToken || tokenSavedFlag == "true" || tokenSavedFlag == "temporary" else {
            completion(.failure(.invalidToken))
            return
        }
        
        let keychainToken = keychain.getString(for: Constants.KeychainKeys.accessToken)
        guard let token = keychainToken, !token.isEmpty else {
            completion(.failure(.apiError(NSLocalizedString("No saved login information found, please enter Token to login again", comment: "No saved login error"))))
            return
        }
        
        print("🔍 [AuthManager] Starting biometry authentication - Device: \(deviceType)")
        
        let context = LAContext()
        let reason = NSLocalizedString("Use biometric authentication to login to GitHub Viewer", comment: "Biometry login reason")
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    // 生物识别成功，验证保存的Token
                    self?.validateCurrentToken(completion: completion)
                } else {
                    if let error = error as? LAError {
                        switch error.code {
                        case .userCancel, .userFallback, .systemCancel:
                            completion(.failure(.userCancel))
                        case .biometryNotAvailable:
                            completion(.failure(.biometryNotAvailable))
                        case .biometryNotEnrolled:
                            completion(.failure(.biometryNotEnrolled))
                        default:
                            completion(.failure(.biometryFailed))
                        }
                    } else {
                        completion(.failure(.biometryFailed))
                    }
                }
            }
        }
    }
    
    func validateCurrentToken(completion: @escaping (Result<GitHubUserProfile, AuthError>) -> Void) {
        
        guard let token = accessToken else {
            completion(.failure(.invalidToken))
            return
        }
        
        apiService.getCurrentUser(token: token)
            .sink(
                receiveCompletion: { completionResult in
                    switch completionResult {
                    case .failure(let error):
                        DispatchQueue.main.async {
                            if let apiError = error as? APIError {
                                switch apiError {
                                case .unauthorized:
                                    completion(.failure(.tokenExpired))
                                case .forbidden:
                                    completion(.failure(.apiError(NSLocalizedString("Token permissions insufficient", comment: "Token permission error"))))
                                case .serverError(let message):
                                    completion(.failure(.apiError(message)))
                                default:
                                    completion(.failure(.networkError(error)))
                                }
                            } else {
                                completion(.failure(.networkError(error)))
                            }
                        }
                    case .finished:
                        break
                    }
                },
                receiveValue: { userProfile in
                    DispatchQueue.main.async {
                        completion(.success(userProfile))
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func logout() {
        keychain.delete(for: Constants.KeychainKeys.accessToken)
        keychain.delete(for: Constants.KeychainKeys.username)
        keychain.delete(for: Constants.KeychainKeys.userID)
        keychain.delete(for: Constants.KeychainKeys.tokenSaved)
        
        // Clear temporary token and reset saved token flag
        temporaryToken = nil
        hasEverSavedToken = false
        
        // Clear user-specific cache
        CacheManager.shared.clearCache()
        
        // Cancel any ongoing requests
        cancellables.removeAll()
        
        // Post logout notification
        NotificationCenter.default.post(name: .userDidLogout, object: nil)
    }
    
    func saveCredentials(userProfile: GitHubUserProfile, token: String, shouldSave: Bool) {
        saveCredentialsQuietly(userProfile: userProfile, token: token, shouldSave: shouldSave)
        
        // Post login notification
        NotificationCenter.default.post(name: .userDidLogin, object: nil)
    }
    
    func saveCredentialsQuietly(userProfile: GitHubUserProfile, token: String, shouldSave: Bool) {
        let deviceType = UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        
        keychain.set(token, for: Constants.KeychainKeys.accessToken)
        keychain.set(userProfile.login, for: Constants.KeychainKeys.username)
        keychain.set(String(userProfile.id), for: Constants.KeychainKeys.userID)
        
        if shouldSave {
            keychain.set("true", for: Constants.KeychainKeys.tokenSaved)
            hasEverSavedToken = true
            temporaryToken = nil  // 清除临时token
            print("🔍 [AuthManager] Token saved permanently - Device: \(deviceType)")
        } else {
            keychain.set("temporary", for: Constants.KeychainKeys.tokenSaved)
            temporaryToken = nil  // 不需要临时token，因为已经在keychain中了
            print("🔍 [AuthManager] Token saved temporarily (will be cleared on next startup) - Device: \(deviceType)")
        }
    }
    
    // MARK: - Biometry Support
    
    func isBiometryAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    func getBiometryType() -> LABiometryType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        return context.biometryType
    }
    
    func checkForSavedToken() -> Bool {
        let tokenSavedFlag = keychain.getString(for: Constants.KeychainKeys.tokenSaved)
        let everSaved = hasEverSavedToken || tokenSavedFlag == "true" || tokenSavedFlag == "temporary"
        
        return everSaved
    }
    
    func requestBiometryPermission(completion: @escaping (Result<Bool, AuthError>) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let error = error {
                switch error.code {
                case LAError.biometryNotAvailable.rawValue:
                    completion(.failure(.biometryNotAvailable))
                case LAError.biometryNotEnrolled.rawValue:
                    completion(.failure(.biometryNotEnrolled))
                default:
                    completion(.failure(.biometryFailed))
                }
            } else {
                completion(.failure(.biometryNotAvailable))
            }
            return
        }
        
        // Request for permission
        let reason = NSLocalizedString("Allow biometric authentication for quick login next time", comment: "Biometry setup reason")
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(.success(true))
                } else {
                    if let error = error as? LAError {
                        switch error.code {
                        case .userCancel, .userFallback, .systemCancel:
                            completion(.failure(.userCancel))
                        case .biometryNotAvailable:
                            completion(.failure(.biometryNotAvailable))
                        case .biometryNotEnrolled:
                            completion(.failure(.biometryNotEnrolled))
                        default:
                            completion(.failure(.biometryFailed))
                        }
                    } else {
                        completion(.failure(.biometryFailed))
                    }
                }
            }
        }
    }
}

// MARK: - Keychain Manager

private class KeychainManager {
    
    func set(_ value: String, for key: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("⚠️ Keychain save error: \(status)")
        }
    }
    
    func getString(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    func delete(for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let userDidLogin = Notification.Name("userDidLogin")
    static let userDidLogout = Notification.Name("userDidLogout")
}
