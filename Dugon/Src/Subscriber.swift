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
    var receivers = [Receiver]()
    
    let asyncQueue = DispatchQueue(label: "subscriber.queue")
    
    var isDtls: Bool = false
    
    var currentMid = 0
    // follow sdp stupid mid's order
    
    public var onDtls: ((_ algorithm: String, _ hash: String, _ role: String) -> Void)?
    public var onTrack: ((_ track: RTCMediaStreamTrack, _ receiver: Receiver) -> Void)?
    
    override init(factory: RTCPeerConnectionFactory, id: String, iceCandidates: [ICECandidate], iceParameters: ICEParameters, dtlsParameters: [String: Any]) {
        super.init(factory: factory, id: id, iceCandidates: iceCandidates, iceParameters: iceParameters, dtlsParameters:
            dtlsParameters)
    }
    
    func subscribe(receiverId: String) {
        if let receiver = receivers.first(where: { $0.id == receiverId }) {
            asyncQueue.async {
                self._subscribe(receiver: receiver)
            }
        }
    }
    
    private func _subscribe(receiver: Receiver) {
        guard let pc = pc else { return }
        
        
        receiver.media.direction = "sendonly"
        let remoteSdp = generateRemoteSdp()
        print(remoteSdp.sdp)
        pc.setRemoteDescription(remoteSdp) { error in
            guard error == nil else {
                // TODO:
                return
            }
            let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
            pc.answer(for: constraints) { answer, error in
                if error == nil, let answer = answer {
                    pc.setLocalDescription(answer) { error in
                        if error != nil {
                            // TODO:
                        }
                        if let transceiver = pc.transceivers.first(where: { $0.mid == receiver.mid }) {
                            if let track = transceiver.receiver.track {
                                guard let onTrack = self.onTrack else { return }
                            
                                onTrack(track,receiver)
                            }
                        }
                        if !self.isDtls {
                            self.isDtls = true
                            let session = Sdp.parse(sdpStr: answer.sdp)
                            let media = session.medias[0]
                            guard let fingerprint = media.fingerprint else { return }
                            
                            guard let onDtls = self.onDtls else { return } //TODO:error
                            onDtls(fingerprint.algorithm, fingerprint.hash, "active")
                        }
                    }
                }
            }
        }
    }
    
    func addReceiver(senderId: String, tokenId: String, receiverId: String, codec: Codec, metadata: [String: String]) -> Receiver {
        let mid = String(currentMid)
        currentMid += 1
        
        let media = Media.create(mid: mid, codec: codec, iceParameters: remoteICEParameters, iceCandidates: remoteICECandidates, msidAppdata: receiverId)
        let receiver = Receiver(mid: mid, senderId: senderId, tokenId: tokenId, receiverId: receiverId, codec: codec, metadata: metadata, media: media)
        
        receivers.append(receiver)
        return receiver
    }
    
    func generateRemoteSdp() -> RTCSessionDescription {
        let sdp = Sdp()
        sdp.version = 0
        sdp.origin = "o=- 10000 2 IN IP4 127.0.0.1"
        sdp.name = "-"
        sdp.timing = "0 0"
        sdp.msidSemantic = " WMS"
        
        if let fingerprint = remoteDTLSParameters["fingerprint"] as? [String: String] {
            if let algorithm = fingerprint["algorithm"], let fingerprintValue = fingerprint["value"] {
                sdp.fingerprint = Fingerprint(algorithm: algorithm, hash: fingerprintValue)
            }
        }
        
        for receiver in receivers {
            sdp.medias.append(receiver.media)
        }
        
        return RTCSessionDescription(type: .offer, sdp: sdp.toString())
    }
}
