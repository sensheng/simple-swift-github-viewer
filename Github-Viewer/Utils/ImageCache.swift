//
//  ImageCache.swift
//  Github-Viewer
//
//  Created by Xu Sensheng on 2026-01-14.
//  Copyright © 2026 Sensheng Xu. All rights reserved.
//

import UIKit

class ImageCache {
    
    static let shared = ImageCache()
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCache: URL
    private let fileManager = FileManager.default
    private let session = URLSession.shared
    
    private init() {
        // Setup memory cache
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        // Setup disk cache
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        diskCache = documentsPath.appendingPathComponent("ImageCache")
        
        if !fileManager.fileExists(atPath: diskCache.path) {
            try? fileManager.createDirectory(at: diskCache, withIntermediateDirectories: true)
        }
        
        // Clean old cache on init
        cleanExpiredCache()
    }
    
    // MARK: - Public Methods
    
    func loadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        let cacheKey = NSString(string: urlString)
        
        // Check memory cache first
        if let cachedImage = memoryCache.object(forKey: cacheKey) {
            completion(cachedImage)
            return
        }
        
        // Check disk cache
        if let diskImage = loadImageFromDisk(urlString: urlString) {
            memoryCache.setObject(diskImage, forKey: cacheKey)
            completion(diskImage)
            return
        }
        
        // Download from network
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        let task = session.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  let image = UIImage(data: data),
                  error == nil else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // Cache the image
            self.memoryCache.setObject(image, forKey: cacheKey)
            self.saveImageToDisk(image: image, urlString: urlString)
            
            DispatchQueue.main.async {
                completion(image)
            }
        }
        
        task.resume()
    }
    
    func clearCache() {
        memoryCache.removeAllObjects()
        
        do {
            let cacheFiles = try fileManager.contentsOfDirectory(at: diskCache, includingPropertiesForKeys: nil)
            for file in cacheFiles {
                try fileManager.removeItem(at: file)
            }
        } catch {
            print("⚠️ Failed to clear image cache: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func loadImageFromDisk(urlString: String) -> UIImage? {
        let fileName = fileName(for: urlString)
        let fileURL = diskCache.appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        // Check if file is expired
        do {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            if let creationDate = attributes[.creationDate] as? Date {
                let expirationTime = Constants.Cache.imageExpirationTime
                if Date().timeIntervalSince(creationDate) > expirationTime {
                    try fileManager.removeItem(at: fileURL)
                    return nil
                }
            }
        } catch {
            return nil
        }
        
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    private func saveImageToDisk(image: UIImage, urlString: String) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        let fileName = fileName(for: urlString)
        let fileURL = diskCache.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
        } catch {
            print("⚠️ Failed to save image to disk: \(error)")
        }
    }
    
    private func fileName(for urlString: String) -> String {
        return urlString.replacingOccurrences(of: "[^a-zA-Z0-9]", with: "_", options: .regularExpression) + ".jpg"
    }
    
    private func cleanExpiredCache() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let cacheFiles = try self.fileManager.contentsOfDirectory(at: self.diskCache, includingPropertiesForKeys: [.creationDateKey])
                
                for file in cacheFiles {
                    let resourceValues = try file.resourceValues(forKeys: [.creationDateKey])
                    if let creationDate = resourceValues.creationDate {
                        let expirationTime = Constants.Cache.imageExpirationTime
                        if Date().timeIntervalSince(creationDate) > expirationTime {
                            try self.fileManager.removeItem(at: file)
                        }
                    }
                }
            } catch {
                print("⚠️ Failed to clean expired image cache: \(error)")
            }
        }
    }
}

// MARK: - UIImageView Extension

extension UIImageView {
    
    func loadImage(from urlString: String?, placeholder: UIImage? = nil) {
        // Set placeholder immediately
        self.image = placeholder
        
        guard let urlString = urlString, !urlString.isEmpty else {
            return
        }
        
        ImageCache.shared.loadImage(from: urlString) { [weak self] image in
            self?.image = image ?? placeholder
        }
    }
}
