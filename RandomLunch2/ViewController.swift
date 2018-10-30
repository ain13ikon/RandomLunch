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

//var global_offLineServiceFlag = false   //オフライン時にコード上でRealm処理をするか ※順番が競合することがある


let global_connectedRef =
    Database.database().reference(withPath: ".info/connected")    //ネットワーク監視用の変数
var global_onlineFlag = false {                //ネットワークフラグを管理し、オフラインならアラートを表示する
    didSet{
        if global_onlineFlag{
            print("オンライン")
            //アラート表示中ならアラートを消す
            if let vc = global_getTopViewController() as? UIAlertController{
                print("アラート中")
                vc.dismiss(animated: false)
            }else{
                print("アラートじゃない")
            }
        }else{
            print("オフライン")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2){
                if !global_onlineFlag{
                    global_showNetworkAlert()
                }
            }

        }
    }
}

var global_unsavedTitleArray: [String] = []     //未保存データのタイトル配列
var global_unsavedDatas: [UnsavedData] = []{    //未保存データのキュー送信時刻とタイトル
    didSet{
        global_unsavedTitleArray = []
        for value in global_unsavedDatas {
            global_unsavedTitleArray.append(value.title)
        }
        print("未保存のタイトル")
        print(global_unsavedTitleArray)
    }
}



class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    //表示用データ
    let requiredHeight: CGFloat = 320 //ディスプレイ（くじ内容の表示）以外で確保したい高さの見積もり
    var displayHeight: CGFloat = 200 //テキトウな初期値
    
    var dataArray: [Data] = []      //Firebaseから取ってきた全てのデータ
    var titleArray: [String] = []   //未使用データ
    var nowDataIndex: Int = 0       //現在使用中のデータのインデックス

    //現在使用中のデータ
    var dataId: String = ""
    var dataTitle: String = ""
    var dataItems: [String] = []
    
    var availableFlag = false  //使用可能なデータがあるか
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var listButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var choiceButton: UIButton!
    @IBOutlet weak var displayHeightConstant: NSLayoutConstraint!
    //@IBOutlet weak var resultConstant: NSLayoutConstraint!
    
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
//        resultLabel.center.y -= 50.0
        UIView.animate(withDuration: 1.0){
            self.resultLabel.alpha = 1.0
//            self.resultLabel.center.y += 50.0
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
            editVC.titleArray = titleArray
        }else if segue.identifier == "editSegue" {
            let editVC = segue.destination as! EditViewController
            editVC.segue = "edit"
            editVC.dataId = dataId
            editVC.dataTitle = dataTitle
            editVC.dataItems = dataItems
            editVC.itemColumnNum = adjustItemColumnNum(editVC.defaultNum, editVC.addItemNum)
            editVC.titleArray = titleArray
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
            availableFlag = true
            return true
        }else{
            availableFlag = false
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
            editButton.alpha = 1.0
            deleteButton.alpha = 1.0
            choiceButton.alpha = 1.0
        }else{
            //無効にする
            listButton.isEnabled = false
            editButton.isEnabled = false
            deleteButton.isEnabled = false
            choiceButton.isEnabled = false
            editButton.alpha = 0.5
            deleteButton.alpha = 0.5
            choiceButton.alpha = 0.3
        }
        setNowData()
        
        titleLabel.text = dataTitle
        resultLabel.isHidden = true
        
        tableView.reloadData()
        tableView.flashScrollIndicators()
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
            //dataArrayとtitleArrayにデータを追加する
            let data = Data(snapshot)
            self.dataArray.insert(data, at: 0)
            self.titleArray.append(data.title!)
            
            print(snapshot.ref)
            self.myReload()
        })
        dataRef.observe(.childChanged, with: {snapshot in
            print("データの更新")
            //dataArrayとtitleArrayから旧データを取り除き、更新データを追加する
            let newData = Data(snapshot)
            for oldData in self.dataArray {
                if oldData.id == newData.id {
                    let index = self.dataArray.index(of: oldData)!
                    self.dataArray.remove(at: index)
                    self.dataArray.insert(newData, at: index)
                    
                    let num = self.titleArray.index(of: oldData.title!)!
                    self.titleArray.remove(at: num)
                    self.titleArray.insert(newData.title!, at: num)
                    break
                }
            }
            self.myReload()
        })
    }

    override func viewDidLoad() {
        print(#function)
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false
        
        //セルのnib取得
        let nib = UINib(nibName: "mainItemTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "itemCell")
        let nib2 = UINib(nibName: "noneTableViewCell", bundle: nil)
        tableView.register(nib2, forCellReuseIdentifier: "noneCell")
        
        adjustHeight()
        resultLabel.adjustsFontSizeToFitWidth = true
        titleLabel.adjustsFontSizeToFitWidth = true

        self.setObserveNetworkCheck()
        self.setFireObserve()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print(#function)
        myReload()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("numberOfRows")
        if availableFlag {
            return dataItems.count
        }else{
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("cellForRowAt")
        if availableFlag {
            //くじデータがある場合
            let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as! mainItemTableViewCell
            cell.itemLabel.text = dataItems[indexPath.row]
            return cell
        }else{
            //くじデータがない場合
            let cell = tableView.dequeueReusableCell(withIdentifier: "noneCell", for: indexPath) as! noneTableViewCell
            cell.createButton.addTarget(self, action: #selector(tapCreateButton), for: .touchUpInside)
            return cell
        }
    }
    
    //tableViewのヘッダー表示をオフに
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }

    func setObserveNetworkCheck(){
        print(#function)
        global_connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {
                print("aaa")
                //オンラインになった時
                if !global_onlineFlag{
                    global_onlineFlag = true
                }
            } else {
                print("bbb")
                //オフラインになった時
                if global_onlineFlag {
                    global_onlineFlag = false
                }
            }
        })
    }
    
    //「くじを作成する」がタップされた時
    @objc func tapCreateButton(){
        print(#function)
        self.performSegue(withIdentifier: "newSegue", sender: nil)
    }
}





//現在表示中のViewControllerを取得する関数
func global_getTopViewController() -> UIViewController? {
    print(#function)
    if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
        print("rootVC:")
        print(rootViewController)
        var topViewControlelr: UIViewController = rootViewController
        
        while let presentedViewController = topViewControlelr.presentedViewController {
            print("presentedVC")
            print(presentedViewController)
            topViewControlelr = presentedViewController
        }
        
        return topViewControlelr
    } else {
        return nil
    }
}

//ネットワークアラートを表示する
func global_showNetworkAlert(){
    let title = "ネットに接続できません"
    let message = "接続を確認してください。\nオフライン状態ですとデータが正しく保存されないことがあります。"
    let alertController =
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
    let vc = global_getTopViewController()
    vc?.present(alertController, animated: true, completion: nil)
}




