import Foundation
import Combine
import CoreGraphics

enum ZombieType {
    case normal
    case fast
    case tank
    case boss
    case finalBoss

    var hp: Int {
        switch self {
        case .normal: return 1
        case .fast: return 1
        case .tank: return 3
        case .boss: return 14
        case .finalBoss: return 40
        }
    }

    var speedMultiplier: CGFloat {
        switch self {
        case .normal: return 1.0
        case .fast: return 1.8
        case .tank: return 0.55
        case .boss: return 0.34
        case .finalBoss: return 0.24
        }
    }

    var scoreValue: Int {
        switch self {
        case .normal: return 10
        case .fast: return 20
        case .tank: return 50
        case .boss: return 250
        case .finalBoss: return 2000
        }
    }

    var isBoss: Bool {
        self == .boss || self == .finalBoss
    }
}

struct StageDefinition {
    let number: Int
    let name: String
    let killsForBoss: Int
    let bossName: String
}

class GameState: ObservableObject {
    static let stages: [StageDefinition] = [
        StageDefinition(number: 1, name: "Old Church", killsForBoss: 6, bossName: "Grave Warden"),
        StageDefinition(number: 2, name: "Neon City", killsForBoss: 7, bossName: "Street Butcher"),
        StageDefinition(number: 3, name: "Black Pines", killsForBoss: 8, bossName: "Rot Walker"),
        StageDefinition(number: 4, name: "Mountain Pass", killsForBoss: 8, bossName: "Cliff Crawler"),
        StageDefinition(number: 5, name: "Flooded Mall", killsForBoss: 9, bossName: "Mall Brute"),
        StageDefinition(number: 6, name: "Factory Yard", killsForBoss: 10, bossName: "Rust Maw"),
        StageDefinition(number: 7, name: "Harbor Fog", killsForBoss: 11, bossName: "Dock Horror"),
        StageDefinition(number: 8, name: "Dead Subway", killsForBoss: 12, bossName: "Tunnel King"),
        StageDefinition(number: 9, name: "Burnt Castle", killsForBoss: 13, bossName: "Ash Baron"),
        StageDefinition(number: 10, name: "Last Cliff", killsForBoss: 14, bossName: "The Final Corpse")
    ]

    @Published var score: Int = 0
    @Published var wave: Int = 1
    @Published var stage: Int = 1
    @Published var killsThisStage: Int = 0
    @Published var isBossActive: Bool = false
    @Published var isGameOver: Bool = false
    @Published var isCleared: Bool = false
    @Published var lives: Int = 3
    @Published var isPaused: Bool = false

    var killCount: Int = 0
    var bestScore: Int {
        get { UserDefaults.standard.integer(forKey: "bestScore") }
        set { UserDefaults.standard.set(newValue, forKey: "bestScore") }
    }

    var currentStage: StageDefinition {
        Self.stages[min(max(stage - 1, 0), Self.stages.count - 1)]
    }

    var isFinalStage: Bool {
        stage >= Self.stages.count
    }

    func addScore(_ points: Int) {
        score += points
        if score > bestScore {
            bestScore = score
        }
    }

    func recordKill() {
        killCount += 1
        killsThisStage += 1
        if killCount % 8 == 0 {
            wave += 1
        }
    }

    func killsNeededForBoss() -> Int {
        currentStage.killsForBoss
    }

    func shouldSpawnBoss() -> Bool {
        !isBossActive && !isCleared && killsThisStage >= killsNeededForBoss()
    }

    func startBossFight() {
        isBossActive = true
    }

    func bossTypeForCurrentStage() -> ZombieType {
        isFinalStage ? .finalBoss : .boss
    }

    func advanceAfterBossDefeat() {
        if isFinalStage {
            isCleared = true
            isBossActive = false
            return
        }

        stage += 1
        wave += 1
        killsThisStage = 0
        isBossActive = false
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
        stage = 1
        killsThisStage = 0
        isBossActive = false
        isGameOver = false
        isCleared = false
        lives = 3
        isPaused = false
        killCount = 0
    }

    func availableZombieTypes() -> [ZombieType] {
        var types: [ZombieType] = [.normal]
        if stage >= 2 || wave >= 3 { types.append(.fast) }
        if stage >= 4 || wave >= 5 { types.append(.tank) }
        return types
    }

    func spawnInterval() -> TimeInterval {
        max(0.38, 1.75 - Double(stage - 1) * 0.09 - Double(wave - 1) * 0.04)
    }
}
