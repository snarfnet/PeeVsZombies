import SpriteKit
import GameplayKit

// MARK: - Physics categories
struct PhysicsCategory {
    static let none:     UInt32 = 0
    static let ground:   UInt32 = 0b0001
    static let cliff:    UInt32 = 0b0010
    static let zombie:   UInt32 = 0b0100
    static let pee:      UInt32 = 0b1000
    static let player:   UInt32 = 0b10000
}

// MARK: - Zombie node
class ZombieNode: SKNode {
    var hp: Int
    let zombieType: ZombieType
    var isClimbing = false
    var isDead = false

    private let body: SKShapeNode
    private let head: SKShapeNode
    private var maxHP: Int
    private var hpBar: SKShapeNode?

    init(type: ZombieType, sceneSize: CGSize) {
        self.zombieType = type
        self.hp = type.hp
        self.maxHP = type.hp

        // Body
        let bodyRect = CGRect(x: -10, y: 0, width: 20, height: 30)
        body = SKShapeNode(rect: bodyRect, cornerRadius: 3)
        head = SKShapeNode(circleOfRadius: 9)

        super.init()

        switch type {
        case .normal:
            body.fillColor = .init(red: 0.2, green: 0.7, blue: 0.2, alpha: 1)
            head.fillColor = .init(red: 0.3, green: 0.8, blue: 0.3, alpha: 1)
        case .fast:
            body.fillColor = .init(red: 0.1, green: 0.45, blue: 0.1, alpha: 1)
            head.fillColor = .init(red: 0.15, green: 0.55, blue: 0.15, alpha: 1)
        case .tank:
            body.fillColor = .init(red: 0.5, green: 0.3, blue: 0.6, alpha: 1)
            head.fillColor = .init(red: 0.6, green: 0.4, blue: 0.65, alpha: 1)
        case .boss:
            body.fillColor = .init(red: 0.18, green: 0.16, blue: 0.18, alpha: 1)
            head.fillColor = .init(red: 0.42, green: 0.48, blue: 0.34, alpha: 1)
        case .finalBoss:
            body.fillColor = .init(red: 0.08, green: 0.06, blue: 0.08, alpha: 1)
            head.fillColor = .init(red: 0.5, green: 0.08, blue: 0.06, alpha: 1)
        }

        body.strokeColor = .clear
        head.strokeColor = .clear
        head.position = CGPoint(x: 0, y: 39)

        // Arms
        let leftArm = armNode(mirrored: false)
        let rightArm = armNode(mirrored: true)
        leftArm.position = CGPoint(x: -14, y: 22)
        rightArm.position = CGPoint(x: 14, y: 22)

        addChild(body)
        addChild(head)
        addChild(leftArm)
        addChild(rightArm)

        // HP bar for stronger enemies
        if type == .tank || type == .boss || type == .finalBoss {
            let barWidth: CGFloat = type == .finalBoss ? 64 : (type == .boss ? 42 : 24)
            let bar = SKShapeNode(rect: CGRect(x: -barWidth / 2, y: 48, width: barWidth, height: 4))
            bar.fillColor = type.isBoss ? .init(red: 1, green: 0.05, blue: 0.02, alpha: 1) : .red
            bar.strokeColor = .clear
            hpBar = bar
            addChild(bar)
        }

        // Eyes
        addEyes()

        // Physics
        let physBody = SKPhysicsBody(rectangleOf: CGSize(width: 20, height: 48), center: CGPoint(x: 0, y: 24))
        physBody.categoryBitMask = PhysicsCategory.zombie
        physBody.contactTestBitMask = PhysicsCategory.pee | PhysicsCategory.player
        physBody.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.cliff
        physBody.allowsRotation = false
        physBody.mass = 1.0
        physBody.restitution = 0
        self.physicsBody = physBody

        if type.isBoss {
            setScale(type == .finalBoss ? 2.75 : 1.85)
            addBossDetails()
            if type == .finalBoss {
                addFinalBossAura()
            }
            physBody.mass = type == .finalBoss ? 8.0 : 4.0
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    private func armNode(mirrored: Bool) -> SKShapeNode {
        let arm = SKShapeNode(rect: CGRect(x: 0, y: -4, width: 12, height: 6), cornerRadius: 3)
        arm.fillColor = head.fillColor
        arm.strokeColor = .clear
        if mirrored { arm.xScale = -1 }
        return arm
    }

    private func addEyes() {
        let leftEye = SKShapeNode(circleOfRadius: 2.5)
        leftEye.fillColor = .white
        leftEye.strokeColor = .clear
        leftEye.position = CGPoint(x: -4, y: 40)

        let rightEye = leftEye.copy() as! SKShapeNode
        rightEye.position = CGPoint(x: 4, y: 40)

        let leftPupil = SKShapeNode(circleOfRadius: 1.2)
        leftPupil.fillColor = .red
        leftPupil.strokeColor = .clear
        leftPupil.position = CGPoint(x: -4, y: 40)

        let rightPupil = leftPupil.copy() as! SKShapeNode
        rightPupil.position = CGPoint(x: 4, y: 40)

        addChild(leftEye)
        addChild(rightEye)
        addChild(leftPupil)
        addChild(rightPupil)
    }

    private func addBossDetails() {
        let jaw = SKShapeNode(rect: CGRect(x: -8, y: 30, width: 16, height: 4), cornerRadius: 1)
        jaw.fillColor = .init(red: 0.08, green: 0.02, blue: 0.02, alpha: 1)
        jaw.strokeColor = .clear
        addChild(jaw)

        for x in [-5, 0, 5] {
            let tooth = SKShapeNode(rect: CGRect(x: CGFloat(x), y: 29, width: 2, height: 5), cornerRadius: 0.5)
            tooth.fillColor = .init(red: 0.9, green: 0.86, blue: 0.65, alpha: 1)
            tooth.strokeColor = .clear
            addChild(tooth)
        }
    }

    private func addFinalBossAura() {
        let aura = SKShapeNode(circleOfRadius: 28)
        aura.fillColor = .init(red: 0.7, green: 0.02, blue: 0.02, alpha: 0.22)
        aura.strokeColor = .init(red: 1.0, green: 0.05, blue: 0.02, alpha: 0.4)
        aura.lineWidth = 2
        aura.position = CGPoint(x: 0, y: 27)
        aura.zPosition = -1
        addChild(aura)

        aura.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.25, duration: 0.7),
                SKAction.fadeAlpha(to: 0.32, duration: 0.7)
            ]),
            SKAction.group([
                SKAction.scale(to: 0.9, duration: 0.7),
                SKAction.fadeAlpha(to: 0.16, duration: 0.7)
            ])
        ])))
    }

    func takeDamage(_ dmg: Int = 1) {
        hp -= dmg
        // Flash
        let flash = SKAction.sequence([
            SKAction.colorize(with: .white, colorBlendFactor: 0.8, duration: 0.05),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.05)
        ])
        body.run(flash)

        if let bar = hpBar {
            let fraction = CGFloat(max(0, hp)) / CGFloat(maxHP)
            bar.xScale = fraction
        }
    }

    func boostHP(by amount: Int) {
        hp += amount
        maxHP += amount
    }

    func beginClimbing() {
        guard !isClimbing else { return }
        isClimbing = true
        physicsBody?.velocity = .zero
        physicsBody?.affectedByGravity = false
        physicsBody?.collisionBitMask = PhysicsCategory.none
        run(SKAction.repeatForever(SKAction.sequence([
            SKAction.rotate(byAngle: 0.08, duration: 0.12),
            SKAction.rotate(byAngle: -0.16, duration: 0.24),
            SKAction.rotate(byAngle: 0.08, duration: 0.12)
        ])), withKey: "climbWobble")
    }
}

