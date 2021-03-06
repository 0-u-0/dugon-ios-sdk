//
//  Sender.swift
//  Dugon
//
//  Created by cong chen on 2020/4/21.
//  Copyright © 2020 dugon. All rights reserved.
//

import Foundation
import WebRTC

public class Sender {
    public var id: String?
    public let metadata: [String: String]
    
    var mid: String {
        return transceiver.mid
    }
    
    public var kind: String {
        if let track = transceiver.sender.track {
            return track.kind
        }
        return ""
    }
    
    var media: Media?
    
    var isStopped: Bool {
        return transceiver.isStopped
    }
    
    var available: Bool {
        return !(transceiver.direction == .inactive)
    }
    
    let transceiver: RTCRtpTransceiver
    init(transceiver: RTCRtpTransceiver, metadata: [String: String]) {
        self.transceiver = transceiver
        self.metadata = metadata
    }
    
    func disableMedia() {
        media?.direction = "inactive"
    }
}
