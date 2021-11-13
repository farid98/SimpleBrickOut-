import SpriteKit
import GameController

enum Direction {
    case left
    case right
    case up
    case down
    case none
}

enum SoundType {
    case brickHit
    case paddleHit
    case lifeLost
}

struct ZLevels {
    static let gameBoard          : CGFloat = 1
    static let gameBricksCanvas   : CGFloat = 2
    static let gameBricks         : CGFloat = 3
    static let gamePaddle         : CGFloat = 3
    static let gameBalls          : CGFloat = 4
    static let gamePowerups       : CGFloat = 5
    static let PauseBack          : CGFloat = 6
    static let textAnnounce       : CGFloat = 8
    static let textTop            : CGFloat = 8
    static let levelCompleteBanner : CGFloat = 9
}

class gameScene: SKScene, SKPhysicsContactDelegate {
    
    var highScore = 0  {
        didSet {
            userDefaults.set(highScore, forKey: "highScore")
        }
    }
    
    
    var brickHitsSinceLastPowerup = 0
    var powerUpNumberInLevel = 0
    var paddleSizeChanges = 0 // 0 is normal, we will raise it by +1 every time padddle grows and vice versa
    var noHitBouncesInLevel : Int = 0
    var sweeperUsedInLevel = false
    var lightsOutOn = false
    var lightOfferedInLevel = false
    var bouncesSinceLightOut = 0
    var bouncesInLevel : Int = 0
    var hitsInLevel : Int = 0
    var bouncesInGame : Int = 0
    var hitsInGame : Int = 0
    var levelCompleteBannerSize = CGSize(width: 400, height: 400)
    var fontSizeForLabels : CGFloat = 20
    var levelCompletedBanner2 = SKSpriteNode(color: .purple  , size: CGSize(width: 100, height: 300))
    var levelCompletedBanner = SKShapeNode()
    var levelCompletedBannerText = SKLabelNode()
    var levelCompletedBannerButton = myButton(text: "Next Board")          //  (states: ["Next Board"])
    
    //MARK: STRUCTURES =============================================================================
    struct Skin {
        var backgroundImage : String
        var onScreenTextColor : SKColor
        var buttonNameColorSuffix : String
        var scrollDirection : Direction
        var scrollSpeed : Int
        var paddleImage : Int
    }
    
    struct release : Decodable {
        var type: PowerUpTypes
        var atBrick: Int
    }
    
    struct BoardDesign : Decodable {
        var board : [[Int]]
    }

    var powerUpProbabilityMatrix = [
        (PowerUpTypes.paddleLonger,80),
        (PowerUpTypes.paddleShorter,90),
        (PowerUpTypes.stickyPaddle,60),
        (PowerUpTypes.lightsOut,50),
        (PowerUpTypes.multiBall,30),
        (PowerUpTypes.fireBall,10),
    ]

    
    //---------------------------------------------------------------------------------------------------------------------
    enum PowerUpTypes : Int, Decodable {
        case paddleLonger      // 0
        case paddleShorter     // 1
        case stickyPaddle      // 3
        case multiBall         // 4
        case fireBall          // 5
        case lightsOut         // 7
        case lightsOn          // 8   // this is only called if lightsOut is there
        case sweepAllBricks    // 6   // this is only called if end of level situation is there
        case extraLife         // 2   // depends on score

        var image : String {
            switch self {
            case .extraLife:
                return "pu_extralife"
            case .paddleShorter:
                return "pu_paddleshorter"
            case .paddleLonger:
                return "pu_paddlelonger"
            case .stickyPaddle:
                return "pu_stickypaddle"
            case .multiBall:
                return "pu_multiball"
            case .fireBall:
                return "pu_fireball"
            case .sweepAllBricks:
                return "puSweep"
            case .lightsOut:
                return "puLightsOff"
            case .lightsOn:
                return "puLightsOn"
                
            }
        }
        
        var announceText : String {
            switch self {
            case .extraLife:
                return "Extra Life"
            case .paddleShorter:
                return "Shorter Paddle"
            case .paddleLonger:
                return "Longer Paddle"
            case .stickyPaddle:
                return "Sticky Paddle"
            case .multiBall:
                return "Multi Ball"
            case .fireBall:
                return "Fire Ball"
            case .sweepAllBricks:
                return "All swept away"
            case .lightsOut:
                return "Lights Out"
            case .lightsOn:
                return "Lights On"
                
            }
        }
        
        
    }
    //---------------------------------------------------------------------------------------------------------
    struct PhysicsCategory {
        static let None       : UInt32 = 0
        static let All        : UInt32 = UInt32.max
        static let Paddle     : UInt32 = 1 << 0
        static let Ball       : UInt32 = 1 << 1
        static let Wall       : UInt32 = 1 << 2
        static let Brick      : UInt32 = 1 << 3
        static let Bottom     : UInt32 = 1 << 4
        static let PowerUp    : UInt32 = 1 << 5
    }
    
    struct PowerUp {
        var sprite : SKSpriteNode
        var type   : PowerUpTypes
    }
    
    struct Balls {
        var sprite : SKSpriteNode
        var isSticky : Bool = false
    }
    
    struct Wall {
        var sprite : SKSpriteNode
        var hitsTaken : Int
        var brickType : Int
    }
    
    
    enum State {
        case firstPlay // just entered scene for first time from the Menu
        case playing
        case newLife
        case gameOver
        case allLevelsDone
        case paused
        case levelCompleted
    }
    
    
    struct Brick  {
        let img : [String]    // name of the image files that represents it. The number of images in array determines how many hits it takes to break this brick
    }
    
    //-------------------------------------------------------------------------------------------------------
    
    let brickTypes = [
        Brick( img: ["brickRed"] ),    //1613981
        Brick( img: ["brickBlue"] ),   // 21240
        Brick( img: ["brickYellow"] ),   // 3
        Brick( img: ["brickGreen"] ),    // 4
        Brick( img: ["brickBlue1"] ),    // 5
        Brick( img: ["brickBlue2"] ),    // 6
        Brick( img: ["brickBlue3"] ),    // 7
        Brick( img: ["brickGreen1"] ),   // 8//m4
        Brick( img: ["brickGreen2"] ),   // 9//e1
        Brick( img: ["brickGreen3"] ),   // 10//hree
        Brick( img: ["brickPurple1"] ),  // 11//xxz
        Brick( img: ["brickPurple2"] ),  // 12//n
        Brick( img: ["brickPurple3"] ),  // 13
        Brick( img: ["brickStrawberry"] ),  // 14
        Brick( img: ["brickMaroon"] ),      // 15
        Brick (img: ["multiHitBrick2", "multiHitBrick1"] ),    // 16
        Brick (img: ["multiHitBrick3", "multiHitBrick2", "multiHitBrick1"] ),   // 17
        Brick (img: ["bric-transparent", "brickPurple1"] ),   // 18
        Brick (img: ["bric-transparent", "brickMaroon" ] ),   // 19
        
    ]
    
    var skin : [Skin] = [
        Skin( backgroundImage: "backStarField",
              onScreenTextColor : SKColor.white  ,
              buttonNameColorSuffix : "White", scrollDirection: .up, scrollSpeed: 1, paddleImage: 0),
        
        Skin( backgroundImage: "backWhite",
              onScreenTextColor : SKColor.black  ,
              buttonNameColorSuffix : "Black", scrollDirection: .none, scrollSpeed: 0, paddleImage: 2),
        
        
        Skin( backgroundImage: "backSky",
              onScreenTextColor : SKColor.black  ,
              buttonNameColorSuffix : "Black", scrollDirection: .right, scrollSpeed: 2, paddleImage: 1),
        
        
        Skin( backgroundImage: "backBlack",
              onScreenTextColor : SKColor.white  ,
              buttonNameColorSuffix : "White", scrollDirection: .none, scrollSpeed: 0, paddleImage: 0),
        
        
    ]
    
