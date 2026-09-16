import Foundation
import WebKit

final class BundleSchemeHandler: NSObject, WKURLSchemeHandler {
    private let mimeTypes = [
        "css": "text/css",
        "eot": "application/vnd.ms-fontobject",
        "gif": "image/gif",
        "html": "text/html",
        "ico": "image/x-icon",
        "jpeg": "image/jpeg",
        "jpg": "image/jpeg",
        "js": "text/javascript",
        "json": "application/json",
        "mp3": "audio/mpeg",
        "ogg": "audio/ogg",
        "png": "image/png",
        "svg": "image/svg+xml",
        "ttf": "font/ttf",
        "wav": "audio/wav",
        "woff": "font/woff"
    ]

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard
            let requestURL = urlSchemeTask.request.url,
            let resources = Bundle.main.resourceURL,
            let relativePath = requestURL.path.removingPercentEncoding
        else {
            urlSchemeTask.didFailWithError(URLError(.badURL))
            return
        }

        let resourceRoot = resources.standardizedFileURL
        let fileURL = resourceRoot
            .appendingPathComponent(String(relativePath.drop(while: { $0 == "/" })))
            .standardizedFileURL

        guard fileURL.path.hasPrefix(resourceRoot.path + "/") else {
            urlSchemeTask.didFailWithError(URLError(.noPermissionsToReadFile))
            return
        }

        do {
            let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
            let fileExtension = fileURL.pathExtension.lowercased()
            let mimeType = mimeTypes[fileExtension] ?? "application/octet-stream"
            let contentType = ["css", "html", "js", "json"].contains(fileExtension) ? "\(mimeType); charset=utf-8" : mimeType
            guard let response = HTTPURLResponse(
                url: requestURL,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: [
                    "Content-Length": String(data.count),
                    "Content-Type": contentType
                ]
            ) else {
                throw URLError(.badServerResponse)
            }
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(data)
            urlSchemeTask.didFinish()
        } catch {
            print("[BrowserQuest asset] Failed to load \(relativePath): \(error.localizedDescription)")
            urlSchemeTask.didFailWithError(error)
        }
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}
}
