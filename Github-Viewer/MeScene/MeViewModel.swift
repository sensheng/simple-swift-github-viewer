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
    case waitingForSaveChoice(GitHubUserProfile)
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
    @Published var showTokenSaveAlert: Bool = false
    @Published var pendingUserProfile: GitHubUserProfile?
    @Published var pendingToken: String = ""
    
    // User repositories
    @Published var userRepositories: [GitHubRepository] = []
    @Published var isLoadingRepositories: Bool = false
    
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
                switch state {
                case .notLoggedIn:
                    return self.authManager.checkForSavedToken() && self.authManager.isBiometryAvailable()
                default:
                    return false
                }
            }
            .assign(to: \.showBiometryLogin, on: self)
            .store(in: &cancellables)
        
        $showTokenSaveAlert
            .sink { isShowing in
                // Do nothing
            }
            .store(in: &cancellables)
    }
    
    private func checkInitialLoginState() {
        if authManager.checkForSavedToken() && authManager.isBiometryAvailable() {
            // If we have a saved token and biometry is available, 
            // automatically prompt for biometric authentication
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.loginWithBiometry()
            }
        } else {
            loginState = .notLoggedIn
        }
    }
    
    private func validateCurrentTokenSilently() {
        // This method is no longer used for initial login
        // Keep it for manual refresh operations
        guard (authManager.accessToken) != nil else {
            loginState = .notLoggedIn
            return
        }
        
        // Validate token silently in background
        authManager.validateCurrentToken { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let userProfile):
                    self?.loginState = .loggedIn(userProfile)
                    self?.loadUserRepositories()
                case .failure:
                    // Token is invalid, show login screen
                    self?.loginState = .notLoggedIn
                }
            }
        }
    }
    
    // MARK: - Public Methods
    
    func loginWithToken() {
        guard !accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = NSLocalizedString("Please enter valid Personal Access Token", comment: "Token validation error")
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
                    self?.pendingUserProfile = userProfile
                    self?.pendingToken = trimmedToken
                    self?.loginState = .waitingForSaveChoice(userProfile)
                    self?.showTokenSaveAlert = true
                case .failure(let error):
                    self?.loginState = .error(error.localizedDescription)
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func saveTokenAndLogin(shouldSave: Bool) {
        guard let userProfile = pendingUserProfile else { return }
        
        if shouldSave {
            // User chose to save, check biometry permission first
            authManager.requestBiometryPermission { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let granted):
                        // Only save token if biometry permission is granted
                        self?.completeSaveAndLogin(shouldSave: true, userProfile: userProfile)
                    case .failure(let error):
                        // If biometry permission failed, do not save token
                        self?.handleBiometryPermissionError(error, userProfile: userProfile)
                    }
                }
            }
        } else {
            // User chose not to save
            completeSaveAndLogin(shouldSave: false, userProfile: userProfile)
        }
    }
    
    private func completeSaveAndLogin(shouldSave: Bool, userProfile: GitHubUserProfile) {
        // Save token if needed, but keep quiet
        authManager.saveCredentialsQuietly(userProfile: userProfile, token: pendingToken, shouldSave: shouldSave)
        
        // Update login status
        loginState = .loggedIn(userProfile)
        accessToken = "" // Clear token from UI for security
        
        // Load user repositories
        loadUserRepositories()
        
        // Clean up
        pendingUserProfile = nil
        pendingToken = ""
        showTokenSaveAlert = false
        
        // Notify the success of login
        NotificationCenter.default.post(name: .userDidLogin, object: nil)
    }
    
    private func handleBiometryPermissionError(_ error: AuthError, userProfile: GitHubUserProfile) {
        var message = ""
        
        switch error {
        case .biometryNotAvailable:
            message = NSLocalizedString("Device does not support biometry, but Token will be saved", comment: "Biometry not available message")
        case .biometryNotEnrolled:
            message = NSLocalizedString("Biometry not set up, please set up in system settings to use quick login", comment: "Biometry not enrolled message")
        case .userCancel:
            message = NSLocalizedString("You cancelled biometric authorization, Token will be saved but quick login unavailable", comment: "User cancelled biometry message")
        default:
            message = NSLocalizedString("Biometric setup failed, Token will be saved", comment: "Biometry failed message")
        }
        
        // Do not save token when biometry permission is denied
        // Complete login without saving credentials
        completeSaveAndLogin(shouldSave: false, userProfile: userProfile)
        
        // Show error message to user
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.errorMessage = message
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
                    self?.loadUserRepositories()
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
        loadUserRepositories()
    }
    
    func loadUserRepositories() {
        guard case .loggedIn(let userProfile) = loginState,
              let token = authManager.accessToken else { return }
        
        isLoadingRepositories = true
        
        apiService.getUserRepositories(
            username: userProfile.login,
            token: token,
            page: 1,
            perPage: 30
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoadingRepositories = false
                if case .failure(let error) = completion {
                    print("⚠️ Failed to load user repositories: \(error)")
                }
            },
            receiveValue: { [weak self] repositories in
                self?.userRepositories = repositories
            }
        )
        .store(in: &cancellables)
    }
    
    func clearError() {
        errorMessage = nil
        if case .error = loginState {
            loginState = .notLoggedIn
        }
    }
    
    func cancelTokenSave() {
        showTokenSaveAlert = false
        pendingUserProfile = nil
        pendingToken = ""
        loginState = .notLoggedIn
        accessToken = ""
    }
    
    // MARK: - Private Methods
    
    private func handleLoginSuccess() {
        // Clear login form
        accessToken = ""
        
        // Wait until user has decision of saving token
        if case .waitingForSaveChoice = loginState {
            return
        }        
    }
    
    private func handleLogout() {
        loginState = .notLoggedIn
        accessToken = ""
        errorMessage = nil
        showTokenSaveAlert = false
        pendingUserProfile = nil
        pendingToken = ""
        userRepositories = []
        isLoadingRepositories = false
    }
    
    private func validateAndLoadProfile() {
        isLoading = true
        
        authManager.validateCurrentToken { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let userProfile):
                    self?.loginState = .loggedIn(userProfile)
                    self?.loadUserRepositories()
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
            return NSLocalizedString("Login with Face ID", comment: "Face ID login button")
        case .touchID:
            return NSLocalizedString("Login with Touch ID", comment: "Touch ID login button")
        default:
            return NSLocalizedString("Login with Biometry", comment: "Generic biometry login button")
        }
    }
    
    var biometryName: String {
        switch authManager.getBiometryType() {
        case .faceID:
            return NSLocalizedString("Face ID", comment: "Face ID name")
        case .touchID:
            return NSLocalizedString("Touch ID", comment: "Touch ID name")
        default:
            return NSLocalizedString("Biometric Authentication", comment: "Generic biometry name")
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
