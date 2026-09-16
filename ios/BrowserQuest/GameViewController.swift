import UIKit
import WebKit

final class GameViewController: UIViewController, WKNavigationDelegate {
    private var webView: WKWebView!
    private let saveBridge = ICloudSaveBridge()
    private let bundleSchemeHandler = BundleSchemeHandler()

    override func loadView() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.setURLSchemeHandler(bundleSchemeHandler, forURLScheme: "browserquest")
        configuration.userContentController.add(saveBridge, name: "browserQuestCloud")
        configuration.userContentController.add(saveBridge, name: "browserQuestLog")
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
#if DEBUG
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
#endif
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadGame()
    }

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }

    private func loadGame() {
        guard let gameURL = URL(string: "browserquest://app/client/index.html") else {
            showLoadError()
            return
        }
        webView.load(URLRequest(url: gameURL))
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

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("[BrowserQuest navigation] \(error.localizedDescription)")
        showLoadError()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("[BrowserQuest navigation] \(error.localizedDescription)")
        showLoadError()
    }
}
