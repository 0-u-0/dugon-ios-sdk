//
//  Player.swift
//  Dugon
//
//  Created by cong chen on 2020/4/15.
//  Copyright © 2020 dugon. All rights reserved.
//

import Foundation
import WebRTC

public struct Player{
    public var view:RTCCameraPreviewView

    public init(){
        self.view = RTCCameraPreviewView(frame: CGRect.zero)

        var localVideoFrame = CGRect.init(x:0, y:0, width:160, height:160)
        localVideoFrame.origin.x = 0;
        localVideoFrame.origin.y = 0;
        
        view.frame = localVideoFrame;
    }
}
