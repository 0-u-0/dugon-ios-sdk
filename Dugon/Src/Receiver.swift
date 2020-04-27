//
//  Receiver.swift
//  Dugon
//
//  Created by cong chen on 2020/4/25.
//  Copyright © 2020 dugon. All rights reserved.
//

import Foundation

public class Receiver {
    public let id:String
    public let mid: String
    public let senderId:String
    public let tokenId:String
    public let metadata:[String:String]
    
    var media:Media
    let codec:Codec

    public var available = false
    
    public var kind:String{
        return codec.kind
    }
    
    public var senderPaused:Bool{
        return codec.senderPaused
    }
    
    init(mid: String, senderId: String, tokenId: String, receiverId: String, codec: Codec, metadata: [String: String], media: Media) {
        self.id = receiverId
        self.mid = mid
        self.senderId = senderId
        self.tokenId = tokenId
        self.codec = codec
        self.metadata = metadata
        self.media = media
    }
}
