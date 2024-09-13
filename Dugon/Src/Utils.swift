//
//  Utils.swift
//  Dugon
//
//  Created by cong chen on 2020/4/20.
//  Copyright © 2020 dugon. All rights reserved.
//

import Foundation

func randomInt(n:Int)-> Int {
    let upper = Int(pow(Double(10),Double(n+1)))
    let floor = Int(pow(Double(10),Double(n)))
    return Int.random(in: floor..<upper)
}


func createByDic<T:Decodable>(type:T.Type,dic:[String:Any]) -> T?{
    
    let codecJson = dic.json.data(using: .utf8)!
    
    var obj: T?
    do {
        obj = try JSONDecoder().decode(T.self, from: codecJson)
        return obj
    } catch let DecodingError.dataCorrupted(context) {
        print(context)
    } catch let DecodingError.keyNotFound(key, context) {
        print("Key '\(key)' not found:", context.debugDescription)
        print("codingPath:", context.codingPath)
    } catch let DecodingError.valueNotFound(value, context) {
        print("Value '\(value)' not found:", context.debugDescription)
        print("codingPath:", context.codingPath)
    } catch let DecodingError.typeMismatch(type, context)  {
        print("Type '\(type)' mismatch:", context.debugDescription)
        print("codingPath:", context.codingPath)
    } catch {
        print("error: ", error)
    }
    return nil
}
