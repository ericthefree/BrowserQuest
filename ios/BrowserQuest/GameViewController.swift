import UIKit
import WebKit

final class GameViewController: UIViewController, WKNavigationDelegate {
    private var webView: WKWebView!
    private let saveBridge = ICloudSaveBridge()

    override func loadView() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.userContentController.add(saveBridge, name: "browserQuestCloud")
        configuration.userContentController.addUserScript(
            WKUserScript(
                source: saveBridge.bootstrapScript,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
        )

        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = .black
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadGame()
    }

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }

    private func loadGame() {
        guard
            let resources = Bundle.main.resourceURL,
            let index = Bundle.main.url(
                forResource: "index",
                withExtension: "html",
                subdirectory: "client"
            )
        else {
            showLoadError()
            return
        }

        webView.loadFileURL(index, allowingReadAccessTo: resources)
    }

    private func showLoadError() {
        let label = UILabel()
        label.backgroundColor = .black
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "BrowserQuest assets could not be loaded."
        view = label
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        loadGame()
    }
}
