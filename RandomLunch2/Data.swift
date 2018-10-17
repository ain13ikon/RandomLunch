//
//  Data.swift
//  RandomLunch2
//
//  Created by きたむら on 2018/10/16.
//  Copyright © 2018年 ain13ikon. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase

class Data: NSObject {
    var id: String?
    var title: String?
    var items: [String]?
    
    init(_ snapshot: DataSnapshot){
        print("Data init()")
        self.id = snapshot.key
        
        let dic = snapshot.value as! [String: Any]
        
        self.title = dic["title"] as? String
        self.items = dic["items"] as? [String]
    }
    
    deinit {
        print("Data deinit")
    }
}

class TextFieldKeepData: NSObject {
    var keepArray: [Int: String] = [:]
    //[セルのindex: 入力されたテキスト]
    
    func update(index: Int, string: String){
        if string != "" {
            keepArray.updateValue(string, forKey: index)
        }
    }
}
