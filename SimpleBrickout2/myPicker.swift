
//
//  myPicker.swift
//  Classic Snake 2
//
//  Created by Farid Ahmad on 02/05/2015.
//  Copyright (c) 2015 Farid Ahmad. All rights reserved.
//

import SpriteKit

class myPicker : SKSpriteNode {
  var selectedOption = SKLabelNode()
  var mWraparound = true
  var mOptionsList = ["_"]
  var mTextSize : CGFloat = 0.5
  var mTextColorTitle = SKColor.black
  var mTextColorOptions = SKColor.black
  var mUserDef = ""
  var mDefaultSelected = 0
  var selectedNumber : Int = 2 {
    didSet {
      if selectedNumber > mOptionsList.count - 1 {
        selectedNumber = 0
      }
      else if selectedNumber < 0 {
        selectedNumber = mOptionsList.count - 1
      }
      selectedOption.text =  mOptionsList[selectedNumber]
      userDefaults.set(selectedNumber, forKey: mUserDef)
    }
  }
  
  //--------------------------------------------------------------------------------------------------------------
  
  init ( list : [String], defaultsTag : String, defaultSelected : Int = 0) {
    super.init(texture: nil, color: SKColor(red: 1, green: 1, blue: 1, alpha: 0)  , size: CGSize.zero)
    mOptionsList = list
    mUserDef = defaultsTag
    mDefaultSelected = defaultSelected
  }
  //------------------------------------------------------------------------------------------------------------------
  func layout() {
    if (userDefaults.object(forKey: mUserDef)  != nil) {
      selectedNumber  = userDefaults.integer(forKey: mUserDef)
    }
    else {
      selectedNumber  = mDefaultSelected
    }
    selectedOption.fontSize = size.height * CGFloat(mTextSize)
    selectedOption.fontName = masterFont
    selectedOption.text =  mOptionsList[selectedNumber]
    selectedOption.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
    selectedOption.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
    selectedOption.fontColor = .white
    self.addChild(selectedOption)
    
    self.texture = SKTexture(imageNamed: "select2")
  }
  //--------------------------------------------------------------------------------------------------------------------------
  func handleClick( _ location : CGPoint) {
    

    
    #if os(iOS)
     // let impact = UIImpactFeedbackGenerator(style: .heavy)
      let select = UISelectionFeedbackGenerator()
     // let notify = UINotificationFeedbackGenerator()
    
    
      select.selectionChanged()
     // impact.impactOccurred()
    //  notify.notificationOccurred( .error  )
    
    #endif
    
    if (location.x + self.frame.width / 2.0 > self.frame.width / 2.0 ) {
      selectedNumber += 1
    }
    else {
      selectedNumber -= 1
    }
  }
  
  //---------------------------------------------------------------------------------------------------------------------------
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)    }
}


