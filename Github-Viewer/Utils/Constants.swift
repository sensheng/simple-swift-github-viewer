//
//  Constants.swift
//  Github-Viewer
//
//  Created by Xu Sensheng on 2026-01-14.
//  Copyright © 2026 Sensheng Xu. All rights reserved.
//

import Foundation

struct Constants {
    
    // MARK: - API Configuration
    struct API {
        static let baseURL = "https://api.github.com"
        static let searchRepositories = "/search/repositories"
        static let defaultPerPage = 20
        static let maxPerPage = 100
        
        // Rate limiting
        static let rateLimitRemaining = "X-RateLimit-Remaining"
        static let rateLimitReset = "X-RateLimit-Reset"
        static let rateLimitLimit = "X-RateLimit-Limit"
    }
    
    // MARK: - Cache Keys
    struct CacheKeys {
        static let trendingRepositories = "trending_repositories"
        static let searchResults = "search_results_"
        static let userProfile = "user_profile"
        static let cacheExpiration = "cache_expiration_"
    }
    
    // MARK: - UserDefaults Keys
    struct UserDefaultsKeys {
        static let isFirstLaunch = "is_first_launch"
        static let lastCacheUpdate = "last_cache_update"
        static let preferredLanguage = "preferred_language"
    }
    
    // MARK: - Keychain Keys
    struct KeychainKeys {
        static let accessToken = "github_access_token"
        static let username = "github_username"
        static let userID = "github_user_id"
        static let tokenSaved = "github_token_saved"
    }
    
    // MARK: - UI Configuration
    struct UI {
        static let defaultRowHeight: CGFloat = 120
        static let searchBarHeight: CGFloat = 44
        static let refreshControlHeight: CGFloat = 60
        
        // Animation durations
        static let defaultAnimationDuration: TimeInterval = 0.3
        static let fastAnimationDuration: TimeInterval = 0.15
    }
    
    // MARK: - Cache Configuration
    struct Cache {
        static let defaultExpirationTime: TimeInterval = 3600 // 1 hour
        static let imageExpirationTime: TimeInterval = 86400 // 24 hours
        static let maxCacheSize: Int = 50 * 1024 * 1024 // 50MB
    }
    
    // MARK: - Search Configuration
    struct Search {
        static let minQueryLength = 2
        static let searchDebounceTime: TimeInterval = 0.5
        static let defaultSortBy = "stars"
        static let defaultOrder = "desc"
    }
}
