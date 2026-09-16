import UIKit
import WebKit

final class GameViewController: UIViewController, WKNavigationDelegate {
    private var webView: WKWebView!

    override func loadView() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.userContentController.addUserScript(
            WKUserScript(
                source: serverConfigurationScript(),
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

    private func serverConfigurationScript() -> String {
        let configured = Bundle.main.object(forInfoDictionaryKey: "BrowserQuestServerURL") as? String
        let rawURL = configured ?? "ws://localhost:8000"
        guard let url = URL(string: rawURL), let host = url.host else {
            return "window.BROWSERQUEST_SERVER = { host: 'localhost', port: 8000, secure: false };"
        }

        let secure = url.scheme?.lowercased() == "wss"
        let defaultPort = secure ? 443 : 80
        let payload: [String: Any] = [
            "host": host,
            "port": url.port ?? defaultPort,
            "secure": secure
        ]
        guard
            let data = try? JSONSerialization.data(withJSONObject: payload),
            let json = String(data: data, encoding: .utf8)
        else {
            return ""
        }
        return "window.BROWSERQUEST_SERVER = \(json);"
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
