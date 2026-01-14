//
//  GitHubService.swift
//  Github-Viewer
//
//  Created by Xu Sensheng on 2026-01-14.
//  Copyright © 2026 Sensheng Xu. All rights reserved.
//

import Foundation
import Combine

protocol GitHubServiceProtocol {
    func searchRepositories(
        query: String,
        sort: String?,
        order: String?,
        page: Int,
        perPage: Int,
        completion: @escaping (Result<GitHubSearchResponse<GitHubRepository>, Error>) -> Void
    )
    
    func getTrendingRepositories(
        language: String?,
        since: String?,
        page: Int,
        perPage: Int,
        completion: @escaping (Result<GitHubSearchResponse<GitHubRepository>, Error>) -> Void
    )
    
    func getRepository(
        owner: String,
        repo: String,
        completion: @escaping (Result<GitHubRepository, Error>) -> Void
    )
    
    func getUserRepositories(
        page: Int,
        perPage: Int,
        completion: @escaping (Result<[GitHubRepository], Error>) -> Void
    )
}

class GitHubService: GitHubServiceProtocol {
    
    static let shared = GitHubService()
    
    private let apiService: GitHubAPIServiceProtocol
    private let authManager: AuthManagerProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(apiService: GitHubAPIServiceProtocol = GitHubAPIService.shared,
         authManager: AuthManagerProtocol = AuthManager.shared) {
        self.apiService = apiService
        self.authManager = authManager
    }
    
    // MARK: - Search Repositories
    
    func searchRepositories(
        query: String,
        sort: String? = "stars",
        order: String? = "desc",
        page: Int = 1,
        perPage: Int = 30,
        completion: @escaping (Result<GitHubSearchResponse<GitHubRepository>, Error>) -> Void
    ) {
        let token = authManager.accessToken
        
        apiService.searchRepositories(
            query: query,
            token: token,
            page: page,
            perPage: perPage
        )
        .sink(
            receiveCompletion: { completionResult in
                if case .failure(let error) = completionResult {
                    completion(.failure(error))
                }
            },
            receiveValue: { searchResponse in
                completion(.success(searchResponse))
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - Get Trending Repositories
    
    func getTrendingRepositories(
        language: String? = nil,
        since: String? = "daily",
        page: Int = 1,
        perPage: Int = 30,
        completion: @escaping (Result<GitHubSearchResponse<GitHubRepository>, Error>) -> Void
    ) {
        // Build query for trending repositories
        var query = "stars:>1"
        
        if let language = language {
            query += " language:\(language)"
        }
        
        // Add date filter for trending
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let calendar = Calendar.current
        let today = Date()
        
        let daysAgo: Int
        switch since {
        case "weekly":
            daysAgo = 7
        case "monthly":
            daysAgo = 30
        default:
            daysAgo = 1
        }
        
        if let pastDate = calendar.date(byAdding: .day, value: -daysAgo, to: today) {
            let dateString = dateFormatter.string(from: pastDate)
            query += " created:>\(dateString)"
        }
        
        searchRepositories(
            query: query,
            sort: "stars",
            order: "desc",
            page: page,
            perPage: perPage,
            completion: completion
        )
    }
    
    // MARK: - Get Single Repository
    
    func getRepository(
        owner: String,
        repo: String,
        completion: @escaping (Result<GitHubRepository, Error>) -> Void
    ) {
        // For now, we'll use search to find the specific repository
        // In a full implementation, you'd add a specific endpoint for this
        let query = "repo:\(owner)/\(repo)"
        
        searchRepositories(
            query: query,
            sort: nil,
            order: nil,
            page: 1,
            perPage: 1
        ) { result in
            switch result {
            case .success(let searchResponse):
                if let repository = searchResponse.items.first {
                    completion(.success(repository))
                } else {
                    completion(.failure(APIError.serverError("Repository not found")))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Get User Repositories
    
    func getUserRepositories(
        page: Int = 1,
        perPage: Int = 30,
        completion: @escaping (Result<[GitHubRepository], Error>) -> Void
    ) {
        guard let token = authManager.accessToken else {
            completion(.failure(APIError.unauthorized))
            return
        }
        
        apiService.getUserRepositories(token: token, page: page, perPage: perPage)
            .sink(
                receiveCompletion: { completionResult in
                    if case .failure(let error) = completionResult {
                        completion(.failure(error))
                    }
                },
                receiveValue: { repositories in
                    completion(.success(repositories))
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Convenience Methods
extension GitHubService {
    
    func searchRepositoriesByLanguage(
        language: String,
        page: Int = 1,
        perPage: Int = 30,
        completion: @escaping (Result<GitHubSearchResponse<GitHubRepository>, Error>) -> Void
    ) {
        let query = "language:\(language) stars:>1"
        searchRepositories(
            query: query,
            sort: "stars",
            order: "desc",
            page: page,
            perPage: perPage,
            completion: completion
        )
    }
    
    func searchRepositoriesByTopic(
        topic: String,
        page: Int = 1,
        perPage: Int = 30,
        completion: @escaping (Result<GitHubSearchResponse<GitHubRepository>, Error>) -> Void
    ) {
        let query = "topic:\(topic) stars:>1"
        searchRepositories(
            query: query,
            sort: "stars",
            order: "desc",
            page: page,
            perPage: perPage,
            completion: completion
        )
    }
}