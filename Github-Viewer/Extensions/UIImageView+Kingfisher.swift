//
//  UIImageView+Kingfisher.swift
//  Github-Viewer
//
//  Created by Xu Sensheng on 2026-01-15.
//  Copyright © 2026 Sensheng Xu. All rights reserved.
//

import UIKit
import Kingfisher

// MARK: - UIImageView Extension using Kingfisher

extension UIImageView {
    
    func loadImage(from urlString: String?, placeholder: UIImage? = nil) {
        // Set placeholder immediately
        self.image = placeholder
        
        guard let urlString = urlString, 
              !urlString.isEmpty,
              let url = URL(string: urlString) else {
            return
        }
        
        // Use Kingfisher to load image with caching
        self.kf.setImage(
            with: url,
            placeholder: placeholder,
            options: [
                .transition(.fade(0.25)),
                .cacheOriginalImage,
                .scaleFactor(UIScreen.main.scale)
            ]
        )
    }
}