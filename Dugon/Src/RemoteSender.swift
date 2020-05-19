//
//  RemoteSender.swift
//  Dugon
//
//  Created by cong chen on 2020/5/19.
//  Copyright © 2020 dugon. All rights reserved.
//

import Foundation

public class RemoteSender: Decodable {
    public let area: String
    public let host: String
    public let mediaId: String
    public let tokenId: String
    public let transportId: String
    public let senderId: String
    public let metadata: [String: String]
}
