//
//  MarkdownView.swift
//  Github-Viewer
//
//  Created by Xu Sensheng on 2026-01-14.
//  Copyright © 2026 Sensheng Xu. All rights reserved.
//

import UIKit
import Down

// MARK: - Markdown View using Down

class MarkdownView: UIView {
    
    // MARK: - Properties
    
    private let scrollView: UIScrollView
    private let contentView: UIView
    private let loadingIndicator: UIActivityIndicatorView
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        self.scrollView = UIScrollView()
        self.contentView = UIView()
        self.loadingIndicator = UIActivityIndicatorView(style: .medium)
        
        super.init(frame: frame)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        self.scrollView = UIScrollView()
        self.contentView = UIView()
        self.loadingIndicator = UIActivityIndicatorView(style: .medium)
        
        super.init(coder: coder)
        
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = UIColor.systemBackground
        
        // Configure scroll view
        scrollView.backgroundColor = UIColor.clear
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure content view
        contentView.backgroundColor = UIColor.clear
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure loading indicator
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        addSubview(scrollView)
        addSubview(loadingIndicator)
        scrollView.addSubview(contentView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    // MARK: - Public Methods
    
    func loadMarkdown(_ markdown: String, baseURL: URL? = nil) {
        loadingIndicator.startAnimating()
        
        // 在主线程获取CSS样式，避免在后台线程访问traitCollection
        let cssStyle = generateCSS()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let down = Down(markdownString: markdown)
                let attributedString = try down.toAttributedString(.default, stylesheet: cssStyle)
                
                DispatchQueue.main.async {
                    self?.displayAttributedString(attributedString)
                    self?.loadingIndicator.stopAnimating()
                }
            } catch {
                print("⚠️ Failed to render markdown: \(error)")
                DispatchQueue.main.async {
                    self?.displayPlainText(markdown)
                    self?.loadingIndicator.stopAnimating()
                }
            }
        }
    }
    
    func loadMarkdownFromURL(_ url: URL) {
        loadingIndicator.startAnimating()
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self,
                      let data = data,
                      let markdown = String(data: data, encoding: .utf8) else {
                    self?.loadingIndicator.stopAnimating()
                    return
                }
                
                self.loadMarkdown(markdown, baseURL: url.deletingLastPathComponent())
            }
        }.resume()
    }
    
    // MARK: - Private Methods
    
    private func displayAttributedString(_ attributedString: NSAttributedString) {
        // Clear previous content
        contentView.subviews.forEach { $0.removeFromSuperview() }
        
        // Create text view
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = UIColor.clear
        textView.attributedText = attributedString
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add text view to content view
        contentView.addSubview(textView)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    private func displayPlainText(_ text: String) {
        // Clear previous content
        contentView.subviews.forEach { $0.removeFromSuperview() }
        
        // Create label
        let label = UILabel()
        label.text = text
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.label
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // Add label to content view
        contentView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    private func generateCSS() -> String {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        let backgroundColor = isDarkMode ? "#1c1c1e" : "#ffffff"
        let textColor = isDarkMode ? "#ffffff" : "#000000"
        let codeBackgroundColor = isDarkMode ? "#2c2c2e" : "#f6f8fa"
        let borderColor = isDarkMode ? "#3a3a3c" : "#d1d9e0"
        
        return """
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
            line-height: 1.6;
            color: \(textColor);
            background-color: \(backgroundColor);
            margin: 0;
            padding: 16px;
            word-wrap: break-word;
        }
        
        h1, h2, h3, h4, h5, h6 {
            margin-top: 24px;
            margin-bottom: 16px;
            font-weight: 600;
            line-height: 1.25;
        }
        
        h1 {
            font-size: 2em;
            border-bottom: 1px solid \(borderColor);
            padding-bottom: 0.3em;
        }
        
        h2 {
            font-size: 1.5em;
            border-bottom: 1px solid \(borderColor);
            padding-bottom: 0.3em;
        }
        
        code {
            background-color: \(codeBackgroundColor);
            border-radius: 6px;
            font-size: 85%;
            margin: 0;
            padding: 0.2em 0.4em;
            font-family: 'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace;
        }
        
        pre {
            background-color: \(codeBackgroundColor);
            border-radius: 6px;
            font-size: 85%;
            line-height: 1.45;
            overflow: auto;
            padding: 16px;
        }
        
        a {
            color: #0969da;
            text-decoration: none;
        }
        
        img {
            max-width: 100%;
            height: auto;
            border-radius: 6px;
            margin: 8px 0;
        }
        """
    }
}