    var paddleImages = [["paddleOrange"],
                        ["paddleGrayPattern"],
                        ["paddleGreenPattern"],
    ]
    
    
    var boards = [BoardDesign]()
    var stateBeforePause = State.newLife
    var stickyPaddleUsed = 0
    let stickyPaddleMaxUsed = 6
    let brickRows = 12
    let brickCols = 15
    // Main sizes:
    var sizePauseTapZoneHeight : CGFloat = 0
    var sizeBrick : CGSize = CGSize(width: 0,height: 0)
    var sizePowerUp : CGFloat = 50.0
    var topGapToBricks : CGFloat = 0
    var bottomToPaddle : CGFloat = 0
    var bottomToText : CGFloat = 150
    var sizeGameButtons: CGSize = CGSize(width : 0, height : 0)
    var sizeButtonsGap : CGFloat = 40
    var sizeBall : CGFloat = 0
    var sizePaddle : CGSize = CGSize.zero
    var buttonSize : CGFloat = 70.0
    var buttonRowHeight : CGFloat = 140.0
    
    var announceTextBack =  SKSpriteNode()
    var pauseBack = SKSpriteNode()
    var announceText = SKLabelNode()
    
    var totalLives = 3
    var ballVelocity : CGFloat = 650.0
    var txtLives = SKLabelNode()
    var txtBoards = SKLabelNode()
    var txtCountDown = SKLabelNode()
    
    
    enum GameSpeed {
        case slow
        case medium
        case fast
        
    }
    
    var gameSpeed : GameSpeed = .medium
    
    var powerUps = [PowerUp]()
    var balls = [Balls]()
    var wallSprites =  [Wall]() //        [SKSpriteNode] = []
    var paddle = SKSpriteNode(imageNamed: "paddleOrange")
    var bottomBorder = SKSpriteNode()
    
    var scrollBack = ScrollingImage()
    
    var btnPlay = SKSpriteNode()
    var btnHome = SKSpriteNode()
    var btnBacks = SKSpriteNode()
    var btnPaddles = SKSpriteNode()
    var btnPause = SKSpriteNode()
    var brickCanvas = SKSpriteNode(color: .black, size: CGSize(width: 0, height: 0))
    
    var txtScore = SKLabelNode()
    var txtHighScore = SKLabelNode()
    var txtBoard = SKLabelNode()
    
    //============================== Varibles with didSet functions
    var currentBoard = 0 {
        
        didSet {
            userDefaults.set(currentBoard, forKey: "currentBoard")
            
        }
    }
    //-----------------------------------------------------------------
    
    var sounds = false
    //--------------------------------------------------------------------------
    var stickyPaddleOn  = false {
        didSet {
            if stickyPaddleOn == false {   /// First get all balls which were sticking to the paddle moving
                for (i,n) in balls.enumerated() {
                    if n.isSticky {
                        balls[i].isSticky = false
                        startBallMovement(ballNumber: i)
                    }
                }
            }
        }
    }
    
    var fireBallOn = false
    //-----------------------------------------------------------------------------------
    var skinNumber : Int = 0 {
        didSet {
            if self.skinNumber >= skin.count {
                self.skinNumber = 0
            }
            else if skinNumber < 0 {
                self.skinNumber = skin.count
            }
            userDefaults.set(skinNumber, forKey: "skin")
            scrollBack.texture = SKTexture(imageNamed: skin[skinNumber].backgroundImage)
            scrollBack.direction = skin[skinNumber].scrollDirection
            scrollBack.scrollSpeed = skin[skinNumber].scrollSpeed
            scrollBack.size.height = self.frame.size.height
            scrollBack.size.width = (scrollBack.texture?.size().width)! / (scrollBack.texture?.size().height)! * self.frame.height
            
            var e = [SKTexture()]
            e.removeAll() // creating the variable causes a blank to be appended - which has to be removed immediately. prob cleaner this way
            for s in  paddleImages[skin[skinNumber].paddleImage] {
                e.append(SKTexture(imageNamed: s))
            }
            let r = SKAction.animate(with: e, timePerFrame: 1)
            let r2 = SKAction.repeatForever(r)
            paddle.run(r2)
            
            scrollBack.setup() // to install the new texture in underlying sprites
            
            txtScore.fontColor = skin[skinNumber].onScreenTextColor
            txtHighScore.fontColor = skin[skinNumber].onScreenTextColor
            txtLives.fontColor = skin[skinNumber].onScreenTextColor
            txtBoard.fontColor = skin[skinNumber].onScreenTextColor
            txtCountDown.fontColor = skin[skinNumber].onScreenTextColor
            btnPause.texture =  SKTexture(imageNamed: "btnPause" +  skin[skinNumber].buttonNameColorSuffix )
            announceText.fontColor = skin[skinNumber].onScreenTextColor
        }
    }
    //----------------------------------------------------------------------------------
    var lives = 3 {
        didSet {
            txtLives.text = "Lives: " + String(lives)
        }
    }
    //-----------------------------------------------------------------------------------
    var score = 0 {
        didSet {
            txtScore.text = "Score: " + String(score)
        }
    }
    
    //-----------------------------------------------------------------------------------
    var state = State.playing {
        didSet {
            // game over and level complete states are handled in the Gameover function
            
            if self.state == .playing {
                pauseBack.isHidden = true
                levelCompletedBanner.isHidden = true
                #if os(OSX)
                NSCursor.hide()
                #endif
                
            }
            else if self.state == .newLife {
                pauseBack.isHidden = true
                levelCompletedBanner.isHidden = true
                #if os(OSX)
                NSCursor.unhide()
                #endif
                
            }
            else if self.state == .paused {
                pauseBack.isHidden = false
                levelCompletedBanner.isHidden = true
                #if os(OSX)
                NSCursor.unhide()
                #endif
            }
            
            else if self.state == .levelCompleted {
                pauseBack.isHidden = true
                levelCompletedBanner.isHidden = false
                #if os(OSX)
                NSCursor.unhide()
                #endif
                
            }
            
        }
    }
    
    
    //-----------------------------------------------------------------------------------------
    
