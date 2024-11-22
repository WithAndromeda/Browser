import XCTest
import WebKit
@testable import Helium

class HeliumTests: XCTestCase {
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
        XCTAssertEqual(viewModel.currentURL, viewModel.homePage)
    }
    
    func testLoadHomePage() {
        viewModel.loadHomePage()
        XCTAssertEqual(viewModel.currentURL, viewModel.homePage)
    }
    
    func testLoadErrorPage() {
        viewModel.loadErrorPage()
        XCTAssertEqual(viewModel.currentURL, viewModel.errorPage)
    }
    
    func testNavigateToURL() {
        let expectation = XCTestExpectation(description: "Navigation completed")
        let testURL = "https://www.example.com"
        
        viewModel.webView.navigationDelegate = self
        viewModel.currentURL = testURL
        viewModel.navigateToURL()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertEqual(self.viewModel.currentURL, testURL)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }
}

extension HeliumTests: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {}
}