private struct StageTheme {
    let name: String
    let tint: SKColor
    let ground: SKColor
    let accent: SKColor
}

// MARK: - GameScene
class GameScene: SKScene, SKPhysicsContactDelegate {

    // State
    var gameState: GameState!
    var onGameOver: (() -> Void)?
    var onGameClear: (() -> Void)?

    // Layout constants
    private var cliffX: CGFloat = 0
    private var groundY: CGFloat = 0
    private var cliffTopY: CGFloat = 0
    private var playerNode: SKNode!
    private let backgroundLayer = SKNode()
    private let stageDecorLayer = SKNode()
    private let terrainLayer = SKNode()

    // Pee
    private var isFiring = false
    private var aimAngle: CGFloat = .pi / 6  // radians above horizontal
    private var touchStartY: CGFloat = 0
    private var aimStartAngle: CGFloat = 0
    private var dropletSpawnTimer: TimeInterval = 0
    private let dropletInterval: TimeInterval = 0.025
    private var streamNode: SKShapeNode?

    // Zombies
    private var zombies: [ZombieNode] = []
    private var spawnTimer: TimeInterval = 0

    // HUD
    private var scoreLabel: SKLabelNode!
    private var waveLabel: SKLabelNode!
    private var stageLabel: SKLabelNode!
    private var bossLabel: SKLabelNode!
    private var heartNodes: [SKLabelNode] = []
    private var aimIndicator: SKShapeNode!
    private var pauseButton: SKLabelNode!

    // MARK: - Setup
    override func didMove(to view: SKView) {
        backgroundColor = .init(red: 0.02, green: 0.02, blue: 0.12, alpha: 1)

        cliffX = size.width * 0.72
        groundY = size.height * 0.22
        cliffTopY = groundY + size.height * 0.42

        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.contactDelegate = self

        backgroundLayer.zPosition = 0
        stageDecorLayer.zPosition = 3
        terrainLayer.zPosition = 5
        addChild(backgroundLayer)
        addChild(stageDecorLayer)
        addChild(terrainLayer)

        buildBackground()
        buildGround()
        buildCliff()
        buildPlayer()
        buildHUD()
        buildAimIndicator()
        updateHUD()
    }

