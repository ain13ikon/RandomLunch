//
//  ViewController.swift
//  RandomLunch2
//
//  Created by きたむら on 2018/10/15.
//  Copyright © 2018年 ain13ikon. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import RealmSwift

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    //表示用データ
    let requiredHeight: CGFloat = 320 //ディスプレイ（くじ内容の表示）以外で確保したい高さの見積もり
    var displayHeight: CGFloat = 200 //テキトウな初期値
    
    var dataArray: [Data] = []  //Firebaseから取ってきた全てのデータ
    var nowDataIndex: Int = 0   //現在使用中のデータのインデックス

    //現在使用中のデータ
    var dataId: String = ""
    var dataTitle: String = ""
    var dataItems: [String] = []
    
    //通信状態
    var networkFlag: Bool = false
    
    var itemAddNum = 5           //(EditVCで)初期表示＆一度に追加するアイテムの数
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var resultLabel: UILabel!
    
    @IBOutlet weak var listButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var choiceButton: UIButton!
    
    @IBOutlet weak var displayHeightConstant: NSLayoutConstraint!
    
    deinit {
        print("View deinit")
    }

    @IBAction func tapNewCreateButton(_ sender: Any) {
        print(#function)
        self.performSegue(withIdentifier: "newSegue", sender: nil)
    }
    
    @IBAction func tapEditButton(_ sender: Any) {
        print(#function)
        self.performSegue(withIdentifier: "editSegue", sender: nil)
    }
    
    @IBAction func tapListButton(_ sender: Any) {
        print(#function)
        self.performSegue(withIdentifier: "listSegue", sender: nil)
    }
    
    @IBAction func tapDeleteButton(_ sender: Any) {
        print(#function)
        showAlert()
    }
    
    @IBAction func tapChoiceButton(_ sender: Any) {
        print(#function)
        let choicedNum = Int(arc4random_uniform(UInt32(dataItems.count)))
        
        resultLabel.adjustsFontSizeToFitWidth = true
        resultLabel.text = dataItems[choicedNum]
        resultLabel.isHidden = false
        
        resultLabel.alpha = 0.0
        UIView.animate(withDuration: 1.0, animations: {
                        self.resultLabel.alpha = 1.0
        })
    }
    
    func deleteAction(){
        //データベースから削除
        Database.database().reference().child(Const.DataPath).child(self.dataId).removeValue()
        
        //dataArrayの更新
        self.dataArray.remove(at: nowDataIndex)
        
        //nowDataIndexの更新
        if nowDataIndex > 0 && nowDataIndex >= dataArray.count {
            nowDataIndex -= 1
        }
        
        //リロード
        myReload()
    }
    
    func showAlert(){
        let title = "「\(dataTitle)」の削除"
        let message = "データを削除しますか？"
        let alertController:UIAlertController =
            UIAlertController(title: title,
                              message: message,
                              preferredStyle: .alert)
        
        // Default のaction
        let defaultAction:UIAlertAction = UIAlertAction(
            title: "削除する",
            style: .default,
            handler:{(action:UIAlertAction!) -> Void in
                print("\(String(action.title!))がタップされました")
                self.deleteAction()
        })
        
        // Destructive のaction
        let cancelAction:UIAlertAction = UIAlertAction(
            title: "キャンセル",
            style: .cancel,
            handler:{(action:UIAlertAction!) -> Void in
                print("\(String(action.title!))がタップされました")
        })
        
        // actionを追加
        alertController.addAction(defaultAction)
        alertController.addAction(cancelAction)
        
        // UIAlertControllerの起動
        present(alertController, animated: true, completion: nil)
    }

    func adjustDisplayNum() -> Int {
        let num = dataItems.count % 5
        if num == 0 {
            return dataItems.count
        } else {
            return dataItems.count + (5 - num)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "newSegue" {
            let editVC = segue.destination as! EditViewController
            editVC.segue = "new"
            editVC.dataId = ""
            editVC.dataTitle = ""
            editVC.dataItems = []
            editVC.displayNum = editVC.defaultNum
        }else if segue.identifier == "editSegue" {
            let editVC = segue.destination as! EditViewController
            editVC.segue = "edit"
            editVC.dataId = dataId
            editVC.dataTitle = dataTitle
            editVC.dataItems = dataItems
            editVC.displayNum = adjustDisplayNum()
            print(adjustDisplayNum())
        }else if segue.identifier == "listSegue" {
            let listVC = segue.destination as! ListViewController
            listVC.dataArray = dataArray
            listVC.displayedDataArray = dataArray
        }
    }
    
    
    func setData(){
        if dataArray.count > nowDataIndex{
            dataId = dataArray[nowDataIndex].id ?? ""
            dataTitle = dataArray[nowDataIndex].title ?? ""
            dataItems = dataArray[nowDataIndex].items ?? []
        }else{
            nowDataIndex = 0
            dataId = ""
            dataTitle = ""
            dataItems = []
        }
    }
    
    func availableCheck() -> Bool {
        if dataArray.count > 0 {
            return true
        }else{
            return false
        }
    }
    
    
    func myReload(){
        if nowDataIndex < 0 {
            nowDataIndex = 0
        }
        if availableCheck() {
            //有効に
            listButton.isEnabled = true
            editButton.isEnabled = true
            deleteButton.isEnabled = true
            choiceButton.isEnabled = true
        }else{
            //ボタン等の操作を無効に
            listButton.isEnabled = false
            editButton.isEnabled = false
            deleteButton.isEnabled = false
            choiceButton.isEnabled = false
        }
        setData()
        print(dataTitle)
        print(dataItems)
        
        titleLabel.text = dataTitle
        tableView.reloadData()
        
        resultLabel.isHidden = true
    }

    func adjustHeight(){
        let height = view.frame.size.height
        displayHeight = height / 2
        if height - displayHeight < requiredHeight {
            displayHeight = height - requiredHeight
        }
        
        print("frame:\(height) display:\(displayHeight)")
        
        displayHeightConstant.constant = displayHeight
    }
    
    func setFireObserve(){
        let dataRef = Database.database().reference().child(Const.DataPath)
        dataRef.observe(.childAdded, with: {snapshot in
            print("データの追加")
            print(snapshot)
            let data = Data(snapshot)
            self.dataArray.insert(data, at: 0)
            
            self.myReload()
        })
        dataRef.observe(.childChanged, with: {snapshot in
            print("データの更新")
            let data = Data(snapshot)
            for data_ in self.dataArray {
                if data_.id == data.id {
                    let index = self.dataArray.index(of: data_)!
                    self.dataArray.remove(at: index)
                    self.dataArray.insert(data, at: index)
                    break
                }
            }
            self.myReload()
        })
        dataRef.observe(.childRemoved, with: {snapshot in
            
        })
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tableView.delegate = self
        tableView.dataSource = self
        
        //セルのnib取得
        let nib = UINib(nibName: "mainItemTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "itemCell")
        
        realmCheck()
        
        checkNet()
        setFireObserve()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print(#function)
       
        adjustHeight()
        
        myReload()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as! mainItemTableViewCell
        cell.itemLabel.text = "・" + dataItems[indexPath.row]
        
        return cell
    }

    func checkNet(){
        print("checkNet")
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {
                print("Connected")
                self.networkFlag = true
            } else {
                print("Not connected")
                self.networkFlag = false
                //１秒待ってもネット接続がされなければアラートを表示（最初の接続時にNot connected→Connectedになるため）
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if !self.networkFlag {
                        print("ネットに接続してください")
                        self.showAlert2()
                    }
                }
            }
        })
    }
    
    
    func showAlert2(){
        let title = "ネットワークエラー"
        let message = "接続を確認してください。"
        let alertController:UIAlertController =
            UIAlertController(title: title,
                              message: message,
                              preferredStyle: .alert)
        
        // Default のaction
        let defaultAction:UIAlertAction = UIAlertAction(
            title: "OK",
            style: .default,
            handler:{(action:UIAlertAction!) -> Void in
                print("\(String(action.title!))がタップされました")
        })
        
        // actionを追加
        alertController.addAction(defaultAction)
        
        // UIAlertControllerの起動
        present(alertController, animated: true, completion: nil)
    }
    
    func realmCheck(){
        let realm = try! Realm()
        let datas = realm.objects(RealmData.self)
        for value in datas{
            let id = value.id!
            let title = value.title!
            let itemList = value.items
            var items: [String] = []
            
            for value2 in itemList{
                items.append(value2.item!)
            }
            print(id)
            print(title)
            print(items)
            
            //データベースに保存
            //保存できたらRealmのデータを削除↓
            try! realm.write {
                //realm.delete(value)
            }
        }
    }

    
}

