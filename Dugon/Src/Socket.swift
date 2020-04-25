//
//  Socket.swift
//  Dugon
//
//  Created by cong chen on 2020/4/15.
//  Copyright © 2020 dugon. All rights reserved.
//

import Foundation
import Starscream



typealias RequestCallback = (_ data: [String:Any]) -> ()

class Socket : WebSocketDelegate{

    let socket:WebSocket
    let url:String
        
    public var onConnected:(()->Void)?
    public var onNotification:((_ event:String,_ data:[String:Any])->Void)?

    //TODO: add timeout
    var callbacks:[Int:RequestCallback]
    public init(url:String,params:[String:Any]) {
        self.url = url
        self.callbacks = [Int:RequestCallback]()

        let completeUrl = "\(self.url)?params=\(params.json.encodBase64()!)"
        var request = URLRequest(url: URL(string: completeUrl)!)
        request.timeoutInterval = 1
        socket = WebSocket(request: request)
        socket.delegate = self
    }
    
    func connect() {
        socket.connect()
    }
    
    func request(params:[String:Any],callback:@escaping RequestCallback){
        let id = randomInt(n: 8)
        let method = "request"
        let data:[String : Any] = ["id":id,"method":method,"params":params]
        
        callbacks[id] = callback
        socket.write(string: data.json)
    }
    
    func request(event:String,data:[String:Any],callback:@escaping RequestCallback) {
        request(params: ["event":event,"data":data], callback: callback)
    }
    
    // MARK: - WebSocketDelegate
    public func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(_):
            guard let onConnected = onConnected else { return } //TODO:error
            onConnected()
        case .disconnected(let reason, let code):
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let mes):
            guard let dic = mes.jsonStr2Dict() else { return }
            
            if let method = dic["method"] as? String,let params = dic["params"] as? [String:Any] {
                switch method {
                case "response":
                    guard let id = dic["id"] as? Int else { return }
                    
                    if let callback = callbacks[id] {
                        callback(params)
                        callbacks[id] = nil
                    }
                case "notification":
                    guard let event = params["event"] as? String,let data = params["data"] as? [String:Any] else { return }
                    guard let onNotification = onNotification else { return } //TODO:error

                    onNotification(event,data)
                default:
                    print("unknown method \(method)")
                }
            } else {
                print("unknown message")
            }
            
        case .binary(let data):
            print("Received data: \(data.count)")
        case .ping(_):
            print("ping")
            break
        case .pong(_):
            print("pong")
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            print("cancelled")
            break
        case .error(let error):
            print("error")
            break
        }
    }
    
}
