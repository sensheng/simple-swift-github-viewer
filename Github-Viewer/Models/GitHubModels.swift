//
//  GitHubModels.swift
//  Github-Viewer
//
//  Created by AI Assistant on 2026-01-14.
//

import Foundation

// MARK: - GitHub User Profile Model
struct GitHubUserProfile: Codable, Equatable {
    let id: Int
    let login: String
    let name: String?
    let email: String?
    let bio: String?
    let avatarURL: String
    let htmlURL: String
    let publicRepos: Int
    let publicGists: Int
    let followers: Int
    let following: Int
    let createdAt: String
    let updatedAt: String
    let company: String?
    let location: String?
    let blog: String?
    let twitterUsername: String?
    
    enum CodingKeys: String, CodingKey {
        case id, login, name, email, bio, company, location, blog
        case avatarURL = "avatar_url"
        case htmlURL = "html_url"
        case publicRepos = "public_repos"
        case publicGists = "public_gists"
        case followers, following
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case twitterUsername = "twitter_username"
    }
}

// MARK: - GitHub Repository Model
struct GitHubRepository: Codable, Identifiable {
    let id: Int
    let name: String
    let fullName: String
    let description: String?
    let htmlURL: String
    let language: String?
    let stargazersCount: Int
    let forksCount: Int
    let watchersCount: Int
    let size: Int
    let defaultBranch: String
    let createdAt: String
    let updatedAt: String
    let pushedAt: String?
    let isPrivate: Bool
    let isFork: Bool
    let isArchived: Bool
    let owner: GitHubUser
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, language, size, owner
        case fullName = "full_name"
        case htmlURL = "html_url"
        case stargazersCount = "stargazers_count"
        case forksCount = "forks_count"
        case watchersCount = "watchers_count"
        case defaultBranch = "default_branch"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case pushedAt = "pushed_at"
        case isPrivate = "private"
        case isFork = "fork"
        case isArchived = "archived"
    }
}

// MARK: - GitHub User Model (for repository owner)
struct GitHubUser: Codable {
    let id: Int
    let login: String
    let avatarURL: String
    let htmlURL: String
    let type: String
    
    enum CodingKeys: String, CodingKey {
        case id, login, type
        case avatarURL = "avatar_url"
        case htmlURL = "html_url"
    }
}

// MARK: - GitHub Search Response
struct GitHubSearchResponse<T: Codable>: Codable {
    let totalCount: Int
    let incompleteResults: Bool
    let items: [T]
    
    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case incompleteResults = "incomplete_results"
        case items
    }
}

// MARK: - API Error Response
struct GitHubAPIError: Codable, Error {
    let message: String
    let documentationURL: String?
    
    enum CodingKeys: String, CodingKey {
        case message
        case documentationURL = "documentation_url"
    }
}

// MARK: - GitHub README Model
struct GitHubReadme: Codable {
    let name: String
    let path: String
    let sha: String
    let size: Int
    let url: String
    let htmlURL: String
    let gitURL: String
    let downloadURL: String?
    let type: String
    let content: String
    let encoding: String
    
    enum CodingKeys: String, CodingKey {
        case name, path, sha, size, url, type, content, encoding
        case htmlURL = "html_url"
        case gitURL = "git_url"
        case downloadURL = "download_url"
    }
}

// MARK: - GitHub Contributor Model
struct GitHubContributor: Codable {
    let id: Int
    let login: String
    let avatarURL: String
    let htmlURL: String
    let contributions: Int
    let type: String
    
    enum CodingKeys: String, CodingKey {
        case id, login, contributions, type
        case avatarURL = "avatar_url"
        case htmlURL = "html_url"
    }
}

// MARK: - GitHub Language Stats
typealias GitHubLanguageStats = [String: Int]

// MARK: - GitHub File Model
struct GitHubFile: Codable {
    let name: String
    let path: String
    let sha: String
    let size: Int
    let url: String
    let htmlURL: String
    let gitURL: String
    let downloadURL: String?
    let type: String // "file" or "dir"
    
    enum CodingKeys: String, CodingKey {
        case name, path, sha, size, url, type
        case htmlURL = "html_url"
        case gitURL = "git_url"
        case downloadURL = "download_url"
    }
    
    var isDirectory: Bool {
        return type == "dir"
    }
    
    var isFile: Bool {
        return type == "file"
    }
    
    var fileExtension: String? {
        return URL(fileURLWithPath: name).pathExtension.isEmpty ? nil : URL(fileURLWithPath: name).pathExtension
    }
    
    var displayName: String {
        // 对于文件列表优化：显示完整路径而不是文件夹
        return path
    }
    
    var iconName: String {
        if isDirectory {
            return "folder.fill"
        }
        
        guard let ext = fileExtension?.lowercased() else {
            return "doc"
        }
        
        switch ext {
        case "swift":
            return "swift"
        case "md", "markdown":
            return "doc.text"
        case "json":
            return "doc.text"
        case "txt":
            return "doc.plaintext"
        case "pdf":
            return "doc.richtext"
        case "jpg", "jpeg", "png", "gif", "svg":
            return "photo"
        case "mp4", "mov", "avi":
            return "video"
        case "mp3", "wav", "m4a":
            return "music.note"
        case "zip", "tar", "gz":
            return "doc.zipper"
        default:
            return "doc"
        }
    }
}

// MARK: - Token Validation Response
struct TokenValidationResponse: Codable {
    let scopes: [String]?
    let token: String?
    let hashedToken: String?
    
    enum CodingKeys: String, CodingKey {
        case scopes, token
        case hashedToken = "hashed_token"
    }
}