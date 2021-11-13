
//
//  myButton.swift
//  My Slider Puzzle
//
//  Created by Farid Ahmad on 11/21/15.
//  Copyright © 2015 Farid Ahmad. All rights reserved.
//

import SpriteKit

class myButton : SKSpriteNode {
  
  var btn = SKShapeNode()
  var title = SKLabelNode(text: "")
  
//-------------------------------------------------------------------------------------------------------------
  init (text : String) {
    super.init(texture: nil, color: SKColor(red: 1, green: 1, blue: 1, alpha: 0)  , size: CGSize.zero)
    self.addChild(btn)
    btn.addChild(title)
    title.text = text
    title.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
    title.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center

  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
//--------------------------------------------------------------------------------------------------------------
  func draw() {
    let pa = CGMutablePath()
    let rect = CGRect(origin: CGPoint(x: -size.width / 2  ,y: -size.height / 2), size: CGSize(width: size.width, height: size.height))
    pa.addRoundedRect(in: rect, cornerWidth: 10, cornerHeight: 10)
    btn.path = pa
    
  }
  
  
}
