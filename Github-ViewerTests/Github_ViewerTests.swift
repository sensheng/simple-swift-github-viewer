//
//  Github_ViewerTests.swift
//  Github-ViewerTests
//
//  Created by Xu Sensheng on 2026-01-14.
//

import XCTest
@testable import Github_Viewer

final class Github_ViewerTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: - GitHubUserProfile Tests
    
    func testGitHubUserProfileDecoding() throws {
        let json = """
        {
            "id": 12345,
            "login": "testuser",
            "name": "Test User",
            "email": "test@example.com",
            "bio": "Test bio",
            "avatar_url": "https://example.com/avatar.jpg",
            "html_url": "https://github.com/testuser",
            "public_repos": 10,
            "public_gists": 5,
            "followers": 100,
            "following": 50,
            "created_at": "2020-01-01T00:00:00Z",
            "updated_at": "2023-01-01T00:00:00Z",
            "company": "Test Company",
            "location": "Test City",
            "blog": "https://testblog.com",
            "twitter_username": "testuser"
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let userProfile = try decoder.decode(GitHubUserProfile.self, from: json)
        
        XCTAssertEqual(userProfile.id, 12345)
        XCTAssertEqual(userProfile.login, "testuser")
        XCTAssertEqual(userProfile.name, "Test User")
        XCTAssertEqual(userProfile.email, "test@example.com")
        XCTAssertEqual(userProfile.bio, "Test bio")
        XCTAssertEqual(userProfile.avatarURL, "https://example.com/avatar.jpg")
        XCTAssertEqual(userProfile.publicRepos, 10)
        XCTAssertEqual(userProfile.followers, 100)
        XCTAssertEqual(userProfile.following, 50)
        XCTAssertEqual(userProfile.company, "Test Company")
        XCTAssertEqual(userProfile.location, "Test City")
    }
    
    func testGitHubUserProfileEquality() throws {
        let userProfile1 = GitHubUserProfile(
            id: 1,
            login: "user1",
            name: "User One",
            email: "user1@example.com",
            bio: "Bio 1",
            avatarURL: "https://example.com/avatar1.jpg",
            htmlURL: "https://github.com/user1",
            publicRepos: 5,
            publicGists: 2,
            followers: 10,
            following: 5,
            createdAt: "2020-01-01T00:00:00Z",
            updatedAt: "2023-01-01T00:00:00Z",
            company: "Company 1",
            location: "City 1",
            blog: "https://blog1.com",
            twitterUsername: "user1"
        )
        
        let userProfile2 = GitHubUserProfile(
            id: 1,
            login: "user1",
            name: "User One",
            email: "user1@example.com",
            bio: "Bio 1",
            avatarURL: "https://example.com/avatar1.jpg",
            htmlURL: "https://github.com/user1",
            publicRepos: 5,
            publicGists: 2,
            followers: 10,
            following: 5,
            createdAt: "2020-01-01T00:00:00Z",
            updatedAt: "2023-01-01T00:00:00Z",
            company: "Company 1",
            location: "City 1",
            blog: "https://blog1.com",
            twitterUsername: "user1"
        )
        
        XCTAssertEqual(userProfile1, userProfile2)
    }
    
    // MARK: - GitHubRepository Tests
    
    func testGitHubRepositoryDecoding() throws {
        let json = """
        {
            "id": 67890,
            "name": "test-repo",
            "full_name": "testuser/test-repo",
            "description": "A test repository",
            "html_url": "https://github.com/testuser/test-repo",
            "language": "Swift",
            "stargazers_count": 25,
            "forks_count": 5,
            "watchers_count": 25,
            "size": 1024,
            "default_branch": "main",
            "created_at": "2020-01-01T00:00:00Z",
            "updated_at": "2023-01-01T00:00:00Z",
            "pushed_at": "2023-06-01T00:00:00Z",
            "private": false,
            "fork": false,
            "archived": false,
            "owner": {
                "id": 12345,
                "login": "testuser",
                "avatar_url": "https://example.com/avatar.jpg",
                "html_url": "https://github.com/testuser",
                "type": "User"
            }
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let repository = try decoder.decode(GitHubRepository.self, from: json)
        
        XCTAssertEqual(repository.id, 67890)
        XCTAssertEqual(repository.name, "test-repo")
        XCTAssertEqual(repository.fullName, "testuser/test-repo")
        XCTAssertEqual(repository.description, "A test repository")
        XCTAssertEqual(repository.language, "Swift")
        XCTAssertEqual(repository.stargazersCount, 25)
        XCTAssertEqual(repository.forksCount, 5)
        XCTAssertEqual(repository.isPrivate, false)
        XCTAssertEqual(repository.owner.login, "testuser")
    }
    
    // MARK: - GitHubFile Tests
    
    func testGitHubFileProperties() throws {
        let fileData = GitHubFile(
            name: "README.md",
            path: "docs/README.md",
            sha: "abc123",
            size: 1024,
            url: "https://api.github.com/repos/user/repo/contents/README.md",
            htmlURL: "https://github.com/user/repo/blob/main/README.md",
            gitURL: "https://api.github.com/repos/user/repo/git/blobs/abc123",
            downloadURL: "https://raw.githubusercontent.com/user/repo/main/README.md",
            type: "file"
        )
        
        XCTAssertTrue(fileData.isFile)
        XCTAssertFalse(fileData.isDirectory)
        XCTAssertEqual(fileData.fileExtension, "md")
        XCTAssertEqual(fileData.displayName, "docs/README.md")
        XCTAssertEqual(fileData.iconName, "doc.text")
    }
    
    func testGitHubDirectoryProperties() throws {
        let directoryData = GitHubFile(
            name: "src",
            path: "src",
            sha: "def456",
            size: 0,
            url: "https://api.github.com/repos/user/repo/contents/src",
            htmlURL: "https://github.com/user/repo/tree/main/src",
            gitURL: "https://api.github.com/repos/user/repo/git/trees/def456",
            downloadURL: nil,
            type: "dir"
        )
        
        XCTAssertFalse(directoryData.isFile)
        XCTAssertTrue(directoryData.isDirectory)
        XCTAssertNil(directoryData.fileExtension)
        XCTAssertEqual(directoryData.iconName, "folder.fill")
    }
    
    func testFileIconMapping() throws {
        let testCases: [(String, String)] = [
            ("test.swift", "swift"),
            ("README.md", "doc.text"),
            ("config.json", "doc.text"),
            ("notes.txt", "doc.plaintext"),
            ("image.png", "photo"),
            ("video.mp4", "video"),
            ("audio.mp3", "music.note"),
            ("archive.zip", "doc.zipper"),
            ("unknown.xyz", "doc")
        ]
        
        for (fileName, expectedIcon) in testCases {
            let file = GitHubFile(
                name: fileName,
                path: fileName,
                sha: "test",
                size: 100,
                url: "test",
                htmlURL: "test",
                gitURL: "test",
                downloadURL: nil,
                type: "file"
            )
            
            XCTAssertEqual(file.iconName, expectedIcon, "File \(fileName) should have icon \(expectedIcon)")
        }
    }
    
    // MARK: - GitHubSearchResponse Tests
    
    func testGitHubSearchResponseDecoding() throws {
        let json = """
        {
            "total_count": 2,
            "incomplete_results": false,
            "items": [
                {
                    "id": 1,
                    "login": "user1",
                    "avatar_url": "https://example.com/avatar1.jpg",
                    "html_url": "https://github.com/user1",
                    "type": "User"
                },
                {
                    "id": 2,
                    "login": "user2",
                    "avatar_url": "https://example.com/avatar2.jpg",
                    "html_url": "https://github.com/user2",
                    "type": "User"
                }
            ]
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let searchResponse = try decoder.decode(GitHubSearchResponse<GitHubUser>.self, from: json)
        
        XCTAssertEqual(searchResponse.totalCount, 2)
        XCTAssertFalse(searchResponse.incompleteResults)
        XCTAssertEqual(searchResponse.items.count, 2)
        XCTAssertEqual(searchResponse.items[0].login, "user1")
        XCTAssertEqual(searchResponse.items[1].login, "user2")
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Test JSON decoding performance
            let json = """
            {
                "id": 12345,
                "login": "testuser",
                "name": "Test User",
                "email": "test@example.com",
                "bio": "Test bio",
                "avatar_url": "https://example.com/avatar.jpg",
                "html_url": "https://github.com/testuser",
                "public_repos": 10,
                "public_gists": 5,
                "followers": 100,
                "following": 50,
                "created_at": "2020-01-01T00:00:00Z",
                "updated_at": "2023-01-01T00:00:00Z",
                "company": "Test Company",
                "location": "Test City",
                "blog": "https://testblog.com",
                "twitter_username": "testuser"
            }
            """.data(using: .utf8)!
            
            let decoder = JSONDecoder()
            do {
                _ = try decoder.decode(GitHubUserProfile.self, from: json)
            } catch {
                XCTFail("Decoding failed: \(error)")
            }
        }
    }
}
