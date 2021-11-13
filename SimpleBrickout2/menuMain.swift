
//
//  menuMain.swift
//  Simple Brickout
//
//  Created by Farid Ahmad on 09/07/2017.
//  Copyright © 2017 Farid Ahmad. All rights reserved.
//



import SpriteKit

//------------------------------------------------------------------------------------------------------------------------------------------
class Labels : SKLabelNode {
    override init() {
        super.init()
        self.fontName = masterFont
        self.fontSize = 18
        self.fontColor = UIColor.black
        self.verticalAlignmentMode = .center
        self.horizontalAlignmentMode = .right
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
//------------------------------------------------------------------------------------------------------------------------------------------
class Pickers : myPicker {
    override init(list: [String], defaultsTag: String, defaultSelected: Int) {
        super.init(list: list, defaultsTag: defaultsTag, defaultSelected: defaultSelected)
        size = CGSize(width: 140, height: 40)
        mTextSize = 0.5
        selectedOption.fontName = masterFont
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
//------------------------------------------------------------------------------------------------------------------------------------------
class menuMain: SKScene {
    
    var topMessageGap : CGFloat = topBuffer + 50
    var bottomMessageGap : CGFloat = bottomBuffer + 10
    var messageFontSize : CGFloat = 40

    var btnSize = CGSize(width: 140, height: 40)
    var playButtonGapFromBottom : CGFloat = 90

    var pickerSize = CGSize(width: 140, height: 40)
    var pickerTitleFontSize : CGFloat = 40
    var pickerTitleOffset : CGFloat = -80
    
    var btnPlay =   myButton(text: "Play")              // myButton(tit  "Play")
    var txtMessage = SKLabelNode()
    var txtJsi = SKLabelNode()
    var txtJsi2 = SKLabelNode()
    
    var lblSpeedPicker = Labels()
    var lblBoardPicker = Labels()
    var lblSoundPicker = Labels()
    var lblSkinPicker = Labels()
    
    var speedPicker =  myPicker( list: ["Slow", "Medium", "Fast"], defaultsTag: "speed", defaultSelected: 1)
    var boardPicker =  myPicker( list: ["Last Played", "First"], defaultsTag: "order", defaultSelected: 0)
    var soundPicker =  myPicker( list: ["Off", "On"], defaultsTag: "sound", defaultSelected: 0)
    var skinPicker =  myPicker( list: ["Stars", "White", "Beach", "Dark"], defaultsTag: "skin", defaultSelected: 0)
    
    
    
    //------------------------------------------------------------------------------------------------------------------------------------------
    
    override func didMove(to view: SKView) {
        
        setSizes()
        
        self.backgroundColor = .white
        
        txtMessage.position = CGPoint(x: self.size.width / 2, y:  bottomMessageGap)
        txtMessage.text = "For Sualeha"
        txtMessage.fontSize = messageFontSize * 0.6
        txtMessage.fontName = "Arial"
        txtMessage.fontColor = UIColor.black
        self.addChild(txtMessage)
        
        txtJsi.position = CGPoint(x: self.size.width / 2, y:  self.size.height - topMessageGap)
        txtJsi.horizontalAlignmentMode = .center
        txtJsi.verticalAlignmentMode = .top
        txtJsi.text = "jumpstartIdeas.com"
        txtJsi.numberOfLines = 2
        txtJsi.fontSize = messageFontSize
        txtJsi.fontName = "Arial"
        txtJsi.fontColor = .black
        self.addChild(txtJsi)
        
        txtJsi2.position = CGPoint(x: self.size.width / 2, y:  self.size.height - topMessageGap - messageFontSize - 3)
        txtJsi2.horizontalAlignmentMode = .center
        txtJsi2.verticalAlignmentMode = .top

        txtJsi2.text = "-Farid-"
        txtJsi2.numberOfLines = 2
        txtJsi2.fontSize = messageFontSize - 2
        txtJsi2.fontName = "Arial"
        txtJsi2.fontColor = .black
        self.addChild(txtJsi2)
        
        
        btnPlay.position = CGPoint(x: self.size.width / 2, y:  playButtonGapFromBottom)
        btnPlay.size = btnSize
        btnPlay.btn.fillColor = UIColor.red
        btnPlay.title.fontSize = 20
        btnPlay.title.fontColor = UIColor.white
        btnPlay.title.fontName = masterFont
        btnPlay.btn.strokeColor = UIColor.red
        btnPlay.draw()
        self.addChild(btnPlay)
        
        var yPos = self.frame.height * 2 / 3
        let xPos = self.size.width / 2 + 35
        
        speedPicker.position = CGPoint(x: xPos, y: yPos )
        speedPicker.size = pickerSize
        speedPicker.layout()
        self.addChild(speedPicker)
        lblSpeedPicker.position = speedPicker.position
        lblSpeedPicker.position.x += pickerTitleOffset
        lblSpeedPicker.fontSize = pickerTitleFontSize
        lblSpeedPicker.text = "Speed: "
        self.addChild(lblSpeedPicker)
        
        yPos -=  speedPicker.size.height * 1.5
        
        boardPicker.position = CGPoint(x: xPos, y: yPos )
        boardPicker.size =  pickerSize
        boardPicker.layout()
        self.addChild(boardPicker)
        lblBoardPicker.position = boardPicker.position
        lblBoardPicker.position.x += pickerTitleOffset
        lblBoardPicker.fontSize = pickerTitleFontSize

        lblBoardPicker.text = "Board : "
        self.addChild(lblBoardPicker)
        
        yPos -=  speedPicker.size.height * 3.0
        
        skinPicker.position = CGPoint(x: xPos, y: yPos )
        skinPicker.size = pickerSize
        skinPicker.layout()
        self.addChild(skinPicker)
        lblSkinPicker.position = skinPicker.position
        lblSkinPicker.position.x += pickerTitleOffset
        lblSkinPicker.fontSize = pickerTitleFontSize

        lblSkinPicker.text = "Theme: "
        self.addChild(lblSkinPicker)
        
        yPos -=  speedPicker.size.height * 1.5
        
        soundPicker.position = CGPoint(x: xPos, y: yPos )
        soundPicker.size = pickerSize
        soundPicker.layout()
        self.addChild(soundPicker)
        lblSoundPicker.position = soundPicker.position
        lblSoundPicker.position.x += pickerTitleOffset
        lblSoundPicker.fontSize = pickerTitleFontSize

        lblSoundPicker.text = "Sounds: "
        self.addChild(lblSoundPicker)
        
    }
    
    
    func setSizes() {
        
        if deviceSize == .iPad {
            topMessageGap  = topBuffer
            btnSize = CGSize(width: 140, height: 40)
            pickerSize = CGSize(width: 200, height: 60)
            
            pickerTitleFontSize  = 35
            pickerTitleOffset  = -110
            
            bottomMessageGap  = bottomBuffer
            messageFontSize  = 32
            btnSize = CGSize(width: 240, height: 80)
            playButtonGapFromBottom = 120

        }
        else {
            topMessageGap  = topBuffer
            btnSize = CGSize(width: 140, height: 40)
            pickerSize = CGSize(width: 140, height: 40)
            
            pickerTitleFontSize  = 20
            pickerTitleOffset  = -75

            bottomMessageGap  = bottomBuffer
            messageFontSize  = 20
            btnSize = CGSize(width: 140, height: 50)
            playButtonGapFromBottom = 100
            
        }
    }
    
    func launchGame() {
        
        let scene = gameScene(size: self.frame.size  )
        let  transition = SKTransition.doorsOpenVertical(withDuration: 0.6)
        self.view?.presentScene(scene, transition: transition)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let location = touches.first!.location(in: self)
        
        if btnPlay.contains(location)   {
            launchGame()
        }
        
        if speedPicker.contains(location) {
            speedPicker.handleClick(convert(location, to: speedPicker))
        }
        
        if boardPicker.contains(location) {
            boardPicker.handleClick(convert(location, to: boardPicker))
        }
        
        if soundPicker.contains(location) {
            soundPicker.handleClick(convert(location, to: soundPicker))
        }
        
        if skinPicker.contains(location) {
            skinPicker.handleClick(convert(location, to: skinPicker))
        }
        
        if txtJsi.contains(location) || txtJsi2.contains(location)   {
//            UIApplication.shared.open(URL.init(string: "http://jumpstartideas.com/apps")! , options: [:], completionHandler: nil)
            UIApplication.shared.open(URL(string: "http://jumpstartideas.com/apps")!)
        }
    }
}
