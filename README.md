# GitHub Viewer - iOS App

一个功能完整的 GitHub 仓库浏览 iOS 应用，支持仓库搜索、用户信息展示、登录认证等核心功能。

## 项目目标

GitHub Viewer 是一个基于 GitHub API 的原生 iOS 应用，主要实现以下功能：

### 主要功能
- **首页仓库浏览**：展示热门 GitHub 仓库，支持无限滚动加载
- **智能搜索**：实时搜索 GitHub 仓库，支持关键词匹配
- **用户认证**：支持 Personal Access Token 登录，集成生物识别认证
- **个人中心**：展示用户信息、仓库统计、个人仓库列表
- **仓库详情**：查看仓库详细信息、README、贡献者、文件浏览
- **用户资料**：查看其他用户的公开信息和仓库
- **多语言支持**：支持中文和英文界面切换
- **深色模式**：完整支持 iOS 系统深色模式
- **多设备适配**：完美适配 iPhone 和 iPad 各种屏幕尺寸

### 数据安全
- **安全存储**：使用 Keychain 安全存储用户凭证
- **生物识别**：支持 Face ID / Touch ID 快速登录

## 🏗️ UI交互架构图

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Viewer App                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │             │  │             │  │             │          │
│  │    MainVC   │  │  SearchBar  │  │     MeVC    │          │
│  │             │  │             │  │  (SwiftUI)  │          │
│  └─────┬───────┘  └─────────────┘  └─────┬───────┘          │
│        │                                 │                  │
│        ▼                                 ▼                  │
│  ┌─────────────┐                  ┌─────────────┐           │
│  │             │                  │             │           │
│  │RepoDetailVC │                  │UserProfileVC│           │
│  │             │                  │             │           │
│  └─────┬───────┘                  └─────────────┘           │
│        │                                                    │
│        ▼                                                    │
│  ┌─────────────┐                                            │
│  │             │                                            │
│  │ FileBrowser │                                            │
│  │             │                                            │
│  └─────────────┘                                            │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                      Services                               │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │             │  │             │  │             │          │
│  │GitHubAPI    │  │AuthManager  │  │CacheManager │          │
│  │Service      │  │             │  │             │          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 页面流转关系
1. **启动流程**：App Launch → 检查登录状态 → 主页面/登录页面
2. **主要导航**：TabBar 导航（首页、我的）+ NavigationController 堆栈
3. **数据流向**：UI → ViewModel → APIService → GitHub API
4. **状态管理**：Combine + MVVM 架构模式

## 技术实现

### 主体架构
- **架构模式**：MVVM (Model-View-ViewModel) + Protocol-Oriented Programming
- **UI框架**：主要基于 **UIKit**，"我的"页面采用 **SwiftUI** 实现
- **响应式编程**：使用 **Combine** 框架处理异步数据流
- **网络层**：基于 **URLSession** + **Combine** 的现代网络架构
- **数据持久化**：**Keychain** (敏感数据) + **UserDefaults** (配置信息)
- **界面适配**：Auto Layout + Size Classes，完美支持多设备

### 技术栈
```
├── UI Layer
│   ├── UIKit (主框架)
│   ├── SwiftUI (Me页面)
│   └── Storyboard + 代码布局
├── Business Layer  
│   ├── MVVM Architecture
│   ├── Protocol-Oriented Design
│   └── Combine Reactive Programming
├── Network Layer
│   ├── URLSession
│   ├── Combine Publishers
│   └── JSON Codable Models
└── Storage Layer
    ├── Keychain Services
    ├── UserDefaults
    └── Cache Management
```

## 开源库依赖

本项目使用了以下优秀的开源库来实现特定功能：

### 1. **Kingfisher** `v8.6.2`
- **功能**：高性能图片加载和缓存
- **用途**：
  - 用户头像异步加载
  - 仓库 owner 头像展示
  - 图片内存和磁盘缓存管理
  - 占位图和加载动画
- **集成方式**：Swift Package Manager
- **关键特性**：
  ```swift
  // 使用示例
  imageView.kf.setImage(
      with: URL(string: user.avatarURL),
      placeholder: UIImage(systemName: "person.circle"),
      options: [.transition(.fade(0.3))]
  )
  ```

### 2. **Down** `master branch`
- **功能**：Markdown 渲染引擎
- **用途**：
  - GitHub README 文件渲染
  - 仓库描述 Markdown 格式支持
  - 文档内容富文本展示
- **集成方式**：Swift Package Manager
- **关键特性**：
  ```swift
  // Markdown 渲染示例
  let down = Down(markdownString: readmeContent)
  let attributedString = try? down.toAttributedString()
  ```

## 开发环境

- **Xcode**: 26.1
- **iOS Deployment Target**: 14.0+
- **Swift**: 5.9+
- **支持设备**: iPhone、iPad (Universal App)


## 测试

项目包含单元测试和UI自动化测试：

- **单元测试** (`Github-ViewerTests`): 测试核心业务逻辑和数据模型
- **UI测试** (`Github-ViewerUITests`): 测试用户交互流程和界面功能


## 许可证
本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。
