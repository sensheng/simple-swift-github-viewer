//
//  MeViewModel.swift
//  Github-Viewer
//
//  Created by Xu Sensheng on 2026-01-14.
//  Copyright © 2026 Sensheng Xu. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import LocalAuthentication

// MARK: - Login State

enum LoginState: Equatable {
    case notLoggedIn
    case loggingIn
    case loggedIn(GitHubUserProfile)
    case error(String)
    
    var isLoggedIn: Bool {
        if case .loggedIn = self {
            return true
        }
        return false
    }
}

// MARK: - Me ViewModel

class MeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var loginState: LoginState = .notLoggedIn
    @Published var accessToken: String = ""
    @Published var isLoading: Bool = false
    @Published var showBiometryLogin: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let authManager: AuthManagerProtocol
    private let apiService: GitHubAPIServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(authManager: AuthManagerProtocol = AuthManager.shared,
         apiService: GitHubAPIServiceProtocol = GitHubAPIService.shared) {
        self.authManager = authManager
        self.apiService = apiService
        
        setupBindings()
        checkInitialLoginState()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Listen for authentication notifications
        NotificationCenter.default.publisher(for: .userDidLogin)
            .sink { [weak self] _ in
                self?.handleLoginSuccess()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .userDidLogout)
            .sink { [weak self] _ in
                self?.handleLogout()
            }
            .store(in: &cancellables)
        
        // Update biometry availability
        $loginState
            .map { [weak self] state in
                guard let self = self else { return false }
                return !state.isLoggedIn && self.authManager.isBiometryAvailable()
            }
            .assign(to: \.showBiometryLogin, on: self)
            .store(in: &cancellables)
    }
    
    private func checkInitialLoginState() {
        if authManager.isLoggedIn {
            validateAndLoadProfile()
        } else {
            loginState = .notLoggedIn
        }
    }
    
    // MARK: - Public Methods
    
    func loginWithToken() {
        guard !accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "请输入有效的 Personal Access Token"
            return
        }
        
        let trimmedToken = accessToken.trimmingCharacters(in: .whitespacesAndNewlines)
        
        isLoading = true
        loginState = .loggingIn
        errorMessage = nil
        
        authManager.loginWithToken(trimmedToken) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let userProfile):
                    self?.loginState = .loggedIn(userProfile)
                    self?.accessToken = "" // Clear token from UI for security
                case .failure(let error):
                    self?.loginState = .error(error.localizedDescription)
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func loginWithBiometry() {
        isLoading = true
        errorMessage = nil
        
        authManager.loginWithBiometry { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let userProfile):
                    self?.loginState = .loggedIn(userProfile)
                case .failure(let error):
                    if case .userCancel = error {
                        // User cancelled, don't show error
                        return
                    }
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func logout() {
        authManager.logout()
        handleLogout()
    }
    
    func refreshProfile() {
        guard loginState.isLoggedIn else { return }
        validateAndLoadProfile()
    }
    
    func clearError() {
        errorMessage = nil
        if case .error = loginState {
            loginState = .notLoggedIn
        }
    }
    
    // MARK: - Private Methods
    
    private func handleLoginSuccess() {
        // Clear login form
        accessToken = ""
        
        // Profile is already loaded in loginWithToken, no need to reload
    }
    
    private func handleLogout() {
        loginState = .notLoggedIn
        accessToken = ""
        errorMessage = nil
    }
    
    private func validateAndLoadProfile() {
        isLoading = true
        
        authManager.validateCurrentToken { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let userProfile):
                    self?.loginState = .loggedIn(userProfile)
                case .failure(let error):
                    // Token is invalid or expired, logout
                    self?.authManager.logout()
                    self?.loginState = .error(error.localizedDescription)
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var biometryButtonTitle: String {
        switch authManager.getBiometryType() {
        case .faceID:
            return "使用 Face ID 登录"
        case .touchID:
            return "使用 Touch ID 登录"
        default:
            return "使用生物识别登录"
        }
    }
    
    var biometryIcon: String {
        switch authManager.getBiometryType() {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        default:
            return "person.fill.checkmark"
        }
    }
}