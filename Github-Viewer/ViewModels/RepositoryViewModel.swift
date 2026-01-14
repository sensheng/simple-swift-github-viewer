//
//  RepositoryViewModel.swift
//  Github-Viewer
//
//  Created by Xu Sensheng on 2026-01-14.
//  Copyright © 2026 Sensheng Xu. All rights reserved.
//

import Foundation

protocol RepositoryViewModelDelegate: AnyObject {
    func repositoryViewModelDidStartLoading(_ viewModel: RepositoryViewModel)
    func repositoryViewModelDidFinishLoading(_ viewModel: RepositoryViewModel)
    func repositoryViewModel(_ viewModel: RepositoryViewModel, didFailWithError error: GitHubAPIError)
    func repositoryViewModel(_ viewModel: RepositoryViewModel, didUpdateRepositories repositories: [GitHubRepository])
    func repositoryViewModel(_ viewModel: RepositoryViewModel, didLoadMoreRepositories repositories: [GitHubRepository])
}

class RepositoryViewModel {
    
    // MARK: - Properties
    
    weak var delegate: RepositoryViewModelDelegate?
    
    private let gitHubService: GitHubServiceProtocol
    private let cacheManager: CacheManagerProtocol
    
    private(set) var repositories: [GitHubRepository] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var hasMoreData = true
    private(set) var currentPage = 1
    private(set) var currentQuery: String?
    private(set) var isSearchMode = false
    
    private var searchWorkItem: DispatchWorkItem?
    
    // MARK: - Initialization
    
    init(gitHubService: GitHubServiceProtocol = GitHubService.shared,
         cacheManager: CacheManagerProtocol = CacheManager.shared) {
        self.gitHubService = gitHubService
        self.cacheManager = cacheManager
    }
    
    // MARK: - Public Methods
    
    func loadTrendingRepositories(refresh: Bool = false) {
        guard !isLoading || refresh else { return }
        
        if refresh {
            resetPagination()
        }
        
        isLoading = true
        isSearchMode = false
        currentQuery = nil
        delegate?.repositoryViewModelDidStartLoading(self)
        
        // Try to load from cache first if not refreshing
        if !refresh {
            loadFromCache(key: Constants.CacheKeys.trendingRepositories)
        }
        
        gitHubService.getTrendingRepositories(
            language: nil,
            since: "daily",
            page: currentPage,
            perPage: Constants.API.defaultPerPage
        ) { [weak self] result in
            self?.handleRepositoryResponse(result, isLoadMore: false, cacheKey: Constants.CacheKeys.trendingRepositories)
        }
    }
    
