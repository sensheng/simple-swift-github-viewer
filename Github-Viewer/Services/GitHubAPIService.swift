//
//  GitHubAPIService.swift
//  Github-Viewer
//
//  Created by AI Assistant on 2026-01-14.
//

import Foundation
import Combine

// MARK: - GitHub API Service Protocol
protocol GitHubAPIServiceProtocol {
    func validateToken(_ token: String) -> AnyPublisher<GitHubUserProfile, Error>
    func getCurrentUser(token: String) -> AnyPublisher<GitHubUserProfile, Error>
    func getUserRepositories(token: String, page: Int, perPage: Int) -> AnyPublisher<[GitHubRepository], Error>
    func searchRepositories(query: String, token: String?, page: Int, perPage: Int) -> AnyPublisher<GitHubSearchResponse<GitHubRepository>, Error>
    func searchUsers(query: String, token: String?, page: Int, perPage: Int) -> AnyPublisher<GitHubSearchResponse<GitHubUser>, Error>
    
    // New methods for detailed views
    func getRepository(owner: String, repo: String, token: String?) -> AnyPublisher<GitHubRepository, Error>
    func getRepositoryReadme(owner: String, repo: String, token: String?) -> AnyPublisher<GitHubReadme, Error>
    func getRepositoryContributors(owner: String, repo: String, token: String?) -> AnyPublisher<[GitHubContributor], Error>
    func getRepositoryLanguages(owner: String, repo: String, token: String?) -> AnyPublisher<GitHubLanguageStats, Error>
    func getRepositoryFiles(owner: String, repo: String, path: String?, token: String?) -> AnyPublisher<[GitHubFile], Error>
    func getAllRepositoryFiles(owner: String, repo: String, token: String?) -> AnyPublisher<[GitHubFile], Error>
    func downloadFile(url: String, token: String?) -> AnyPublisher<Data, Error>
    func getUser(username: String, token: String?) -> AnyPublisher<GitHubUserProfile, Error>
    func getUserRepositories(username: String, token: String?, page: Int, perPage: Int) -> AnyPublisher<[GitHubRepository], Error>
}

// MARK: - GitHub API Service Implementation
class GitHubAPIService: GitHubAPIServiceProtocol {
    static let shared = GitHubAPIService()
    
    private let baseURL = "https://api.github.com"
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Token Validation
    func validateToken(_ token: String) -> AnyPublisher<GitHubUserProfile, Error> {
        return getCurrentUser(token: token)
    }
    
