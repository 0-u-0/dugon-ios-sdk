//
//  Subscriber.swift
//  Dugon
//
//  Created by cong chen on 2020/4/21.
//  Copyright © 2020 dugon. All rights reserved.
//

import Foundation
import WebRTC

class Subscriber: Transport {
    var receiver = [Receiver]()
    
    let asyncQueue = DispatchQueue(label: "publisher.queue")
    
    var isDtls: Bool = false
    
    var currentMid = 0;
    // follow sdp stupid mid's order
    
    public var onDtls: ((_ algorithm: String, _ hash: String, _ role: String) -> Void)?
    
    override init(factory: RTCPeerConnectionFactory, id: String, iceCandidate: [[String: Any]], iceParameters: [String: Any], dtlsParameters: [String: Any]) {
        super.init(factory: factory, id: id, iceCandidate: iceCandidate, iceParameters: iceParameters, dtlsParameters:
            dtlsParameters)
    }
    
    func addReceiver(senderId:String, tokenId:String, receiverId:String, codec:Codec, metadata:[String:String]){
//        const receiver = Receiver(String(this.currentMid++), senderId, tokenId, receiverId, codec, metadata, this.remoteICEParameters, this.remoteICECandidates);
//
//        this.receivers.set(senderId, receiver);
//        return receiver;
    }
}
