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
    private var hpBar: SKShapeNode?

    init(type: ZombieType, sceneSize: CGSize) {
        self.zombieType = type
        self.hp = type.hp

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

        // HP bar for tank
        if type == .tank {
            let bar = SKShapeNode(rect: CGRect(x: -12, y: 48, width: 24, height: 4))
            bar.fillColor = .red
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

    func takeDamage(_ dmg: Int = 1) {
        hp -= dmg
        // Flash
        let flash = SKAction.sequence([
            SKAction.colorize(with: .white, colorBlendFactor: 0.8, duration: 0.05),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.05)
        ])
        body.run(flash)

        if let bar = hpBar {
            let fraction = CGFloat(max(0, hp)) / CGFloat(zombieType.hp)
            bar.xScale = fraction
        }
    }
}

// MARK: - GameScene
class GameScene: SKScene, SKPhysicsContactDelegate {

    // State
    var gameState: GameState!
    var onGameOver: (() -> Void)?

    // Layout constants
    private var cliffX: CGFloat = 0
    private var groundY: CGFloat = 0
    private var cliffTopY: CGFloat = 0
    private var playerNode: SKNode!

    // Pee
    private var isFiring = false
    private var aimAngle: CGFloat = .pi / 6  // radians above horizontal
    private var touchStartY: CGFloat = 0
    private var aimStartAngle: CGFloat = 0
    private var dropletSpawnTimer: TimeInterval = 0
    private let dropletInterval: TimeInterval = 0.05

    // Zombies
    private var zombies: [ZombieNode] = []
    private var spawnTimer: TimeInterval = 0

    // HUD
    private var scoreLabel: SKLabelNode!
    private var waveLabel: SKLabelNode!
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

