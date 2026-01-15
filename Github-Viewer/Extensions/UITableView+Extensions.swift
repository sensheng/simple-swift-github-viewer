//
//  UITableView+Extensions.swift
//  Github-Viewer
//
//  Created by Xu Sensheng on 2026-01-14.
//  Copyright © 2026 Sensheng Xu. All rights reserved.
//

import UIKit

extension UITableView {
    
    // MARK: - Cell Registration
    
    func registerCell<T: UITableViewCell>(_ cellClass: T.Type) {
        let identifier = String(describing: cellClass)
        register(cellClass, forCellReuseIdentifier: identifier)
    }
    
    func dequeueReusableCell<T: UITableViewCell>(_ cellClass: T.Type, for indexPath: IndexPath) -> T {
        let identifier = String(describing: cellClass)
        guard let cell = dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(identifier)")
        }
        return cell
    }
    
    // MARK: - Empty State
    
    func setEmptyState(message: String, image: UIImage? = nil) {
        let emptyView = EmptyStateView()
        emptyView.configure(message: message, image: image)
        backgroundView = emptyView
    }
    
    func removeEmptyState() {
        backgroundView = nil
    }
    
    // MARK: - Loading State
    
    func setLoadingState() {
        let loadingView = LoadingStateView()
        backgroundView = loadingView
    }
    
    // MARK: - Scroll to Top
    
    func scrollToTop(animated: Bool = true) {
        guard numberOfSections > 0 else { return }
        
        let indexPath = IndexPath(row: 0, section: 0)
        if numberOfRows(inSection: 0) > 0 {
            scrollToRow(at: indexPath, at: .top, animated: animated)
        }
    }
}

// MARK: - Empty State View

class EmptyStateView: UIView {
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.systemGray3
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.systemGray2
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        addSubview(stackView)
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(messageLabel)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 32),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -32),
            
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    func configure(message: String, image: UIImage? = nil) {
        messageLabel.text = message
        
        if let image = image {
            imageView.image = image
            imageView.isHidden = false
        } else {
            imageView.image = UIImage(systemName: "folder")
            imageView.isHidden = false
        }
    }
}

// MARK: - Loading State View

class LoadingStateView: UIView {
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = UIColor.systemGray2
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Loading...", comment: "Loading text")
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.systemGray2
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        addSubview(activityIndicator)
        addSubview(messageLabel)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -20),
            
            messageLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 16),
            messageLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
        
        activityIndicator.startAnimating()
    }
}