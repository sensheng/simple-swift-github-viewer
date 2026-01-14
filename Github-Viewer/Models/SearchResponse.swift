//
//  SearchResponse.swift
//  Github-Viewer
//
//  Created by Xu Sensheng on 2026-01-14.
//  Copyright © 2026 Sensheng Xu. All rights reserved.
//

import Foundation

struct GitHubSearchResponse: Codable {
    let totalCount: Int
    let incompleteResults: Bool
    let items: [GitHubRepository]
    
    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case incompleteResults = "incomplete_results"
        case items
    }
}

// MARK: - API Error Response
struct GitHubErrorResponse: Codable {
    let message: String
    let errors: [GitHubError]?
    let documentationURL: String?
    
    enum CodingKeys: String, CodingKey {
        case message
        case errors
        case documentationURL = "documentation_url"
    }
}

struct GitHubError: Codable {
    let resource: String?
    let field: String?
    let code: String
    let message: String?
}

// MARK: - Custom Error Types
enum GitHubAPIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case networkError(Error)
    case rateLimitExceeded
    case unauthorized
    case notFound
    case serverError(Int)
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .noData:
            return "没有数据"
        case .decodingError(let error):
            return "数据解析错误: \(error.localizedDescription)"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .rateLimitExceeded:
            return "API调用频率超限，请稍后再试"
        case .unauthorized:
            return "未授权访问"
        case .notFound:
            return "资源未找到"
        case .serverError(let code):
            return "服务器错误 (\(code))"
        case .apiError(let message):
            return message
        }
    }
}