    // MARK: - Get Current User
    func getCurrentUser(token: String) -> AnyPublisher<GitHubUserProfile, Error> {
        guard let url = URL(string: "\(baseURL)/user") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("Github-Viewer-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if httpResponse.statusCode == 401 {
                    throw APIError.unauthorized
                } else if httpResponse.statusCode == 403 {
                    throw APIError.forbidden
                } else if !(200...299).contains(httpResponse.statusCode) {
                    // Try to decode error message
                    if let errorResponse = try? JSONDecoder().decode(GitHubAPIError.self, from: data) {
                        throw APIError.serverError(errorResponse.message)
                    }
                    throw APIError.serverError("HTTP \(httpResponse.statusCode)")
                }
                
                return data
            }
            .decode(type: GitHubUserProfile.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Get User Repositories
    func getUserRepositories(token: String, page: Int = 1, perPage: Int = 30) -> AnyPublisher<[GitHubRepository], Error> {
        guard let url = URL(string: "\(baseURL)/user/repos?page=\(page)&per_page=\(perPage)&sort=updated") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("Github-Viewer-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if httpResponse.statusCode == 401 {
                    throw APIError.unauthorized
                } else if !(200...299).contains(httpResponse.statusCode) {
                    if let errorResponse = try? JSONDecoder().decode(GitHubAPIError.self, from: data) {
                        throw APIError.serverError(errorResponse.message)
                    }
                    throw APIError.serverError("HTTP \(httpResponse.statusCode)")
                }
                
                return data
            }
            .decode(type: [GitHubRepository].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Search Repositories
    func searchRepositories(query: String, token: String? = nil, page: Int = 1, perPage: Int = 30) -> AnyPublisher<GitHubSearchResponse<GitHubRepository>, Error> {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "\(baseURL)/search/repositories?q=\(encodedQuery)&page=\(page)&per_page=\(perPage)&sort=stars&order=desc") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        if let token = token {
            request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("Github-Viewer-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    if let errorResponse = try? JSONDecoder().decode(GitHubAPIError.self, from: data) {
                        throw APIError.serverError(errorResponse.message)
                    }
                    throw APIError.serverError("HTTP \(httpResponse.statusCode)")
                }
                
                return data
            }
            .decode(type: GitHubSearchResponse<GitHubRepository>.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Search Users
    func searchUsers(query: String, token: String? = nil, page: Int = 1, perPage: Int = 30) -> AnyPublisher<GitHubSearchResponse<GitHubUser>, Error> {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "\(baseURL)/search/users?q=\(encodedQuery)&page=\(page)&per_page=\(perPage)") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        if let token = token {
            request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("Github-Viewer-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    if let errorResponse = try? JSONDecoder().decode(GitHubAPIError.self, from: data) {
                        throw APIError.serverError(errorResponse.message)
                    }
                    throw APIError.serverError("HTTP \(httpResponse.statusCode)")
                }
                
                return data
            }
            .decode(type: GitHubSearchResponse<GitHubUser>.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Get Repository Details
    func getRepository(owner: String, repo: String, token: String? = nil) -> AnyPublisher<GitHubRepository, Error> {
        guard let url = URL(string: "\(baseURL)/repos/\(owner)/\(repo)") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        if let token = token {
            request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("Github-Viewer-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    if let errorResponse = try? JSONDecoder().decode(GitHubAPIError.self, from: data) {
                        throw APIError.serverError(errorResponse.message)
                    }
                    throw APIError.serverError("HTTP \(httpResponse.statusCode)")
                }
                
                return data
            }
            .decode(type: GitHubRepository.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Get Repository README
    func getRepositoryReadme(owner: String, repo: String, token: String? = nil) -> AnyPublisher<GitHubReadme, Error> {
        guard let url = URL(string: "\(baseURL)/repos/\(owner)/\(repo)/readme") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        if let token = token {
            request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("Github-Viewer-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    if let errorResponse = try? JSONDecoder().decode(GitHubAPIError.self, from: data) {
                        throw APIError.serverError(errorResponse.message)
                    }
                    throw APIError.serverError("HTTP \(httpResponse.statusCode)")
                }
                
                return data
            }
            .decode(type: GitHubReadme.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Get Repository Contributors
    func getRepositoryContributors(owner: String, repo: String, token: String? = nil) -> AnyPublisher<[GitHubContributor], Error> {
        guard let url = URL(string: "\(baseURL)/repos/\(owner)/\(repo)/contributors") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        if let token = token {
            request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("Github-Viewer-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    if let errorResponse = try? JSONDecoder().decode(GitHubAPIError.self, from: data) {
                        throw APIError.serverError(errorResponse.message)
                    }
                    throw APIError.serverError("HTTP \(httpResponse.statusCode)")
                }
                
                return data
            }
            .decode(type: [GitHubContributor].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Get Repository Languages
    func getRepositoryLanguages(owner: String, repo: String, token: String? = nil) -> AnyPublisher<GitHubLanguageStats, Error> {
        guard let url = URL(string: "\(baseURL)/repos/\(owner)/\(repo)/languages") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        if let token = token {
            request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("Github-Viewer-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    if let errorResponse = try? JSONDecoder().decode(GitHubAPIError.self, from: data) {
                        throw APIError.serverError(errorResponse.message)
                    }
                    throw APIError.serverError("HTTP \(httpResponse.statusCode)")
                }
                
                return data
            }
            .decode(type: GitHubLanguageStats.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Get Repository Files
    func getRepositoryFiles(owner: String, repo: String, path: String? = nil, token: String? = nil) -> AnyPublisher<[GitHubFile], Error> {
        let pathComponent = path?.isEmpty == false ? "/\(path!)" : ""
        guard let url = URL(string: "\(baseURL)/repos/\(owner)/\(repo)/contents\(pathComponent)") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        if let token = token {
            request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("Github-Viewer-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    if let errorResponse = try? JSONDecoder().decode(GitHubAPIError.self, from: data) {
                        throw APIError.serverError(errorResponse.message)
                    }
                    throw APIError.serverError("HTTP \(httpResponse.statusCode)")
                }
                
                return data
            }
            .decode(type: [GitHubFile].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Get All Repository Files (Recursive)
    func getAllRepositoryFiles(owner: String, repo: String, token: String? = nil) -> AnyPublisher<[GitHubFile], Error> {
        return getRepositoryFilesRecursive(owner: owner, repo: repo, path: nil, token: token)
            .map { files in
                // 只返回文件，不返回文件夹，并按路径排序
                return files
                    .filter { !$0.isDirectory }
                    .sorted { $0.path < $1.path }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private Recursive Helper
    private func getRepositoryFilesRecursive(owner: String, repo: String, path: String?, token: String?) -> AnyPublisher<[GitHubFile], Error> {
        return getRepositoryFiles(owner: owner, repo: repo, path: path, token: token)
            .flatMap { files -> AnyPublisher<[GitHubFile], Error> in
                let filePublishers = files.map { file -> AnyPublisher<[GitHubFile], Error> in
                    if file.isDirectory {
                        // 递归获取子目录中的文件
                        return self.getRepositoryFilesRecursive(owner: owner, repo: repo, path: file.path, token: token)
                    } else {
                        // 直接返回文件
                        return Just([file])
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                    }
                }
                
                // 合并所有结果
                return Publishers.MergeMany(filePublishers)
                    .collect()
                    .map { arrays in
                        return arrays.flatMap { $0 }
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Download File
    func downloadFile(url: String, token: String? = nil) -> AnyPublisher<Data, Error> {
        guard let fileURL = URL(string: url) else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: fileURL)
        if let token = token {
            request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("Github-Viewer-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    throw APIError.serverError("HTTP \(httpResponse.statusCode)")
                }
                
                return data
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Get User Profile
    func getUser(username: String, token: String? = nil) -> AnyPublisher<GitHubUserProfile, Error> {
        guard let url = URL(string: "\(baseURL)/users/\(username)") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        if let token = token {
            request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("Github-Viewer-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    if let errorResponse = try? JSONDecoder().decode(GitHubAPIError.self, from: data) {
                        throw APIError.serverError(errorResponse.message)
                    }
                    throw APIError.serverError("HTTP \(httpResponse.statusCode)")
                }
                
                return data
            }
            .decode(type: GitHubUserProfile.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Get User Repositories by Username
    func getUserRepositories(username: String, token: String? = nil, page: Int = 1, perPage: Int = 30) -> AnyPublisher<[GitHubRepository], Error> {
        guard let url = URL(string: "\(baseURL)/users/\(username)/repos?page=\(page)&per_page=\(perPage)&sort=updated") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        if let token = token {
            request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("Github-Viewer-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    if let errorResponse = try? JSONDecoder().decode(GitHubAPIError.self, from: data) {
                        throw APIError.serverError(errorResponse.message)
                    }
                    throw APIError.serverError("HTTP \(httpResponse.statusCode)")
                }
                
                return data
            }
            .decode(type: [GitHubRepository].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// MARK: - API Error Types
enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case serverError(String)
    case decodingError
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .invalidResponse:
            return "无效的响应"
        case .unauthorized:
            return "Token无效或已过期，请重新登录"
        case .forbidden:
            return "访问被拒绝，请检查Token权限"
        case .serverError(let message):
            return "服务器错误: \(message)"
        case .decodingError:
            return "数据解析错误"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        }
    }
}