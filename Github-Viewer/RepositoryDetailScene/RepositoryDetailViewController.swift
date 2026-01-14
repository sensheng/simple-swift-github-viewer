//
//  RepositoryDetailViewController.swift
//  Github-Viewer
//
//  Created by Xu Sensheng on 2026-01-14.
//  Copyright © 2026 Sensheng Xu. All rights reserved.
//

import UIKit
import WebKit

class RepositoryDetailViewController: UIViewController {
    
    // MARK: - Properties
    
    private let viewModel: RepositoryDetailViewModel
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // MARK: - UI Elements
    
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 30
        imageView.backgroundColor = UIColor.systemGray5
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let repositoryNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.textColor = UIColor.label
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let ownerLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = UIColor.systemBlue
        label.isUserInteractionEnabled = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let segmentedControl: UISegmentedControl = {
        let items = ["README", "语言", "贡献者"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private let contentContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let readmeWebView: WKWebView = {
        let webView = WKWebView()
        webView.backgroundColor = UIColor.systemBackground
        webView.isOpaque = false
        webView.translatesAutoresizingMaskIntoConstraints = false
        return webView
    }()
    
    private let languagesTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = UIColor.systemGroupedBackground
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private let contributorsTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = UIColor.systemGroupedBackground
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Initialization
    
    init(repository: GitHubRepository) {
        self.viewModel = RepositoryDetailViewModel(repository: repository)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupViewModel()
        setupTableViews()
        setupSegmentedControl()
        
        // Load data
        viewModel.loadRepositoryDetails()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide tab bar when entering repository detail
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show tab bar when leaving repository detail (if going back to main)
        if isMovingFromParent {
            tabBarController?.tabBar.isHidden = false
        }
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemGroupedBackground
        title = viewModel.repositoryName
        
        // Configure navigation bar
        navigationItem.largeTitleDisplayMode = .never
        
        // Add Safari button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "safari"),
            style: .plain,
            target: self,
            action: #selector(openInSafariButtonTapped)
        )
        
        // Setup scroll view
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Add subviews
        contentView.addSubview(headerView)
        contentView.addSubview(segmentedControl)
        contentView.addSubview(contentContainerView)
        contentView.addSubview(loadingIndicator)
        
        setupHeaderView()
        setupContentViews()
        setupConstraints()
        setupGestureRecognizers()
    }
    
    private func setupHeaderView() {
        headerView.addSubview(avatarImageView)
        headerView.addSubview(repositoryNameLabel)
        headerView.addSubview(ownerLabel)
        headerView.addSubview(descriptionLabel)
        headerView.addSubview(statsStackView)
        
        setupStatsStackView()
    }
    
    private func setupStatsStackView() {
        let starsStat = createStatView(icon: "star.fill", color: .systemYellow, title: "Stars", value: viewModel.starsCount)
        let forksStat = createStatView(icon: "tuningfork", color: .systemBlue, title: "Forks", value: viewModel.forksCount)
        let watchersStat = createStatView(icon: "eye.fill", color: .systemGreen, title: "Watchers", value: viewModel.watchersCount)
        
        statsStackView.addArrangedSubview(starsStat)
        statsStackView.addArrangedSubview(forksStat)
        statsStackView.addArrangedSubview(watchersStat)
    }
    
    private func createStatView(icon: String, color: UIColor, title: String, value: String) -> UIView {
        let containerView = UIView()
        
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = color
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.boldSystemFont(ofSize: 18)
        valueLabel.textColor = UIColor.label
        valueLabel.textAlignment = .center
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.secondaryLabel
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(iconImageView)
        containerView.addSubview(valueLabel)
        containerView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            valueLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 4),
            valueLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 2),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
    
    private func setupContentViews() {
        contentContainerView.addSubview(readmeWebView)
        contentContainerView.addSubview(languagesTableView)
        contentContainerView.addSubview(contributorsTableView)
        
        // Initially show README
        readmeWebView.isHidden = false
        languagesTableView.isHidden = true
        contributorsTableView.isHidden = true
    }
    
    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Header view
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            // Avatar
            avatarImageView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            avatarImageView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            avatarImageView.widthAnchor.constraint(equalToConstant: 60),
            avatarImageView.heightAnchor.constraint(equalToConstant: 60),
            
