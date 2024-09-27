//
//  File.swift
//  
//
//  Created by cong chen on 2024/9/24.
//

import Foundation

public enum WebSocketEvent {
    case connected([String: String])
    case disconnected(String, UInt16)
    case text(String)
    case binary(Data)
    case pong(Data?)
    case ping(Data?)
    case error(Error?)
    case viabilityChanged(Bool)
    case reconnectSuggested(Bool)
    case cancelled
    case peerClosed
}

public protocol WebSocketDelegate: AnyObject {
    func didReceive(event: WebSocketEvent)
}

public class WebSocket : NSObject, URLSessionDataDelegate, URLSessionWebSocketDelegate {
    private var webSocketTask: URLSessionWebSocketTask?
    public weak var delegate: WebSocketDelegate?

    private let url:URL
    init(_ url: String) {
        self.url = URL(string: url)!
    }

    func connect() {
        let session = URLSession(configuration: URLSessionConfiguration.default,delegate: self, delegateQueue: nil)
        webSocketTask = session.webSocketTask(with: self.url)
        webSocketTask?.resume()
        receiveMessage()
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }

    func write(_ message: String) {
        let message = URLSessionWebSocketTask.Message.string(message)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("WebSocket send error: \(error)")
            }
        }
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let weakSelf = self else {
                return
            }

            // WebSocketEvent
            switch result {
            case .failure(let error):
                print("WebSocket receive error: \(error)")
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received text: \(text)")
                    weakSelf.delegate?.didReceive(event: .text(text))
                case .data(let data):
                    print("Received data: \(data.count) bytes")
                    weakSelf.delegate?.didReceive(event: .binary(data))
                @unknown default:
                    fatalError()
                }
                // Continue to listen for more messages
                weakSelf.receiveMessage()
            }
        }
    }

    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
         let p = `protocol` ?? ""
        delegate?.didReceive(event: .connected(["Sec-WebSocket-Protocol": p]))
        
        print("connected")

    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        // var r = ""
        // if let d = reason {
        //     r = String(data: d, encoding: .utf8) ?? ""
        // }
        // broadcast(event: .disconnected(r, UInt16(closeCode.rawValue)))
        print("closed")
//        delegate?.didReceive(event: event)

    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // broadcast(event: .error(error))
        print("error")
    }
}
