import Foundation
import Combine

enum ZombieType {
    case normal  // green, 1 HP, normal speed
    case fast    // dark green, 1 HP, 2x speed (wave 3+)
    case tank    // purple/grey, 3 HP, slow (wave 5+)

    var hp: Int {
        switch self {
        case .normal: return 1
        case .fast:   return 1
        case .tank:   return 3
        }
    }

    var speedMultiplier: CGFloat {
        switch self {
        case .normal: return 1.0
        case .fast:   return 2.0
        case .tank:   return 0.5
        }
    }

    var scoreValue: Int {
        switch self {
        case .normal: return 10
        case .fast:   return 20
        case .tank:   return 50
        }
    }
}

class GameState: ObservableObject {
    @Published var score: Int = 0
    @Published var wave: Int = 1
    @Published var lives: Int = 3
    @Published var isGameOver: Bool = false
    @Published var isPaused: Bool = false

    var killCount: Int = 0
    var bestScore: Int {
        get { UserDefaults.standard.integer(forKey: "bestScore") }
        set { UserDefaults.standard.set(newValue, forKey: "bestScore") }
    }

    func addScore(_ points: Int) {
        score += points
        if score > bestScore {
            bestScore = score
        }
    }

    func recordKill() {
        killCount += 1
        if killCount % 10 == 0 {
            wave += 1
        }
    }

    func loseLife() {
        lives -= 1
        if lives <= 0 {
            isGameOver = true
        }
    }

    func reset() {
        score = 0
        wave = 1
        lives = 3
        isGameOver = false
        isPaused = false
        killCount = 0
    }

    /// Types available for spawning at the current wave
    func availableZombieTypes() -> [ZombieType] {
        var types: [ZombieType] = [.normal]
        if wave >= 3 { types.append(.fast) }
        if wave >= 5 { types.append(.tank) }
        return types
    }

    /// Spawn interval in seconds (gets shorter with wave)
    func spawnInterval() -> TimeInterval {
        max(0.4, 2.0 - Double(wave - 1) * 0.15)
    }
}
