import UIKit
import SpriteKit
import SwiftUI

class GameViewController: UIViewController {
    var gameState: GameState!
    var onGameOver: (() -> Void)?
    var onGameClear: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let skView = view as? SKView, skView.scene == nil else { return }
        presentGameScene(in: skView)
    }

    override func loadView() {
        let skView = SKView()
        skView.ignoresSiblingOrder = true
        skView.showsFPS = false
        skView.showsNodeCount = false
        view = skView
    }

    private func presentGameScene(in skView: SKView) {
        let scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .resizeFill
        scene.gameState = gameState
        scene.onGameOver = onGameOver
        scene.onGameClear = onGameClear
        skView.presentScene(scene, transition: SKTransition.fade(withDuration: 0.4))
    }
}

// MARK: - SwiftUI wrapper
struct GameView: UIViewControllerRepresentable {
    @ObservedObject var gameState: GameState
    var onGameOver: () -> Void
    var onGameClear: () -> Void

    func makeUIViewController(context: Context) -> GameViewController {
        let vc = GameViewController()
        vc.gameState = gameState
        vc.onGameOver = onGameOver
        vc.onGameClear = onGameClear
        return vc
    }

    func updateUIViewController(_ uiViewController: GameViewController, context: Context) {}
}