    // MARK: - Scene construction
    private func buildBackground() {
        backgroundLayer.removeAllChildren()
        stageDecorLayer.removeAllChildren()

        let background = SKSpriteNode(imageNamed: "RealisticStageBackground")
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.zPosition = 0
        let scale = max(size.width / max(background.size.width, 1), size.height / max(background.size.height, 1))
        background.setScale(scale)
        backgroundLayer.addChild(background)

        let theme = currentStageTheme()
        let tint = SKShapeNode(rect: CGRect(origin: .zero, size: size))
        tint.fillColor = theme.tint
        tint.strokeColor = .clear
        tint.alpha = 0.38
        tint.zPosition = 1
        backgroundLayer.addChild(tint)

        for _ in 0..<28 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.5...2.5))
            star.fillColor = .init(red: 0.84, green: 0.9, blue: 0.86, alpha: 1)
            star.strokeColor = .clear
            star.alpha = CGFloat.random(in: 0.08...0.24)
            star.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: groundY + CGFloat.random(in: 0...size.height)
            )
            backgroundLayer.addChild(star)
        }

        buildStageDecor(theme: theme)
    }

    private func currentStageTheme() -> StageTheme {
        switch gameState.stage {
        case 1:
            return StageTheme(
                name: "Old Church",
                tint: .init(red: 0.05, green: 0.08, blue: 0.11, alpha: 1),
                ground: .init(red: 0.16, green: 0.18, blue: 0.14, alpha: 1),
                accent: .init(red: 0.8, green: 0.9, blue: 0.95, alpha: 1)
            )
        case 2:
            return StageTheme(
                name: "Neon City",
                tint: .init(red: 0.02, green: 0.08, blue: 0.16, alpha: 1),
                ground: .init(red: 0.12, green: 0.12, blue: 0.13, alpha: 1),
                accent: .init(red: 0.1, green: 0.85, blue: 0.95, alpha: 1)
            )
        case 3:
            return StageTheme(
                name: "Black Pines",
                tint: .init(red: 0.02, green: 0.09, blue: 0.05, alpha: 1),
                ground: .init(red: 0.07, green: 0.12, blue: 0.09, alpha: 1),
                accent: .init(red: 0.25, green: 0.8, blue: 0.35, alpha: 1)
            )
        case 4:
            return StageTheme(
                name: "Mountain Pass",
                tint: .init(red: 0.04, green: 0.1, blue: 0.07, alpha: 1),
                ground: .init(red: 0.11, green: 0.16, blue: 0.11, alpha: 1),
                accent: .init(red: 0.6, green: 0.9, blue: 0.55, alpha: 1)
            )
        case 5:
            return StageTheme(
                name: "Flooded Mall",
                tint: .init(red: 0.03, green: 0.11, blue: 0.13, alpha: 1),
                ground: .init(red: 0.08, green: 0.1, blue: 0.12, alpha: 1),
                accent: .init(red: 0.25, green: 0.75, blue: 0.9, alpha: 1)
            )
        case 6:
            return StageTheme(
                name: "Factory Yard",
                tint: .init(red: 0.12, green: 0.08, blue: 0.05, alpha: 1),
                ground: .init(red: 0.13, green: 0.11, blue: 0.1, alpha: 1),
                accent: .init(red: 0.95, green: 0.42, blue: 0.16, alpha: 1)
            )
        case 7:
            return StageTheme(
                name: "Harbor Fog",
                tint: .init(red: 0.05, green: 0.08, blue: 0.13, alpha: 1),
                ground: .init(red: 0.08, green: 0.1, blue: 0.12, alpha: 1),
                accent: .init(red: 0.55, green: 0.72, blue: 0.85, alpha: 1)
            )
        case 8:
            return StageTheme(
                name: "Dead Subway",
                tint: .init(red: 0.08, green: 0.06, blue: 0.12, alpha: 1),
                ground: .init(red: 0.1, green: 0.09, blue: 0.12, alpha: 1),
                accent: .init(red: 0.65, green: 0.42, blue: 0.95, alpha: 1)
            )
        case 9:
            return StageTheme(
                name: "Burnt Castle",
                tint: .init(red: 0.14, green: 0.05, blue: 0.04, alpha: 1),
                ground: .init(red: 0.15, green: 0.09, blue: 0.08, alpha: 1),
                accent: .init(red: 1.0, green: 0.32, blue: 0.12, alpha: 1)
            )
        default:
            return StageTheme(
                name: "Last Cliff",
                tint: .init(red: 0.02, green: 0.01, blue: 0.03, alpha: 1),
                ground: .init(red: 0.08, green: 0.06, blue: 0.07, alpha: 1),
                accent: .init(red: 1.0, green: 0.08, blue: 0.04, alpha: 1)
            )
        }
    }

    private func buildStageDecor(theme: StageTheme) {
        let sign = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        sign.text = theme.name.uppercased()
        sign.fontSize = 18
        sign.fontColor = theme.accent.withAlphaComponent(0.55)
        sign.position = CGPoint(x: size.width * 0.18, y: groundY + 38)
        sign.zPosition = 4
        stageDecorLayer.addChild(sign)

        for i in 0..<6 {
            let width = CGFloat.random(in: 18...42)
            let height = CGFloat.random(in: 28...95)
            let x = CGFloat(i) * (cliffX / 6) + CGFloat.random(in: 10...35)
            let shape = SKShapeNode(rect: CGRect(x: x, y: groundY, width: width, height: height), cornerRadius: 2)
            shape.fillColor = theme.ground.withAlphaComponent(0.72)
            shape.strokeColor = .clear
            shape.zPosition = 3
            stageDecorLayer.addChild(shape)
        }
    }

    private func buildGround() {
        let theme = currentStageTheme()

        // Dirt ground on the left
        let groundRect = CGRect(x: 0, y: 0, width: cliffX, height: groundY)
        let ground = SKShapeNode(rect: groundRect)
        ground.fillColor = theme.ground
        ground.strokeColor = .clear
        ground.zPosition = 5

        // Green grass strip on top
        let grass = SKShapeNode(rect: CGRect(x: 0, y: groundY - 6, width: cliffX, height: 10))
        grass.fillColor = theme.accent.withAlphaComponent(0.72)
        grass.strokeColor = .clear
        grass.zPosition = 6

        terrainLayer.addChild(ground)
        terrainLayer.addChild(grass)

        // Ground physics
        let groundBody = SKNode()
        groundBody.position = CGPoint(x: cliffX / 2, y: groundY)
        let pb = SKPhysicsBody(rectangleOf: CGSize(width: cliffX, height: 10))
        pb.isDynamic = false
        pb.categoryBitMask = PhysicsCategory.ground
        pb.collisionBitMask = PhysicsCategory.zombie | PhysicsCategory.pee
        pb.contactTestBitMask = PhysicsCategory.pee
        groundBody.physicsBody = pb
        terrainLayer.addChild(groundBody)

        // Also extend ground under everything
        let fullGround = SKNode()
        fullGround.position = CGPoint(x: size.width / 2, y: groundY - 5)
        let fpb = SKPhysicsBody(rectangleOf: CGSize(width: size.width, height: 10))
        fpb.isDynamic = false
        fpb.categoryBitMask = PhysicsCategory.ground
        fpb.collisionBitMask = PhysicsCategory.pee
        fpb.contactTestBitMask = PhysicsCategory.pee
        fullGround.physicsBody = fpb
        terrainLayer.addChild(fullGround)
    }

    private func buildCliff() {
        let theme = currentStageTheme()
        let cliffWidth: CGFloat = size.width - cliffX
        let cliffHeight: CGFloat = cliffTopY - groundY

        // Cliff body
        let cliffRect = CGRect(x: cliffX, y: groundY, width: cliffWidth, height: cliffHeight)
        let cliff = SKShapeNode(rect: cliffRect)
        cliff.fillColor = theme.ground.withAlphaComponent(0.95)
        cliff.strokeColor = .clear
        cliff.zPosition = 5
        terrainLayer.addChild(cliff)

        // Cliff edge highlight
        let edgeLine = SKShapeNode(rect: CGRect(x: cliffX, y: cliffTopY - 8, width: cliffWidth, height: 8))
        edgeLine.fillColor = theme.accent.withAlphaComponent(0.65)
        edgeLine.strokeColor = .clear
        edgeLine.zPosition = 6
        terrainLayer.addChild(edgeLine)

        // Cliff physics (wall)
        let cliffPhys = SKNode()
        cliffPhys.position = CGPoint(x: cliffX, y: groundY + cliffHeight / 2)
        let cpb = SKPhysicsBody(rectangleOf: CGSize(width: 10, height: cliffHeight))
        cpb.isDynamic = false
        cpb.categoryBitMask = PhysicsCategory.cliff
        cpb.collisionBitMask = PhysicsCategory.zombie
        cliffPhys.physicsBody = cpb
        terrainLayer.addChild(cliffPhys)
    }

    private func rebuildTerrain() {
        terrainLayer.removeAllChildren()
        buildGround()
        buildCliff()
    }

    private func buildPlayer() {
        playerNode = SKNode()
        playerNode.position = CGPoint(x: cliffX + 20, y: cliffTopY)
        playerNode.zPosition = 10

        let shadow = SKShapeNode(ellipseIn: CGRect(x: -18, y: -18, width: 36, height: 8))
        shadow.fillColor = .black.withAlphaComponent(0.45)
        shadow.strokeColor = .clear

        let leftLeg = SKShapeNode(rect: CGRect(x: -8, y: -15, width: 7, height: 17), cornerRadius: 2)
        leftLeg.fillColor = .init(red: 0.08, green: 0.1, blue: 0.14, alpha: 1)
        leftLeg.strokeColor = .clear

        let rightLeg = SKShapeNode(rect: CGRect(x: 1, y: -15, width: 7, height: 17), cornerRadius: 2)
        rightLeg.fillColor = .init(red: 0.1, green: 0.12, blue: 0.16, alpha: 1)
        rightLeg.strokeColor = .clear

        let torso = SKShapeNode(rect: CGRect(x: -10, y: 0, width: 20, height: 25), cornerRadius: 4)
        torso.fillColor = .init(red: 0.19, green: 0.21, blue: 0.18, alpha: 1)
        torso.strokeColor = .clear
        torso.zPosition = 2

        let jacketHighlight = SKShapeNode(rect: CGRect(x: -7, y: 3, width: 4, height: 19), cornerRadius: 2)
        jacketHighlight.fillColor = .init(red: 0.36, green: 0.39, blue: 0.32, alpha: 0.75)
        jacketHighlight.strokeColor = .clear
        jacketHighlight.zPosition = 3

        let belt = SKShapeNode(rect: CGRect(x: -10, y: 0, width: 20, height: 3), cornerRadius: 1)
        belt.fillColor = .init(red: 0.04, green: 0.04, blue: 0.04, alpha: 1)
        belt.strokeColor = .clear
        belt.zPosition = 4

        let headNode = SKShapeNode(circleOfRadius: 10)
        headNode.fillColor = .init(red: 0.78, green: 0.61, blue: 0.47, alpha: 1)
        headNode.strokeColor = .clear
        headNode.position = CGPoint(x: 0, y: 31)
        headNode.zPosition = 4

        let cheekShade = SKShapeNode(rect: CGRect(x: -8, y: 28, width: 16, height: 5), cornerRadius: 2)
        cheekShade.fillColor = .init(red: 0.44, green: 0.28, blue: 0.22, alpha: 0.42)
        cheekShade.strokeColor = .clear
        cheekShade.zPosition = 5

        let hair = SKShapeNode(rect: CGRect(x: -11, y: 35, width: 22, height: 8), cornerRadius: 4)
        hair.fillColor = .init(red: 0.08, green: 0.055, blue: 0.035, alpha: 1)
        hair.strokeColor = .clear
        hair.zPosition = 6

        let leftArm = SKShapeNode(rect: CGRect(x: -18, y: 11, width: 16, height: 5), cornerRadius: 2.5)
        leftArm.fillColor = .init(red: 0.2, green: 0.22, blue: 0.18, alpha: 1)
        leftArm.strokeColor = .clear
        leftArm.rotation = -0.25
        leftArm.zPosition = 1

        let rightArm = SKShapeNode(rect: CGRect(x: -2, y: 10, width: 18, height: 5), cornerRadius: 2.5)
        rightArm.fillColor = .init(red: 0.2, green: 0.22, blue: 0.18, alpha: 1)
        rightArm.strokeColor = .clear
        rightArm.rotation = 0.14
        rightArm.zPosition = 5

        let streamOriginMarker = SKShapeNode(circleOfRadius: 2.2)
        streamOriginMarker.fillColor = .init(red: 0.97, green: 0.74, blue: 0.22, alpha: 0.9)
        streamOriginMarker.strokeColor = .init(red: 1.0, green: 0.92, blue: 0.52, alpha: 0.8)
        streamOriginMarker.position = CGPoint(x: -10, y: 9)
        streamOriginMarker.zPosition = 6

        playerNode.addChild(shadow)
        playerNode.addChild(leftLeg)
        playerNode.addChild(rightLeg)
        playerNode.addChild(leftArm)
        playerNode.addChild(torso)
        playerNode.addChild(jacketHighlight)
        playerNode.addChild(belt)
        playerNode.addChild(rightArm)
        playerNode.addChild(headNode)
        playerNode.addChild(cheekShade)
        playerNode.addChild(hair)
        playerNode.addChild(streamOriginMarker)

        // Idle sway
        let sway = SKAction.sequence([
            SKAction.rotate(byAngle: 0.04, duration: 0.8),
            SKAction.rotate(byAngle: -0.04, duration: 0.8)
        ])
        playerNode.run(SKAction.repeatForever(sway))

        addChild(playerNode)
    }

    private func buildHUD() {
        let hudZ: CGFloat = 50

        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 16, y: size.height - 36)
        scoreLabel.zPosition = hudZ
        scoreLabel.text = "Score: 0"
        addChild(scoreLabel)

        waveLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        waveLabel.fontSize = 20
        waveLabel.fontColor = .init(red: 0.4, green: 1.0, blue: 0.4, alpha: 1)
        waveLabel.horizontalAlignmentMode = .center
        waveLabel.position = CGPoint(x: size.width / 2, y: size.height - 36)
        waveLabel.zPosition = hudZ
        waveLabel.text = "Wave 1"
        addChild(waveLabel)

        stageLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        stageLabel.fontSize = 17
        stageLabel.fontColor = .init(red: 0.8, green: 0.92, blue: 1.0, alpha: 1)
        stageLabel.horizontalAlignmentMode = .left
        stageLabel.position = CGPoint(x: 16, y: size.height - 62)
        stageLabel.zPosition = hudZ
        stageLabel.text = "Stage 1"
        addChild(stageLabel)

        bossLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        bossLabel.fontSize = 18
        bossLabel.fontColor = .init(red: 1, green: 0.22, blue: 0.14, alpha: 1)
        bossLabel.horizontalAlignmentMode = .right
        bossLabel.position = CGPoint(x: size.width - 16, y: size.height - 62)
        bossLabel.zPosition = hudZ
        bossLabel.text = ""
        addChild(bossLabel)

        // Hearts
        for i in 0..<3 {
            let heart = SKLabelNode(text: "")
            heart.fontSize = 22
            heart.position = CGPoint(x: size.width - 24 - CGFloat(i) * 30, y: size.height - 36)
            heart.zPosition = hudZ
            heartNodes.append(heart)
            addChild(heart)
        }

        // Pause
        pauseButton = SKLabelNode(fontNamed: "AvenirNext-Bold")
        pauseButton.text = "II"
        pauseButton.fontSize = 18
        pauseButton.fontColor = .white
        pauseButton.horizontalAlignmentMode = .center
        pauseButton.position = CGPoint(x: size.width / 2, y: size.height - 62)
        pauseButton.zPosition = hudZ
        pauseButton.name = "pauseBtn"
        addChild(pauseButton)
    }

    private func buildAimIndicator() {
        aimIndicator = SKShapeNode()
        aimIndicator.strokeColor = .init(red: 1, green: 1, blue: 0, alpha: 0.5)
        aimIndicator.lineWidth = 2
        aimIndicator.zPosition = 8
        aimIndicator.isHidden = true
        addChild(aimIndicator)
        updateAimPath()
    }

    private func updateAimPath() {
        let origin = firingOrigin()
        let path = CGMutablePath()
        path.move(to: origin)

        // Parabolic preview
        let speed: CGFloat = 320
        let vx = -speed * cos(aimAngle)
        let vy = speed * sin(aimAngle)
        var px = origin.x, py = origin.y
        let dt: CGFloat = 0.04
        let g: CGFloat = -9.8 * 30

        for _ in 0..<30 {
            px += vx * dt
            py += vy * dt + 0.5 * g * dt * dt
            let pt = CGPoint(x: px, y: py)
            path.addLine(to: pt)
            if py < groundY { break }
        }
        aimIndicator.path = path
    }

    private func firingOrigin() -> CGPoint {
        CGPoint(x: cliffX + 10, y: cliffTopY + 9)
    }

    // MARK: - Update
    override func update(_ currentTime: TimeInterval) {
        guard !gameState.isGameOver && !gameState.isPaused && !gameState.isCleared else { return }

        // Spawn zombies
        spawnTimer += 1.0 / 60.0
        if gameState.shouldSpawnBoss() {
            spawnBoss()
        } else if !gameState.isBossActive && spawnTimer >= gameState.spawnInterval() {
            spawnTimer = 0
            spawnZombie()
        }

        // Move zombies toward cliff (left to right)
        let baseSpeed: CGFloat = 55
        var zombiesThatReachedPlayer: [ZombieNode] = []
        for zombie in zombies where !zombie.isDead {
            let speed = baseSpeed * zombie.zombieType.speedMultiplier
            if zombie.isClimbing {
                zombie.position.x = cliffX - 8
                zombie.position.y += max(0.55, speed * 0.018)
                if Int.random(in: 0...10) == 0 {
                    spawnCliffDust(at: zombie.position)
                }

                if zombie.position.y >= cliffTopY - 6 {
                    zombiesThatReachedPlayer.append(zombie)
                    continue
                }
            } else {
                zombie.physicsBody?.velocity.dx = speed
                zombie.physicsBody?.velocity.dy = min(zombie.physicsBody?.velocity.dy ?? 0, 50)
            }

            if !zombie.isClimbing && zombie.position.x >= cliffX - 12 {
                zombie.beginClimbing()
                zombie.position.x = cliffX - 8
                spawnCliffDust(at: zombie.position)
            }

            if zombie.position.x >= cliffX + 12 {
                zombiesThatReachedPlayer.append(zombie)
            }
        }

        handleZombiesThatReachedPlayer(zombiesThatReachedPlayer)

        // Pee droplets
        if isFiring {
            dropletSpawnTimer += 1.0 / 60.0
            if dropletSpawnTimer >= dropletInterval {
                dropletSpawnTimer = 0
                spawnDroplet()
            }
            updateStreamEffect()
        }

        // Cleanup dead droplets (by name, as timer removes them via SKAction)
    }

    private func handleZombiesThatReachedPlayer(_ reachedZombies: [ZombieNode]) {
        guard !reachedZombies.isEmpty else { return }

        for zombie in reachedZombies where !zombie.isDead {
            zombie.isDead = true
            spawnCliffDust(at: zombie.position)
            zombie.removeFromParent()
            gameState.loseLife()
        }

        zombies.removeAll { zombie in
            reachedZombies.contains { $0 === zombie }
        }
        updateHUD()
        shakeCamera()

        if gameState.isGameOver {
            onGameOver?()
        }
    }

    // MARK: - Zombie spawning
    private func spawnZombie() {
        let types = gameState.availableZombieTypes()
        let type = types.randomElement()!
        let zombie = ZombieNode(type: type, sceneSize: size)

        let spawnX = CGFloat.random(in: 30...cliffX * 0.4)
        zombie.position = CGPoint(x: spawnX, y: groundY - 20)
        zombie.zPosition = 7
        zombie.alpha = 0.25

        zombie.setScale(0.01)
        spawnEmergenceDirt(at: CGPoint(x: spawnX, y: groundY))
        let rise = SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.48),
            SKAction.moveTo(y: groundY + 24, duration: 0.48),
            SKAction.fadeAlpha(to: 1.0, duration: 0.32)
        ])
        rise.timingMode = .easeOut
        zombie.run(rise)

        zombies.append(zombie)
        addChild(zombie)
    }

    private func spawnBoss() {
        gameState.startBossFight()
        updateHUD()
        clearRemainingZombies(keepBosses: false)

        let bossType = gameState.bossTypeForCurrentStage()
        let boss = ZombieNode(type: bossType, sceneSize: size)
        boss.boostHP(by: gameState.stage * (bossType == .finalBoss ? 8 : 4))
        boss.position = CGPoint(x: max(56, cliffX * 0.16), y: groundY - 24)
        boss.zPosition = 8
        boss.alpha = 0

        let warning = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        warning.text = bossType == .finalBoss ? "FINAL BOSS: \(gameState.currentStage.bossName)" : "BOSS: \(gameState.currentStage.bossName)"
        warning.fontSize = bossType == .finalBoss ? 28 : 30
        warning.fontColor = .init(red: 1, green: 0.1, blue: 0.05, alpha: 1)
        warning.position = CGPoint(x: size.width / 2, y: size.height * 0.7)
        warning.zPosition = 60
        addChild(warning)
        if bossType == .finalBoss {
            run(SKAction.sequence([
                SKAction.colorize(with: .red, colorBlendFactor: 0.18, duration: 0.12),
                SKAction.colorize(withColorBlendFactor: 0, duration: 0.3)
            ]))
            shakeCamera()
        }
        warning.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.12, duration: 0.25),
                SKAction.fadeOut(withDuration: 1.0)
            ]),
            SKAction.removeFromParent()
        ]))

        spawnEmergenceDirt(at: CGPoint(x: boss.position.x, y: groundY), scale: bossType == .finalBoss ? 2.2 : 1.5)
        boss.run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.65),
            SKAction.moveTo(y: groundY + (bossType == .finalBoss ? 72 : 46), duration: 0.65)
        ]))
        zombies.append(boss)
        addChild(boss)
    }

    // MARK: - Pee mechanics
    private func spawnDroplet() {
        let origin = firingOrigin()
        let radius = CGFloat.random(in: 2.0...3.6)
        let droplet = SKShapeNode(circleOfRadius: radius)
        droplet.fillColor = .init(red: 1.0, green: 0.78, blue: 0.12, alpha: 0.78)
        droplet.strokeColor = .init(red: 1.0, green: 0.94, blue: 0.42, alpha: 0.5)
        droplet.lineWidth = 0.7
        droplet.position = origin
        droplet.zPosition = 9
        droplet.name = "droplet"

        // Slight random spread
        let spread = CGFloat.random(in: -0.06...0.06)
        let angle = aimAngle + spread
        let speed: CGFloat = 300 + CGFloat.random(in: -20...20)
        let vx = -speed * cos(angle)
        let vy = speed * sin(angle)

        let pb = SKPhysicsBody(circleOfRadius: 4)
        pb.velocity = CGVector(dx: vx, dy: vy)
        pb.categoryBitMask = PhysicsCategory.pee
        pb.contactTestBitMask = PhysicsCategory.zombie | PhysicsCategory.ground
        pb.collisionBitMask = PhysicsCategory.ground
        pb.restitution = 0
        pb.linearDamping = 0.1
        droplet.physicsBody = pb

        addChild(droplet)

        // Auto-remove after 3s
        droplet.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.2),
            SKAction.removeFromParent()
        ]))
    }

    private func updateStreamEffect() {
        let origin = firingOrigin()
        let path = CGMutablePath()
        path.move(to: origin)

        let speed: CGFloat = 265
        let vx = -speed * cos(aimAngle)
        let vy = speed * sin(aimAngle)
        let dt: CGFloat = 0.035
        let g: CGFloat = -9.8 * 30
        var px = origin.x
        var py = origin.y

        for _ in 0..<16 {
            px += vx * dt
            py += vy * dt + 0.5 * g * dt * dt
            path.addLine(to: CGPoint(x: px, y: py))
            if py < groundY { break }
        }

        let stream: SKShapeNode
        if let current = streamNode {
            stream = current
        } else {
            stream = SKShapeNode()
            stream.lineCap = .round
            stream.lineJoin = .round
            stream.zPosition = 8.8
            addChild(stream)
            streamNode = stream
        }

        stream.path = path
        stream.strokeColor = .init(red: 1.0, green: 0.74, blue: 0.08, alpha: 0.62)
        stream.lineWidth = 5

        if Int.random(in: 0...2) == 0 {
            spawnMist(at: CGPoint(x: px, y: py))
        }
    }

    private func stopStreamEffect() {
        streamNode?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.08),
            SKAction.removeFromParent()
        ]))
        streamNode = nil
    }

    private func spawnMist(at position: CGPoint) {
        let mist = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.2...2.2))
        mist.fillColor = .init(red: 1.0, green: 0.88, blue: 0.25, alpha: 0.45)
        mist.strokeColor = .clear
        mist.position = position
        mist.zPosition = 8.7
        addChild(mist)
        mist.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: CGFloat.random(in: -10...8), y: CGFloat.random(in: -8...10), duration: 0.22),
                SKAction.fadeOut(withDuration: 0.22),
                SKAction.scale(to: 1.7, duration: 0.22)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    private func spawnSplash(at position: CGPoint, scale: CGFloat) {
        for _ in 0..<8 {
            let splash = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3.2) * scale)
            splash.fillColor = .init(red: 1.0, green: 0.78, blue: 0.12, alpha: 0.72)
            splash.strokeColor = .clear
            splash.position = position
            splash.zPosition = 12
            addChild(splash)

            splash.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(
                        x: CGFloat.random(in: -18...18) * scale,
                        y: CGFloat.random(in: -6...18) * scale,
                        duration: 0.2
                    ),
                    SKAction.fadeOut(withDuration: 0.22),
                    SKAction.scale(to: 0.35, duration: 0.22)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    private func spawnEmergenceDirt(at position: CGPoint, scale: CGFloat = 1.0) {
        let mound = SKShapeNode(ellipseIn: CGRect(
            x: position.x - 24 * scale,
            y: position.y - 8 * scale,
            width: 48 * scale,
            height: 16 * scale
        ))
        mound.fillColor = .init(red: 0.09, green: 0.065, blue: 0.045, alpha: 0.95)
        mound.strokeColor = .clear
        mound.zPosition = 6.5
        addChild(mound)
        mound.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.55),
            SKAction.fadeOut(withDuration: 0.45),
            SKAction.removeFromParent()
        ]))

        for _ in 0..<18 {
            let clod = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...4.5) * scale)
            clod.fillColor = .init(red: 0.18, green: 0.12, blue: 0.07, alpha: 0.85)
            clod.strokeColor = .clear
            clod.position = position
            clod.zPosition = 11
            addChild(clod)
            clod.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(
                        x: CGFloat.random(in: -28...28) * scale,
                        y: CGFloat.random(in: 2...28) * scale,
                        duration: 0.36
                    ),
                    SKAction.fadeOut(withDuration: 0.42),
                    SKAction.scale(to: 0.35, duration: 0.42)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    private func spawnCliffDust(at position: CGPoint) {
        for _ in 0..<5 {
            let dust = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.2...3.0))
            dust.fillColor = .init(red: 0.58, green: 0.48, blue: 0.34, alpha: 0.5)
            dust.strokeColor = .clear
            dust.position = CGPoint(x: cliffX + CGFloat.random(in: -8...4), y: position.y + CGFloat.random(in: -8...12))
            dust.zPosition = 12
            addChild(dust)
            dust.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: CGFloat.random(in: -12...4), y: CGFloat.random(in: -12...4), duration: 0.28),
                    SKAction.fadeOut(withDuration: 0.28),
                    SKAction.scale(to: 1.8, duration: 0.28)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: - Contact
    func didBegin(_ contact: SKPhysicsContact) {
        let a = contact.bodyA
        let b = contact.bodyB

        if (a.categoryBitMask == PhysicsCategory.pee && b.categoryBitMask == PhysicsCategory.zombie) {
            handlePeeHitsZombie(pee: a.node, zombie: b.node)
        } else if (a.categoryBitMask == PhysicsCategory.zombie && b.categoryBitMask == PhysicsCategory.pee) {
            handlePeeHitsZombie(pee: b.node, zombie: a.node)
        } else if (a.categoryBitMask == PhysicsCategory.pee && b.categoryBitMask == PhysicsCategory.ground) ||
                  (a.categoryBitMask == PhysicsCategory.ground && b.categoryBitMask == PhysicsCategory.pee) {
            let peeNode = a.categoryBitMask == PhysicsCategory.pee ? a.node : b.node
            if let peeNode {
                spawnSplash(at: peeNode.position, scale: 0.7)
            }
            peeNode?.removeFromParent()
        }
    }

    private func handlePeeHitsZombie(pee: SKNode?, zombie: SKNode?) {
        guard let pee = pee, let zombieNode = zombie as? ZombieNode ?? zombie?.parent as? ZombieNode else { return }
        guard !zombieNode.isDead else { return }

        pee.removeFromParent()
        spawnSplash(at: pee.position, scale: zombieNode.zombieType.isBoss ? 1.35 : 1.0)
        zombieNode.takeDamage()

        if zombieNode.hp <= 0 {
            killZombie(zombieNode)
        }
    }

    private func killZombie(_ zombie: ZombieNode) {
        zombie.isDead = true
        gameState.addScore(zombie.zombieType.scoreValue)
        if zombie.zombieType.isBoss {
            let wasFinalBoss = zombie.zombieType == .finalBoss
            gameState.advanceAfterBossDefeat()
            if wasFinalBoss {
                onGameClear?()
            } else {
                showStageTransition()
            }
        } else {
            gameState.recordKill()
        }
        updateHUD()

        // Death splat
        let splat = SKEmitterNode()
        if let emitter = makeSplatEmitter() {
            emitter.position = zombie.position
            emitter.zPosition = 20
            addChild(emitter)
            emitter.run(SKAction.sequence([
                SKAction.wait(forDuration: 1.0),
                SKAction.removeFromParent()
            ]))
        } else {
            _ = splat
        }

        zombie.run(SKAction.sequence([
            SKAction.group([
                SKAction.scaleX(to: 2.0, duration: 0.15),
                SKAction.scaleY(to: 0.1, duration: 0.15),
                SKAction.fadeOut(withDuration: 0.15)
            ]),
            SKAction.removeFromParent()
        ]))
        zombies.removeAll { $0 === zombie }
    }

    private func clearRemainingZombies(keepBosses: Bool) {
        for zombie in zombies {
            if keepBosses && zombie.zombieType.isBoss { continue }
            spawnEmergenceDirt(at: zombie.position, scale: zombie.zombieType.isBoss ? 1.5 : 0.8)
            zombie.removeFromParent()
        }
        zombies.removeAll { keepBosses ? !$0.zombieType.isBoss : true }
    }

    private func makeSplatEmitter() -> SKEmitterNode? {
        // Programmatic green splat particles
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 60
        emitter.numParticlesToEmit = 20
        emitter.particleLifetime = 0.6
        emitter.particleSpeed = 80
        emitter.particleSpeedRange = 40
        emitter.emissionAngle = 0
        emitter.emissionAngleRange = .pi * 2
        emitter.particleScale = 0.15
        emitter.particleScaleRange = 0.1
        emitter.particleScaleSpeed = -0.2
        emitter.particleColor = .init(red: 0.2, green: 0.8, blue: 0.2, alpha: 1)
        emitter.particleColorBlendFactor = 1
        emitter.particleAlphaSpeed = -1.5
        return emitter
    }

    // MARK: - HUD updates
    private func updateHUD() {
        scoreLabel.text = "Score: \(gameState.score)"
        waveLabel.text = "Wave \(gameState.wave)"
        stageLabel.text = "Stage \(gameState.stage)/10  \(currentStageTheme().name)  \(gameState.killsThisStage)/\(gameState.killsNeededForBoss())"
        bossLabel.text = gameState.isBossActive ? gameState.currentStage.bossName : ""
        for (i, heart) in heartNodes.enumerated() {
            heart.text = i < gameState.lives ? "HP" : "--"
        }
    }

    private func showStageTransition() {
        clearRemainingZombies(keepBosses: true)
        buildBackground()
        rebuildTerrain()
        updateAimPath()

        let title = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        title.text = "STAGE \(gameState.stage): \(currentStageTheme().name.uppercased())"
        title.fontSize = 26
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.66)
        title.zPosition = 70
        title.alpha = 0
        addChild(title)
        title.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.25),
            SKAction.wait(forDuration: 1.0),
            SKAction.fadeOut(withDuration: 0.45),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Touch handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)

        // Pause button
        if let node = atPoint(loc) as? SKLabelNode, node.name == "pauseBtn" {
            gameState.isPaused.toggle()
            isPaused = gameState.isPaused
            return
        }

        guard !gameState.isGameOver && !gameState.isPaused else { return }

        isFiring = true
        touchStartY = loc.y
        aimStartAngle = aimAngle
        aimIndicator.isHidden = false
        dropletSpawnTimer = 0
        updateStreamEffect()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isFiring, let touch = touches.first else { return }
        let loc = touch.location(in: self)
        let delta = (loc.y - touchStartY) / size.height * .pi
        aimAngle = max(0.05, min(.pi / 2.2, aimStartAngle + delta))
        updateAimPath()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isFiring = false
        aimIndicator.isHidden = true
        stopStreamEffect()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isFiring = false
        aimIndicator.isHidden = true
        stopStreamEffect()
    }

    // MARK: - Camera shake
    private func shakeCamera() {
        let shake = SKAction.sequence([
            SKAction.moveBy(x: 8, y: 0, duration: 0.05),
            SKAction.moveBy(x: -16, y: 0, duration: 0.05),
            SKAction.moveBy(x: 8, y: 0, duration: 0.05)
        ])
        run(shake)
    }
}