        buildBackground()
        buildGround()
        buildCliff()
        buildPlayer()
        buildHUD()
        buildAimIndicator()
    }

    // MARK: - Scene construction
    private func buildBackground() {
        // Stars
        for _ in 0..<80 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.5...2))
            star.fillColor = .white
            star.strokeColor = .clear
            star.alpha = CGFloat.random(in: 0.3...1.0)
            star.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: groundY + CGFloat.random(in: 0...size.height)
            )
            addChild(star)
        }

        // Moon
        let moon = SKShapeNode(circleOfRadius: 36)
        moon.fillColor = .init(red: 1.0, green: 0.97, blue: 0.8, alpha: 1)
        moon.strokeColor = .clear
        moon.position = CGPoint(x: size.width * 0.15, y: size.height * 0.82)
        moon.zPosition = 1
        addChild(moon)

        // Moon shadow (crescent effect)
        let shadow = SKShapeNode(circleOfRadius: 32)
        shadow.fillColor = .init(red: 0.02, green: 0.02, blue: 0.12, alpha: 1)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: size.width * 0.15 + 10, y: size.height * 0.82)
        shadow.zPosition = 2
        addChild(shadow)
    }

    private func buildGround() {
        // Dirt ground on the left
        let groundRect = CGRect(x: 0, y: 0, width: cliffX, height: groundY)
        let ground = SKShapeNode(rect: groundRect)
        ground.fillColor = .init(red: 0.3, green: 0.2, blue: 0.1, alpha: 1)
        ground.strokeColor = .clear
        ground.zPosition = 5

        // Green grass strip on top
        let grass = SKShapeNode(rect: CGRect(x: 0, y: groundY - 6, width: cliffX, height: 10))
        grass.fillColor = .init(red: 0.2, green: 0.5, blue: 0.15, alpha: 1)
        grass.strokeColor = .clear
        grass.zPosition = 6

        addChild(ground)
        addChild(grass)

        // Ground physics
        let groundBody = SKNode()
        groundBody.position = CGPoint(x: cliffX / 2, y: groundY)
        let pb = SKPhysicsBody(rectangleOf: CGSize(width: cliffX, height: 10))
        pb.isDynamic = false
        pb.categoryBitMask = PhysicsCategory.ground
        pb.collisionBitMask = PhysicsCategory.zombie | PhysicsCategory.pee
        pb.contactTestBitMask = PhysicsCategory.pee
        groundBody.physicsBody = pb
        addChild(groundBody)

        // Also extend ground under everything
        let fullGround = SKNode()
        fullGround.position = CGPoint(x: size.width / 2, y: groundY - 5)
        let fpb = SKPhysicsBody(rectangleOf: CGSize(width: size.width, height: 10))
        fpb.isDynamic = false
        fpb.categoryBitMask = PhysicsCategory.ground
        fpb.collisionBitMask = PhysicsCategory.pee
        fpb.contactTestBitMask = PhysicsCategory.pee
        fullGround.physicsBody = fpb
        addChild(fullGround)
    }

    private func buildCliff() {
        let cliffWidth: CGFloat = size.width - cliffX
        let cliffHeight: CGFloat = cliffTopY - groundY

        // Cliff body
        let cliffRect = CGRect(x: cliffX, y: groundY, width: cliffWidth, height: cliffHeight)
        let cliff = SKShapeNode(rect: cliffRect)
        cliff.fillColor = .init(red: 0.45, green: 0.3, blue: 0.15, alpha: 1)
        cliff.strokeColor = .clear
        cliff.zPosition = 5
        addChild(cliff)

        // Cliff edge highlight
        let edgeLine = SKShapeNode(rect: CGRect(x: cliffX, y: cliffTopY - 8, width: cliffWidth, height: 8))
        edgeLine.fillColor = .init(red: 0.55, green: 0.4, blue: 0.2, alpha: 1)
        edgeLine.strokeColor = .clear
        edgeLine.zPosition = 6
        addChild(edgeLine)

        // Cliff physics (wall)
        let cliffPhys = SKNode()
        cliffPhys.position = CGPoint(x: cliffX, y: groundY + cliffHeight / 2)
        let cpb = SKPhysicsBody(rectangleOf: CGSize(width: 10, height: cliffHeight))
        cpb.isDynamic = false
        cpb.categoryBitMask = PhysicsCategory.cliff
        cpb.collisionBitMask = PhysicsCategory.zombie
        cliffPhys.physicsBody = cpb
        addChild(cliffPhys)
    }

    private func buildPlayer() {
        playerNode = SKNode()
        playerNode.position = CGPoint(x: cliffX + 20, y: cliffTopY)
        playerNode.zPosition = 10

        // Body (torso)
        let torso = SKShapeNode(rect: CGRect(x: -8, y: 0, width: 16, height: 22), cornerRadius: 3)
        torso.fillColor = .init(red: 0.9, green: 0.75, blue: 0.6, alpha: 1)
        torso.strokeColor = .clear

        // Head
        let headNode = SKShapeNode(circleOfRadius: 10)
        headNode.fillColor = .init(red: 0.95, green: 0.82, blue: 0.68, alpha: 1)
        headNode.strokeColor = .clear
        headNode.position = CGPoint(x: 0, y: 31)

        // Hair
        let hair = SKShapeNode(rect: CGRect(x: -10, y: 33, width: 20, height: 8), cornerRadius: 4)
        hair.fillColor = .init(red: 0.3, green: 0.15, blue: 0.05, alpha: 1)
        hair.strokeColor = .clear

        // Legs
        let leftLeg = SKShapeNode(rect: CGRect(x: -7, y: -14, width: 6, height: 14), cornerRadius: 2)
        leftLeg.fillColor = .init(red: 0.2, green: 0.3, blue: 0.7, alpha: 1)
        leftLeg.strokeColor = .clear

        let rightLeg = SKShapeNode(rect: CGRect(x: 1, y: -14, width: 6, height: 14), cornerRadius: 2)
        rightLeg.fillColor = leftLeg.fillColor
        rightLeg.strokeColor = .clear

        playerNode.addChild(torso)
        playerNode.addChild(headNode)
        playerNode.addChild(hair)
        playerNode.addChild(leftLeg)
        playerNode.addChild(rightLeg)

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
        let origin = CGPoint(x: cliffX - 5, y: cliffTopY + 10)
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

    // MARK: - Update
    override func update(_ currentTime: TimeInterval) {
        guard !gameState.isGameOver && !gameState.isPaused else { return }

        // Spawn zombies
        spawnTimer += 1.0 / 60.0
        if spawnTimer >= gameState.spawnInterval() {
            spawnTimer = 0
            spawnZombie()
        }

        // Move zombies
        let baseSpeed: CGFloat = 55
        for zombie in zombies where !zombie.isDead {
            let speed = baseSpeed * zombie.zombieType.speedMultiplier
            zombie.physicsBody?.velocity.dx = -speed
            zombie.physicsBody?.velocity.dy = min(zombie.physicsBody?.velocity.dy ?? 0, 50)

            // Check if reached cliff wall
            if zombie.position.x <= cliffX + 22 {
                // zombie reached player
                zombie.isDead = true
                zombie.removeFromParent()
                zombies.removeAll { $0 === zombie }
                gameState.loseLife()
                updateHUD()
                shakeCamera()
                if gameState.isGameOver {
                    onGameOver?()
                }
            }
        }

        // Pee droplets
        if isFiring {
            dropletSpawnTimer += 1.0 / 60.0
            if dropletSpawnTimer >= dropletInterval {
                dropletSpawnTimer = 0
                spawnDroplet()
            }
        }

        // Cleanup dead droplets (by name, as timer removes them via SKAction)
    }

    // MARK: - Zombie spawning
    private func spawnZombie() {
        let types = gameState.availableZombieTypes()
        let type = types.randomElement()!
        let zombie = ZombieNode(type: type, sceneSize: size)

        let spawnX = CGFloat.random(in: 30...cliffX * 0.4)
        zombie.position = CGPoint(x: spawnX, y: groundY)
        zombie.zPosition = 7

        // Rise-from-ground animation
        zombie.position.y = groundY - 50
        let rise = SKAction.moveBy(x: 0, y: 50, duration: 0.5)
        rise.timingMode = .easeOut
        zombie.run(rise)

        zombies.append(zombie)
        addChild(zombie)
    }

    // MARK: - Pee mechanics
    private func spawnDroplet() {
        let origin = CGPoint(x: cliffX - 8, y: cliffTopY + 8)
        let droplet = SKShapeNode(circleOfRadius: 4)
        droplet.fillColor = .init(red: 1.0, green: 0.95, blue: 0.0, alpha: 0.9)
        droplet.strokeColor = .init(red: 1.0, green: 1.0, blue: 0.3, alpha: 0.5)
        droplet.lineWidth = 1
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
            SKAction.wait(forDuration: 3.0),
            SKAction.removeFromParent()
        ]))
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
            peeNode?.removeFromParent()
        }
    }

    private func handlePeeHitsZombie(pee: SKNode?, zombie: SKNode?) {
        guard let pee = pee, let zombieNode = zombie as? ZombieNode ?? zombie?.parent as? ZombieNode else { return }
        guard !zombieNode.isDead else { return }

        pee.removeFromParent()
        zombieNode.takeDamage()

        if zombieNode.hp <= 0 {
            killZombie(zombieNode)
        }
    }

    private func killZombie(_ zombie: ZombieNode) {
        zombie.isDead = true
        gameState.addScore(zombie.zombieType.scoreValue)
        gameState.recordKill()
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
        for (i, heart) in heartNodes.enumerated() {
            heart.text = i < gameState.lives ? "" : "🖤"
        }
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
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isFiring = false
        aimIndicator.isHidden = true
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
