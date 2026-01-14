//
//  CacheManager.swift
//  Github-Viewer
//
//  Created by Xu Sensheng on 2026-01-14.
//  Copyright © 2026 Sensheng Xu. All rights reserved.
//

import Foundation

protocol CacheManagerProtocol {
    func cacheRepositories(_ repositories: [GitHubRepository], for key: String)
    func getCachedRepositories(for key: String) -> [GitHubRepository]?
    func cacheSearchResponse(_ response: GitHubSearchResponse, for key: String)
    func getCachedSearchResponse(for key: String) -> GitHubSearchResponse?
    func isCacheValid(for key: String) -> Bool
    func clearCache()
    func clearExpiredCache()
}

class CacheManager: CacheManagerProtocol {
    
    static let shared = CacheManager()
    
    private let userDefaults = UserDefaults.standard
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        // Create cache directory
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheDirectory = documentsPath.appendingPathComponent("GitHubCache")
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
        
        // Clean expired cache on init
        clearExpiredCache()
    }
    
    // MARK: - Repository Caching
    
    func cacheRepositories(_ repositories: [GitHubRepository], for key: String) {
        let cacheData = CacheData(repositories: repositories, timestamp: Date())
        saveCacheData(cacheData, for: key)
    }
    
    func getCachedRepositories(for key: String) -> [GitHubRepository]? {
        guard let cacheData: CacheData<[GitHubRepository]> = loadCacheData(for: key),
              isCacheValid(cacheData.timestamp) else {
            return nil
        }
        return cacheData.data
    }
    
    // MARK: - Search Response Caching
    
    func cacheSearchResponse(_ response: GitHubSearchResponse, for key: String) {
        let cacheData = CacheData(data: response, timestamp: Date())
        saveCacheData(cacheData, for: key)
    }
    
    func getCachedSearchResponse(for key: String) -> GitHubSearchResponse? {
        guard let cacheData: CacheData<GitHubSearchResponse> = loadCacheData(for: key),
              isCacheValid(cacheData.timestamp) else {
            return nil
        }
        return cacheData.data
    }
    
    // MARK: - Cache Validation
    
    func isCacheValid(for key: String) -> Bool {
        guard let cacheData: CacheData<GitHubSearchResponse> = loadCacheData(for: key) else {
            return false
        }
        return isCacheValid(cacheData.timestamp)
    }
    
    private func isCacheValid(_ timestamp: Date) -> Bool {
        let expirationTime = Constants.Cache.defaultExpirationTime
        return Date().timeIntervalSince(timestamp) < expirationTime
    }
    
    // MARK: - Cache Management
    
    func clearCache() {
        // Remove all cache files
        do {
            let cacheFiles = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in cacheFiles {
                try fileManager.removeItem(at: file)
            }
        } catch {
            print("Failed to clear cache: \(error)")
        }
        
        // Clear UserDefaults cache keys
        let keys = userDefaults.dictionaryRepresentation().keys
        for key in keys {
            if key.hasPrefix(Constants.CacheKeys.cacheExpiration) {
                userDefaults.removeObject(forKey: key)
            }
        }
    }
    
    func clearExpiredCache() {
        do {
            let cacheFiles = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.creationDateKey])
            
            for file in cacheFiles {
                let resourceValues = try file.resourceValues(forKeys: [.creationDateKey])
                if let creationDate = resourceValues.creationDate,
                   !isCacheValid(creationDate) {
                    try fileManager.removeItem(at: file)
                    
                    // Also remove from UserDefaults
                    let fileName = file.lastPathComponent
                    userDefaults.removeObject(forKey: Constants.CacheKeys.cacheExpiration + fileName)
                }
            }
        } catch {
            print("Failed to clear expired cache: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func saveCacheData<T: Codable>(_ cacheData: CacheData<T>, for key: String) {
        let fileName = sanitizeFileName(key)
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        do {
            let data = try JSONEncoder().encode(cacheData)
            try data.write(to: fileURL)
            
            // Store expiration time in UserDefaults for quick access
            userDefaults.set(cacheData.timestamp, forKey: Constants.CacheKeys.cacheExpiration + fileName)
        } catch {
            print("Failed to save cache data for key \(key): \(error)")
        }
    }
    
    private func loadCacheData<T: Codable>(for key: String) -> CacheData<T>? {
        let fileName = sanitizeFileName(key)
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(CacheData<T>.self, from: data)
        } catch {
            print("Failed to load cache data for key \(key): \(error)")
            // Remove corrupted cache file
            try? fileManager.removeItem(at: fileURL)
            return nil
        }
    }
    
    private func sanitizeFileName(_ key: String) -> String {
        return key.replacingOccurrences(of: "[^a-zA-Z0-9_-]", with: "_", options: .regularExpression) + ".json"
    }
}

// MARK: - Cache Data Structure

private struct CacheData<T: Codable>: Codable {
    let data: T
    let timestamp: Date
    
    init(data: T, timestamp: Date) {
        self.data = data
        self.timestamp = timestamp
    }
    
    // For repositories array
    init(repositories: [GitHubRepository], timestamp: Date) where T == [GitHubRepository] {
        self.data = repositories as! T
        self.timestamp = timestamp
    }
}

// MARK: - Cache Statistics
extension CacheManager {
    
    func getCacheStatistics() -> CacheStatistics {
        var totalSize: Int64 = 0
        var fileCount = 0
        
        do {
            let cacheFiles = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            
            for file in cacheFiles {
                let resourceValues = try file.resourceValues(forKeys: [.fileSizeKey])
                if let fileSize = resourceValues.fileSize {
                    totalSize += Int64(fileSize)
                }
                fileCount += 1
            }
        } catch {
            print("Failed to get cache statistics: \(error)")
        }
        
        return CacheStatistics(totalSize: totalSize, fileCount: fileCount)
    }
}

struct CacheStatistics {
    let totalSize: Int64
    let fileCount: Int
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSize)
    }
}