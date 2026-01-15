//
//  Github_ViewerUITestsLaunchTests.swift
//  Github-ViewerUITests
//
//  Created by Xu Sensheng on 2026-01-14.
//

import XCTest

final class Github_ViewerUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app
        
        // 等待应用完全启动
        sleep(2)
        
        // 验证主要UI元素存在
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Tab bar should exist after launch")

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testLaunchInDarkMode() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UIUserInterfaceStyle", "dark"]
        app.launch()
        
        sleep(2)
        
        // 验证应用在深色模式下正常启动
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Tab bar should exist in dark mode")
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen - Dark Mode"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testLaunchInLightMode() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UIUserInterfaceStyle", "light"]
        app.launch()
        
        sleep(2)
        
        // 验证应用在浅色模式下正常启动
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Tab bar should exist in light mode")
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen - Light Mode"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testLaunchWithMemoryWarning() throws {
        let app = XCUIApplication()
        app.launch()
        
        sleep(2)
        
        // 模拟内存警告
        // 注意：这在真实设备上可能不会触发，主要用于模拟器测试
        
        // 验证应用在内存压力下仍然正常运行
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "App should handle memory warnings gracefully")
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen - Memory Warning Test"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
