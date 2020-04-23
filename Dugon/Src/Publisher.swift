//
//  Publisher.swift
//  Dugon
//
//  Created by cong chen on 2020/4/21.
//  Copyright © 2020 dugon. All rights reserved.
//

import Foundation
import WebRTC


class Publisher:Transport{
    
    let senders = [String:Sender]()
    
    let asyncQueue = DispatchQueue(label: "publisher.queue")
    
    var isDtls:Bool = false
    
    
    public var onDtls : ((_ algorithm: String, _ hash: String,_ role:String) -> Void)?
    public var onSender: ((_ sender:Sender)->Void)?
    
    override init(factory: RTCPeerConnectionFactory, id: String, iceCandidate: [[String : Any]], iceParameters: [String : Any], dtlsParameters: [String : Any]) {
        
        super.init(factory: factory, id: id, iceCandidate: iceCandidate, iceParameters: iceParameters, dtlsParameters
            : dtlsParameters)
    }
    
    
    
    func publish(source:MediaSource,codec:Codec) {
        asyncQueue.async {
            self._publish(source: source,codec:codec)
        }
    }
    
    func _publish(source:MediaSource,codec:Codec) {
        guard let pc = pc else { return }
        
        let initConfig = RTCRtpTransceiverInit()
        initConfig.direction = RTCRtpTransceiverDirection.sendOnly

        let transceiver =   pc.addTransceiver(with: source.track, init: initConfig)
        let sender = Sender(transceiver: transceiver)
        
        let constraints2 = RTCMediaConstraints.init(mandatoryConstraints: nil, optionalConstraints: nil)

        pc.offer(for: constraints2) { (sdp, error) in
            guard error == nil else {
                //TODO:
                return
            }
            
            guard let sdp = sdp else { return }
            pc.setLocalDescription(sdp) { (error) in
                guard error == nil else {
                    //TODO:
                    return
                }
                let session = Sdp.parse(sdpStr: sdp.sdp)
                                
                if !self.isDtls {
                    self.isDtls = true
                    let media = session.medias[0]
                    guard let fingerprint = media.fingerprint else { return }
                    
                    guard let onDtls = self.onDtls else { return } //TODO:error  
                    onDtls(fingerprint.algorithm, fingerprint.hash, "active")
                }
                
                //RemoteSdp
                for media in session.medias{
                    guard let mid = media.mid else { break }
                    if sender.mid == String(mid){
                        let mergedMedia = media.merge(codecCap: codec,iceParameters: self.remoteICEParameters,iceCandidates:self.remoteICECandidates)
                        sender.media = mergedMedia
                        let remoteSdp = self.generateRemoteSdp(sender: sender)
//                        print(remoteSdp)
                        let remoteSdpObj = RTCSessionDescription(type: .answer, sdp: remoteSdp)
//                        print(remoteSdpObj)
                        self.pc?.setRemoteDescription(remoteSdpObj, completionHandler: { (error:Error?) in
                            guard error == nil else {print(error);return}
                            guard let onSender = self.onSender else { return } //TODO:error
                            onSender(sender)
                        })
                    }
                }
            }
            

        }
    }
    
    func generateRemoteSdp(sender:Sender) -> String{
        let sdp = Sdp()
        sdp.version = 0
        sdp.origin = "o=- 10000 2 IN IP4 127.0.0.1"
        sdp.name = "-"
        sdp.timing = "0 0"
        sdp.msidSemantic = " WMS"
        
        if let fingerprint = self.remoteDTLSParameters["fingerprint"] as? [String:String]  {
            if let algorithm = fingerprint["algorithm"],let fingerprintValue = fingerprint["value"] {
                sdp.fingerprint = Fingerprint(algorithm: algorithm, hash: fingerprintValue)
            }
        }
     
        
        for (i,s) in senders {
            if let media = s.media {
                sdp.medias.append(media)
            }
        }
        
        if let media = sender.media {
            sdp.medias.append(media)
        }
    

        return sdp.toString()
    }
}