    func searchRepositories(_ query: String) {
        // Cancel previous search
        searchWorkItem?.cancel()
        
        // Debounce search
        let workItem = DispatchWorkItem { [weak self] in
            self?.performSearch(query)
        }
        
        searchWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.Search.searchDebounceTime, execute: workItem)
    }
    
    func loadMoreRepositories() {
        guard !isLoadingMore && hasMoreData && !repositories.isEmpty else { return }
        
        isLoadingMore = true
        let nextPage = currentPage + 1
        
        if isSearchMode, let query = currentQuery {
            gitHubService.searchRepositories(
                query: query,
                sort: Constants.Search.defaultSortBy,
                order: Constants.Search.defaultOrder,
                page: nextPage,
                perPage: Constants.API.defaultPerPage
            ) { [weak self] result in
                self?.handleRepositoryResponse(result, isLoadMore: true, cacheKey: nil)
            }
        } else {
            gitHubService.getTrendingRepositories(
                language: nil,
                since: "daily",
                page: nextPage,
                perPage: Constants.API.defaultPerPage
            ) { [weak self] result in
                self?.handleRepositoryResponse(result, isLoadMore: true, cacheKey: nil)
            }
        }
    }
    
    func clearSearch() {
        searchWorkItem?.cancel()
        isSearchMode = false
        currentQuery = nil
        loadTrendingRepositories()
    }
    
    // MARK: - Private Methods
    
    private func performSearch(_ query: String) {
        guard query.count >= Constants.Search.minQueryLength else {
            if query.isEmpty {
                clearSearch()
            }
            return
        }
        
        resetPagination()
        isLoading = true
        isSearchMode = true
        currentQuery = query
        delegate?.repositoryViewModelDidStartLoading(self)
        
        // Try to load from cache first
        let cacheKey = Constants.CacheKeys.searchResults + query
        loadFromCache(key: cacheKey)
        
        gitHubService.searchRepositories(
            query: query,
            sort: Constants.Search.defaultSortBy,
            order: Constants.Search.defaultOrder,
            page: currentPage,
            perPage: Constants.API.defaultPerPage
        ) { [weak self] result in
            self?.handleRepositoryResponse(result, isLoadMore: false, cacheKey: cacheKey)
        }
    }
    
    private func handleRepositoryResponse(
        _ result: Result<GitHubSearchResponse, GitHubAPIError>,
        isLoadMore: Bool,
        cacheKey: String?
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.isLoading = false
            self.isLoadingMore = false
            
            switch result {
            case .success(let response):
                self.handleSuccessResponse(response, isLoadMore: isLoadMore, cacheKey: cacheKey)
                
            case .failure(let error):
                self.delegate?.repositoryViewModel(self, didFailWithError: error)
            }
            
            self.delegate?.repositoryViewModelDidFinishLoading(self)
        }
    }
    
    private func handleSuccessResponse(
        _ response: GitHubSearchResponse,
        isLoadMore: Bool,
        cacheKey: String?
    ) {
        let newRepositories = response.items
        
        if isLoadMore {
            // Append new repositories, avoiding duplicates
            let uniqueNewRepos = newRepositories.filter { newRepo in
                !repositories.contains { existingRepo in
                    existingRepo.id == newRepo.id
                }
            }
            
            repositories.append(contentsOf: uniqueNewRepos)
            currentPage += 1
            
            delegate?.repositoryViewModel(self, didLoadMoreRepositories: uniqueNewRepos)
        } else {
            // Replace existing repositories
            repositories = newRepositories
            currentPage = 1
            
            delegate?.repositoryViewModel(self, didUpdateRepositories: repositories)
        }
        
        // Update hasMoreData based on response
        hasMoreData = newRepositories.count == Constants.API.defaultPerPage
        
        // Cache the response if cache key is provided
        if let cacheKey = cacheKey, !isLoadMore {
            cacheManager.cacheSearchResponse(response, for: cacheKey)
        }
    }
    
    private func loadFromCache(key: String) {
        if let cachedResponse = cacheManager.getCachedSearchResponse(for: key) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.repositories = cachedResponse.items
                self.delegate?.repositoryViewModel(self, didUpdateRepositories: self.repositories)
            }
        }
    }
    
    private func resetPagination() {
        currentPage = 1
        hasMoreData = true
        repositories.removeAll()
    }
}

// MARK: - Repository Access

extension RepositoryViewModel {
    
    var numberOfRepositories: Int {
        return repositories.count
    }
    
    func repository(at index: Int) -> GitHubRepository? {
        guard index >= 0 && index < repositories.count else { return nil }
        return repositories[index]
    }
    
    func shouldLoadMore(at index: Int) -> Bool {
        // Trigger load more when reaching the last 3 items
        return index >= repositories.count - 3 && hasMoreData && !isLoadingMore
    }
}

// MARK: - Search State

extension RepositoryViewModel {
    
    var searchStateDescription: String {
        if isSearchMode {
            if let query = currentQuery {
                return "搜索: \(query)"
            } else {
                return "搜索中..."
            }
        } else {
            return "热门项目"
        }
    }
    
    var isEmpty: Bool {
        return repositories.isEmpty && !isLoading
    }
    
    var emptyStateMessage: String {
        if isSearchMode {
            return "未找到相关项目"
        } else {
            return "暂无数据"
        }
    }
}