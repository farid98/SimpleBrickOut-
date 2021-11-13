//
//  ScrollerNode.swift
//  SimpleBrickOut
//
//  Created by Farid Ahmad on 21/08/2018.
//  Copyright © 2018 Farid Ahmad. All rights reserved.
//

import SpriteKit


// an SKNode object that scrolls a textutre for a scrolling background effect

class ScrollingImage : SKSpriteNode {
  var sprite1     = SKSpriteNode()
  var sprite2     = SKSpriteNode()
  var direction   = Direction.down
  var stepSize : CGFloat = 1
  var cyclesCount = 1
  var scrollSpeed = 1
  
  
  init() {
    super.init(texture: nil, color: UIColor.black, size: CGSize(width: 0, height: 0))
    self.addChild(sprite1)
    self.addChild(sprite2)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  
  func setup() {
    // call this once all properties have been set
    
    sprite1.texture = self.texture
    sprite1.size = self.size
    sprite1.anchorPoint = self.anchorPoint
    sprite1.zPosition = self.zPosition
    sprite1.position = CGPoint(x: 0, y: 0)
    
    sprite2.texture = self.texture
    sprite2.size = self.size
    sprite2.anchorPoint = self.anchorPoint
    sprite2.zPosition = self.zPosition
    sprite2.position = CGPoint(x: 0, y: 0)
    
    
  }
  
  
  func scroll() {
    // call this from update function of main gameloop
    var cyclesBeforeScroll = 0
    
    cyclesCount += 1
    switch scrollSpeed {
      case 1: // slowest
      cyclesBeforeScroll = 10
      stepSize = 1
    case 2:
      cyclesBeforeScroll = 4
       stepSize = 1
    case 3:
      cyclesBeforeScroll = 1
      stepSize = 1
    case 4:
      cyclesBeforeScroll = 1
      stepSize = 3

    default:
      cyclesBeforeScroll = 1
      stepSize = 1

    }
    
    cyclesCount += 1
    
    guard cyclesCount >= cyclesBeforeScroll else {
      return
    }
    
    // otherwise carry on......
    
    cyclesCount = 0
    
    switch direction  {
    case .up:
      sprite1.position.y += stepSize
      if sprite1.position.y > self.frame.height {
         sprite1.position.y  = 0
      }
      sprite2.position.y = sprite1.position.y - self.frame.height
      
    case .down :
      sprite1.position.y -= stepSize
      if sprite1.position.y < -self.frame.height {
         sprite1.position.y  = 0 // this is basically now replacing the second sprite - since they are identical thats OK, and then slide again
      }
      sprite2.position.y = sprite1.position.y + self.frame.height
      
    case .left:
      sprite1.position.x -= stepSize
      if sprite1.position.x < -self.frame.width {
        sprite1.position.x  = 0
      }
      sprite2.position.x = sprite1.position.x + self.frame.width
      
    case .right:
      sprite1.position.x += stepSize
      if sprite1.position.x > self.frame.width {
        sprite1.position.x  = 0
      }
      sprite2.position.x = sprite1.position.x - self.frame.width
    case .none:
      break
    }
    
  }
  
  
  
  
  
  
  
  
  
  
  
  
  
  
}

