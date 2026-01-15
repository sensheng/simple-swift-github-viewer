//
//  RemoteImageView.swift
//  Github-Viewer
//
//  Created by Xu Sensheng on 2026-01-14.
//  Copyright © 2026 Sensheng Xu. All rights reserved.
//

import SwiftUI
import Kingfisher

// iOS 14 compatible remote image view using Kingfisher
struct RemoteImageView: View {
    
    let url: String?
    
    var body: some View {
        Group {
            if let urlString = url, let imageURL = URL(string: urlString) {
                KFImage(imageURL)
                    .placeholder {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.gray)
            }
        }
    }
}