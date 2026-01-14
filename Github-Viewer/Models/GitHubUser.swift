//
//  GitHubUser.swift
//  Github-Viewer
//
//  Created by Xu Sensheng on 2026-01-14.
//  Copyright © 2026 Sensheng Xu. All rights reserved.
//

import Foundation

struct GitHubUser: Codable {
    let id: Int
    let login: String
    let avatarURL: String?
    let htmlURL: String?
    let type: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case login
        case avatarURL = "avatar_url"
        case htmlURL = "html_url"
        case type
    }
}

// MARK: - Equatable
extension GitHubUser: Equatable {
    static func == (lhs: GitHubUser, rhs: GitHubUser) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension GitHubUser: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}