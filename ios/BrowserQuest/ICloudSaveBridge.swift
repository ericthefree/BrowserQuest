import Foundation
import WebKit

final class ICloudSaveBridge: NSObject, WKScriptMessageHandler {
    private enum Key {
        static let save = "BrowserQuest.save"
        static let world = "BrowserQuest.world"
    }

    private let store = NSUbiquitousKeyValueStore.default

    override init() {
        super.init()
        store.synchronize()
    }

    var bootstrapScript: String {
        let save = store.string(forKey: Key.save)
        let world = store.string(forKey: Key.world)
        return """
        window.BROWSERQUEST_OFFLINE = true;
        window.BROWSERQUEST_CLOUD_SAVE = \(javascriptValue(save));
        window.BROWSERQUEST_OFFLINE_WORLD = \(javascriptObject(world));
        window.BrowserQuestCloud = {
            save: function(save, world) {
                window.webkit.messageHandlers.browserQuestCloud.postMessage({ save: save, world: world });
            }
        };
        (function() {
            function report(kind, message) {
                window.webkit.messageHandlers.browserQuestLog.postMessage(kind + ": " + message);
            }
            var originalError = console.error;
            console.error = function() {
                var message = Array.prototype.map.call(arguments, String).join(" ");
                report("console.error", message);
                originalError.apply(console, arguments);
            };
            window.addEventListener("error", function(event) {
                report("window.error", event.message + " at " + event.filename + ":" + event.lineno);
            });
            window.addEventListener("unhandledrejection", function(event) {
                report("unhandledrejection", String(event.reason));
            });
        }());
        """
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "browserQuestLog" {
            print("[BrowserQuest JS] \(message.body)")
            return
        }
        guard
            message.name == "browserQuestCloud",
            let body = message.body as? [String: Any]
        else { return }

        if let save = body["save"] as? String {
            store.set(save, forKey: Key.save)
        }
        if let world = body["world"] as? String {
            store.set(world, forKey: Key.world)
        }
        store.synchronize()
    }

    private func javascriptValue(_ value: String?) -> String {
        guard
            let value,
            let data = try? JSONSerialization.data(withJSONObject: [value]),
            let array = String(data: data, encoding: .utf8)
        else { return "null" }
        return String(array.dropFirst().dropLast())
    }

    private func javascriptObject(_ value: String?) -> String {
        guard
            let value,
            let data = value.data(using: .utf8),
            (try? JSONSerialization.jsonObject(with: data)) is [String: Any]
        else { return "null" }
        return value
    }
}
