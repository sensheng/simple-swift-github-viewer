//
//  MeView.swift
//  Github-Viewer
//
//  Created by Xu Sensheng on 2026-01-14.
//  Copyright © 2026 Sensheng Xu. All rights reserved.
//

import SwiftUI
import Combine
import LocalAuthentication

// MARK: - Navigation Delegate Protocol

protocol MeViewNavigationDelegate: AnyObject {
    func navigateToRepositoryDetail(_ repository: GitHubRepository)
}

struct MeView: View {
    
    @ObservedObject var viewModel: MeViewModel  // compatible for UIKit reference
    @State private var showingErrorAlert = false
    weak var navigationDelegate: MeViewNavigationDelegate?
    
    init(viewModel: MeViewModel) {
        self.viewModel = viewModel
    }
    
    init() {
        self.viewModel = MeViewModel()
    }
    
    var body: some View {        
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            // Content
            switch viewModel.loginState {
            case .notLoggedIn:
                LoginView(viewModel: viewModel)
            case .loggingIn:
                LoadingView(message: NSLocalizedString("Logging in...", comment: "Login loading message"))
            case .loggedIn(let userProfile):
                ProfileView(userProfile: userProfile, viewModel: viewModel, navigationDelegate: navigationDelegate)
            case .waitingForSaveChoice(let userProfile):
                ProfileView(userProfile: userProfile, viewModel: viewModel, navigationDelegate: navigationDelegate)
            case .error(let errorMessage):
                ErrorView(message: errorMessage, viewModel: viewModel)
            }
        }
        .alert(isPresented: $viewModel.showTokenSaveAlert) {
            Alert(
                title: Text(NSLocalizedString("Save login information", comment: "Save login dialog title")),
                message: Text(String(format: NSLocalizedString("Save login info question %@", comment: "Save login dialog message"), viewModel.biometryName)),
                primaryButton: .default(Text(NSLocalizedString("Save", comment: "Save button"))) {
                    viewModel.saveTokenAndLogin(shouldSave: true)
                },
                secondaryButton: .cancel(Text(NSLocalizedString("Don't save", comment: "Don't save button"))) {
                    viewModel.saveTokenAndLogin(shouldSave: false)
                }
            )
        }
    }
}

// MARK: - Login View

struct LoginView: View {
    
