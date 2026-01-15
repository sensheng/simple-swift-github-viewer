//
//  Github_ViewerUITests.swift
//  Github-ViewerUITests
//
//  Created by Xu Sensheng on 2026-01-14.
//

import XCTest

final class Github_ViewerUITests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        // In UI tests it's important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
        
        // 等待应用启动
        sleep(2)
        
        // 切换到我的标签页
        let meTab = app.tabBars.buttons["我的"].firstMatch
        if meTab.exists {
            meTab.tap()
            sleep(1)
            
            // 尝试查找Token输入框，用于调试
            print("🔍 查找SecureField...")
            let secureFields = app.secureTextFields
            print("🔍 找到 \(secureFields.count) 个SecureField")
            
            let textFields = app.textFields
            print("🔍 找到 \(textFields.count) 个TextField")
            
            // 尝试通过accessibility标识符查找
            let tokenFieldById = app.secureTextFields["tokenTextField"]
            print("🔍 通过ID查找SecureField: \(tokenFieldById.exists)")
            
            // 尝试通过placeholder查找
            let tokenFieldByPlaceholder = app.secureTextFields.containing(NSPredicate(format: "placeholderValue CONTAINS 'Personal Access Token'"))
            print("🔍 通过placeholder查找SecureField: \(tokenFieldByPlaceholder.count)")
            
            // 输出所有SecureField的信息
            for i in 0..<secureFields.count {
                let field = secureFields.element(boundBy: i)
                print("🔍 SecureField \(i): identifier='\(field.identifier)', placeholder='\(field.placeholderValue ?? "nil")', label='\(field.label)'")
            }
        }
        
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    @MainActor
    func testLoginLogoutFlow() throws {
        let app = XCUIApplication()
        app.launch()
        
        // 等待应用启动完成
        sleep(2)
        
        // 切换到"我的"标签页 - 使用更可靠的方式查找
        let meTab = app.tabBars.buttons.matching(identifier: "Me").firstMatch
        if !meTab.exists {
            // 如果通过identifier找不到，尝试通过标签文本查找
            let meTabByLabel = app.tabBars.buttons["我的"].firstMatch
            if !meTabByLabel.exists {
                let meTabByEnglishLabel = app.tabBars.buttons["Me"].firstMatch
                XCTAssertTrue(meTabByEnglishLabel.waitForExistence(timeout: 10), "Me tab should exist")
                meTabByEnglishLabel.tap()
            } else {
                meTabByLabel.tap()
            }
        } else {
            meTab.tap()
        }
        
        // 等待页面加载
        sleep(1)
        
        // 检查是否已经登录，如果已登录则先退出登录
        // 优先使用accessibility标识符
        var logoutButton = app.buttons["logoutButton"].firstMatch
        if !logoutButton.exists {
            logoutButton = app.buttons["退出"].firstMatch
            if !logoutButton.exists {
                logoutButton = app.buttons["Logout"].firstMatch
            }
        }
        
        if logoutButton.exists {
            print("User is already logged in, logging out first...")
            logoutButton.tap()
            
            // 处理退出登录确认对话框
            var confirmLogoutButton = app.alerts.buttons["退出"].firstMatch
            if !confirmLogoutButton.exists {
                confirmLogoutButton = app.alerts.buttons["Logout"].firstMatch
            }
            if confirmLogoutButton.waitForExistence(timeout: 5) {
                confirmLogoutButton.tap()
            }
            
            // 等待退出登录完成
            sleep(2)
        }
        
        // 现在应该在登录页面，查找Token输入框
        // 优先使用accessibility标识符，注意SecureField在测试中是secureTextFields
        var tokenTextField = app.secureTextFields["tokenTextField"].firstMatch
        if !tokenTextField.exists {
            // 尝试textFields（以防万一）
            tokenTextField = app.textFields["tokenTextField"].firstMatch
        }
        
        if !tokenTextField.exists {
            // 使用placeholder查找SecureField
            tokenTextField = app.secureTextFields.containing(NSPredicate(format: "placeholderValue CONTAINS 'Personal Access Token'")).firstMatch
            if !tokenTextField.exists {
                // 尝试textFields中的placeholder
                tokenTextField = app.textFields.containing(NSPredicate(format: "placeholderValue CONTAINS 'Personal Access Token'")).firstMatch
            }
        }
        
        if !tokenTextField.exists {
            // 通过具体文本查找
            tokenTextField = app.secureTextFields["请输入您的 GitHub Personal Access Token"].firstMatch
            if !tokenTextField.exists {
                tokenTextField = app.secureTextFields["Please enter your GitHub Personal Access Token"].firstMatch
                if !tokenTextField.exists {
                    tokenTextField = app.secureTextFields["请输入您的 GitHub Personal Access Token"].firstMatch
                    if !tokenTextField.exists {
                        tokenTextField = app.textFields["Please enter your GitHub Personal Access Token"].firstMatch
                    }
                }
            }
        }
        
        XCTAssertTrue(tokenTextField.waitForExistence(timeout: 10), "Token text field should exist")
        
        // 输入测试Token
        tokenTextField.tap()
        tokenTextField.typeText("****************************************")
        
        // 点击登录按钮
        // 优先使用accessibility标识符
        var loginButton = app.buttons["loginButton"].firstMatch
        if !loginButton.exists {
            loginButton = app.buttons["登录"].firstMatch
            if !loginButton.exists {
                loginButton = app.buttons["Login"].firstMatch
            }
        }
        XCTAssertTrue(loginButton.exists, "Login button should exist")
        loginButton.tap()
        
        // 等待登录完成 - 可能会有保存登录信息的对话框
        sleep(3)
        
        // 处理可能出现的保存登录信息对话框
        var dontSaveButton = app.alerts.buttons["不保存"].firstMatch
        if !dontSaveButton.exists {
            dontSaveButton = app.alerts.buttons["Don't save"].firstMatch
        }
        if dontSaveButton.waitForExistence(timeout: 5) {
            dontSaveButton.tap()
        }
        
        // 等待登录成功，应该能看到用户信息
        sleep(3)
        
        // 验证登录成功 - 检查是否有退出按钮
        var logoutButtonAfterLogin = app.buttons["logoutButton"].firstMatch
        if !logoutButtonAfterLogin.exists {
            logoutButtonAfterLogin = app.buttons["退出"].firstMatch
            if !logoutButtonAfterLogin.exists {
                logoutButtonAfterLogin = app.buttons["Logout"].firstMatch
            }
        }
        XCTAssertTrue(logoutButtonAfterLogin.waitForExistence(timeout: 10), "Logout button should appear after successful login")
        
        // 执行退出登录
        logoutButtonAfterLogin.tap()
        
        // 确认退出登录
        var confirmLogoutButtonFinal = app.alerts.buttons["退出"].firstMatch
        if !confirmLogoutButtonFinal.exists {
            confirmLogoutButtonFinal = app.alerts.buttons["Logout"].firstMatch
        }
        if confirmLogoutButtonFinal.waitForExistence(timeout: 5) {
            confirmLogoutButtonFinal.tap()
        }
        
        // 等待退出登录完成
        sleep(2)
        
        // 验证已经退出登录 - 应该重新看到登录界面
        var tokenTextFieldAfterLogout = app.secureTextFields["tokenTextField"].firstMatch
        if !tokenTextFieldAfterLogout.exists {
            tokenTextFieldAfterLogout = app.textFields["tokenTextField"].firstMatch
        }
        
        if !tokenTextFieldAfterLogout.exists {
            tokenTextFieldAfterLogout = app.secureTextFields.containing(NSPredicate(format: "placeholderValue CONTAINS 'Personal Access Token'")).firstMatch
            if !tokenTextFieldAfterLogout.exists {
                tokenTextFieldAfterLogout = app.textFields.containing(NSPredicate(format: "placeholderValue CONTAINS 'Personal Access Token'")).firstMatch
                if !tokenTextFieldAfterLogout.exists {
                    tokenTextFieldAfterLogout = app.secureTextFields["请输入您的 GitHub Personal Access Token"].firstMatch
                    if !tokenTextFieldAfterLogout.exists {
                        tokenTextFieldAfterLogout = app.textFields["Please enter your GitHub Personal Access Token"].firstMatch
                    }
                }
            }
        }
        XCTAssertTrue(tokenTextFieldAfterLogout.waitForExistence(timeout: 10), "Should return to login screen after logout")
        
        print("Login and logout flow test completed successfully!")
    }
    
    @MainActor
    func testNavigationBetweenTabs() throws {
        let app = XCUIApplication()
        app.launch()
        
        // 等待应用启动
        sleep(2)
        
        // 测试标签页切换
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")
        
        // 切换到GitHub标签页
        var githubTab = app.tabBars.buttons["GitHub"].firstMatch
        if !githubTab.exists {
            githubTab = app.tabBars.buttons.element(boundBy: 0) // 第一个标签页
        }
        if githubTab.exists {
            githubTab.tap()
            sleep(1)
        }
        
        // 切换到我的标签页
        var meTab = app.tabBars.buttons.matching(identifier: "Me").firstMatch
        if !meTab.exists {
            meTab = app.tabBars.buttons["我的"].firstMatch
            if !meTab.exists {
                meTab = app.tabBars.buttons["Me"].firstMatch
            }
        }
        XCTAssertTrue(meTab.exists, "Me tab should exist")
        meTab.tap()
        sleep(1)
        
        // 验证在我的页面 - 检查导航栏标题或登录相关元素
        let isOnMePage = app.navigationBars["我的"].exists ||
        app.navigationBars["Me"].exists ||
        app.staticTexts["登录 GitHub"].exists ||
        app.staticTexts["Login to GitHub"].exists
        XCTAssertTrue(isOnMePage, "Should be on Me page")
    }
    
    @MainActor
    func testTokenInputValidation() throws {
        let app = XCUIApplication()
        app.launch()
        
        // 切换到我的标签页
        var meTab = app.tabBars.buttons.matching(identifier: "Me").firstMatch
        if !meTab.exists {
            meTab = app.tabBars.buttons["我的"].firstMatch
            if !meTab.exists {
                meTab = app.tabBars.buttons["Me"].firstMatch
            }
        }
        XCTAssertTrue(meTab.waitForExistence(timeout: 10), "Me tab should exist")
        meTab.tap()
        
        sleep(1)
        
        // 确保在登录页面
        var tokenTextField = app.secureTextFields["tokenTextField"].firstMatch
        if !tokenTextField.exists {
            tokenTextField = app.textFields["tokenTextField"].firstMatch
        }
        
        if !tokenTextField.exists {
            tokenTextField = app.secureTextFields.containing(NSPredicate(format: "placeholderValue CONTAINS 'Personal Access Token'")).firstMatch
            if !tokenTextField.exists {
                tokenTextField = app.textFields.containing(NSPredicate(format: "placeholderValue CONTAINS 'Personal Access Token'")).firstMatch
                if !tokenTextField.exists {
                    tokenTextField = app.textFields["Personal Access Token"].firstMatch
                    if !tokenTextField.exists {
                        tokenTextField = app.textFields["Personal Access Token"].firstMatch
                    }
                }
            }
        }
        
        if !tokenTextField.exists {
            // 如果已登录，先退出
            var logoutButton = app.buttons["logoutButton"].firstMatch
            if !logoutButton.exists {
                logoutButton = app.buttons["退出"].firstMatch
                if !logoutButton.exists {
                    logoutButton = app.buttons["Logout"].firstMatch
                }
            }
            if logoutButton.exists {
                logoutButton.tap()
                var confirmButton = app.alerts.buttons["退出"].firstMatch
                if !confirmButton.exists {
                    confirmButton = app.alerts.buttons["Logout"].firstMatch
                }
                if confirmButton.waitForExistence(timeout: 5) {
                    confirmButton.tap()
                }
                sleep(2)
            }
        }
        
        // 重新查找Token输入框
        tokenTextField = app.secureTextFields["tokenTextField"].firstMatch
        if !tokenTextField.exists {
            tokenTextField = app.textFields["tokenTextField"].firstMatch
        }
        
        if !tokenTextField.exists {
            tokenTextField = app.secureTextFields.containing(NSPredicate(format: "placeholderValue CONTAINS 'Personal Access Token'")).firstMatch
            if !tokenTextField.exists {
                tokenTextField = app.textFields.containing(NSPredicate(format: "placeholderValue CONTAINS 'Personal Access Token'")).firstMatch
                if !tokenTextField.exists {
                    tokenTextField = app.secureTextFields["请输入您的 GitHub Personal Access Token"].firstMatch
                    if !tokenTextField.exists {
                        tokenTextField = app.textFields["Please enter your GitHub Personal Access Token"].firstMatch
                    }
                }
            }
        }
        XCTAssertTrue(tokenTextField.waitForExistence(timeout: 10), "Token text field should exist")
        
        // 尝试用空Token登录
        var loginButton = app.buttons["loginButton"].firstMatch
        if !loginButton.exists {
            loginButton = app.buttons["登录"].firstMatch
            if !loginButton.exists {
                loginButton = app.buttons["Login"].firstMatch
            }
        }
        XCTAssertTrue(loginButton.exists, "Login button should exist")
        loginButton.tap()
        
        // 应该仍然在登录页面（因为Token为空）
        sleep(1)
        XCTAssertTrue(tokenTextField.exists, "Should still be on login page with empty token")
        
        // 输入无效Token
        tokenTextField.tap()
        tokenTextField.typeText("invalid_token")
        loginButton.tap()
        
        // 等待可能的错误提示
        sleep(3)
        
        print("Token input validation test completed!")
    }
    
    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}


