//
//  NetworkManager.swift
//  Github-Viewer
//
//  Created by Xu Sensheng on 2026-01-14.
//  Copyright © 2026 Sensheng Xu. All rights reserved.
//

import Foundation

protocol NetworkManagerProtocol {
    func request<T: Codable>(
        url: URL,
        method: HTTPMethod,
        headers: [String: String]?,
        parameters: [String: Any]?,
        responseType: T.Type,
        completion: @escaping (Result<T, GitHubAPIError>) -> Void
    )
    
    func buildURL(path: String, queryItems: [URLQueryItem]?) -> URL?
}

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

class NetworkManager: NetworkManagerProtocol {
    
    static let shared = NetworkManager()
    
    private let session: URLSession
    private let decoder: JSONDecoder
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
        
        // Configure date decoding strategy
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
    }
    
    func request<T: Codable>(
        url: URL,
        method: HTTPMethod = .GET,
        headers: [String: String]? = nil,
        parameters: [String: Any]? = nil,
        responseType: T.Type,
        completion: @escaping (Result<T, GitHubAPIError>) -> Void
    ) {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // Set default headers
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("Github-Viewer/1.0", forHTTPHeaderField: "User-Agent")
        
        // Add custom headers
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add parameters for POST requests
        if method != .GET, let parameters = parameters {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            } catch {
                completion(.failure(.networkError(error)))
                return
            }
        }
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.handleResponse(data: data, response: response, error: error, responseType: responseType, completion: completion)
            }
        }
        
        task.resume()
    }
    
    private func handleResponse<T: Codable>(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        responseType: T.Type,
        completion: @escaping (Result<T, GitHubAPIError>) -> Void
    ) {
        // Handle network error
        if let error = error {
            completion(.failure(.networkError(error)))
            return
        }
        
        // Handle HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(.noData))
            return
        }
        
        // Handle HTTP status codes
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            completion(.failure(.unauthorized))
            return
        case 403:
            // Check if it's rate limit exceeded
            if let remaining = httpResponse.value(forHTTPHeaderField: Constants.API.rateLimitRemaining),
               remaining == "0" {
                completion(.failure(.rateLimitExceeded))
            } else {
                completion(.failure(.unauthorized))
            }
            return
        case 404:
            completion(.failure(.notFound))
            return
        case 422:
            // Validation failed
            if let data = data {
                do {
                    let errorResponse = try decoder.decode(GitHubErrorResponse.self, from: data)
                    completion(.failure(.apiError(errorResponse.message)))
                } catch {
                    completion(.failure(.serverError(httpResponse.statusCode)))
                }
            } else {
                completion(.failure(.serverError(httpResponse.statusCode)))
            }
            return
        case 500...599:
            completion(.failure(.serverError(httpResponse.statusCode)))
            return
        default:
            completion(.failure(.serverError(httpResponse.statusCode)))
            return
        }
        
        // Handle response data
        guard let data = data else {
            completion(.failure(.noData))
            return
        }
        
        // Decode response
        do {
            let decodedResponse = try decoder.decode(responseType, from: data)
            completion(.success(decodedResponse))
        } catch {
            completion(.failure(.decodingError(error)))
        }
    }
}

// MARK: - URL Building Helper
extension NetworkManager {
    
    func buildURL(path: String, queryItems: [URLQueryItem]? = nil) -> URL? {
        guard var components = URLComponents(string: Constants.API.baseURL + path) else {
            return nil
        }
        
        components.queryItems = queryItems
        return components.url
    }
}