    @ObservedObject var viewModel: MeViewModel
    @State private var showTokenGuide = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text(NSLocalizedString("Login to GitHub", comment: "Login title"))
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(NSLocalizedString("Use Personal Access Token to login and get real GitHub data", comment: "Login description"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Login Form
                VStack(spacing: 16) {
                    // Token Field
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Personal Access Token")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Button(NSLocalizedString("How to Get?", comment: "How to get token button")) {
                                showTokenGuide = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        
                        SecureField(NSLocalizedString("Please enter your GitHub Personal Access Token", comment: "Token field placeholder"), text: $viewModel.accessToken)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .accessibilityIdentifier("tokenTextField")
                    }
                    
                    // Login Button
                    Button(action: {
                        viewModel.loginWithToken()
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Text(NSLocalizedString("Login", comment: "Login button"))
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(viewModel.accessToken.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.isLoading || viewModel.accessToken.isEmpty)
                    .accessibilityIdentifier("loginButton")
                    
                    // Biometry Login Button
                    if viewModel.showBiometryLogin {
                        Button(action: {
                            viewModel.loginWithBiometry()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: viewModel.biometryIcon)
                                Text(viewModel.biometryButtonTitle)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(.systemGray6))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
                
                // Info Section
                VStack(spacing: 12) {
                    Text(NSLocalizedString("Security Tips", comment: "Security tips title"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(icon: "shield.fill", text: NSLocalizedString("Token will be securely stored in device keychain", comment: "Security tip"))
                        InfoRow(icon: "faceid", text: NSLocalizedString("biometric authentication required to save Token", comment: "Security tip"))
                        InfoRow(icon: "checkmark.seal", text: NSLocalizedString("Recommended permissions: read:user, user:email, repo", comment: "Security tip"))
                        InfoRow(icon: "exclamationmark.triangle", text: NSLocalizedString("Do not share your Token with others", comment: "Security warning"))
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
        }
        .sheet(isPresented: $showTokenGuide) {
            TokenGuideView()
        }
    }
}

// MARK: - Profile View

struct ProfileView: View {
    
    let userProfile: GitHubUserProfile
    @ObservedObject var viewModel: MeViewModel
    weak var navigationDelegate: MeViewNavigationDelegate?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                ProfileHeaderView(userProfile: userProfile)
                
                // Stats
                ProfileStatsView(userProfile: userProfile)
                
                // Info Sections
                VStack(spacing: 16) {
                    if let bio = userProfile.bio, !bio.isEmpty {
                        ProfileInfoSection(title: NSLocalizedString("Bio", comment: "Bio section"), content: bio, icon: "text.quote")
                    }
                    
                    if let location = userProfile.location, !location.isEmpty {
                        ProfileInfoSection(title: NSLocalizedString("Location", comment: "Location section"), content: location, icon: "location")
                    }
                    
                    if let company = userProfile.company, !company.isEmpty {
                        ProfileInfoSection(title: NSLocalizedString("Company", comment: "Company section"), content: company, icon: "building.2")
                    }
                    
                    if let blog = userProfile.blog, !blog.isEmpty {
                        ProfileInfoSection(title: NSLocalizedString("Blog", comment: "Blog section"), content: blog, icon: "link")
                    }
                    
                    if let email = userProfile.email, !email.isEmpty {
                        ProfileInfoSection(title: NSLocalizedString("Email", comment: "Email section"), content: email, icon: "envelope")
                    }
                }
                
                // User Repositories Section
                UserRepositoriesSection(viewModel: viewModel, navigationDelegate: navigationDelegate)
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            // Auto refresh on appear if needed
        }
    }
}

// MARK: - Profile Header View

struct ProfileHeaderView: View {
    
    let userProfile: GitHubUserProfile
    
    var body: some View {
        VStack(spacing: 16) {
            RemoteImageView(url: userProfile.avatarURL)
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color(.systemGray4), lineWidth: 2)
                )
            
            // Name and Username
            VStack(spacing: 4) {
                if let name = userProfile.name, !name.isEmpty {
                    Text(name)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Text("@\(userProfile.login)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Join Date
            Text(String(format: NSLocalizedString("Joined on", comment: "Joined date prefix") + " %@", formatDate(userProfile.createdAt)))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.locale = Locale(identifier: "zh_CN")
        
        return displayFormatter.string(from: date)
    }
}

// MARK: - Profile Stats View

struct ProfileStatsView: View {
    
    let userProfile: GitHubUserProfile
    
    var body: some View {
        HStack(spacing: 0) {
            StatItemView(title: NSLocalizedString("Repositories", comment: "Repositories count"), value: "\(userProfile.publicRepos)")
            
            Divider()
                .frame(height: 40)
            
            StatItemView(title: NSLocalizedString("Followers", comment: "Followers count"), value: "\(userProfile.followers)")
            
            Divider()
                .frame(height: 40)
            
            StatItemView(title: NSLocalizedString("Following", comment: "Following count"), value: "\(userProfile.following)")
            
            Divider()
                .frame(height: 40)
            
            StatItemView(title: NSLocalizedString("Gists", comment: "Gists count"), value: "\(userProfile.publicGists)")
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct StatItemView: View {
    
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Profile Info Section

struct ProfileInfoSection: View {
    
    let title: String
    let content: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(content)
                    .font(.body)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Loading View

struct LoadingView: View {
    
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(1.2)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Error View

struct ErrorView: View {
    
    let message: String
    @ObservedObject var viewModel: MeViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text(NSLocalizedString("An Error Occurred", comment: "Error message title"))
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(NSLocalizedString("Retry", comment: "Retry button")) {
                viewModel.clearError()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Info Row

struct InfoRow: View {
    
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Token Guide View

struct TokenGuideView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "key.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            Text(NSLocalizedString("Get Personal Access Token", comment: "Token guide title"))
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Text(NSLocalizedString("Follow the steps below to generate your personal access token on GitHub", comment: "Token guide description"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Steps
                    VStack(alignment: .leading, spacing: 16) {
                        GuideStepView(
                            step: "1",
                            title: NSLocalizedString("Access GitHub Settings", comment: "Token guide step title"),
                            description: NSLocalizedString("Access GitHub Settings Description", comment: "Token guide step description")
                        )
                        
                        GuideStepView(
                            step: "2",
                            title: NSLocalizedString("Enter Developer Settings", comment: "Token guide step title"),
                            description: NSLocalizedString("Enter Developer Settings Description", comment: "Token guide step description")
                        )
                        
                        GuideStepView(
                            step: "3",
                            title: NSLocalizedString("Create Token", comment: "Token guide step title"),
                            description: NSLocalizedString("Create Token Description", comment: "Token guide step description")
                        )
                        
                        GuideStepView(
                            step: "4",
                            title: NSLocalizedString("Configure Permissions", comment: "Token guide step title"),
                            description: NSLocalizedString("Configure Permissions Description", comment: "Token guide step description")
                        )
                        
                        VStack(alignment: .leading, spacing: 8) {
                            PermissionRow(permission: "read:user", description: NSLocalizedString("Permission read:user description", comment: "Permission description"))
                            PermissionRow(permission: "user:email", description: NSLocalizedString("Permission user:email description", comment: "Permission description"))
                            PermissionRow(permission: "repo", description: NSLocalizedString("Permission repo description", comment: "Permission description"))
                        }
                        .padding(.leading, 40)
                        
                        GuideStepView(
                            step: "5",
                            title: NSLocalizedString("Generate and Copy", comment: "Token guide step title"),
                            description: NSLocalizedString("Generate and Copy Description", comment: "Token guide step description")
                        )
                        
                        GuideStepView(
                            step: "6",
                            title: NSLocalizedString("Use in App", comment: "Token guide step title"),
                            description: NSLocalizedString("Use in App Description", comment: "Token guide step description")
                        )
                    }
                    
                    // Security Notice
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(NSLocalizedString("Security Reminder", comment: "Security reminder title"))
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(NSLocalizedString("Token has same permissions as your GitHub account", comment: "Security warning"))
                            Text(NSLocalizedString("Do not share your Token with others", comment: "Security warning"))
                            Text(NSLocalizedString("If Token is leaked, delete it immediately on GitHub", comment: "Security warning"))
                            Text(NSLocalizedString("Set reasonable expiration time", comment: "Security warning"))
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemYellow).opacity(0.1))
                    .cornerRadius(12)
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("Get Personal Access Token", comment: "Token guide title"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button(NSLocalizedString("Done", comment: "Done button")) {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Guide Step View

struct GuideStepView: View {
    
    let step: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Step Number
            Text(step)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.blue)
                .clipShape(Circle())
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Permission Row

struct PermissionRow: View {
    
    let permission: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(permission)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - User Repositories Section

struct UserRepositoriesSection: View {
    
    @ObservedObject var viewModel: MeViewModel
    weak var navigationDelegate: MeViewNavigationDelegate?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Text(NSLocalizedString("My Repositories", comment: "My repositories section title"))
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if viewModel.isLoadingRepositories {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            // Repositories List
            if viewModel.userRepositories.isEmpty && !viewModel.isLoadingRepositories {
                // Empty State
                VStack(spacing: 12) {
                    Image(systemName: "folder")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text(NSLocalizedString("No repositories yet", comment: "Empty repositories message"))
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(NSLocalizedString("You have not created any repositories yet", comment: "Empty repositories description"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                // Repository Cards
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.userRepositories.prefix(5), id: \.id) { repository in
                        UserRepositoryCard(repository: repository, navigationDelegate: navigationDelegate)
                    }

                    // Show More Button if there are more repositories
                    if viewModel.userRepositories.count > 5 {
                        Button(action: {
                            // TODO: Navigate to full repository list
                        }) {
                            HStack {
                                Text(String(format: NSLocalizedString("View all %lld repositories", comment: "View all repositories button"), viewModel.userRepositories.count))
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - User Repository Card

struct UserRepositoryCard: View {
    
    let repository: GitHubRepository
    weak var navigationDelegate: MeViewNavigationDelegate?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Repository Name and Visibility
            HStack {
                Text(repository.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Spacer()
                
                // Visibility Badge
                Text(repository.isPrivate ? NSLocalizedString("Private", comment: "Private repository badge") : NSLocalizedString("Public", comment: "Public repository badge"))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(repository.isPrivate ? Color.orange : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
            
            // Description
            if let description = repository.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // Stats
            HStack(spacing: 16) {
                if let language = repository.language {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                        Text(language)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "star")
                        .font(.caption)
                    Text("\(repository.stargazersCount)")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "tuningfork")
                        .font(.caption)
                    Text("\(repository.forksCount)")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                Text(repository.updatedAt.toDate()?.timeAgoDisplay() ?? NSLocalizedString("Unknown time", comment: "Unknown time display"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onTapGesture {
            navigationDelegate?.navigateToRepositoryDetail(repository)
        }
    }
}

// MARK: - Date Extension

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - String Extension

extension String {
    func toDate() -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: self)
    }
}

// MARK: - Preview

struct MeView_Previews: PreviewProvider {
    static var previews: some View {
        MeView()
    }
}
