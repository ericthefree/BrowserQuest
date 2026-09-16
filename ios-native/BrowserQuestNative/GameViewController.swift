import SpriteKit
import UIKit

final class GameViewController: UIViewController {
    private let saveStore = SaveStore()

    override func loadView() {
        view = SKView(frame: .zero)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let skView = view as? SKView else { return }
        skView.ignoresSiblingOrder = true
        skView.preferredFramesPerSecond = 60
        showMenu()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let skView = view as? SKView else { return }
        skView.scene?.size = skView.bounds.size
    }

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }

    private func showMenu() {
        guard let skView = view as? SKView else { return }
        let menu = MenuScene(size: skView.bounds.size)
        menu.onCreate = { [weak self] in self?.promptForCharacter() }
        menu.onStart = { [weak self] in self?.startGame() }
        menu.onDelete = { [weak self] in self?.confirmDelete() }
        skView.presentScene(menu, transition: .fade(withDuration: 0.25))
    }

    private func promptForCharacter() {
        let alert = UIAlertController(title: "Create Character", message: "Choose your character's name.", preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "Adventurer"
            field.autocapitalizationType = .words
            field.clearButtonMode = .whileEditing
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Create", style: .default) { [weak self, weak alert] _ in
            let enteredName = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            self?.saveStore.createCharacter(named: enteredName?.isEmpty == false ? enteredName! : "Adventurer")
            self?.showMenu()
        })
        present(alert, animated: true)
    }

    private func startGame() {
        guard saveStore.hasCharacter(), let skView = view as? SKView else { return }
        skView.presentScene(GameScene(size: skView.bounds.size), transition: .fade(withDuration: 0.35))
    }

    private func confirmDelete() {
        let alert = UIAlertController(
            title: "Delete Character?",
            message: "This removes the character from this device and iCloud.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.saveStore.deleteCharacter()
            self?.showMenu()
        })
        present(alert, animated: true)
    }
}
