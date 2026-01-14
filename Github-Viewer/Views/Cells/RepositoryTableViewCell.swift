//
//  RepositoryTableViewCell.swift
//  Github-Viewer
//
//  Created by Xu Sensheng on 2026-01-14.
//  Copyright © 2026 Sensheng Xu. All rights reserved.
//

import UIKit

class RepositoryTableViewCell: UITableViewCell {
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBackground
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.label.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 20
        imageView.backgroundColor = UIColor.systemGray5
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = UIColor.label
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let ownerLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.secondaryLabel
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.label
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let languageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.white
        label.backgroundColor = UIColor.systemBlue
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let starImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "star.fill")
        imageView.tintColor = UIColor.systemYellow
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let starCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let forkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "tuningfork")
        imageView.tintColor = UIColor.systemGray
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let forkCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = UIColor.systemGroupedBackground
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        
        containerView.addSubview(avatarImageView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(ownerLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(languageLabel)
        containerView.addSubview(statsStackView)
        
        setupStatsStackView()
        setupConstraints()
    }
    
    private func setupStatsStackView() {
        let starStackView = UIStackView(arrangedSubviews: [starImageView, starCountLabel])
        starStackView.axis = .horizontal
        starStackView.spacing = 4
        starStackView.alignment = .center
        
        let forkStackView = UIStackView(arrangedSubviews: [forkImageView, forkCountLabel])
        forkStackView.axis = .horizontal
        forkStackView.spacing = 4
        forkStackView.alignment = .center
        
        statsStackView.addArrangedSubview(starStackView)
        statsStackView.addArrangedSubview(forkStackView)
        statsStackView.addArrangedSubview(UIView()) // Spacer
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            // Avatar image view
            avatarImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            avatarImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),
            
            // Name label
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: languageLabel.leadingAnchor, constant: -8),
            
            // Owner label
            ownerLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            ownerLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            ownerLabel.trailingAnchor.constraint(lessThanOrEqualTo: languageLabel.leadingAnchor, constant: -8),
            
            // Language label
            languageLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            languageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            languageLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            languageLabel.heightAnchor.constraint(equalToConstant: 24),
            
            // Description label
            descriptionLabel.topAnchor.constraint(equalTo: ownerLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            // Stats stack view
            statsStackView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 12),
            statsStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            statsStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            statsStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            
            // Star and fork image views
            starImageView.widthAnchor.constraint(equalToConstant: 16),
            starImageView.heightAnchor.constraint(equalToConstant: 16),
            forkImageView.widthAnchor.constraint(equalToConstant: 16),
            forkImageView.heightAnchor.constraint(equalToConstant: 16)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with repository: GitHubRepository) {
        nameLabel.text = repository.name
        ownerLabel.text = repository.owner.login
        descriptionLabel.text = repository.description ?? "无描述"
        starCountLabel.text = repository.formattedStarCount
        forkCountLabel.text = repository.formattedForkCount
        
        // Configure language label
        if let language = repository.language {
            languageLabel.text = language
            languageLabel.isHidden = false
            languageLabel.backgroundColor = colorForLanguage(language)
        } else {
            languageLabel.isHidden = true
        }
        
        // Load avatar image
        avatarImageView.loadImage(
            from: repository.avatarURL,
            placeholder: UIImage(systemName: "person.circle.fill")
        )
    }
    
    // MARK: - Helper Methods
    
    private func colorForLanguage(_ language: String) -> UIColor {
        switch language.lowercased() {
        case "swift":
            return UIColor.systemOrange
        case "javascript", "typescript":
            return UIColor.systemYellow
        case "python":
            return UIColor.systemBlue
        case "java":
            return UIColor.systemRed
        case "kotlin":
            return UIColor.systemPurple
        case "go":
            return UIColor.systemTeal
        case "rust":
            return UIColor.systemBrown
        case "c++", "c":
            return UIColor.systemIndigo
        case "ruby":
            return UIColor.systemPink
        case "php":
            return UIColor.systemGray
        default:
            return UIColor.systemBlue
        }
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.image = nil
        nameLabel.text = nil
        ownerLabel.text = nil
        descriptionLabel.text = nil
        languageLabel.text = nil
        starCountLabel.text = nil
        forkCountLabel.text = nil
        languageLabel.isHidden = false
    }
}