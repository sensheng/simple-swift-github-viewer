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

protocol AuthManagerProtocol {
    var isLoggedIn: Bool { get }
    var accessToken: String? { get }
    var username: String? { get }
    
    func loginWithToken(_ token: String, completion: @escaping (Result<GitHubUserProfile, AuthError>) -> Void)
    func loginWithBiometry(completion: @escaping (Result<GitHubUserProfile, AuthError>) -> Void)
    func logout()
    func saveCredentials(userProfile: GitHubUserProfile, token: String)
    func isBiometryAvailable() -> Bool
    func getBiometryType() -> LABiometryType
    func validateCurrentToken(completion: @escaping (Result<GitHubUserProfile, AuthError>) -> Void)
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
            return "Token 无效或已过期"
        case .tokenExpired:
            return "Token 已过期，请重新登录"
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
        case .apiError(let message):
            return message
        case .unknownError:
            return "未知错误"
        }
    }
}

class AuthManager: AuthManagerProtocol {
    
    static let shared = AuthManager()
    
    private let keychain = KeychainManager()
    private let apiService = GitHubAPIService.shared
    private var cancellables = Set<AnyCancellable>()
    
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
    
    func loginWithToken(_ token: String, completion: @escaping (Result<GitHubUserProfile, AuthError>) -> Void) {
        // Validate token by fetching user profile
        apiService.validateToken(token)
            .sink(
                receiveCompletion: { [weak self] completionResult in
                    switch completionResult {
                    case .failure(let error):
                        DispatchQueue.main.async {
                            if let apiError = error as? APIError {
                                switch apiError {
                                case .unauthorized:
                                    completion(.failure(.invalidToken))
                                case .forbidden:
                                    completion(.failure(.apiError("Token 权限不足，请检查权限设置")))
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
                receiveValue: { [weak self] userProfile in
                    DispatchQueue.main.async {
                        // Save credentials
                        self?.saveCredentials(userProfile: userProfile, token: token)
                        completion(.success(userProfile))
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func loginWithBiometry(completion: @escaping (Result<GitHubUserProfile, AuthError>) -> Void) {
        guard isBiometryAvailable() else {
            completion(.failure(.biometryNotAvailable))
            return
        }
        
        guard let savedToken = accessToken else {
            completion(.failure(.invalidToken))
            return
        }
        
        let context = LAContext()
        let reason = "使用生物识别登录 GitHub Viewer"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    // Validate current token
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
                                    completion(.failure(.apiError("Token 权限不足")))
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
        
        // Clear user-specific cache
        CacheManager.shared.clearCache()
        
        // Cancel any ongoing requests
        cancellables.removeAll()
        
        // Post logout notification
        NotificationCenter.default.post(name: .userDidLogout, object: nil)
    }
    
    func saveCredentials(userProfile: GitHubUserProfile, token: String) {
        keychain.set(token, for: Constants.KeychainKeys.accessToken)
        keychain.set(userProfile.login, for: Constants.KeychainKeys.username)
        keychain.set(String(userProfile.id), for: Constants.KeychainKeys.userID)
        
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