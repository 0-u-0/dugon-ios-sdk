//
//  Session.swift
//  Dugon
//
//  Created by cong chen on 2020/4/20.
//  Copyright © 2020 dugon. All rights reserved.
//

import Foundation
import WebRTC

let DEFAULT_VIDEO_CODEC = "VP8"
let DEFAULT_AUDIO_CODEC = "opus"

// TODO: move
struct ICEParameters: Codable {
    let password: String
    let usernameFragment: String
}

public protocol SessionDelegate: class {
    func onConnected()
    func onSender(senderId: String, tokenId: String, metadata: [String: String])
    func onIn(tokenId: String, metadata: [String: String])
    func onOut(tokenId: String)
    func onReceiver(receiver: Receiver)
    func onMedia(source: MediaSource, receiver: Receiver)
    func onUnsubscribed(receiver: Receiver)
    func onChange(receiver: Receiver, isPaused: Bool)
}

public class Session {
    var pub: Bool = false
    var sub: Bool = false
    
    let tokenId: String
    let socket: Socket
    var supportedCodec: [String: Codec?]?
    
    let factory: RTCPeerConnectionFactory
    
    var publisher: Publisher?
    var subscriber: Subscriber?
    
    public weak var delegate: SessionDelegate?
    
    init(factory: RTCPeerConnectionFactory, url: String, sessionId: String, tokenId: String, metadata: [String: Any]) {
        self.factory = factory
        self.tokenId = tokenId
        let params = ["sessionId": sessionId, "tokenId": tokenId, "metadata": metadata] as [String: Any]
        socket = Socket(url: url, params: params)
        socket.onConnected = onConnected
        socket.onNotification = onNotification
    }
    
    public func connect(pub: Bool = true, sub: Bool = true) {
        self.pub = pub
        self.sub = sub
        socket.connect()
    }
    
    public func publish(source: MediaSource, codec: String, metadata: [String: String]) {
        guard let publisher = publisher else { return }
        guard let supportedCodec = supportedCodec else { return }
        
        if let codecCap = supportedCodec[codec] {
            publisher.publish(source: source, codec: codecCap!, metadata: metadata)
        }
    }
    
    public func publish(source: MediaSource, codec: String){
        publish(source: source, codec: codec, metadata: [String: String]())
    }
    
    public func publish(source: MediaSource) {
        var codec: String
        if source.type == .audio {
            codec = DEFAULT_AUDIO_CODEC
        } else {
            codec = DEFAULT_VIDEO_CODEC
        }
        publish(source: source, codec: codec, metadata: [String: String]())
    }
    
    public func unpublish(senderId: String) {
        guard let publisher = publisher else { return }
        publisher.unpublish(senderId: senderId)
    }
    
    public func subscribe(receiverId: String) {
        guard let subscriber = subscriber else { return }
        subscriber.subscribe(receiverId: receiverId)
    }
    
    public func unsubscribe(receiverId: String) {
        guard let subscriber = subscriber else { return }
        subscriber.unsubscriber(receiverId: receiverId)
    }
    
    func request(event: String, data: [String: Any], callback: @escaping RequestCallback) {
        socket.request(params: ["event": event, "data": data], callback: callback)
    }
    
    private func getInfoById(id: String) -> (transportId: String, role: String, senderId: String) {
        var transportId = ""
        var role = ""
        var senderId = ""
        if let subscriber = self.subscriber, let receiver = subscriber.getReceiver(id: id) {
            role = "sub"
            transportId = subscriber.id
            senderId = receiver.senderId
        } else if let publisher = self.publisher, let sender = publisher.getSender(id: id) {
            role = "pub"
            transportId = publisher.id
            senderId = sender.id!
        }
        return (transportId, role, senderId)
    }
    
    public func pause(id: String) {
        let bounds = getInfoById(id: id)
        if !bounds.transportId.isEmpty {
            request(event: "pause", data: [
                "transportId": bounds.transportId,
                "role": bounds.role,
                "senderId": bounds.senderId
            ], callback: { (_: [String: Any]) -> () in
                print("pause ok")
            })
        }
    }
    
    public func resume(id: String) {
        let bounds = getInfoById(id: id)
        if !bounds.transportId.isEmpty {
            request(event: "resume", data: [
                "transportId": bounds.transportId,
                "role": bounds.role,
                "senderId": bounds.senderId
            ], callback: { (_: [String: Any]) -> () in
                print("resume ok")
            })
        }
    }
    
