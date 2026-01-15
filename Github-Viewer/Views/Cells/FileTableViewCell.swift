//
//  FileTableViewCell.swift
//  Github-Viewer
//
//  Created by Xu Sensheng on 2026-01-14.
//  Copyright © 2026 Sensheng Xu. All rights reserved.
//

import UIKit

class FileTableViewCell: UITableViewCell {
    
    static let identifier = "FileTableViewCell"
    
    // MARK: - UI Elements
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.systemBlue
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.label
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let sizeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.secondaryLabel
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let chevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.tertiaryLabel
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
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
        backgroundColor = UIColor.systemBackground
        selectionStyle = .default
        
        contentView.addSubview(iconImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(sizeLabel)
        contentView.addSubview(chevronImageView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Icon
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            // Name label
            nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronImageView.leadingAnchor, constant: -8),
            
            // Size label
            sizeLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            sizeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            sizeLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronImageView.leadingAnchor, constant: -8),
            sizeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            // Chevron
            chevronImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chevronImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 12)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with file: GitHubFile) {
        // 显示完整路径而不是仅文件名
        nameLabel.text = file.displayName
        iconImageView.image = UIImage(systemName: file.iconName)
        
        // 由于我们只显示文件（不显示文件夹），所以总是显示文件大小
        sizeLabel.text = formatFileSize(file.size)
        iconImageView.tintColor = colorForFileType(file.fileExtension)
        chevronImageView.isHidden = false
    }
    
    // MARK: - Helper Methods
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func colorForFileType(_ extension: String?) -> UIColor {
        guard let ext = `extension`?.lowercased() else {
            return UIColor.systemGray
        }
        
        switch ext {
        case "swift":
            return UIColor.systemOrange
        case "js", "ts", "jsx", "tsx":
            return UIColor.systemYellow
        case "py":
            return UIColor.systemBlue
        case "java", "kt":
            return UIColor.systemRed
        case "go":
            return UIColor.systemTeal
        case "rs":
            return UIColor.systemBrown
        case "cpp", "c", "h":
            return UIColor.systemIndigo
        case "rb":
            return UIColor.systemPink
        case "php":
            return UIColor.systemPurple
        case "html", "htm":
            return UIColor.systemOrange
        case "css", "scss", "sass":
            return UIColor.systemBlue
        case "json", "xml", "yaml", "yml":
            return UIColor.systemGreen
        case "md", "markdown":
            return UIColor.systemBlue
        case "txt":
            return UIColor.systemGray
        case "pdf":
            return UIColor.systemRed
        case "jpg", "jpeg", "png", "gif", "svg":
            return UIColor.systemPink
        case "mp4", "mov", "avi":
            return UIColor.systemPurple
        case "mp3", "wav", "m4a":
            return UIColor.systemGreen
        case "zip", "tar", "gz":
            return UIColor.systemBrown
        default:
            return UIColor.systemGray
        }
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        sizeLabel.text = nil
        iconImageView.image = nil
        iconImageView.tintColor = UIColor.systemBlue
        chevronImageView.isHidden = false
    }
}