//
//  Extensioin.swift
//  Dugon
//
//  Created by cong chen on 2020/4/22.
//  Copyright © 2020 dugon. All rights reserved.
//

import Foundation

extension Array where Element == String {
    public static func == (lhs: Array<String>, rhs: Array<String>) -> Bool {
        var match = true
        for l in lhs {
           match = rhs.contains(l) && match
        }

        for r in rhs {
           match = lhs.contains(r) && match
        }
        return match
    }
}

extension String {
    subscript (i: Int) -> String {
        return String(self[self.index(self.startIndex, offsetBy: i)])
    }
    
    subscript (r: ClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: r.lowerBound)
        let end = index(startIndex, offsetBy: r.upperBound)
        return String(self[start...end])
    }
    
    subscript(value: PartialRangeFrom<Int>) -> String {
        let start = index(startIndex, offsetBy: value.lowerBound)
        return String(self[start...])
    }
}

extension String {
    //Base64编码
    func encodBase64() -> String?
    {
        let strData = self.data(using: String.Encoding.utf8)
        let base64String = strData?.base64EncodedString(options: NSData.Base64EncodingOptions.init(rawValue: 0))
        return base64String
    }

    //Base64解码
    func decodeBase64() -> String?
    {
        let decodedData = NSData(base64Encoded: self, options: NSData.Base64DecodingOptions.init(rawValue: 0))
        let decodedString = NSString(data: decodedData! as Data, encoding: String.Encoding.utf8.rawValue) as String?
        return decodedString
    }
    
    
    func jsonStr2Dict() ->Dictionary<String, Any>?{
        do{
            let json = try JSONSerialization.jsonObject(with: self.data(using: .utf8)!, options: .mutableContainers)

            let dic = json as! Dictionary<String, Any>

            return dic

        }catch _ {

            return nil

        }
    }
}

extension Dictionary {

    var json: String {
        let invalidJson = "Not a valid JSON"
        do {
            if #available(iOS 13.0, macOS 10.15, *) {
                let jsonData = try JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted, .withoutEscapingSlashes])
                return String(bytes: jsonData, encoding: String.Encoding.utf8) ?? invalidJson

            } else {
                let jsonData = try JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted])
                let jsonStr = String(bytes: jsonData, encoding: String.Encoding.utf8)!
                return jsonStr.replacingOccurrences(of: "\\/", with: "/")
            }
  
        } catch {
            return invalidJson
        }
    }
    

}


extension String {
    func matchingStrings(regex: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: regex, options: []) else { return [] }
        let nsString = self as NSString
        let results  = regex.matches(in: self, options: [], range: NSMakeRange(0, nsString.length))
        if results.count > 0 {
            var filterResult = [String]()
            for r in 0..<results[0].numberOfRanges {
                if results[0].range(at: r).location != NSNotFound{
                    filterResult.append(nsString.substring(with: results[0].range(at: r )))
                }
            }
            return filterResult
        }else{
            return []
        }
    }
    func splitOnce(separator:Character) -> [String] {
        return split(separator:separator,maxSplits:1,omittingEmptySubsequences:true).map{String($0)}
    }
    
    func split(separator:Character) -> [String] {
        return split(separator:separator,omittingEmptySubsequences:true).map{String($0)}
    }
    
}
