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
import RealmSwift

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
    
    func update(key: Int?, string: String?){
        if let key = key, let string = string {
            if string == "" {
                print("keepArray削除")
                keepArray[key] = nil
            }else{
                print("keepArray追加")
                keepArray.updateValue(string, forKey: key)
            }
        }else{
            print("nilのため処理せず")
        }
    }
    
}

class UnsavedData: NSObject{
    var time: TimeInterval
    var title: String
    
    init(_ time: TimeInterval, _ title: String) {
        self.time = time
        self.title = title
    }
}
