//
//  AudioSource.swift
//  Dugon
//
//  Created by cong chen on 2020/4/15.
//  Copyright © 2020 dugon. All rights reserved.
//

import Foundation
import WebRTC

public class AudioSource:MediaSource{
        
    init(source:RTCAudioSource,track:RTCAudioTrack) {
        super.init(track: track, source: source)
    }
}
