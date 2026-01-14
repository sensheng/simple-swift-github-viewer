//
//  UserProfileViewController.swift
//  Github-Viewer
//
//  Created by Xu Sensheng on 2026-01-14.
//  Copyright © 2026 Sensheng Xu. All rights reserved.
//

import UIKit

class UserProfileViewController: UIViewController {
    
    // MARK: - Properties
    
    private let viewModel: UserProfileViewModel
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let refreshControl = UIRefreshControl()
    
    // MARK: - UI Elements
    
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBackground
        return view
    }()
    
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 50
        imageView.backgroundColor = UIColor.systemGray5
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.textColor = UIColor.label
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = UIColor.secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let bioLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.label
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let infoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let statsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let joinedDateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Initialization
    
    init(username: String) {
        self.viewModel = UserProfileViewModel(username: username)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupViewModel()
        
        // Load data
        viewModel.loadUserProfile()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide tab bar when entering user profile
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show tab bar when leaving user profile (if going back to main)
        if isMovingFromParent {
            tabBarController?.tabBar.isHidden = false
        }
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemGroupedBackground
        title = viewModel.userLogin
        
        // Configure navigation bar
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
        
        // Add share button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(shareButtonTapped)
        )
        
        // Setup header view
        setupHeaderView()
        
        // Add table view
        view.addSubview(tableView)
        view.addSubview(loadingIndicator)
        
        setupConstraints()
    }
    
    private func setupHeaderView() {
        headerView.addSubview(avatarImageView)
        headerView.addSubview(nameLabel)
        headerView.addSubview(usernameLabel)
        headerView.addSubview(bioLabel)
        headerView.addSubview(infoStackView)
        headerView.addSubview(statsStackView)
        headerView.addSubview(joinedDateLabel)
        
        setupStatsStackView()
        setupHeaderConstraints()
    }
    
    private func setupStatsStackView() {
        let followersStat = createStatView(title: "关注者", value: viewModel.followersCount)
        let followingStat = createStatView(title: "关注中", value: viewModel.followingCount)
        let reposStat = createStatView(title: "仓库", value: viewModel.publicReposCount)
        
        statsStackView.addArrangedSubview(followersStat)
        statsStackView.addArrangedSubview(followingStat)
        statsStackView.addArrangedSubview(reposStat)
    }
    
    private func createStatView(title: String, value: String) -> UIView {
        let containerView = UIView()
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.boldSystemFont(ofSize: 20)
        valueLabel.textColor = UIColor.label
        valueLabel.textAlignment = .center
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.secondaryLabel
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(valueLabel)
        containerView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            valueLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            valueLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
    
    private func setupHeaderConstraints() {
        NSLayoutConstraint.activate([
            // Avatar
            avatarImageView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
            avatarImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 100),
            avatarImageView.heightAnchor.constraint(equalToConstant: 100),
            
            // Name
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            // Username
            usernameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            usernameLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            usernameLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            // Bio
            bioLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 12),
            bioLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            bioLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            // Info stack view
            infoStackView.topAnchor.constraint(equalTo: bioLabel.bottomAnchor, constant: 16),
            infoStackView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            infoStackView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            // Stats
            statsStackView.topAnchor.constraint(equalTo: infoStackView.bottomAnchor, constant: 20),
            statsStackView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            statsStackView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            // Joined date
            joinedDateLabel.topAnchor.constraint(equalTo: statsStackView.bottomAnchor, constant: 16),
            joinedDateLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            joinedDateLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            joinedDateLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupConstraints() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Table view
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.systemGroupedBackground
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Constants.UI.defaultRowHeight
        
        // Register cell
        tableView.registerCell(RepositoryTableViewCell.self)
        
        // Setup refresh control
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        // Set header view
        tableView.tableHeaderView = headerView
        
        // Update header view size
        updateHeaderViewSize()
    }
    
    private func setupViewModel() {
        viewModel.delegate = self
    }
    
    private func updateHeaderViewSize() {
        headerView.setNeedsLayout()
        headerView.layoutIfNeeded()
        
        let size = headerView.systemLayoutSizeFitting(
            CGSize(width: tableView.frame.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        
        if headerView.frame.size.height != size.height {
            headerView.frame.size.height = size.height
            tableView.tableHeaderView = headerView
        }
    }
    
    // MARK: - Actions
    
    @objc private func shareButtonTapped() {
        guard let url = viewModel.shareProfile() else { return }
        
        let activityViewController = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        
        if let popover = activityViewController.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(activityViewController, animated: true)
    }
    
    @objc private func handleRefresh() {
        viewModel.loadUserProfile()
    }
    
    // MARK: - Private Methods
    
    private func updateUI() {
        nameLabel.text = viewModel.displayName
        usernameLabel.text = "@\(viewModel.userLogin)"
        bioLabel.text = viewModel.userBio
        joinedDateLabel.text = viewModel.joinedDate
        
        // Load avatar
        if let avatarURL = viewModel.avatarURL {
            avatarImageView.loadImage(
                from: avatarURL,
                placeholder: UIImage(systemName: "person.circle.fill")
            )
        }
        
        // Update info stack view
        updateInfoStackView()
        
        // Update stats
        updateStatsStackView()
        
        // Update header view size
        updateHeaderViewSize()
    }
    
    private func updateInfoStackView() {
        // Clear existing arranged subviews
        infoStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add location if available
        if let location = viewModel.userLocation, !location.isEmpty {
            let locationView = createInfoView(icon: "location.fill", text: location)
            infoStackView.addArrangedSubview(locationView)
        }
        
        // Add company if available
        if let company = viewModel.userCompany, !company.isEmpty {
            let companyView = createInfoView(icon: "building.2.fill", text: company)
            infoStackView.addArrangedSubview(companyView)
        }
        
        // Add blog if available
        if let blog = viewModel.userBlog, !blog.isEmpty {
            let blogView = createInfoView(icon: "link", text: blog)
            infoStackView.addArrangedSubview(blogView)
        }
        
        // Add email if available
        if let email = viewModel.userEmail, !email.isEmpty {
            let emailView = createInfoView(icon: "envelope.fill", text: email)
            infoStackView.addArrangedSubview(emailView)
        }
    }
    
    private func createInfoView(icon: String, text: String) -> UIView {
        let containerView = UIView()
        
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = UIColor.secondaryLabel
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let textLabel = UILabel()
        textLabel.text = text
        textLabel.font = UIFont.systemFont(ofSize: 16)
        textLabel.textColor = UIColor.label
        textLabel.numberOfLines = 0
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(iconImageView)
        containerView.addSubview(textLabel)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            textLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            textLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            textLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            textLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
    
    private func updateStatsStackView() {
        // Remove existing arranged subviews
        statsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add updated stats
        let followersStat = createStatView(title: "关注者", value: viewModel.followersCount)
        let followingStat = createStatView(title: "关注中", value: viewModel.followingCount)
        let reposStat = createStatView(title: "仓库", value: viewModel.publicReposCount)
        
        statsStackView.addArrangedSubview(followersStat)
        statsStackView.addArrangedSubview(followingStat)
        statsStackView.addArrangedSubview(reposStat)
    }
}

// MARK: - User Profile View Model Delegate

extension UserProfileViewController: UserProfileViewModelDelegate {
    
    func userProfileViewModelDidStartLoading(_ viewModel: UserProfileViewModel) {
        if viewModel.numberOfRepositories == 0 {
            loadingIndicator.startAnimating()
        }
    }
    
    func userProfileViewModelDidFinishLoading(_ viewModel: UserProfileViewModel) {
        loadingIndicator.stopAnimating()
        refreshControl.endRefreshing()
        
        if viewModel.isEmpty {
            let message = "该用户暂无公开仓库"
            let image = UIImage(systemName: "folder")
            tableView.setEmptyState(message: message, image: image)
        } else {
            tableView.removeEmptyState()
        }
    }
    
    func userProfileViewModel(_ viewModel: UserProfileViewModel, didFailWithError error: Error) {
        loadingIndicator.stopAnimating()
        refreshControl.endRefreshing()
        
        // Show error alert
        let alert = UIAlertController(
            title: "加载失败",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "重试", style: .default) { [weak self] _ in
            self?.viewModel.loadUserProfile()
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        present(alert, animated: true)
        
        // Show empty state with error message
        if viewModel.numberOfRepositories == 0 {
            let image = UIImage(systemName: "exclamationmark.triangle")
            tableView.setEmptyState(message: error.localizedDescription, image: image)
        }
    }
    
    func userProfileViewModel(_ viewModel: UserProfileViewModel, didUpdateUser user: GitHubUserProfile) {
        updateUI()
    }
    
    func userProfileViewModel(_ viewModel: UserProfileViewModel, didUpdateRepositories repositories: [GitHubRepository]) {
        tableView.reloadData()
        
        // Scroll to top if this is a new load
        if !repositories.isEmpty {
            tableView.scrollToTop(animated: false)
        }
    }
    
    func userProfileViewModel(_ viewModel: UserProfileViewModel, didLoadMoreRepositories repositories: [GitHubRepository]) {
        let startIndex = viewModel.numberOfRepositories - repositories.count
        let indexPaths = repositories.enumerated().map { index, _ in
            IndexPath(row: startIndex + index, section: 0)
        }
        
        tableView.insertRows(at: indexPaths, with: .fade)
    }
}

// MARK: - Table View Data Source & Delegate

extension UserProfileViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRepositories
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let repository = viewModel.repository(at: indexPath.row) else { return }
        
        // Navigate to repository detail
        let detailViewController = RepositoryDetailViewController(repository: repository)
        navigationController?.pushViewController(detailViewController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.numberOfRepositories > 0 ? "仓库列表" : nil
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Add animation for cell appearance
        cell.alpha = 0
        cell.transform = CGAffineTransform(translationX: 0, y: 20)
        
        UIView.animate(withDuration: Constants.UI.defaultAnimationDuration) {
            cell.alpha = 1
            cell.transform = .identity
        }
    }
}