//
//  RemoteSender.swift
//  Dugon
//
//  Created by cong chen on 2020/5/19.
//  Copyright © 2020 dugon. All rights reserved.
//

import Foundation

public class RemoteSender: Codable {
    public let area: String
    public let host: String
    public let mediaId: String
    public let tokenId: String
    public let transportId: String
    public let senderId: String
    public let metadata: [String: String]
    
    func toJson() -> [String:Any]? {

        do {
            let encoder = JSONEncoder()
            if #available(iOS 13.0, *) {
                encoder.outputFormatting = .withoutEscapingSlashes
            } else {
                //TODO:
            }
            let jsonData = try encoder.encode(self)
            let json = String(data: jsonData, encoding: String.Encoding.utf8)
            if let json = json {
                return json.jsonStr2Dict()
            }
            
        } catch {
            return nil
        }
        
        return nil
       
    }
}
