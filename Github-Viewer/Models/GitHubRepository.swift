//
//  GitHubRepository.swift
//  Github-Viewer
//
//  Created by Xu Sensheng on 2026-01-14.
//  Copyright © 2026 Sensheng Xu. All rights reserved.
//

import Foundation

struct GitHubRepository: Codable {
    let id: Int
    let name: String
    let fullName: String
    let description: String?
    let stargazersCount: Int
    let forksCount: Int
    let watchersCount: Int
    let language: String?
    let owner: GitHubUser
    let htmlURL: String
    let createdAt: String
    let updatedAt: String
    let pushedAt: String?
    let size: Int
    let defaultBranch: String
    let openIssuesCount: Int
    let topics: [String]?
    let hasIssues: Bool
    let hasProjects: Bool
    let hasWiki: Bool
    let hasPages: Bool
    let hasDownloads: Bool
    let archived: Bool
    let disabled: Bool
    let visibility: String?
    let license: GitHubLicense?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case fullName = "full_name"
        case description
        case stargazersCount = "stargazers_count"
        case forksCount = "forks_count"
        case watchersCount = "watchers_count"
        case language
        case owner
        case htmlURL = "html_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case pushedAt = "pushed_at"
        case size
        case defaultBranch = "default_branch"
        case openIssuesCount = "open_issues_count"
        case topics
        case hasIssues = "has_issues"
        case hasProjects = "has_projects"
        case hasWiki = "has_wiki"
        case hasPages = "has_pages"
        case hasDownloads = "has_downloads"
        case archived
        case disabled
        case visibility
        case license
    }
}

struct GitHubLicense: Codable {
    let key: String
    let name: String
    let spdxID: String?
    let url: String?
    let nodeID: String
    
    enum CodingKeys: String, CodingKey {
        case key
        case name
        case spdxID = "spdx_id"
        case url
        case nodeID = "node_id"
    }
}

// MARK: - Equatable
extension GitHubRepository: Equatable {
    static func == (lhs: GitHubRepository, rhs: GitHubRepository) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension GitHubRepository: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Convenience Properties
extension GitHubRepository {
    var avatarURL: String? {
        return owner.avatarURL
    }
    
    var formattedStarCount: String {
        if stargazersCount >= 1000 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 1
            
            if stargazersCount >= 1000000 {
                let millions = Double(stargazersCount) / 1000000.0
                return "\(formatter.string(from: NSNumber(value: millions)) ?? "0")M"
            } else {
                let thousands = Double(stargazersCount) / 1000.0
                return "\(formatter.string(from: NSNumber(value: thousands)) ?? "0")K"
            }
        } else {
            return "\(stargazersCount)"
        }
    }
    
    var formattedForkCount: String {
        if forksCount >= 1000 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 1
            
            if forksCount >= 1000000 {
                let millions = Double(forksCount) / 1000000.0
                return "\(formatter.string(from: NSNumber(value: millions)) ?? "0")M"
            } else {
                let thousands = Double(forksCount) / 1000.0
                return "\(formatter.string(from: NSNumber(value: thousands)) ?? "0")K"
            }
        } else {
            return "\(forksCount)"
        }
    }
}