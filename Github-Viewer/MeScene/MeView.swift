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

struct MeView: View {
    
    @StateObject private var viewModel = MeViewModel()
    @State private var showingErrorAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                // Content
                switch viewModel.loginState {
                case .notLoggedIn:
                    LoginView(viewModel: viewModel)
                case .loggingIn:
                    LoadingView(message: "登录中...")
                case .loggedIn(let userProfile):
                    ProfileView(userProfile: userProfile, viewModel: viewModel)
                case .waitingForSaveChoice(let userProfile):
                    ProfileView(userProfile: userProfile, viewModel: viewModel)
                case .error(let errorMessage):
                    ErrorView(message: errorMessage, viewModel: viewModel)
                }
            }
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert(isPresented: $viewModel.showTokenSaveAlert) {
            Alert(
                title: Text("保存登录信息"),
                message: Text("是否保存您的登录信息？保存后可使用\(viewModel.biometryName)快速登录。"),
                primaryButton: .default(Text("保存")) {
                    viewModel.saveTokenAndLogin(shouldSave: true)
                },
                secondaryButton: .cancel(Text("不保存")) {
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
                    
                    Text("登录 GitHub")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("使用 Personal Access Token 登录以获取真实的 GitHub 数据")
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
                            
                            Button("如何获取?") {
                                showTokenGuide = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        
                        SecureField("请输入您的 GitHub Personal Access Token", text: $viewModel.accessToken)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
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
                            
                            Text("登录")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(viewModel.accessToken.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.isLoading || viewModel.accessToken.isEmpty)
                    
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
                    Text("安全提示")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(icon: "shield.fill", text: "Token 将安全存储在设备钥匙串中")
                        InfoRow(icon: "faceid", text: "只有获得生物识别权限才会保存Token")
                        InfoRow(icon: "checkmark.seal", text: "推荐权限：read:user, user:email, repo")
                        InfoRow(icon: "exclamationmark.triangle", text: "请勿与他人分享您的 Token")
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
                        ProfileInfoSection(title: "简介", content: bio, icon: "text.quote")
                    }
                    
                    if let location = userProfile.location, !location.isEmpty {
                        ProfileInfoSection(title: "位置", content: location, icon: "location")
                    }
                    
                    if let company = userProfile.company, !company.isEmpty {
                        ProfileInfoSection(title: "公司", content: company, icon: "building.2")
                    }
                    
                    if let blog = userProfile.blog, !blog.isEmpty {
                        ProfileInfoSection(title: "博客", content: blog, icon: "link")
                    }
                    
                    if let email = userProfile.email, !email.isEmpty {
                        ProfileInfoSection(title: "邮箱", content: email, icon: "envelope")
                    }
                }
                
                // Actions
                VStack(spacing: 12) {
                    Button(action: {
                        viewModel.refreshProfile()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("刷新资料")
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.isLoading)
                    
                    Button(action: {
                        viewModel.logout()
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("退出登录")
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(.systemGray6))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                    }
                }
                
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
            Text("加入于 \(formatDate(userProfile.createdAt))")
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
            StatItemView(title: "仓库", value: "\(userProfile.publicRepos)")
            
            Divider()
                .frame(height: 40)
            
            StatItemView(title: "关注者", value: "\(userProfile.followers)")
            
            Divider()
                .frame(height: 40)
            
            StatItemView(title: "关注", value: "\(userProfile.following)")
            
            Divider()
                .frame(height: 40)
            
            StatItemView(title: "Gists", value: "\(userProfile.publicGists)")
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
                Text("出现错误")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("重试") {
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
                            
                            Text("获取 Personal Access Token")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Text("按照以下步骤在 GitHub 上生成您的个人访问令牌")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Steps
                    VStack(alignment: .leading, spacing: 16) {
                        GuideStepView(
                            step: "1",
                            title: "访问 GitHub 设置",
                            description: "登录 GitHub.com，点击右上角头像 → Settings"
                        )
                        
                        GuideStepView(
                            step: "2",
                            title: "进入开发者设置",
                            description: "在左侧菜单中找到 \"Developer settings\""
                        )
                        
                        GuideStepView(
                            step: "3",
                            title: "创建 Token",
                            description: "点击 \"Personal access tokens\" → \"Tokens (classic)\" → \"Generate new token\""
                        )
                        
                        GuideStepView(
                            step: "4",
                            title: "配置权限",
                            description: "为 Token 命名，选择过期时间，勾选以下权限："
                        )
                        
                        VStack(alignment: .leading, spacing: 8) {
                            PermissionRow(permission: "read:user", description: "读取用户基本信息")
                            PermissionRow(permission: "user:email", description: "读取用户邮箱地址")
                            PermissionRow(permission: "repo", description: "访问仓库信息（可选）")
                        }
                        .padding(.leading, 40)
                        
                        GuideStepView(
                            step: "5",
                            title: "生成并复制",
                            description: "点击 \"Generate token\"，立即复制生成的 Token（只显示一次）"
                        )
                        
                        GuideStepView(
                            step: "6",
                            title: "在应用中使用",
                            description: "返回应用，将复制的 Token 粘贴到登录界面"
                        )
                    }
                    
                    // Security Notice
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("安全提醒")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Token 具有与您的 GitHub 账户相同的权限")
                            Text("• 请勿与他人分享您的 Token")
                            Text("• 如果 Token 泄露，请立即在 GitHub 上删除")
                            Text("• 建议设置合理的过期时间")
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
            .navigationTitle("Token 获取指南")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("完成") {
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

// MARK: - Preview

struct MeView_Previews: PreviewProvider {
    static var previews: some View {
        MeView()
    }
}
