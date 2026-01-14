//
//  MainViewController.swift
//  Github-Viewer
//
//  Created by Xu Sensheng on 2026-01-14.
//  Copyright © 2026 Sensheng Xu. All rights reserved.
//

import UIKit

class MainViewController: UITableViewController {
    
    // MARK: - Properties
    
    private let viewModel = RepositoryViewModel()
    private let searchController = UISearchController(searchResultsController: nil)
    private let customRefreshControl = UIRefreshControl()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupViewModel()
        setupSearchController()
        setupRefreshControl()
        
        // Load initial data
        viewModel.loadTrendingRepositories()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        title = "GitHub"
        
        // Configure table view
        tableView.backgroundColor = UIColor.systemGroupedBackground
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Constants.UI.defaultRowHeight
        
        // Register cell
        tableView.registerCell(RepositoryTableViewCell.self)
        
        // Configure navigation bar
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        // Add search controller to navigation item
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func setupViewModel() {
        viewModel.delegate = self
    }
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "搜索 GitHub 项目"
        searchController.searchBar.delegate = self
        
        // Configure search bar appearance
        if let textField = searchController.searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = UIColor.systemBackground
        }
    }
    
    private func setupRefreshControl() {
        customRefreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = customRefreshControl
    }
    
    // MARK: - Actions
    
    @objc private func handleRefresh() {
        if searchController.isActive && !searchController.searchBar.text!.isEmpty {
            // Refresh search results
            viewModel.searchRepositories(searchController.searchBar.text!)
        } else {
            // Refresh trending repositories
            viewModel.loadTrendingRepositories(refresh: true)
        }
    }
    
    // MARK: - Table View Data Source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRepositories
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(RepositoryTableViewCell.self, for: indexPath)
        
        if let repository = viewModel.repository(at: indexPath.row) {
            cell.configure(with: repository)
        }
        
        // Check if we need to load more data
        if viewModel.shouldLoadMore(at: indexPath.row) {
            viewModel.loadMoreRepositories()
        }
        
        return cell
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let repository = viewModel.repository(at: indexPath.row) else { return }
        let detailViewController = RepositoryDetailViewController(repository: repository)
        navigationController?.pushViewController(detailViewController, animated: true)
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Add animation for cell appearance
        cell.alpha = 0
        cell.transform = CGAffineTransform(translationX: 0, y: 20)
        
        UIView.animate(withDuration: Constants.UI.defaultAnimationDuration) {
            cell.alpha = 1
            cell.transform = .identity
        }
    }
    
    // MARK: - Scroll View Delegate
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Hide keyboard when scrolling
        if searchController.isActive {
            searchController.searchBar.resignFirstResponder()
        }
    }
}

// MARK: - RepositoryViewModelDelegate

extension MainViewController: RepositoryViewModelDelegate {
    
    func repositoryViewModelDidStartLoading(_ viewModel: RepositoryViewModel) {
        if viewModel.numberOfRepositories == 0 {
            tableView.setLoadingState()
        }
    }
    
    func repositoryViewModelDidFinishLoading(_ viewModel: RepositoryViewModel) {
        customRefreshControl.endRefreshing()
        
        if viewModel.isEmpty {
            let message = viewModel.emptyStateMessage
            let image = UIImage(systemName: "magnifyingglass")
            tableView.setEmptyState(message: message, image: image)
        } else {
            tableView.removeEmptyState()
        }
    }
    
    func repositoryViewModel(_ viewModel: RepositoryViewModel, didFailWithError error: Error) {
        customRefreshControl.endRefreshing()
        
        // Show error alert
        let alert = UIAlertController(
            title: "加载失败",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "重试", style: .default) { [weak self] _ in
            self?.handleRefresh()
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        present(alert, animated: true)
        
        // Show empty state with error message
        if viewModel.numberOfRepositories == 0 {
            let image = UIImage(systemName: "exclamationmark.triangle")
            tableView.setEmptyState(message: error.localizedDescription, image: image)
        }
    }
    
    func repositoryViewModel(_ viewModel: RepositoryViewModel, didUpdateRepositories repositories: [GitHubRepository]) {
        tableView.reloadData()
        
        // Scroll to top if this is a new search or refresh
        if !repositories.isEmpty {
            tableView.scrollToTop(animated: false)
        }
    }
    
    func repositoryViewModel(_ viewModel: RepositoryViewModel, didLoadMoreRepositories repositories: [GitHubRepository]) {
        let startIndex = viewModel.numberOfRepositories - repositories.count
        let indexPaths = repositories.enumerated().map { index, _ in
            IndexPath(row: startIndex + index, section: 0)
        }
        
        tableView.insertRows(at: indexPaths, with: .fade)
    }
}

// MARK: - UISearchResultsUpdating

extension MainViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        
        if searchText.isEmpty {
            viewModel.clearSearch()
        } else {
            viewModel.searchRepositories(searchText)
        }
    }
}

// MARK: - UISearchBarDelegate

extension MainViewController: UISearchBarDelegate {
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        viewModel.clearSearch()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
