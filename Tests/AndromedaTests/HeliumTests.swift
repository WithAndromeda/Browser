import XCTest
import WebKit
@testable import Andromeda

class AndromedaTests: XCTestCase {
    var viewModel: ViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = ViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    func testInitialization() {
        XCTAssertNotNil(viewModel.webView)
        XCTAssertEqual(viewModel.tabs.count, 1)
        XCTAssertEqual(viewModel.selectedTabIndex, 0)
        XCTAssertEqual(viewModel.currentURL, "")
    }
    
    func testAddNewTab() {
        let initialCount = viewModel.tabs.count
        viewModel.addNewTab()
        XCTAssertEqual(viewModel.tabs.count, initialCount + 1)
        XCTAssertEqual(viewModel.selectedTabIndex, viewModel.tabs.count - 1)
    }
    
    func testCloseTab() {
        viewModel.addNewTab()
        let initialCount = viewModel.tabs.count
        viewModel.closeTab(at: 1)
        XCTAssertEqual(viewModel.tabs.count, initialCount - 1)
        
        viewModel.closeTab(at: 0)
        XCTAssertEqual(viewModel.tabs.count, 1)
    }
    
    func testURLDisplay() {
        let backendURL = "https://andromeda-backend-536388745693.us-central1.run.app/test"
        let normalURL = "https://example.com"
        
        XCTAssertEqual(viewModel.getDisplayURL(backendURL), "")
        XCTAssertEqual(viewModel.getDisplayURL(normalURL), normalURL)
    }
    
    func testNavigateToURL() {
        let expectation = XCTestExpectation(description: "Navigation completed")
        let testURL = "https://example.com"
        
        viewModel.currentURL = testURL
        viewModel.navigateToURL()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let actualURL = self.viewModel.tabURLs[self.viewModel.selectedTabIndex]?
                .replacingOccurrences(of: "/", with: "", options: [.anchored, .backwards])
            XCTAssertEqual(actualURL, testURL)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }
}

extension AndromedaTests: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {}
}
