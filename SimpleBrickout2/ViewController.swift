//
//  ViewController.swift
//  ipaddle1
//
//  Created by Farid Ahmad on 29/06/2017.
//  Copyright © 2017 Farid Ahmad. All rights reserved.
//

import UIKit
import SpriteKit

var topBuffer : CGFloat = 50
var bottomBuffer : CGFloat = 10


enum DeviceSize {
    case iPhoneSE
    case iPhone8
    case iPhone8Plus
    case iPhoneXR
    case iPhoneX
    case iphoneXMax
    case iphone12
    case iphone12ProMax
    case iPad
}


var deviceSize : DeviceSize = .iPhone8

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let spriteView : SKView = view as! SKView
        spriteView.showsDrawCount = false
        spriteView.showsNodeCount = false
        spriteView.showsFPS = false
        
        setUsableScreenAreas()
        
        let startScene = menuMain(size: CGSize(width: view.frame.width, height: view.frame.height))
        spriteView.presentScene(startScene)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    func setUsableScreenAreas() {
        
        let window = UIApplication.shared.windows[0]
        topBuffer = window.safeAreaInsets.top
        if topBuffer == 0 {topBuffer = 5}
        bottomBuffer = window.safeAreaInsets.bottom
        if bottomBuffer == 0 {bottomBuffer = 5}
        
        if UIDevice().userInterfaceIdiom == .phone {
            
            switch UIScreen.main.nativeBounds.height {
            case 1136:
                deviceSize = .iPhoneSE      //iPhone 5 or 5S or 5C..or SE
            case 1334:
                deviceSize = .iPhone8       //iPhone 6/6S/7/8
            case 1792:
                deviceSize = .iPhoneXR
            case 2208:
                deviceSize = .iPhone8Plus   // iPhone 6+/6S+/7+/8+
            case 2436:
                deviceSize = .iPhoneX       // iPhoneX, iphoneXS
            case 2688:
                deviceSize = .iphoneXMax
            case 2532:
                deviceSize = .iphone12
            case 2778:
                deviceSize = .iphone12ProMax
                
            default:
                deviceSize = .iPhone8       // default to best bet
            }
        }
        else  {                         // iPad
            print("Ipad")
            deviceSize = .iPad
        }
    }
    
    
}


