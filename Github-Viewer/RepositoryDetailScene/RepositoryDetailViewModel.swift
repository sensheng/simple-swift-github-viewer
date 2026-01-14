//
//  RepositoryDetailViewModel.swift
//  Github-Viewer
//
//  Created by Xu Sensheng on 2026-01-14.
//  Copyright © 2026 Sensheng Xu. All rights reserved.
//

import Foundation
import Combine
import UIKit

// MARK: - Repository Detail View Model Delegate
protocol RepositoryDetailViewModelDelegate: AnyObject {
    func repositoryDetailViewModelDidStartLoading(_ viewModel: RepositoryDetailViewModel)
    func repositoryDetailViewModelDidFinishLoading(_ viewModel: RepositoryDetailViewModel)
    func repositoryDetailViewModel(_ viewModel: RepositoryDetailViewModel, didFailWithError error: Error)
    func repositoryDetailViewModel(_ viewModel: RepositoryDetailViewModel, didUpdateRepository repository: GitHubRepository)
    func repositoryDetailViewModel(_ viewModel: RepositoryDetailViewModel, didUpdateReadme readme: GitHubReadme?)
    func repositoryDetailViewModel(_ viewModel: RepositoryDetailViewModel, didUpdateContributors contributors: [GitHubContributor])
    func repositoryDetailViewModel(_ viewModel: RepositoryDetailViewModel, didUpdateLanguages languages: GitHubLanguageStats)
}

// MARK: - Repository Detail View Model
class RepositoryDetailViewModel: ObservableObject {
    
    // MARK: - Properties
    
    weak var delegate: RepositoryDetailViewModelDelegate?
    
    @Published private(set) var repository: GitHubRepository
    @Published private(set) var readme: GitHubReadme?
    @Published private(set) var contributors: [GitHubContributor] = []
    @Published private(set) var languages: GitHubLanguageStats = [:]
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    private let apiService: GitHubAPIServiceProtocol
    private let authService: AuthManagerProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var ownerName: String {
        return repository.owner.login
    }
    
    var repositoryName: String {
        return repository.name
    }
    
    var repositoryDescription: String {
        return repository.description ?? "无描述"
    }
    
    var starsCount: String {
        return formatCount(repository.stargazersCount)
    }
    
    var forksCount: String {
        return formatCount(repository.forksCount)
    }
    
    var watchersCount: String {
        return formatCount(repository.watchersCount)
    }
    
    var primaryLanguage: String? {
        return repository.language
    }
    
    var createdDate: String {
        return formatDate(repository.createdAt)
    }
    
    var updatedDate: String {
        return formatDate(repository.updatedAt)
    }
    
    var repositoryURL: String {
        return repository.htmlURL
    }
    
    var readmeContent: String? {
        guard let readme = readme else { return nil }
        
        // Decode base64 content
        guard let data = Data(base64Encoded: readme.content.replacingOccurrences(of: "\n", with: "")) else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    var languagePercentages: [(language: String, percentage: Double, color: UIColor)] {
        let total = languages.values.reduce(0, +)
        guard total > 0 else { return [] }
        
        return languages.map { (language, bytes) in
            let percentage = Double(bytes) / Double(total) * 100
            let color = colorForLanguage(language)
            return (language: language, percentage: percentage, color: color)
        }.sorted { $0.percentage > $1.percentage }
    }
    
    // MARK: - Initialization
    
    init(repository: GitHubRepository,
         apiService: GitHubAPIServiceProtocol = GitHubAPIService.shared,
         authService: AuthManagerProtocol = AuthManager.shared) {
        self.repository = repository
        self.apiService = apiService
        self.authService = authService
    }
    
    // MARK: - Public Methods
    
    func loadRepositoryDetails() {
        isLoading = true
        error = nil
        delegate?.repositoryDetailViewModelDidStartLoading(self)
        
        let token = authService.accessToken
        
        // Load repository details, README, contributors, and languages in parallel
        let repositoryPublisher = apiService.getRepository(
            owner: ownerName,
            repo: repositoryName,
            token: token
        )
        
        let readmePublisher = apiService.getRepositoryReadme(
            owner: ownerName,
            repo: repositoryName,
            token: token
        )
        .map { readme -> GitHubReadme? in readme }
        .catch { _ in Just(nil as GitHubReadme?).setFailureType(to: Error.self) } // Don't fail if README doesn't exist
        
        let contributorsPublisher = apiService.getRepositoryContributors(
            owner: ownerName,
            repo: repositoryName,
            token: token
        )
        .catch { _ in Just([GitHubContributor]()).setFailureType(to: Error.self) } // Don't fail if contributors can't be loaded
        
        let languagesPublisher = apiService.getRepositoryLanguages(
            owner: ownerName,
            repo: repositoryName,
            token: token
        )
        .catch { _ in Just(GitHubLanguageStats()).setFailureType(to: Error.self) } // Don't fail if languages can't be loaded
        
        Publishers.CombineLatest4(
            repositoryPublisher,
            readmePublisher,
            contributorsPublisher,
            languagesPublisher
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                self.isLoading = false
                
                switch completion {
                case .finished:
                    self.delegate?.repositoryDetailViewModelDidFinishLoading(self)
                case .failure(let error):
                    self.error = error
                    self.delegate?.repositoryDetailViewModel(self, didFailWithError: error)
                }
            },
            receiveValue: { [weak self] repository, readme, contributors, languages in
                guard let self = self else { return }
                
                self.repository = repository
                self.readme = readme
                self.contributors = contributors
                self.languages = languages
                
                self.delegate?.repositoryDetailViewModel(self, didUpdateRepository: repository)
                self.delegate?.repositoryDetailViewModel(self, didUpdateReadme: readme)
                self.delegate?.repositoryDetailViewModel(self, didUpdateContributors: contributors)
                self.delegate?.repositoryDetailViewModel(self, didUpdateLanguages: languages)
            }
        )
        .store(in: &cancellables)
    }
    
    func openInSafari() {
        guard let url = URL(string: repositoryURL) else { return }
        UIApplication.shared.open(url)
    }
    
    func shareRepository() -> URL? {
        return URL(string: repositoryURL)
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
    
    private func colorForLanguage(_ language: String) -> UIColor {
        switch language.lowercased() {
        case "swift":
            return UIColor.systemOrange
        case "javascript", "typescript":
            return UIColor.systemYellow
        case "python":
            return UIColor.systemBlue
        case "java":
            return UIColor.systemRed
        case "kotlin":
            return UIColor.systemPurple
        case "go":
            return UIColor.systemTeal
        case "rust":
            return UIColor.systemBrown
        case "c++", "c":
            return UIColor.systemIndigo
        case "ruby":
            return UIColor.systemPink
        case "php":
            return UIColor.systemGray
        case "html":
            return UIColor.systemOrange
        case "css":
            return UIColor.systemBlue
        case "shell":
            return UIColor.systemGreen
        default:
            return UIColor.systemBlue
        }
    }
}