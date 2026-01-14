//
//  UserProfileViewModel.swift
//  Github-Viewer
//
//  Created by Xu Sensheng on 2026-01-14.
//  Copyright © 2026 Sensheng Xu. All rights reserved.
//

import Foundation
import Combine
import UIKit

// MARK: - User Profile View Model Delegate
protocol UserProfileViewModelDelegate: AnyObject {
    func userProfileViewModelDidStartLoading(_ viewModel: UserProfileViewModel)
    func userProfileViewModelDidFinishLoading(_ viewModel: UserProfileViewModel)
    func userProfileViewModel(_ viewModel: UserProfileViewModel, didFailWithError error: Error)
    func userProfileViewModel(_ viewModel: UserProfileViewModel, didUpdateUser user: GitHubUserProfile)
    func userProfileViewModel(_ viewModel: UserProfileViewModel, didUpdateRepositories repositories: [GitHubRepository])
    func userProfileViewModel(_ viewModel: UserProfileViewModel, didLoadMoreRepositories repositories: [GitHubRepository])
}

// MARK: - User Profile View Model
class UserProfileViewModel: ObservableObject {
    
    // MARK: - Properties
    
    weak var delegate: UserProfileViewModelDelegate?
    
    @Published private(set) var user: GitHubUserProfile?
    @Published private(set) var repositories: [GitHubRepository] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var error: Error?
    
    private let username: String
    private let apiService: GitHubAPIServiceProtocol
    private let authService: AuthManagerProtocol
    private var cancellables = Set<AnyCancellable>()
    
    private var currentPage = 1
    private let perPage = 30
    private var hasMoreData = true
    
    // MARK: - Computed Properties
    
    var displayName: String {
        return user?.name ?? user?.login ?? username
    }
    
    var userLogin: String {
        return user?.login ?? username
    }
    
    var userBio: String {
        return user?.bio ?? "这个人很懒，什么都没写"
    }
    
    var userLocation: String? {
        return user?.location
    }
    
    var userCompany: String? {
        return user?.company
    }
    
    var userBlog: String? {
        return user?.blog
    }
    
    var userEmail: String? {
        return user?.email
    }
    
    var followersCount: String {
        guard let user = user else { return "0" }
        return formatCount(user.followers)
    }
    
    var followingCount: String {
        guard let user = user else { return "0" }
        return formatCount(user.following)
    }
    
    var publicReposCount: String {
        guard let user = user else { return "0" }
        return formatCount(user.publicRepos)
    }
    
    var joinedDate: String {
        guard let user = user else { return "" }
        return "加入于 " + formatDate(user.createdAt)
    }
    
    var avatarURL: String? {
        return user?.avatarURL
    }
    
    var profileURL: String? {
        return user?.htmlURL
    }
    
    var numberOfRepositories: Int {
        return repositories.count
    }
    
    var isEmpty: Bool {
        return repositories.isEmpty && !isLoading
    }
    
    // MARK: - Initialization
    
    init(username: String,
         apiService: GitHubAPIServiceProtocol = GitHubAPIService.shared,
         authService: AuthManagerProtocol = AuthManager.shared) {
        self.username = username
        self.apiService = apiService
        self.authService = authService
    }
    
    // MARK: - Public Methods
    
    func loadUserProfile() {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        delegate?.userProfileViewModelDidStartLoading(self)
        
        let token = authService.accessToken
        
        // Load user profile and repositories in parallel
        let userPublisher = apiService.getUser(username: username, token: token)
        let repositoriesPublisher = apiService.getUserRepositories(
            username: username,
            token: token,
            page: 1,
            perPage: perPage
        )
        
        Publishers.CombineLatest(userPublisher, repositoriesPublisher)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    
                    self.isLoading = false
                    
                    switch completion {
                    case .finished:
                        self.delegate?.userProfileViewModelDidFinishLoading(self)
                    case .failure(let error):
                        self.error = error
                        self.delegate?.userProfileViewModel(self, didFailWithError: error)
                    }
                },
                receiveValue: { [weak self] user, repositories in
                    guard let self = self else { return }
                    
                    self.user = user
                    self.repositories = repositories
                    self.currentPage = 1
                    self.hasMoreData = repositories.count == self.perPage
                    
                    self.delegate?.userProfileViewModel(self, didUpdateUser: user)
                    self.delegate?.userProfileViewModel(self, didUpdateRepositories: repositories)
                }
            )
            .store(in: &cancellables)
    }
    
    func loadMoreRepositories() {
        guard !isLoadingMore && hasMoreData else { return }
        
        isLoadingMore = true
        let nextPage = currentPage + 1
        let token = authService.accessToken
        
        apiService.getUserRepositories(
            username: username,
            token: token,
            page: nextPage,
            perPage: perPage
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                self.isLoadingMore = false
                
                if case .failure(let error) = completion {
                    self.error = error
                    self.delegate?.userProfileViewModel(self, didFailWithError: error)
                }
            },
            receiveValue: { [weak self] newRepositories in
                guard let self = self else { return }
                
                self.repositories.append(contentsOf: newRepositories)
                self.currentPage = nextPage
                self.hasMoreData = newRepositories.count == self.perPage
                
                self.delegate?.userProfileViewModel(self, didLoadMoreRepositories: newRepositories)
            }
        )
        .store(in: &cancellables)
    }
    
    func repository(at index: Int) -> GitHubRepository? {
        guard index >= 0 && index < repositories.count else { return nil }
        return repositories[index]
    }
    
    func shouldLoadMore(at index: Int) -> Bool {
        return index >= repositories.count - 5 && hasMoreData && !isLoadingMore
    }
    
    func openInSafari() {
        guard let urlString = profileURL, let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
    
    func shareProfile() -> URL? {
        guard let urlString = profileURL else { return nil }
        return URL(string: urlString)
    }
    
    // MARK: - Private Methods
    
    private func formatCount(_ count: Int) -> String {
        if count >= 1000000 {
            return String(format: "%.1fM", Double(count) / 1000000.0)
        } else if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000.0)
        } else {
            return "\(count)"
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .none
        displayFormatter.locale = Locale(identifier: "zh_CN")
        
        return displayFormatter.string(from: date)
    }
}