//
//  MediaSource.swift
//  Dugon
//
//  Created by cong chen on 2020/4/21.
//  Copyright © 2020 dugon. All rights reserved.
//

import Foundation
import WebRTC


//interface
public class MediaSource {
    let track:RTCMediaStreamTrack
    let source:RTCMediaSource
    var type:String{
        return track.kind
    }
    
    init(track:RTCMediaStreamTrack,source:RTCMediaSource) {
        self.track = track
        self.source = source
    }

}
