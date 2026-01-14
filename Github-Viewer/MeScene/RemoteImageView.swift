//
//  RemoteImageView.swift
//  Github-Viewer
//
//  Created by Xu Sensheng on 2026-01-14.
//  Copyright © 2026 Sensheng Xu. All rights reserved.
//

import SwiftUI
import Combine

// iOS 14 compatible remote image view
struct RemoteImageView: View {
    
    let url: String?
    @StateObject private var imageLoader = ImageLoader()
    
    var body: some View {
        Group {
            if let image = imageLoader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            if let urlString = url {
                imageLoader.loadImage(from: urlString)
            }
        }
    }
}

// Image loader for iOS 14 compatibility using existing ImageCache
class ImageLoader: ObservableObject {
    
    @Published var image: UIImage?
    
    func loadImage(from urlString: String) {
        // Use existing ImageCache from the project
        ImageCache.shared.loadImage(from: urlString) { [weak self] loadedImage in
            DispatchQueue.main.async {
                self?.image = loadedImage
            }
        }
    }
}