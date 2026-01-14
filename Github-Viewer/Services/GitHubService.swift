//
//  GitHubService.swift
//  Github-Viewer
//
//  Created by Xu Sensheng on 2026-01-14.
//  Copyright © 2026 Sensheng Xu. All rights reserved.
//

import Foundation

protocol GitHubServiceProtocol {
    func searchRepositories(
        query: String,
        sort: String?,
        order: String?,
        page: Int,
        perPage: Int,
        completion: @escaping (Result<GitHubSearchResponse, GitHubAPIError>) -> Void
    )
    
    func getTrendingRepositories(
        language: String?,
        since: String?,
        page: Int,
        perPage: Int,
        completion: @escaping (Result<GitHubSearchResponse, GitHubAPIError>) -> Void
    )
    
    func getRepository(
        owner: String,
        repo: String,
        completion: @escaping (Result<GitHubRepository, GitHubAPIError>) -> Void
    )
}

class GitHubService: GitHubServiceProtocol {
    
    static let shared = GitHubService()
    
    private let networkManager: NetworkManagerProtocol
    private let authManager: AuthManagerProtocol
    
    init(networkManager: NetworkManagerProtocol = NetworkManager.shared,
         authManager: AuthManagerProtocol = AuthManager.shared) {
        self.networkManager = networkManager
        self.authManager = authManager
    }
    
    // MARK: - Search Repositories
    
    func searchRepositories(
        query: String,
        sort: String? = Constants.Search.defaultSortBy,
        order: String? = Constants.Search.defaultOrder,
        page: Int = 1,
        perPage: Int = Constants.API.defaultPerPage,
        completion: @escaping (Result<GitHubSearchResponse, GitHubAPIError>) -> Void
    ) {
        var queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(min(perPage, Constants.API.maxPerPage))")
        ]
        
        if let sort = sort {
            queryItems.append(URLQueryItem(name: "sort", value: sort))
        }
        
        if let order = order {
            queryItems.append(URLQueryItem(name: "order", value: order))
        }
        
        guard let url = networkManager.buildURL(path: Constants.API.searchRepositories, queryItems: queryItems) else {
            completion(.failure(.invalidURL))
            return
        }
        
        let headers = buildHeaders()
        
        networkManager.request(
            url: url,
            method: .GET,
            headers: headers,
            parameters: nil,
            responseType: GitHubSearchResponse.self,
            completion: completion
        )
    }
    
    // MARK: - Get Trending Repositories
    
    func getTrendingRepositories(
        language: String? = nil,
        since: String? = "daily",
        page: Int = 1,
        perPage: Int = Constants.API.defaultPerPage,
        completion: @escaping (Result<GitHubSearchResponse, GitHubAPIError>) -> Void
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
        completion: @escaping (Result<GitHubRepository, GitHubAPIError>) -> Void
    ) {
        guard let url = networkManager.buildURL(path: "/repos/\(owner)/\(repo)", queryItems: nil) else {
            completion(.failure(.invalidURL))
            return
        }
        
        let headers = buildHeaders()
        
        networkManager.request(
            url: url,
            method: .GET,
            headers: headers,
            parameters: nil,
            responseType: GitHubRepository.self,
            completion: completion
        )
    }
    
    // MARK: - Helper Methods
    
    private func buildHeaders() -> [String: String] {
        var headers: [String: String] = [:]
        
        if let token = authManager.accessToken {
            headers["Authorization"] = "token \(token)"
        }
        
        return headers
    }
}

// MARK: - Convenience Methods
extension GitHubService {
    
    func searchRepositoriesByLanguage(
        language: String,
        page: Int = 1,
        perPage: Int = Constants.API.defaultPerPage,
        completion: @escaping (Result<GitHubSearchResponse, GitHubAPIError>) -> Void
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
        perPage: Int = Constants.API.defaultPerPage,
        completion: @escaping (Result<GitHubSearchResponse, GitHubAPIError>) -> Void
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