    private func initTransport(role: String, parameters: [String: Any]) {
        guard let transportId = parameters["id"] as? String else { return }
        guard let iceParam = parameters["iceParameters"] as? [String: Any] else { return }
        guard let iceCandidates = parameters["iceCandidates"] as? [[String: Any]] else { return }
        guard let dtlsParameters = parameters["dtlsParameters"] as? [String: String] else { return }
        
        let candidates = iceCandidates.map { createByDic(type: ICECandidate.self, dic: $0)! }
        let iceParameters = createByDic(type: ICEParameters.self, dic: iceParam)!
        if role == "pub" {
            publisher = Publisher(factory: factory, id: transportId, iceCandidates: candidates, iceParameters: iceParameters, dtlsParameters: dtlsParameters)
            publisher!.onDtls = { (algorithm, hash, role) -> () in
                self.socket.request(params: ["event": "dtls", "data": [
                    "transportId": self.publisher!.id,
                    "role": "pub",
                    "dtlsParameters": [
                        "setup": role,
                        "fingerprint": [
                            "algorithm": algorithm,
                            "value": hash
                        ]
                    ]
                ]], callback: { (_: [String: Any]) -> () in
                    print("dtls ok")
                })
            }
            
            publisher!.onSender = { (sender) -> () in
                print("onsender")
                if let mergedMedia = sender.media {
                    if let pubCodec = mergedMedia.toCodec() {
                        let codecJson = pubCodec.toJson()
                        self.request(event: "publish", data: [
                            "transportId": self.publisher!.id,
                            "codec": codecJson,
                            "metadata": []
                        ], callback: { (data: [String: Any]) -> () in
                            guard let senderId = data["senderId"] as? String else { return }
                            sender.id = senderId
                            
                            guard let delegate = self.delegate else { return }
//                            delegate.onSender(senderId: senderId, tokenId: self.tokenId, metadata: s)
                        })
                    }
                }
            }
            
            publisher!.onUnpublished = { (senderId) -> () in
                self.request(event: "unpublish", data: [
                    "transportId": self.publisher!.id,
                    "senderId": senderId,
                    "metadata": []
                ], callback: { (_: [String: Any]) -> () in
                    print("unpublish ok")
                })
            }
            
            publisher!.initi()
        } else if role == "sub" {
            // TODO:
            subscriber = Subscriber(factory: factory, id: transportId, iceCandidates: candidates, iceParameters: iceParameters, dtlsParameters: dtlsParameters)
            subscriber!.onMedia = { (source, receiver) -> () in
                guard let delegate = self.delegate else { return }
                delegate.onMedia(source: source, receiver: receiver)
                // receiver start with pausing
                self.resume(id: receiver.id)
            }
            
            subscriber!.onDtls = { (algorithm, hash, role) -> () in
                self.socket.request(params: ["event": "dtls", "data": [
                    "transportId": self.subscriber!.id,
                    "role": "sub",
                    "dtlsParameters": [
                        "setup": role,
                        "fingerprint": [
                            "algorithm": algorithm,
                            "value": hash
                        ]
                    ]
                ]], callback: { (_: [String: Any]) -> () in
                    print("dtls ok")
                })
            }
            
            subscriber!.onUnsubscribed = { (receiver) -> () in
                guard let delegate = self.delegate else { return }
                delegate.onUnsubscribed(receiver: receiver)
                self.request(event: "unsubscribe", data: [
                    "transportId": self.subscriber!.id, "senderId": receiver.senderId
                ], callback: { (_: [String: Any]) -> () in
                    print("unsubscribed ok")
                })
            }
            
            subscriber!.initi()
        }
    }
    
    func remotePubChange(senderId: String, isPaused: Bool) {
        guard let subscriber = self.subscriber else { return }
        if let receiver = subscriber.getReceiver(senderId: senderId) {
            receiver.senderPaused = isPaused
            guard let delegate = delegate else { return }
            delegate.onChange(receiver: receiver, isPaused: isPaused)
        }
    }
    
    // MARK: - SocketDelegate
    
    func onConnected() {
        print("onconnect")
        socket.request(params: ["event": "join", "data": [
            "pub": pub,
            "sub": sub
        ]], callback: { (data: [String: Any]) -> () in
            guard let codecs = data["codecs"] as? [String: Any] else { return }
            if self.pub {
                guard let pubParameters = data["pub"] as? [String: Any] else { return }
                self.initTransport(role: "pub", parameters: pubParameters)
            }
            if self.sub {
                guard let subParameters = data["sub"] as? [String: Any] else { return }
                self.initTransport(role: "sub", parameters: subParameters)
            }
            
            self.supportedCodec = codecs.mapValues { (codecAny) -> Codec? in
                if let codecDic = codecAny as? [String: Any] {
                    return createByDic(type: Codec.self, dic: codecDic)
                }
                return nil
            }
            
            guard let delegate = self.delegate else { return }
            delegate.onConnected()
        })
    }
    
    func onNotification(event: String, data: [String: Any]) {
        print("notification: \(event) ")
        switch event {
            case "join":
                guard let tokenId = data["tokenId"] as? String, let metadata = data["metadata"] as? [String: String] else { return }
                guard let delegate = delegate else { return }
                delegate.onIn(tokenId: tokenId, metadata: metadata)
            case "leave":
                guard let tokenId = data["tokenId"] as? String else { return }
                
                if let subscriber = self.subscriber {
                    subscriber.unsubscribers(tokenId: tokenId)
                }
                
                guard let delegate = delegate else { return }
                delegate.onOut(tokenId: tokenId)
                
            case "publish":
                guard let subscriber = self.subscriber else { return }
                
                if let remoteSender = createByDic(type: RemoteSender.self, dic: data) {
                    print(remoteSender)
                    subscriber.remoteSenders[remoteSender.senderId] = remoteSender
                    
                    guard let delegate = delegate else { return }
                    delegate.onOut(tokenId: tokenId)
                }
                
//                guard let senderId = data["senderId"] as? String, let tokenId = data["tokenId"] as? String, let receiverId = data["receiverId"] as? String, let metadata = data["metadata"] as? [String: String], let codecDic = data["codec"] as? [String: Any] else { return }
//                // TODO: check codec
//                let codec = createByDic(type: Codec.self, dic: codecDic)!
//
//                guard let subscriber = self.subscriber else { return }
//                let receiver = subscriber.addReceiver(senderId: senderId, tokenId: tokenId, receiverId: receiverId, codec: codec, metadata: metadata)
//                guard let delegate = delegate else { return }
//                delegate.onReceiver(receiver: receiver)
                
            case "unpublish":
                guard let senderId = data["senderId"] as? String else { return }
                guard let subscriber = self.subscriber else { return }
                subscriber.unsubscriber(senderId: senderId)
                
            case "pause":
                guard let senderId = data["senderId"] as? String else { return }
                remotePubChange(senderId: senderId, isPaused: true)
            case "resume":
                guard let senderId = data["senderId"] as? String else { return }
                remotePubChange(senderId: senderId, isPaused: false)
            default:
                break
        }
    }
}
