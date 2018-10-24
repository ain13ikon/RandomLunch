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

var global_offLineServiceFlag = false   //オフライン時にコード上でRealm処理をするか ※順番が競合することがある
//var global_networkFlag = false  //ネットワークに繋がっているか

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
    
    var networkFlag: Bool = false   //通信状態
    let realm = try! Realm()        //Realmインスタンスの取得
    //var itemAddNum = 5              //(EditVCで)初期表示＆一度に追加するアイテムの数
    
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
        showDeleteAlert()
    }
    
    //抽選を行い、結果をラベルに表示する
    @IBAction func tapChoiceButton(_ sender: Any) {
        print(#function)
        let choicedNum = Int(arc4random_uniform(UInt32(dataItems.count)))
        
        resultLabel.text = dataItems[choicedNum]
        resultLabel.isHidden = false
        
        //結果をアニメーション表示
        resultLabel.alpha = 0.0
        UIView.animate(withDuration: 1.0){
            self.resultLabel.alpha = 1.0
        }
    }
    
    func showDeleteAlert(){
        let title = "「\(dataTitle)」の削除"
        let message = "データを削除しますか？"
        let alertController: UIAlertController =
            UIAlertController(title: title,
                              message: message,
                              preferredStyle: .alert)
        
        // Default のaction
        let defaultAction:UIAlertAction = UIAlertAction(
            title: "削除する",
            style: .default,
            handler:{(action:UIAlertAction!) -> Void in
                print("\(String(action.title!))がタップされました")
                self.deletefunction()
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

    func deletefunction(){
        //データベースから削除
        Database.database().reference().child(Const.DataPath).child(self.dataId).removeValue()
        //オフライン時に更新内容を予備保存
        if global_offLineServiceFlag && !networkFlag {
            print("削除データを予備保存")
            let data = RealmDeleteData()
            data.id = dataId
            try! realm.write {
                realm.add(data)
            }
        }
        //dataArrayの更新
        self.dataArray.remove(at: nowDataIndex)
        
        //nowDataIndexの更新
        if nowDataIndex > 0 && nowDataIndex >= dataArray.count {
            nowDataIndex -= 1
        }
        //リロード
        myReload()
    }
    
    //編集画面(EditVC)に表示するアイテム欄の数を調整する
    func adjustItemColumnNum(_ defaultNum: Int, _ addNum: Int) -> Int {
        var i = 0
        while dataItems.count > defaultNum + addNum * i{
            i += 1
            //ストッパー
            if i > 100 {
                print("エラー発生：\(#function)")
                break
            }
        }
        print("num: \(defaultNum + addNum * i)")
        return defaultNum + addNum * i
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "newSegue" {
            let editVC = segue.destination as! EditViewController
            editVC.segue = "new"
            editVC.dataId = ""
            editVC.dataTitle = ""
            editVC.dataItems = []
            editVC.itemColumnNum = editVC.defaultNum
        }else if segue.identifier == "editSegue" {
            let editVC = segue.destination as! EditViewController
            editVC.segue = "edit"
            editVC.dataId = dataId
            editVC.dataTitle = dataTitle
            editVC.dataItems = dataItems
            editVC.itemColumnNum = adjustItemColumnNum(editVC.defaultNum, editVC.addItemNum)
        }else if segue.identifier == "listSegue" {
            let listVC = segue.destination as! ListViewController
            listVC.dataArray = dataArray
            listVC.displayedDataArray = dataArray
        }
    }
    
    //現在表示中のデータを変数に保管する
    func setNowData(){
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
        //ボタン等の操作の有効・無効
        if availableCheck() {
            //有効にする
            listButton.isEnabled = true
            editButton.isEnabled = true
            deleteButton.isEnabled = true
            choiceButton.isEnabled = true
        }else{
            //無効にする
            listButton.isEnabled = false
            editButton.isEnabled = false
            deleteButton.isEnabled = false
            choiceButton.isEnabled = false
        }
        setNowData()
        titleLabel.text = dataTitle
        resultLabel.isHidden = true
        
        tableView.reloadData()
    }

    //ディスプレイの高さを端末の画面サイズを元に調整する
    func adjustHeight(){
        let height = view.frame.size.height
        displayHeight = height / 2
        if height - displayHeight < requiredHeight {
            displayHeight = height - requiredHeight
        }
        displayHeightConstant.constant = displayHeight
    }
    
    //Firebaseのobserveイベントを設定する
    func setFireObserve(){
        let dataRef = Database.database().reference().child(Const.DataPath)
        dataRef.observe(.childAdded, with: {snapshot in
            print("データの追加")
            //dataArrayにデータを追加する
            let data = Data(snapshot)
            self.dataArray.insert(data, at: 0)
            
            self.myReload()
        })
        dataRef.observe(.childChanged, with: {snapshot in
            print("データの更新")
            //dataArrayから旧データを取り除き、更新データを追加する
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
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tableView.delegate = self
        tableView.dataSource = self
        //セルのnib取得
        let nib = UINib(nibName: "mainItemTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "itemCell")
        
        /*
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(closeApp(_:)),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        */
        
        adjustHeight()
        resultLabel.adjustsFontSizeToFitWidth = true

        self.setObserveCheckNet()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5){
            self.setFireObserve()
            self.realmCheck()
        }

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print(#function)
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

    func setObserveCheckNet(){
        print("checkNet")
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {
                print("Connected")
                self.networkFlag = true
            } else {
                print("Not connected")
                self.networkFlag = false
                //１秒待ってもネット接続がされなければアラートを表示（最初の接続時にNot connected→Connectedになるため少し待つ）
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if !self.networkFlag {
                        self.showNetworkAlert()
                    }
                }
            }
        })
    }
    
    
    func showNetworkAlert(){
        let title = "ネットに接続できません"
        let message = "接続を確認してください。\nオフライン状態ですとデータが正しく保存されないことがあります。"
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
        guard global_offLineServiceFlag else {return}
        manualUpdateFirebase()
        manualDeleteFirebase()
    }
    
    func manualDeleteFirebase(){
        let datas = realm.objects(RealmDeleteData.self)
        print(datas)
        
        for value in datas {
            guard networkFlag else{continue}
            
            print("予備データをデータベースから削除します")
            Database.database().reference().child(Const.DataPath).child(value.id).removeValue()
            
            try! realm.write {
                realm.delete(value)
            }
        }
    }
    
    func manualUpdateFirebase(){
        let datas = realm.objects(RealmData.self)
        print(datas)

        for value in datas{
            let id = value.id!
            let title = value.title!
            let items = setItemsArrayFromRealm(value.items)
            
            guard networkFlag else {continue}
            
            //データベースに保存
            print("予備データをデータベースへ保存します")
            let dataRef = Database.database().reference().child(Const.DataPath).child(id)
            dataRef.setValue(
                ["title": title, "items": items],
                withCompletionBlock: {(error, dataRef) in
                    if let error = error{
                        print(error)
                    }
            })
            
            //保存できたらRealmのデータを削除
            try! realm.write {
                realm.delete(value)
            }
        }
        
    }

    func setItemsArrayFromRealm(_ itemList: List<RealmItemData>) -> [String]{
        var items: [String] = []
        for value in itemList{
            items.append(value.item!)
        }
        return items
    }

    //未使用
    @objc func closeApp(_ notification: Notification){
        print("アプリが終了します")
        //print(text)
        
    }
    
}

