//
//  MeViewController.swift
//  Github-Viewer
//
//  Created by Xu Sensheng on 2026-01-14.
//  Copyright © 2026 Sensheng Xu. All rights reserved.
//

import UIKit
import SwiftUI
import Combine

class MeViewController: UIViewController {
    
    // MARK: - Properties
    
    private var hostingController: UIHostingController<MeView>!
    private var meView: MeView!
    private var viewModel: MeViewModel!
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSwiftUIView()
        setupNavigationBar()
        observeLoginState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Show navigation bar and setup buttons
        navigationController?.setNavigationBarHidden(false, animated: animated)
        setupNavigationBarButtons()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Clear navigation bar buttons when leaving
        navigationItem.rightBarButtonItems = nil
    }
    
    // MARK: - Setup
    
    private func setupSwiftUIView() {
        title = NSLocalizedString("Me", comment: "Me tab title")
        
        viewModel = MeViewModel()
        meView = MeView(viewModel: viewModel)
        meView.navigationDelegate = self
        
        // Create hosting controller
        hostingController = UIHostingController(rootView: meView)
        
        // Add as child view controller
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        // Setup constraints
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Match system background
        view.backgroundColor = UIColor.systemGroupedBackground
        hostingController.view.backgroundColor = UIColor.clear
    }
    
    private func setupNavigationBarButtons() {
        // Check if user is logged in through AuthManager instead of accessing StateObject
        if AuthManager.shared.checkForSavedToken() && AuthManager.shared.accessToken != nil {
            let refreshButton = UIBarButtonItem(
                image: UIImage(systemName: "arrow.clockwise"),
                style: .plain,
                target: self,
                action: #selector(refreshButtonTapped)
            )
            
            let logoutButton = UIBarButtonItem(
                image: UIImage(systemName: "rectangle.portrait.and.arrow.right"),
                style: .plain,
                target: self,
                action: #selector(logoutButtonTapped)
            )
            
            logoutButton.tintColor = .systemRed
            
            navigationItem.rightBarButtonItems = [logoutButton, refreshButton]
            print("🔍 [MeViewController] Navigation bar buttons created. Count: \(navigationItem.rightBarButtonItems?.count ?? 0)")
            
            // Force layout update for iPad
            if UIDevice.current.userInterfaceIdiom == .pad {
                DispatchQueue.main.async { [weak self] in
                    self?.navigationController?.navigationBar.setNeedsLayout()
                    self?.navigationController?.navigationBar.layoutIfNeeded()
                    print("🔍 [MeViewController] Forced navigation bar layout update for iPad")
                }
            }
        } else {
            navigationItem.rightBarButtonItems = nil
        }
    }
    
    @objc private func refreshButtonTapped() {
        viewModel.refreshProfile()
    }
    
    @objc private func logoutButtonTapped() {
        let alert = UIAlertController(
            title: NSLocalizedString("Logout Confirmation", comment: "Logout alert title"),
            message: NSLocalizedString("Logout Confirmation Message", comment: "Logout alert message"),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button"), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Logout", comment: "Logout button"), style: .destructive) { [weak self] _ in
            self?.viewModel.logout()
            self?.navigationItem.rightBarButtonItems = nil
        })
        
        present(alert, animated: true)
    }
    
    private func observeLoginState() {
        // Listen for login/logout notifications instead of accessing StateObject
        NotificationCenter.default.publisher(for: .userDidLogin)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.setupNavigationBarButtons()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .userDidLogout)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.setupNavigationBarButtons()
            }
            .store(in: &cancellables)
    }
    
    private func setupNavigationBar() {
        // Configure tab bar item
        tabBarItem = UITabBarItem(
            title: NSLocalizedString("Me", comment: "Me tab title"),
            image: UIImage(systemName: "person"),
            selectedImage: UIImage(systemName: "person.fill")
        )
    }
}

// MARK: - MeViewNavigationDelegate

extension MeViewController: MeViewNavigationDelegate {
    
    func navigateToRepositoryDetail(_ repository: GitHubRepository) {
        let detailViewController = RepositoryDetailViewController(repository: repository)
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}