    func setSizes() {
        
        let _ : CGFloat = CGFloat(brickRows)
        let fbrickCols : CGFloat  = CGFloat(brickCols)
        
        sizeBrick.width  = (self.frame.width - (fbrickCols - 1) ) / fbrickCols
        sizeBrick.height = sizeBrick.width *     5 / 6
        
        levelCompleteBannerSize = CGSize(width: self.size.width - 30, height: self.size.width - 30)
        topGapToBricks = sizeBrick.height * 3.5
        bottomToPaddle = 80
        sizeBall = 15.0
        sizePaddle = CGSize(width: 100, height: 20)
        sizeGameButtons = CGSize(width : 50, height : 30)
        sizePowerUp = 50.0
        sizePauseTapZoneHeight = 200.0
        buttonSize  = 70.0
        buttonRowHeight = 160.0
        bottomToText  = 180.0
        
        fontSizeForLabels = 20
        
        switch deviceSize {
        case .iPhoneSE:
            topGapToBricks = sizeBrick.height * 3.8
            bottomToPaddle = 45
            sizeBall = 10.0
            sizePaddle = CGSize(width: 80, height: 20)
            sizeGameButtons = CGSize(width : 50, height : 30)
            sizePowerUp = 35.0
            buttonRowHeight  = 140.0
            bottomToText  = 150.0
            
        case .iPhone8:
            topGapToBricks = sizeBrick.height * 4.0
            sizePowerUp = 40.0
            buttonRowHeight  = 140.0
            bottomToText  = 150.0
            
        case .iPhone8Plus:
            topGapToBricks = sizeBrick.height * 4.0
            bottomToText  = 160.0
            
        case .iPhoneXR:
            topGapToBricks = sizeBrick.height * 4.0
            bottomToText  = 160.0
            
        case .iPhoneX:
            break
        case .iphoneXMax:
            break
        case .iphone12:
            break
        case .iphone12ProMax: break
            
            
        case .iPad:
            bottomToPaddle = 100
            topGapToBricks = sizeBrick.height * 2.5
            //  ballVelocity *= ( 850 / 667 ) // to adjust for longer bricks
            sizeBall = 25.0
            sizePaddle = CGSize(width: 160, height: 25)
            sizeGameButtons = CGSize(width : 70, height : 40)
            sizePowerUp = 50.0
            sizePauseTapZoneHeight = 400.0
            buttonSize  = 90.0
            buttonRowHeight  = 140.0
            bottomToText  = 250.0
            
            levelCompleteBannerSize = CGSize(width: self.size.width / 2, height: self.size.width / 2)
            fontSizeForLabels = 40
            
        }
        
        
    }
    
    // MARK: 🔴🔴🔴 Main Entry Point 🔴🔴🔴
    //---------------------------------------------------------------------------------------
    override func didMove(to view: SKView) {
        
        
        totalLives = 3
        
        // Sualeha cheat mode only on ios and on her phone
        
        if UIDevice.current.name == "Sualeha" {
            totalLives = 10
        }
        
        loadBoards()
        state = .firstPlay
        
        highScore = userDefaults.integer(forKey: "highScore")
        
        
        switch userDefaults.integer(forKey: "sound") {
        case 0:
            sounds = false
        case 1:
            sounds = true
        default:
            sounds = true
        }
        
        switch userDefaults.integer(forKey: "speed") {
        
        
        case 0:
            ballVelocity = 400
            gameSpeed = .slow
        case 1:
            ballVelocity = 550
            gameSpeed = .medium
        case 2:
            ballVelocity = 800
            gameSpeed = .fast
        default:
            ballVelocity = 400
            gameSpeed = .slow 
        
        }
        
        skinNumber = userDefaults.integer(forKey: "skin")
        if skinNumber < 0 || skinNumber >= skin.count {
            skinNumber = 0
        }
        
        currentBoard = userDefaults.integer(forKey: "currentBoard")
        let boardTemp = userDefaults.integer(forKey: "order")
        if boardTemp == 1 {
            currentBoard = 0 // reset the player decided to start from board 1
        }
        if currentBoard >= boards.count || currentBoard < 0 {
            currentBoard = 0
        }
        
        physicsWorld.gravity = CGVector(dx: 0, dy: -0.0)
        physicsWorld.contactDelegate = self
        let r = CGRect(x: 0, y: -20, width: self.frame.width, height: self.frame.height + 20)
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: r)
        
        setSizes()
        addBoardElements()
        
