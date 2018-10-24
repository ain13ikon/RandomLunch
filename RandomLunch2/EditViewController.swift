//
//  EditViewController.swift
//  RandomLunch2
//
//  Created by きたむら on 2018/10/15.
//  Copyright © 2018年 ain13ikon. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import RealmSwift

class EditViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var constantTableViewBottom: NSLayoutConstraint!
    
    //仕様データ
    var defaultNum = 5 //初期表示するアイテム欄の数
    var addItemNum = 5 //追加ボタンを押した時に、一度に追加するアイテム欄の数
    var itemColumnNum = 0 //現在表示しているアイテム欄の数
    var maxItemNum = 30 //アイテム欄の最大数
    
    //textFieldの入力内容を一時保管するための変数・配列
    var keepText: TextFieldKeepData!    //入力データを保管する辞書配列
    var editingIndex: Int?           //入力中のセルインデックスをキープする
    var editingTextField: UITextField?  //入力中のtextFieldオブジェクトをキープする

//    var titleArray: [String] = []
    
    //ViewControllerから画面遷移時に送られるデータ
    var segue: String = ""
    var dataId: String = ""
    var dataTitle: String = ""
    var dataItems: [String] = []
    var titleArray: [String] = []   //未使用データ
    
    //データベースに保存する新しいデータ
    var newTitleText: String = ""
    var newItemArray: [String] = []
    
    //ネットワークに繋がっているか
    var networkFlag: Bool!
    
    deinit {
        print("Edit deinit")
    }

    @IBAction func tapSaveButton(_ sender: Any) {
        print(#function)
        
        //textFieldに入力中のデータを一時保管配列に追加
        keepTextField()
        
        //タイトルの読み取り
        newTitleText = ""
        if let text = titleTextField.text{
            newTitleText = text
        }
        
        //アイテムの読み取り
        newItemArray = []
        print(itemColumnNum)
        for i in 0..<itemColumnNum {
            print(i)
            if let text = keepText.keepArray[i] {
                newItemArray.append(text)
            }
        }
        
        print(newTitleText)
        print(newItemArray)
        
        //入力チェック
        guard check() else {return}
        
        /*
        do{
            //データベースに保存
            try? saveToDatabase()
        }catch{
            print("エラー！！！！！")
        }
        */
        
        saveToDatabase()
        
        //抽選画面へ戻る
        if segue == "new"{
            let vc = self.presentingViewController as! ViewController
            vc.nowDataIndex = 0
        }
        self.dismiss(animated: true, completion: nil)
        
    }

    @IBAction func tapCloseButton(_ sender: Any) {
        print(#function)
        self.dismiss(animated: true, completion: nil)
    }
    
    func saveToDatabase(){
        print(#function)
        
        //新規登録時
        if dataId == "" {
            print("新規登録")
            //保存先の取得
            let dataRef = Database.database().reference().child(Const.DataPath).childByAutoId()
            dataId = dataRef.key
            print(dataId)
            //新規登録
            dataRef.setValue(
                ["title": newTitleText, "items": newItemArray],
                withCompletionBlock: {(error, dataRef) in
                    if let error = error{
                        print(error)
                    }
            })
        //編集時
        }else{
            //保存先の取得
            let dataRef = Database.database().reference().child(Const.DataPath).child(dataId)
            //上書き
            print("上書き保存")
            print(dataRef.key)
            dataRef.updateChildValues(
                ["title": newTitleText, "items": newItemArray],
                withCompletionBlock: {(error, dataRef) in
                    if let error = error{
                        print(error)
                    }
            })
        }
        if !networkFlag {
            reserveRealm()
        }
    }

    func check() -> Bool{
        var returnFlag = true
        var error: [String] = []
        if newTitleText == "" {
            print("エラー：　タイトルが空白")
            error.append("タイトルを入力してください。")
            returnFlag = false
        }
        
        if newItemArray.count < 2 {
            print("エラー：　アイテムが少ない")
            error.append("アイテムは２つ以上登録してください。")
            returnFlag = false
        }
        
        if error != [] {
            showAlert(error)
        }
        
        return returnFlag
    }
    
    func showAlert(_ alerts: [String]){
        let title = "入力が間違っています"
        var message = ""
        for text in alerts {
            message += text
        }
        
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("セルを操作中：\(indexPath.row)")
    }
    
    //入力中のセルインデックスとテキストフィールドオブジェクトをクラス変数に一時保管する
    func textFieldDidBeginEditing(_ textField: UITextField) {
        print("入力開始時に呼び出し")
        //入力されたtextFieldが存在するセルを取得して、セルが存在するindexを取得
        //UITextFieldを含むUITableViewCellのIndexPathを取得
        if let cell = textField.superview?.superview as? editItemTableViewCell,
            let indexPath = tableView.indexPath(for: cell){
            editingIndex = indexPath.row
            editingTextField = textField
            print(editingIndex!)
        }
    }
    
    //入力終了時
    func textFieldDidEndEditing(_ textField:UITextField){
        print("入力完了後に呼び出し")
        keepTextField()
    }
    
    //一時保管の配列にデータを追加・更新
    func keepTextField(){
        keepText.update(key: editingIndex, string: editingTextField?.text)
        print(keepText.keepArray)
    }

    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any] else {
            return
        }
        guard let keyboardInfo = userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue else {
            return
        }
        
        let keyboardSize = keyboardInfo.cgRectValue.height
        print("キーボードの高さ")
        print(keyboardSize)
        constantTableViewBottom.constant = CGFloat(keyboardSize + 40)
    }
    
    @objc private func keyboardWillHide(_ notification: Notification){
        constantTableViewBottom.constant = 20
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false
        
        //セル情報をnibから取得
        let itemCellNib = UINib(nibName: "editItemTableViewCell", bundle: nil)
        tableView.register(itemCellNib, forCellReuseIdentifier: "itemCell")
        
        let addCellNib = UINib(nibName: "editAddTableViewCell", bundle: nil)
        tableView.register(addCellNib, forCellReuseIdentifier: "addCell")
        
        
        //キーボードの高さに合わせてtableViewの位置を調整
        //constantTableViewBottom.constant = keyboardHeight
        
        //オンライン状態を監視
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {
                print("Connected")
                self.networkFlag = true
            } else {
                print("Not connected")
                self.networkFlag = false
            }
        })
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("edit appear")
    
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )

        
        //キーボードの高さに合わせてtableViewの位置を調整
        //let keyboardHeight = KeyboardService.keyboardHeight()
        //print("keyboardの高さ：\(keyboardHeight)")
        //constantTableViewBottom.constant = keyboardHeight + 40
        /*メモ：
         viewWillAppearメソッドからこれを呼び出します。
         viewDidLoadで呼び出されるべきではありません。
         正しい値はビューが配置されているかどうかに依存します。
         
         keyboardHeight()で取得できる値には変換欄が含まれない？
         */

        titleTextField.text = dataTitle
        keepText = TextFieldKeepData()
        for (index, string) in dataItems.enumerated() {
            keepText.update(key: index, string: string)
        }
        
        print(keepText.keepArray.count)
        print(keepText.keepArray)
        tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print(#function)
        super.viewWillDisappear(animated)
        
        self.view.endEditing(true)
        
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillShowNotification,
            object: self.view.window
        )
        
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillHideNotification,
            object: self.view.window
        )
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2    //section0:アイテム入力欄、section1:追加ボタン
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return itemColumnNum
        }else{
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            print("indexPath.row:\(indexPath.row)")
            let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell") as! editItemTableViewCell
            
            //プレスホルダーを設定
            if indexPath.row == 0 {
                cell.itemTextField.placeholder = "３０文字まで"
            }else{
                cell.itemTextField.placeholder = ""
            }
            //テキストを設定
            if let text = keepText.keepArray[indexPath.row] {
                cell.itemTextField.text = text
            }else{
                cell.itemTextField.text = ""
            }
            
            cell.itemTextField.delegate = self
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "addCell", for: indexPath) as! editAddTableViewCell
            cell.addButton.addTarget(self, action:#selector(handleTapAddButton), for: .touchUpInside)
            if itemColumnNum >= maxItemNum {
                cell.addButton.isEnabled = false
            }
            
            return cell
        }
    }
    
    @objc func handleTapAddButton(){
        keepTextField()
        
        if itemColumnNum >= maxItemNum {
            return
        }
        
        itemColumnNum += addItemNum
        
        if itemColumnNum > maxItemNum {
            itemColumnNum = maxItemNum
        }
        
        tableView.reloadData()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    func reserveRealm(){
        guard global_offLineServiceFlag else{return}
        print("Realmに予備保存")
        let data = RealmData()
        data.id = dataId
        data.title = newTitleText
        for value in newItemArray{
            let subData = RealmItemData()
            subData.item = value
            data.items.append(subData)
        }
        
        let realm = try! Realm()
        try! realm.write {
            realm.add(data)
        }
        
        let keep = realm.objects(RealmData.self)
        print(keep)
    }

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
