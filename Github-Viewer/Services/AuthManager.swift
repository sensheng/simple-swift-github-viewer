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

protocol AuthManagerProtocol {
    var isLoggedIn: Bool { get }
    var accessToken: String? { get }
    var username: String? { get }
    
    func login(username: String, password: String, completion: @escaping (Result<Void, AuthError>) -> Void)
    func loginWithBiometry(completion: @escaping (Result<Void, AuthError>) -> Void)
    func logout()
    func saveCredentials(username: String, token: String)
    func isBiometryAvailable() -> Bool
    func getBiometryType() -> LABiometryType
}

enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case networkError(Error)
    case biometryNotAvailable
    case biometryNotEnrolled
    case biometryFailed
    case userCancel
    case keychainError(OSStatus)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "用户名或密码错误"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .biometryNotAvailable:
            return "生物识别不可用"
        case .biometryNotEnrolled:
            return "未设置生物识别"
        case .biometryFailed:
            return "生物识别验证失败"
        case .userCancel:
            return "用户取消操作"
        case .keychainError(let status):
            return "钥匙串错误: \(status)"
        case .unknownError:
            return "未知错误"
        }
    }
}

class AuthManager: AuthManagerProtocol {
    
    static let shared = AuthManager()
    
    private let keychain = KeychainManager()
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - Public Properties
    
    var isLoggedIn: Bool {
        return accessToken != nil
    }
    
    var accessToken: String? {
        return keychain.getString(for: Constants.KeychainKeys.accessToken)
    }
    
    var username: String? {
        return keychain.getString(for: Constants.KeychainKeys.username)
    }
    
    // MARK: - Authentication Methods
    
    func login(username: String, password: String, completion: @escaping (Result<Void, AuthError>) -> Void) {
        // Note: GitHub deprecated password authentication for API access
        // In a real app, you would use OAuth or Personal Access Tokens
        // For this demo, we'll simulate a successful login with a demo token
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // Simulate network delay
            Thread.sleep(forTimeInterval: 1.0)
            
            DispatchQueue.main.async {
                // For demo purposes, accept any non-empty credentials
                if !username.isEmpty && !password.isEmpty {
                    // Save demo credentials
                    self?.saveCredentials(username: username, token: "demo_token_\(username)")
                    completion(.success(()))
                } else {
                    completion(.failure(.invalidCredentials))
                }
            }
        }
    }
    
    func loginWithBiometry(completion: @escaping (Result<Void, AuthError>) -> Void) {
        guard isBiometryAvailable() else {
            completion(.failure(.biometryNotAvailable))
            return
        }
        
        guard let savedUsername = username else {
            completion(.failure(.invalidCredentials))
            return
        }
        
        let context = LAContext()
        let reason = "使用生物识别登录 GitHub Viewer"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    // Biometry authentication successful
                    // In a real app, you might need to refresh the token here
                    completion(.success(()))
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
    
    func logout() {
        keychain.delete(for: Constants.KeychainKeys.accessToken)
        keychain.delete(for: Constants.KeychainKeys.username)
        keychain.delete(for: Constants.KeychainKeys.userID)
        
        // Clear user-specific cache
        CacheManager.shared.clearCache()
        
        // Post logout notification
        NotificationCenter.default.post(name: .userDidLogout, object: nil)
    }
    
    func saveCredentials(username: String, token: String) {
        keychain.set(token, for: Constants.KeychainKeys.accessToken)
        keychain.set(username, for: Constants.KeychainKeys.username)
        
        // Post login notification
        NotificationCenter.default.post(name: .userDidLogin, object: nil)
    }
    
    // MARK: - Biometry Support
    
    func isBiometryAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) && isLoggedIn
    }
    
    func getBiometryType() -> LABiometryType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        return context.biometryType
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
            print("Keychain save error: \(status)")
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