            // Repository name
            repositoryNameLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            repositoryNameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 16),
            repositoryNameLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            // Owner
            ownerLabel.topAnchor.constraint(equalTo: repositoryNameLabel.bottomAnchor, constant: 4),
            ownerLabel.leadingAnchor.constraint(equalTo: repositoryNameLabel.leadingAnchor),
            ownerLabel.trailingAnchor.constraint(equalTo: repositoryNameLabel.trailingAnchor),
            
            // Description
            descriptionLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            // Stats
            statsStackView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20),
            statsStackView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            statsStackView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            statsStackView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16),
            
            // Segmented control
            segmentedControl.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Content container
            contentContainerView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            contentContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            contentContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 400),
            
            // Content views
            readmeWebView.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
            readmeWebView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            readmeWebView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            readmeWebView.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor),
            
            languagesTableView.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
            languagesTableView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            languagesTableView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            languagesTableView.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor),
            
            contributorsTableView.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
            contributorsTableView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            contributorsTableView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            contributorsTableView.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor),
            
            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    private func setupViewModel() {
        viewModel.delegate = self
        updateUI()
    }
    
    private func setupTableViews() {
        languagesTableView.delegate = self
        languagesTableView.dataSource = self
        languagesTableView.register(UITableViewCell.self, forCellReuseIdentifier: "LanguageCell")
        
        contributorsTableView.delegate = self
        contributorsTableView.dataSource = self
        contributorsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "ContributorCell")
    }
    
    private func setupSegmentedControl() {
        segmentedControl.addTarget(self, action: #selector(segmentedControlChanged), for: .valueChanged)
    }
    
    private func setupGestureRecognizers() {
        // Owner tap gesture
        let ownerTapGesture = UITapGestureRecognizer(target: self, action: #selector(ownerTapped))
        ownerLabel.addGestureRecognizer(ownerTapGesture)
    }
    
    // MARK: - Actions
    
    @objc private func openInSafariButtonTapped() {
        viewModel.openInSafari()
    }
    
    @objc private func ownerTapped() {
        let userProfileViewController = UserProfileViewController(username: viewModel.ownerName)
        navigationController?.pushViewController(userProfileViewController, animated: true)
    }
    
    @objc private func segmentedControlChanged() {
        switch segmentedControl.selectedSegmentIndex {
        case 0: // README
            readmeWebView.isHidden = false
            languagesTableView.isHidden = true
            contributorsTableView.isHidden = true
        case 1: // Languages
            readmeWebView.isHidden = true
            languagesTableView.isHidden = false
            contributorsTableView.isHidden = true
        case 2: // Contributors
            readmeWebView.isHidden = true
            languagesTableView.isHidden = true
            contributorsTableView.isHidden = false
        default:
            break
        }
    }
    
    // MARK: - Private Methods
    
    private func updateUI() {
        repositoryNameLabel.text = viewModel.repositoryName
        ownerLabel.text = viewModel.ownerName
        descriptionLabel.text = viewModel.repositoryDescription
        
        // Load avatar
        avatarImageView.loadImage(
            from: viewModel.repository.owner.avatarURL,
            placeholder: UIImage(systemName: "person.circle.fill")
        )
        
        // Update stats
        updateStatsStackView()
    }
    
    private func updateStatsStackView() {
        // Remove existing arranged subviews
        statsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add updated stats
        let starsStat = createStatView(icon: "star.fill", color: .systemYellow, title: "Stars", value: viewModel.starsCount)
        let forksStat = createStatView(icon: "tuningfork", color: .systemBlue, title: "Forks", value: viewModel.forksCount)
        let watchersStat = createStatView(icon: "eye.fill", color: .systemGreen, title: "Watchers", value: viewModel.watchersCount)
        
        statsStackView.addArrangedSubview(starsStat)
        statsStackView.addArrangedSubview(forksStat)
        statsStackView.addArrangedSubview(watchersStat)
    }
    
    private func loadReadmeContent() {
        guard let readmeContent = viewModel.readmeContent else {
            let html = "<html><body><p>无README文件</p></body></html>"
            readmeWebView.loadHTMLString(html, baseURL: nil)
            return
        }
        
        // Convert Markdown to HTML (simplified)
        let html = """
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body { 
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    padding: 16px;
                    line-height: 1.6;
                    color: \(UIColor.label.hexString);
                    background-color: \(UIColor.systemBackground.hexString);
                }
                pre { 
                    background-color: \(UIColor.systemGray6.hexString);
                    padding: 12px;
                    border-radius: 8px;
                    overflow-x: auto;
                }
                code {
                    background-color: \(UIColor.systemGray6.hexString);
                    padding: 2px 4px;
                    border-radius: 4px;
                }
            </style>
        </head>
        <body>
            <pre>\(readmeContent.htmlEscaped)</pre>
        </body>
        </html>
        """
        
        readmeWebView.loadHTMLString(html, baseURL: nil)
    }
}

// MARK: - Repository Detail View Model Delegate

extension RepositoryDetailViewController: RepositoryDetailViewModelDelegate {
    
    func repositoryDetailViewModelDidStartLoading(_ viewModel: RepositoryDetailViewModel) {
        loadingIndicator.startAnimating()
    }
    
    func repositoryDetailViewModelDidFinishLoading(_ viewModel: RepositoryDetailViewModel) {
        loadingIndicator.stopAnimating()
    }
    
    func repositoryDetailViewModel(_ viewModel: RepositoryDetailViewModel, didFailWithError error: Error) {
        loadingIndicator.stopAnimating()
        
        let alert = UIAlertController(
            title: "加载失败",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "重试", style: .default) { [weak self] _ in
            self?.viewModel.loadRepositoryDetails()
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        present(alert, animated: true)
    }
    
    func repositoryDetailViewModel(_ viewModel: RepositoryDetailViewModel, didUpdateRepository repository: GitHubRepository) {
        updateUI()
    }
    
    func repositoryDetailViewModel(_ viewModel: RepositoryDetailViewModel, didUpdateReadme readme: GitHubReadme?) {
        loadReadmeContent()
    }
    
    func repositoryDetailViewModel(_ viewModel: RepositoryDetailViewModel, didUpdateContributors contributors: [GitHubContributor]) {
        contributorsTableView.reloadData()
    }
    
    func repositoryDetailViewModel(_ viewModel: RepositoryDetailViewModel, didUpdateLanguages languages: GitHubLanguageStats) {
        languagesTableView.reloadData()
    }
}

// MARK: - Table View Data Source & Delegate

extension RepositoryDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == languagesTableView {
            return viewModel.languagePercentages.count
        } else if tableView == contributorsTableView {
            return viewModel.contributors.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == languagesTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LanguageCell", for: indexPath)
            let languageInfo = viewModel.languagePercentages[indexPath.row]
            
            cell.textLabel?.text = languageInfo.language
            cell.detailTextLabel?.text = String(format: "%.1f%%", languageInfo.percentage)
            cell.backgroundColor = UIColor.systemBackground
            
            // Add color indicator
            let colorView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
            colorView.backgroundColor = languageInfo.color
            colorView.layer.cornerRadius = 10
            cell.accessoryView = colorView
            
            return cell
        } else if tableView == contributorsTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContributorCell", for: indexPath)
            let contributor = viewModel.contributors[indexPath.row]
            
            cell.textLabel?.text = contributor.login
            cell.detailTextLabel?.text = "\(contributor.contributions) 贡献"
            cell.backgroundColor = UIColor.systemBackground
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if tableView == contributorsTableView {
            let contributor = viewModel.contributors[indexPath.row]
            let userProfileViewController = UserProfileViewController(username: contributor.login)
            navigationController?.pushViewController(userProfileViewController, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView == languagesTableView {
            return "编程语言"
        } else if tableView == contributorsTableView {
            return "贡献者"
        }
        return nil
    }
}

// MARK: - Extensions

extension UIColor {
    var hexString: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return String(format: "#%02X%02X%02X",
                     Int(red * 255),
                     Int(green * 255),
                     Int(blue * 255))
    }
}

extension String {
    var htmlEscaped: String {
        return self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}