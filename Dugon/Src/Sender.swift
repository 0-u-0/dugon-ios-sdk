//
//  Sender.swift
//  Dugon
//
//  Created by cong chen on 2020/4/21.
//  Copyright © 2020 dugon. All rights reserved.
//

import Foundation
import WebRTC

class Sender{
    
    var mid:String {
        return transceiver.mid
    }
    
    var media:Media?
    
    let transceiver:RTCRtpTransceiver
    init(transceiver:RTCRtpTransceiver) {
        self.transceiver = transceiver
    }
}