        skinNumber = userDefaults.integer(forKey: "skin")
        if skinNumber < 0 || skinNumber > skin.count {
            skinNumber = 0
        }
        startNewGame()
    }
    
    func startNewGame() {
        bouncesInGame  = 0
        hitsInGame  = 0
        
        lives = totalLives
        score = 0
        txtHighScore.text = "High:   " + String(highScore)
        startLevel()
    }

    func startLevel() {
        
        txtBoard.text  = "Board: " + String(currentBoard + 1)
        bouncesInLevel = 1
        noHitBouncesInLevel += 1
        sweeperUsedInLevel = false
        hitsInLevel = 0
        lightOfferedInLevel = false
        powerUpNumberInLevel = 0
        brickCanvas.position =  CGPoint(x: 0, y: self.frame.height - topGapToBricks - topBuffer) // in case it was moved in the last level
        addBricks()
        newLife()
    }

    func levelCompleted() {
        
        cleanupEverything()
        levelCompletedBannerText.text = "Board \(currentBoard + 1) Cleared !\n\n \(hitsInLevel) Bricks\n \(bouncesInLevel) Bounces"
        levelCompletedBannerButton.title.text = "Next Board"
        levelCompletedBannerButton.draw()
        
        
        currentBoard += 1
        //  startAtBoard = currentBoard // save for next time also, this is persistent
        
        if currentBoard < boards.count {
            state = .levelCompleted
        }
        else {
            state = .allLevelsDone
            currentBoard = 0 // reset for next time.
            gameOver()
        }
        
    }
    
    func gameOver() {
        
        pauseBack.isHidden = true
        levelCompletedBanner.isHidden = false
        removeAllActivePowerUps()
        removeAllBalls()
        
        var newHighScore = false
        
        if score > highScore {
            newHighScore = true
            highScore = score
        }
        
        if state == .gameOver {
            if newHighScore {
                levelCompletedBannerText.text = "Game Over. \n\n New High Score !!! "
                levelCompletedBanner.fillColor = .yellow
                levelCompletedBannerText.fontColor = .black
            }
            else {
                levelCompletedBannerText.text = "Game Over.\nThat was the last life !!\n"
                levelCompletedBanner.fillColor = .purple
                levelCompletedBannerText.fontColor = .white
            }
        }
        
        else if state == .allLevelsDone {
            if newHighScore {
                levelCompletedBannerText.text = "All Boards Completed !!\n\n New High Score !!! "
                levelCompletedBanner.fillColor = .yellow
                levelCompletedBannerText.fontColor = .black
            }
            else {
                levelCompletedBannerText.text = "All Boards Completed !!\n"
                levelCompletedBanner.fillColor = .purple
                levelCompletedBannerText.fontColor = .white
            }
        }
        levelCompletedBannerButton.title.text = "Home"
        levelCompletedBannerButton.draw()
    }

    func cleanupEverything() {
        
        deactivateAllActivePowerUps()
        removeAllActivePowerUps()
        brickHitsSinceLastPowerup = 0
        paddleSizeChanges = 0
        
        for (i,n) in balls.enumerated().reversed() {    // Not really needed. Logic ensures we only come here when all balls are exhausted, but just a fail-safe
            n.sprite.removeFromParent()
            balls.remove(at: i)
        }
    }

    func newLife() {
        
        cleanupEverything()
        state = .newLife
        
        addBall()
        balls[0].sprite.physicsBody?.velocity  =  CGVector(dx : 0, dy : 0)
        balls[0].sprite.run(SKAction.move(to:  CGPoint(x: paddle.position.x , y: paddle.size.height + paddle.position.y + 5  )   , duration: 0) )
        balls[0].sprite.isHidden = false
        balls[0].isSticky = true
    }
    
    func setBallDxFromPositionOnPaddle ( _ ballNumber : Int) {
        
        var hitPosition = balls[ballNumber].sprite.position.x - paddle.position.x
        hitPosition = hitPosition / paddle.size.width * 2
        balls[ballNumber].sprite.physicsBody?.velocity.dx = hitPosition * 500 + 100
    }
    
    func startBallMovement( ballNumber : Int = 0) {
        
        let delay = SKAction.wait(forDuration: 5.0)
        
        setBallDxFromPositionOnPaddle(ballNumber)
        setBallDyFromDx(ballNumber: ballNumber)
        balls[ballNumber].isSticky = false
        
        balls[ballNumber].sprite.run(delay)
        
    }

    func startMultiBall(numberOfBalls : Int = 1) {
        for _ in 0..<numberOfBalls {
            addBall()
            let x = CGFloat.random(in: CGFloat(50)..<(self.frame.width - 50) )
            let y = CGFloat.random(in: (paddle.position.y + 10)..<(paddle.position.y + 100)    )
            
            balls.last?.sprite.run(SKAction.move(to:  CGPoint(x: x , y: y)   , duration: 0) )
            startBallMovement(ballNumber: balls.count - 1) // i.e. the last ball we added, get it moving
        }
    }

    func endMultiBall() {
        for (i,_) in balls.enumerated().reversed() {
            if i == 0 {break}
            balls[i].sprite.removeFromParent()
            balls.remove(at: i)
        }
    }
    

    func bombAllBricks() {
        
        // powerup which removes all balls, basically a bomb to finish level, typically will appear at the end of a level
        
        for n in wallSprites {
            
            let a0 = [SKAction.rotate(byAngle: 10, duration: 1.0), SKAction.scale(to: 0, duration: 1.0)]
            let a00 = SKAction.group(a0)
            
            //      let a1 = [SKAction.scale(by: 2.5, duration: 0.1),SKAction.scale(by: 0.0, duration: 1.0), SKAction.fadeOut(withDuration: 0.5), SKAction.removeFromParent() ]
            
            let a1 = [SKAction.scale(by: 2.5, duration: 0.1), a00 , SKAction.removeFromParent() ]
            
            
            let b = SKAction.sequence(a1)
            n.sprite.run(b)
            
        }
        removeAllBalls()
        removeAllActivePowerUps()
        
        
        // let xx = Timer(timeInterval: 5000, repeats: false, block: {_ in self.wallSprites.removeAll(); self.levelCompleted()})
        
        //    Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: {_ in self.wallSprites.removeAll(); self.levelCompleted()} )
        
        print ("About to")
        _ = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(gameScene.test),
                                 userInfo: nil, repeats: false)
        
    }
    
    @objc func test() {
        
        wallSprites.removeAll()
        levelCompleted()
        
    }
    
    //--------------------------------------------------------------------------------------
    func startFireBall() {
        fireBallOn = true
        for (i,_) in balls.enumerated() {
            balls[i].sprite.physicsBody?.collisionBitMask = PhysicsCategory.Paddle |  PhysicsCategory.Bottom
            balls[i].sprite.texture = SKTexture(imageNamed: "fireBall")
        }
        
        
    }

    func endFireBall() {
        fireBallOn = false
        for (i,_) in balls.enumerated() {
            balls[i].sprite.physicsBody?.collisionBitMask = PhysicsCategory.Paddle |  PhysicsCategory.Bottom | PhysicsCategory.Brick
            balls[i].sprite.texture = SKTexture(imageNamed: "redBall")
        }
    }

    func addPowerUpNode(ofType: PowerUpTypes, at : CGPoint ) {

        var a = SKAction.rotate(byAngle: 1, duration: 1)
        brickCanvas.run(a)

        
        brickHitsSinceLastPowerup = 0
        
        powerUps.append(PowerUp(sprite: SKSpriteNode(imageNamed: "pu_extralife")  , type:  ofType ))
        
        var imageToUse : String
        imageToUse = ofType.image
        
        powerUps.last?.sprite.size.width = sizePowerUp
        powerUps.last?.sprite.size.height = sizePowerUp
        powerUps.last?.sprite.zPosition = ZLevels.gamePowerups
        powerUps.last?.sprite.texture = SKTexture(imageNamed: imageToUse)
        powerUps.last?.sprite.position = at
        powerUps.last?.sprite.physicsBody = SKPhysicsBody(rectangleOf: powerUps.last!.sprite.size)
        powerUps.last?.sprite.physicsBody?.angularDamping = 0.0
        powerUps.last?.sprite.physicsBody?.linearDamping = 0.0
        powerUps.last?.sprite.physicsBody?.isDynamic = true
        powerUps.last?.sprite.physicsBody?.categoryBitMask = PhysicsCategory.PowerUp
        powerUps.last?.sprite.physicsBody?.contactTestBitMask = PhysicsCategory.Paddle | PhysicsCategory.Bottom
        powerUps.last?.sprite.physicsBody?.collisionBitMask = PhysicsCategory.Paddle | PhysicsCategory.Bottom
        powerUps.last?.sprite.physicsBody?.velocity.dx = 0.0
        powerUps.last?.sprite.physicsBody?.velocity.dy = -ballVelocity * 0.65 //  -abs((balls[0].sprite.physicsBody?.velocity.dy)!) //   -150.0 // -ballVelocity * 0.35 //  -140.0
        self.addChild((powerUps.last?.sprite)!)
        powerUps.last?.sprite.physicsBody?.friction = 0
        powerUpNumberInLevel += 1
    }

    func addBricks() {
        for i in wallSprites {
            i.sprite.removeFromParent()
        }
        wallSprites.removeAll()
        
        var xPos : CGFloat =  sizeBrick.width / 2
        var yPos : CGFloat = 0 // self.frame.height - topGapToBricks - topBuffer
        for m in 0..<brickRows {
            for n in 0..<brickCols {
                if boards[currentBoard].board[m][n] != 0 {  // zero means blank
                    var brickImage : Int = boards[currentBoard].board[m][n]
                    
                    if brickImage == -1 {
                        brickImage = Int.random(in: 0..<17)  // all but invisible
                    }
                    else if brickImage == -2 {
                        brickImage = Int.random(in: 0..<15)  // all but invisible and multi-hits
                    }
                    else {
                        brickImage -= 1 // to index back into the bricks array which starts at zero. The representation starts at 1 as 0 means blank
                    }
                    
                    
                    wallSprites.append(Wall(sprite: SKSpriteNode(imageNamed: brickTypes[brickImage].img[0] ), hitsTaken: 0, brickType : brickImage))
                    wallSprites.last?.sprite.size.width = sizeBrick.width
                    wallSprites.last?.sprite.size.height = sizeBrick.height
                    wallSprites.last?.sprite.zPosition = ZLevels.gameBricks
                    wallSprites.last?.sprite.position.x = xPos
                    wallSprites.last?.sprite.position.y = yPos
                    wallSprites.last?.sprite.physicsBody = SKPhysicsBody(rectangleOf: wallSprites.last!.sprite.size)
                    wallSprites.last?.sprite.physicsBody?.isDynamic = false
                    wallSprites.last?.sprite.physicsBody?.categoryBitMask = PhysicsCategory.Brick
                    wallSprites.last?.sprite.physicsBody?.contactTestBitMask = PhysicsCategory.Ball
                    brickCanvas.addChild(wallSprites.last!.sprite)
                }
                xPos += sizeBrick.width + 1
            }
            yPos -= sizeBrick.height + 2
            xPos = sizeBrick.width / 2
        }
    }

    func addBall() {
        //    let  temp = SKSpriteNode(imageNamed: "redCircle")
        
        balls.append(Balls(sprite: SKSpriteNode(imageNamed: "redCircle"), isSticky: true))
        
        balls.last?.sprite.position.x = 0
        balls.last?.sprite.position.y = -50 // off-screen till positioned
        balls.last?.sprite.zPosition  = ZLevels.gameBalls
        balls.last?.sprite.size.width = sizeBall
        balls.last?.sprite.size.height = sizeBall
        balls.last?.sprite.physicsBody = SKPhysicsBody(circleOfRadius: sizeBall / 2)
        balls.last?.sprite.physicsBody?.friction = 0
        balls.last?.sprite.physicsBody?.restitution = 1.0
        balls.last?.sprite.physicsBody?.angularDamping = 0.0
        balls.last?.sprite.physicsBody?.linearDamping = 0.0
        balls.last?.sprite.physicsBody?.allowsRotation = false
        balls.last?.sprite.physicsBody?.categoryBitMask = PhysicsCategory.Ball
        balls.last?.sprite.physicsBody?.collisionBitMask = PhysicsCategory.Paddle | PhysicsCategory.Brick | PhysicsCategory.Bottom
        
        self.addChild((balls.last?.sprite)!)
        //    balls.append(Balls ( sprite: temp, isSticky: true))

    }

    func didBegin(_ contact: SKPhysicsContact) {
        guard state == .playing  else {
            return
        }
        
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        }
        else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if (firstBody.node as? SKSpriteNode) != nil  {
            if (secondBody.node as? SKSpriteNode) != nil {
                
                if ((firstBody.categoryBitMask & PhysicsCategory.Paddle != 0) && (secondBody.categoryBitMask & PhysicsCategory.Ball != 0)) {
                    
                    print ("Paddle Hit Ball")
                    
                    paddleHitBall(ball: secondBody.node as! SKSpriteNode)
                }
                else if (firstBody.categoryBitMask & PhysicsCategory.Ball != 0) && (secondBody.categoryBitMask & PhysicsCategory.Bottom != 0) {
                    print ("Ball Hit Bottom")
                    ballHitBottom(ball: firstBody.node as! SKSpriteNode)
                }
                else if (firstBody.categoryBitMask & PhysicsCategory.Ball != 0) && (secondBody.categoryBitMask & PhysicsCategory.Brick != 0) {
                    print ("Ball Hit Brick")
                    ballHitBrick(bricktoBeRemoved: secondBody.node as! SKSpriteNode)
                }
                else if (firstBody.categoryBitMask & PhysicsCategory.Paddle != 0) && (secondBody.categoryBitMask & PhysicsCategory.PowerUp != 0) {
                    print ("PowerUp caught")
                    paddleHitPowerup(sprite: secondBody.node as! SKSpriteNode )
                }
                else if (firstBody.categoryBitMask & PhysicsCategory.Bottom != 0) && (secondBody.categoryBitMask & PhysicsCategory.PowerUp != 0) {
                    print ("PowerUp hit bottom")
                    removeOnePowerUp(sprite: secondBody.node as! SKSpriteNode )
                }
            }
        }
    }
    

    func paddleHitBall(ball : SKSpriteNode) {
        
        // to prevent ball  from brushig along underside of paddle as it passese by and getting stuck under the paddle
        guard ball.position.y > paddle.position.y else {
            return
        }
        
        // The sweeper powerup is the only we can call when ball hits paddle - all others are called when ball hits brick
        // because the sweeper is called ONLY player is FAILING to hit a brick for a long time
        if !sweeperUsedInLevel && wallSprites.count < 5 && noHitBouncesInLevel > 10 {
            
            if noHitBouncesInLevel > 30 ||
               noHitBouncesInLevel > 20 && Int.random(in: 0..<10) < 8 ||
               Int.random(in: 0..<10) < 5
            {
                addPowerUpNode(ofType: .sweepAllBricks, at: CGPoint(x: CGFloat.random(in: 30..<(self.frame.width - 30)),
                                                                    y: self.frame.height - 10))
                sweeperUsedInLevel.toggle()
            }
        }

        playSound(type: .paddleHit)
        bouncesInLevel += 1
        bouncesInGame += 1
        
        if balls.count == 1 {    // Dont count if multiball is in play
            noHitBouncesInLevel += 1
        }
        
        var ballNumber = 0
        for (i,n) in balls.enumerated() {
            if n.sprite  == ball {
                ballNumber = i
                break
            }
        }
        
        setBallDxFromPositionOnPaddle(ballNumber)
        
        if stickyPaddleOn {
            stickyPaddleUsed += 1
            if stickyPaddleUsed > stickyPaddleMaxUsed {
                stickyPaddleOn = false
                stickyPaddleUsed = 0
                setBallDyFromDx(ballNumber: ballNumber)
            }
            else {
                balls[ballNumber].sprite.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                balls[ballNumber].isSticky = true
            }
        }
        else {
            setBallDyFromDx(ballNumber: ballNumber)
        }
        
        // if lights are out, possibly give a light
        
        if lightsOutOn {
            bouncesSinceLightOut += 1
        }
    }

    func scoring()  {
        
        switch gameSpeed {
        
        case .slow:
            score += 1
        case .medium:
            score += 3
        case .fast:
            score += 5
            
        }
    }

    func ballHitBrick(bricktoBeRemoved : SKSpriteNode) {

        brickHitsSinceLastPowerup += 1
        hitsInLevel += 1
        hitsInGame += 1
        noHitBouncesInLevel = 0 // reset it, as this counting how many paddle bounces has it been since last brick was hit

        playSound(type: .brickHit)
        var hitPosition = bricktoBeRemoved.position
        hitPosition.y += brickCanvas.position.y
        
        for (i,_) in wallSprites.enumerated() {
            if wallSprites[i].sprite == bricktoBeRemoved {
                wallSprites[i].hitsTaken += 1
                if wallSprites[i].hitsTaken >=    (brickTypes[wallSprites[i].brickType].img).count   {
                    scoring()
                    let a = [SKAction.fadeOut(withDuration: 0.2), SKAction.removeFromParent() ]
                    let b = SKAction.sequence(a)
                    wallSprites[i].sprite.run(b)
                    wallSprites.remove(at: i)
                }
                else {
                    // change the image to reflect that a hit has happened
                    wallSprites[i].sprite.texture = SKTexture(imageNamed: brickTypes[wallSprites[i].brickType].img[wallSprites[i].hitsTaken]  )
                    nudgeBricks()
                }
                break
            }
        }
        
        if wallSprites.count ==  0 {
            levelCompleted()
        }
        else  {                           // still going on current level, see if a powerup is unlocked
            addPowerUp(at: hitPosition)
        }
    }

    func addPowerUp( at : CGPoint) {
        
        guard  powerUps.count < 2 && brickHitsSinceLastPowerup > 5  else {
            print("____ Too soon for powerup after  - returning from Guard")
            return
        }
        
        if lightsOutOn == true && lightOfferedInLevel == false && bouncesSinceLightOut > 5 &&  Int.random(in: 0..<10) == 0  {
            addPowerUpNode(ofType: .lightsOn, at: at)
            lightOfferedInLevel = true
        }
        else if hitsInGame % 300  == 0 && hitsInGame > 0 {   // so we get an extra life every 300 BRICKS HITS.
            addPowerUpNode(ofType: .extraLife, at : at)
        }
        else {
            print("____ OK. Lets try to add a powerup")

            if Int.random(in: 0..<10) > 4 {    // overall probablity of giving a powerup. Once this is OK, we WILL select a powerup
                
                var powerUpApplied = false
                var timesPowerUpRejected = 0
                
                repeat {
                    let powerUpIndex = Int.random(in: 0..<powerUpProbabilityMatrix.count)  // Lets try this one
                    let powerUpSelected = powerUpProbabilityMatrix[powerUpIndex].0

                    if  ( powerUpSelected == .stickyPaddle && stickyPaddleOn == true ) ||
                        ( powerUpSelected == .fireBall && fireBallOn == true ) ||
                        ( powerUpSelected == .lightsOut && lightsOutOn == true )  ||
                        ( powerUpSelected == .paddleLonger && paddleSizeChanges >= 2 )  ||
                        ( powerUpSelected == .paddleShorter && paddleSizeChanges <= -2 )   ||
                        ( powerUpSelected == .multiBall && balls.count > 6 )
                        {
                         // Don't add this poweron, it is already in operation.
                        timesPowerUpRejected += 1 // keep track of rejections, if too many we leave and dont add powerup anywa
                        print("____ Powerup was selected, but rejected due to pre-condition")

                        }
                    else {   // we still have to select the powerup according to its own probablity of appearance
                        print("____ No precondition, lets do this")

                        if ( Int.random(in: 0..<100) < powerUpProbabilityMatrix[powerUpIndex].1  ) {
                            addPowerUpNode(ofType: powerUpSelected, at: at)
                            powerUpApplied = true
                            print("____ YESSSS. Bloody finally got a powerup !", powerUpSelected)

                        }
                        else {
                            print("____ Nope. Missed it on the probability of this powerup")

                        }
                    }
                } while powerUpApplied == false || timesPowerUpRejected > 30 // keep trying until we find one
                
            }
        }
    }
    
    func ballHitBottom(ball : SKSpriteNode) {
        
        for (i,n) in balls.enumerated().reversed() {
            if n.sprite == ball {
                balls[i].sprite.removeFromParent()
                balls.remove(at: i)
                break
            }
        }
        
        if balls.count == 0   {            // if this was the last ball, reduce a life and see if we need to game over or reposition for another try
            lives = lives - 1
            //    playSound(sound: ballFalling)
            playSound(type: .lifeLost)
            
            if lives <= 0 {
                state = .gameOver
                gameOver()
            }
            else {
                announceIt(String (String (lives) + (lives > 1 ? " Lives " : " Life ") + "left"), holdTime: 0.3  )
                newLife()
            }
        }
    }

    func removeOnePowerUp(sprite : SKSpriteNode) {
        print("Removing one powerup which hit bottome")
        
        for (i, _) in powerUps.enumerated() {
            if powerUps[i].sprite == sprite  {
                powerUps[i].sprite.removeFromParent()
                powerUps.remove(at: i)
                break
            }
        }
    }

    func paddleHitPowerup(sprite : SKSpriteNode) {
        // first get the PowerUpNumber from the sprite
        var powerUpNum : Int = 0
        for (i,_) in powerUps.enumerated() {
            if powerUps[i].sprite == sprite  {
                powerUpNum = i
                break
            }
        }
        // Then act on it
        
        let xx = powerUps[powerUpNum].type
        switch  xx {
        case .paddleLonger:
            paddle.run(SKAction.scaleX(by: 1.3 , y: 1.0, duration: 0.5))
            paddleSizeChanges += 1
            announceIt( xx.announceText)
            
        case .paddleShorter:
            paddle.run(SKAction.scaleX(by: 0.7 , y: 1.0, duration: 0.5))
            announceIt( xx.announceText)
            paddleSizeChanges -= 1
            
        case .extraLife:
            lives += 1
            announceIt( xx.announceText)
            
        case .stickyPaddle:
            stickyPaddleOn = true
            announceIt( xx.announceText)
            
            
        case .multiBall:
            startMultiBall(numberOfBalls: 5)
            announceIt( xx.announceText)
            
        case .fireBall:
            startFireBall()
            announceIt( xx.announceText)
            
        case .sweepAllBricks:
            announceIt(xx.announceText, holdTime: 2.0)
            bombAllBricks()
            
        case .lightsOut:
            announceIt( xx.announceText)
            brickCanvas.run(SKAction.fadeOut(withDuration: 1))
            lightsOutOn = true
            
            
        case .lightsOn:
            announceIt( xx.announceText)
            brickCanvas.run(SKAction.fadeIn(withDuration: 1))
            bouncesSinceLightOut = 0
            
        }
        // All done, now also remove it, it has been processed
        removeOnePowerUp(sprite: sprite)
    }
    
    func deactivateAllActivePowerUps() {
        print("Removing all powerups, becuse level ended")
        // This would reset all powerups currently in play
        
        // return paddle to normal size
        paddle.run(SKAction.scaleX(to: 1, y: 1, duration: 0.3))
        
        stickyPaddleOn = false
        stickyPaddleUsed = 0
        
        endMultiBall()
        endFireBall()
        
        brickCanvas.alpha = 1
        lightsOutOn = false
        bouncesSinceLightOut = 0
        
    }

    func removeAllActivePowerUps() {
        
        for (i, _) in powerUps.enumerated().reversed() {
            powerUps[i].sprite.removeFromParent()
            powerUps.remove(at: i)
        }
    }

    func removeAllBalls() {
        for (i, _) in balls.enumerated().reversed() {
            balls[i].sprite.removeFromParent()
            balls.remove(at: i)
        }
        
    }

    override func update(_ currentTime: TimeInterval) {
        
        let dxLimit = ballVelocity * 0.61                            // x-velocity should not be more than 60% of velocity vector. Or the ball becomes almost horizontal and takea too long to reach ground
        for (i,n) in balls.enumerated() {
            if (n.sprite.physicsBody?.velocity.dx)! > dxLimit  {
                n.sprite.physicsBody?.velocity.dx = dxLimit - 5        // the -5 is to take care of rounding. Otherwise it goes into next check and next..etc in edge cases
                print("Speed contrupdateol")
                setBallDyFromDx(ballNumber: i)
            }
            else if (n.sprite.physicsBody?.velocity.dx)! < -(dxLimit) {
                n.sprite.physicsBody?.velocity.dx = -(dxLimit  - 5)
                print("negative Speed control")
                setBallDyFromDx(ballNumber: i)
            }
        }
        
        // Update background scrollers
        
        scrollBack.scroll()
        
        //-----------------------------------------------
        // prevent ball from getting pushed off screen. There is a frame around screen, but sometimes paddle pushes balls thru the frame
        for (_,n) in balls.enumerated() {
            if n.sprite.position.x < 0 {
                n.sprite.position.x = 0
            }
            else if n.sprite.position.x > self.frame.width {
                n.sprite.position.x = self.frame.width
            }
        }
        
        //------------------------------------------------
        if paddle.position.x < 0 {
            paddle.position.x = 0
        }
        else  if paddle.position.x > self.frame.width {
            paddle.position.x = self.frame.width
            //    paddle.position.x = paddle.position.x
            
        }
    }
    
    //----------------------------------------------------------------------------
    
    func nudgeBricks() {

        let d = Double.random(in: 0.03...0.06)
        
        var r = CGFloat.random(in: 2...4)
        r = Int.random(in: 0...1) == 0 ?   r   :   -r   // on a 50/50 chance, change its sign

        
        // The four movement types. When using them in SKAction, remember that all x movements must add to zero, and all y movements must add to zero. This will ensure that the bricks end up back at the original positions after the nudge.
        let a1 = SKAction.moveBy(x: r, y: -r, duration: d)
        let a2 = SKAction.moveBy(x: -r, y: -r, duration: d)
        let a3 = SKAction.moveBy(x: r, y: r, duration: d)
        let a4 = SKAction.moveBy(x: -r, y: r, duration: d)
        
        brickCanvas.run(SKAction.sequence([a1,a2,a3,a2,a3,a4]))
        
    }
    

    func setBallDyFromDx( ballNumber : Int = 0)  {
        
        let dx = Double((balls[ballNumber].sprite.physicsBody?.velocity.dx)!)
        var dy : Double  =   pow(Double(ballVelocity), 2.0) -    pow(Double(dx), 2.0)
        dy = dy.squareRoot()
        
        balls[ballNumber].sprite.physicsBody?.velocity.dy = CGFloat(dy)
    }

    
    func exitToMainMenu() {
        
        boards.removeAll()
        print ("About to exit")
        self.view?.presentScene(menuMain(size: self.size), transition: SKTransition.doorsOpenVertical(withDuration: 0.6))
        print ("exit completed")
        
    }
    

    func addBoardElements() {
        
        let rect = CGRect(x: -levelCompleteBannerSize.width / 2, y: -levelCompleteBannerSize.height / 2,
                          width: levelCompleteBannerSize.width, height: levelCompleteBannerSize.height)
        let pa = CGMutablePath()
        pa.addRoundedRect(in: rect, cornerWidth: 20, cornerHeight: 20)
        levelCompletedBanner.path = pa
        levelCompletedBanner.fillColor = .purple
        levelCompletedBanner.position = CGPoint(x: self.frame.width / 2, y: self.frame.height / 2)
        levelCompletedBanner.zPosition = ZLevels.levelCompleteBanner
        self.addChild(levelCompletedBanner)
        
        levelCompletedBannerButton.position = CGPoint(x: 0, y: -rect.size.height / 2 + 80)
        levelCompletedBannerButton.size = CGSize(width: 140,height: 60)
        levelCompletedBannerButton.btn.fillColor = .red
        levelCompletedBannerButton.btn.strokeColor = .red
        levelCompletedBannerButton.title.fontSize  = 20
        levelCompletedBannerButton.title.fontColor  = .white
        levelCompletedBannerButton.title.fontName = masterFont
        levelCompletedBannerButton.draw()
        levelCompletedBanner.addChild(levelCompletedBannerButton)
        
        levelCompletedBannerText.position = CGPoint(x: 0, y: rect.size.height / 2 - 80)
        levelCompletedBannerText.horizontalAlignmentMode = .center
        levelCompletedBannerText.verticalAlignmentMode = .center
        levelCompletedBannerText.fontName = masterFont
        levelCompletedBannerText.fontSize = 20
        levelCompletedBannerText.fontColor = .white
        levelCompletedBannerText.numberOfLines = 0
        levelCompletedBanner.addChild(levelCompletedBannerText)

        
        brickCanvas.size.width = self.frame.width
        brickCanvas.color = .red
        brickCanvas.size.height = ( sizeBrick.height + 1 ) * CGFloat(brickRows)
        brickCanvas.position = CGPoint(x: 0, y: self.frame.height - topGapToBricks - topBuffer)
        brickCanvas.zPosition = ZLevels.gameBricksCanvas
        brickCanvas.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.addChild(brickCanvas)

        scrollBack.texture = SKTexture(imageNamed: "backStarField")
        scrollBack.size = (scrollBack.texture?.size())!
        scrollBack.zPosition = ZLevels.gameBoard
        scrollBack.anchorPoint = CGPoint(x: 0, y: 0)
        scrollBack.texture = SKTexture(imageNamed: "backStarField")
        scrollBack.direction = .right
        scrollBack.scrollSpeed = 2
        self.addChild(scrollBack)
        scrollBack.setup()
        
        pauseBack.texture = SKTexture(imageNamed:  "pauseBack" )
        pauseBack.size.height = self.frame.height / 2
        pauseBack.size.width = self.frame.width
        pauseBack.anchorPoint = CGPoint(x: 0, y: 0)
        pauseBack.zPosition =  ZLevels.PauseBack
        pauseBack.position = CGPoint(x: 0, y: 0  )
        self.addChild(pauseBack)
        
        
        btnPause.texture = SKTexture(imageNamed: "btnPause")
        btnPause.size = CGSize(width: buttonSize / 3, height: buttonSize / 3)
        btnPause.position = CGPoint(x: self.frame.width / 2, y: self.frame.height - topBuffer - 20.0)
        btnPause.zPosition = ZLevels.textAnnounce
        self.addChild(btnPause)
        
        btnPlay.texture = SKTexture(imageNamed: "btnPlay")
        btnPlay.size = CGSize(width: buttonSize, height: buttonSize)
        btnPlay.position = CGPoint(x: self.frame.width / 2, y: buttonRowHeight)
        pauseBack.addChild(btnPlay)
        
        btnHome.texture = SKTexture(imageNamed: "btnHome")
        btnHome.size = CGSize(width: buttonSize, height: buttonSize)
        btnHome.position = CGPoint(x: btnPlay.position.x - buttonSize - 20 , y: buttonRowHeight)
        pauseBack.addChild(btnHome)
        
        
        btnBacks.texture = SKTexture(imageNamed: "btnBacks")
        btnBacks.size = CGSize(width: buttonSize, height: buttonSize)
        btnBacks.position = CGPoint(x: btnPlay.position.x + buttonSize + 20, y: buttonRowHeight)
        pauseBack.addChild(btnBacks)
        
        txtScore = SKLabelNode(text: "Score: ")
        txtScore.horizontalAlignmentMode = .left
        txtScore.verticalAlignmentMode = .center
        txtScore.fontName = defaultFont
        txtScore.fontSize = fontSizeForLabels
        txtScore.fontColor =  .white //  SKColor(red: 0, green: 0, blue: 0, alpha: 1)
        txtScore.position = CGPoint(x: 10 , y:self.frame.height - fontSizeForLabels  - topBuffer )
        txtScore.setScale(1.0)
        txtScore.alpha  = 1.0
        txtScore.zPosition = 1000 // ZLevels.topMenuElements
        self.addChild(txtScore)

        txtHighScore = SKLabelNode(text: "Hi : ")
        txtHighScore.horizontalAlignmentMode = .left
        txtHighScore.verticalAlignmentMode = .center
        txtHighScore.fontName = defaultFont
        txtHighScore.fontSize = fontSizeForLabels
        txtHighScore.fontColor =  SKColor.white //  SKColor(red: 0, green: 0, blue: 0, alpha: 1)
        txtHighScore.position = CGPoint(x: 10 , y:self.frame.height - fontSizeForLabels*2  - topBuffer )
        txtHighScore.setScale(1.0)
        txtHighScore.alpha  = 1.0
        txtHighScore.zPosition = 1000 // ZLevels.topMenuElements
        self.addChild(txtHighScore)

        txtCountDown = SKLabelNode(text: " 3 ")
        txtCountDown.horizontalAlignmentMode = .center
        txtCountDown.verticalAlignmentMode = .center
        txtCountDown.fontName = "Futura-CondensedExtraBold"
        txtCountDown.fontSize = 60;
        txtCountDown.fontColor =  SKColor.white //  SKColor(red: 0, green: 0, blue: 0, alpha: 1)
        txtCountDown.position = CGPoint(x: self.frame.width / 2 , y: 250 )
        txtCountDown.setScale(1.0)
        txtCountDown.alpha  = 1.0
        txtCountDown.zPosition = 1000 // ZLevels.topMenuElements
        txtCountDown.isHidden = true
        self.addChild(txtCountDown)

        txtLives = SKLabelNode(text: "Balls: ")
        txtLives.horizontalAlignmentMode = .right
        txtLives.verticalAlignmentMode = .center
        txtLives.fontName = defaultFont
        txtLives.fontSize = fontSizeForLabels
        txtLives.fontColor =  SKColor.white //  SKColor(red: 0, green: 0, blue: 0, alpha: 1)
        txtLives.position = CGPoint(x: self.frame.width - 10 , y:self.frame.height - fontSizeForLabels * 2  - topBuffer )
        txtLives.setScale(1.0)
        txtLives.alpha  = 1.0
        txtLives.zPosition = 1000 // ZLevels.topMenuElements
        self.addChild(txtLives)
        
        txtBoard = SKLabelNode(text: "Board: ")
        txtBoard.horizontalAlignmentMode = .right
        txtBoard.verticalAlignmentMode = .center
        txtBoard.fontName = defaultFont
        txtBoard.fontSize = fontSizeForLabels
        txtBoard.fontColor =  .white //  SKColor(red: 0, green: 0, blue: 0, alpha: 1)
        txtBoard.position = CGPoint(x: self.frame.width - 10 , y:self.frame.height - fontSizeForLabels  - topBuffer )
        txtBoard.setScale(1.0)
        txtBoard.zPosition = 1000 // ZLevels.topMenuElements
        self.addChild(txtBoard)

        announceTextBack.alpha = 0.0
        announceTextBack.zPosition = ZLevels.textAnnounce
        announceTextBack.texture = SKTexture(imageNamed: "brickRed")
        announceTextBack.size = CGSize(width: self.frame.width *  2 / 3, height: 0)
        announceTextBack.position = CGPoint(x: self.frame.width / 2  , y: 250.0)
        self.addChild(announceTextBack)
        
        announceText.horizontalAlignmentMode =  SKLabelHorizontalAlignmentMode.center
        announceText.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
        announceText.fontName = defaultFont
        announceText.fontSize = 30;
        announceText.fontColor = SKColor.white
        announceText.position =  CGPoint(x: 0,y: 0)
        announceText.setScale(1.0)
        announceTextBack.addChild(announceText)

        var e = [SKTexture()]
        e.removeAll() // creating the variable causes a blank to be appended - which has to be removed immediately. prob cleaner this way
        for s in paddleImages[0] {
            e.append(SKTexture(imageNamed: s))
        }
        let r = SKAction.animate(with: e, timePerFrame: 1)
        let r2 = SKAction.repeatForever(r)
        paddle.run(r2)

        paddle.position.y = bottomBuffer + bottomToPaddle
        paddle.position.x = 100
        paddle.zPosition = ZLevels.gamePaddle
        paddle.size = sizePaddle
        paddle.physicsBody = SKPhysicsBody(rectangleOf: paddle.size)
        paddle.physicsBody?.allowsRotation = false
        paddle.physicsBody?.isDynamic = false
        paddle.physicsBody?.categoryBitMask = PhysicsCategory.Paddle
        paddle.physicsBody?.contactTestBitMask = PhysicsCategory.Ball
        self.addChild(paddle)

        let bottomRect = CGRect(x: frame.origin.x, y: bottomBuffer  , width: frame.size.width, height: 1)
        bottomBorder.physicsBody = SKPhysicsBody(edgeLoopFrom: bottomRect)
        bottomBorder.physicsBody?.categoryBitMask = PhysicsCategory.Bottom
        bottomBorder.physicsBody?.contactTestBitMask = PhysicsCategory.Ball
        addChild(bottomBorder)
        
        
    }
    
    // -----------------------------------------------------------------------------------
    func playSound(type: SoundType) {
        
        guard sounds == true else {
            return
        }
        
        switch type {
        
        case .brickHit:
            self.run(SKAction.playSoundFileNamed("ballSound1.wav", waitForCompletion: false))
            
        case .paddleHit:
            self.run(SKAction.playSoundFileNamed("ballSound2.wav", waitForCompletion: false))
            
        case .lifeLost:
            self.run(SKAction.playSoundFileNamed("ballSound3.wav", waitForCompletion: false))
        }
        
    }
    //---------------------------------------------------------------------------------------------------------------------------
    func announceIt (_ s : String, holdTime : Double = 0.8) {
        let a = SKAction.sequence([SKAction.fadeAlpha(to: 1, duration: 0.3), SKAction.wait(forDuration: holdTime), SKAction.fadeAlpha(to: 0, duration: 0.5)])
        announceText.text = s
        announceTextBack.run(a)
    }
    
    //------------------------------------------------------------------------------------
    func togglePause() {
        
        if state == .paused {
            // state = stateBeforePause
            
            let wait = SKAction.wait(forDuration: 1)
            
            let a1 = SKAction.run {self.txtCountDown.isHidden = false}
            let c3 = SKAction.run {self.txtCountDown.text = "2"}
            let c2 = SKAction.run {self.txtCountDown.text = "1"}
            //      let c1 = SKAction.run {self.txtCountDown.text = "1"}
            let a2 = SKAction.run {self.txtCountDown.isHidden = true}
            
            
            
            let seq = SKAction.sequence([a1, c3, wait, c2, wait, a2])
            self.run(seq, completion : {self.physicsWorld.speed = 1; self.state = self.stateBeforePause})
            
            
            //      physicsWorld.speed = 1
        }
        else {
            if state == .playing || state == .newLife {
                stateBeforePause = state
                state = .paused
                physicsWorld.speed = 0
            }
        }
        
    }
    
    
    
    func paddlePositionChange( paddleMovementDelta : CGFloat) {

        for (_,n) in balls.enumerated() {            // move any balls sticking to the paddle by the same amount
            if n.isSticky {
                //        n.sprite.position.x = paddle.position.x
                n.sprite.position.x += paddleMovementDelta

            }
        }
        
    }
    
    
    
    
    
    //------------------------------------------------------------------------------------------------------------
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard state == .playing  || state == .newLife else {
            return }
        
        
        let touch = touches.first
        let touchLocation = touch!.location(in: self)
        let previousLocation = touch!.previousLocation(in: self)
        
        let paddleMovementDelta =  touchLocation.x - previousLocation.x
        paddle.position.x += paddleMovementDelta
        
        paddlePositionChange(paddleMovementDelta: paddleMovementDelta)
        
        
        //    for (_,n) in balls.enumerated() {
        //      if n.isSticky {
        ////        n.sprite.position.x += touchLocation.x - previousLocation.x
        //          n.sprite.position.x += paddleMovementDelta
        //      }
        //    }
        
        
        
    }
    //-------------------------------------------------------------------------------------------------------------
    
    //--------------------------------------
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let location = touches.first?.location(in: self)
        
        if (location!.y > self.frame.height - sizePauseTapZoneHeight) {
            togglePause()
        }
        
        
    }
    
    
    
    //------------------------------------------------------------------------------------------------------
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print ("IN tocuhes ended")
        
        let location = touches.first?.location(in: self)
        
        
        if (state == .levelCompleted || state ==  .gameOver || state == .allLevelsDone) && levelCompletedBanner.contains(location!) {
            let l2 = convert(location!, to: levelCompletedBanner)
            if levelCompletedBannerButton.contains(l2) {
                if state == .levelCompleted {
                    startLevel()
                }
                else if state ==  .gameOver || state == .allLevelsDone {
                    exitToMainMenu()
                }
            }
        }
        
        else if state == .newLife {
            print ("state was newLife")
            state = .playing
            startBallMovement()
        }
        
        else  if btnHome.contains(location!)  && ( state == .paused || state == .gameOver || state == .allLevelsDone     )  {
            exitToMainMenu()
        }
        
        else  if btnBacks.contains(location!)  && ( state == .paused || state == .gameOver || state == .allLevelsDone     )  {
            skinNumber += 1
        }
        
        else if btnPlay.contains(location!) && (state == .paused  ) {
            togglePause()
        }
        
        else if btnPlay.contains(location!) && (state == .gameOver  || state == .allLevelsDone  ) {
            startNewGame()
        }
        
        
        else if stickyPaddleOn {
            for (i,n) in balls.enumerated() {
                if n.isSticky {
                    balls[i].isSticky = false
                    startBallMovement(ballNumber: i)
                }
            }
            
        }
        
    }
    
    
    //-----------------------------------------------------------------------------------
    func loadBoards() {
        
        if let url = Bundle.main.url(forResource: "simpleBrickoutBoards", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                boards  = try decoder.decode([BoardDesign].self, from: data)
            } catch {
                print("error:\(error)")
            }
        }
        
    }
    
    
    
    
}





