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
    @IBOutlet weak var titleErrorLabel: UILabel!
    @IBOutlet weak var itemErrorLabel: UILabel!
    
    //仕様データ
    var defaultNum = 5 //初期表示するアイテム欄の数
    var addItemNum = 5 //追加ボタンを押した時に、一度に追加するアイテム欄の数
    var itemColumnNum = 0 //現在表示しているアイテム欄の数
    var maxItemNum = 30 //アイテム欄の最大数
    
    //textFieldの入力内容を一時保管するための変数・配列
    var keepText: TextFieldKeepData!    //入力データを保管する辞書配列
    var editingIndex: Int?           //入力中のセルインデックスをキープする
    var editingTextField: UITextField?  //入力中のtextFieldオブジェクトをキープする
    
    //ViewControllerから画面遷移時に送られるデータ
    var segue: String = ""
    var dataId: String = ""
    var dataTitle: String = ""
    var dataItems: [String] = []
    var titleArray: [String] = []
    
    //データベースに保存する新しいデータ
    var newTitleText: String = ""
    var newItemArray: [String] = []
    
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

        //入力チェック
        guard check() else {return}
        
        //データベースに保存
        saveToDatabase()
        
        //抽選画面へ戻る
        let vc = self.presentingViewController as! ViewController
        if segue == "new"{
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
        
        //保存予定のデータを未保存配列に入れる
        let time = Date().timeIntervalSince1970
        let unsavedData = UnsavedData(time, newTitleText)
        print(unsavedData)
        global_unsavedDatas.append(unsavedData)
        
        //新規登録時
        if dataId == "" {
            print("新規登録")
            //保存先の取得
            let dataRef = Database.database().reference().child(Const.DataPath).childByAutoId()
            dataId = dataRef.key
            print(dataId)
            //新規登録
            dataRef.setValue(
                ["title": newTitleText, "items": newItemArray], withCompletionBlock: {_,_ in
                    print("登録完了")
                    print(self.newTitleText)
                    //未保存配列から削除
                    for (index, data) in global_unsavedDatas.enumerated(){
                        if data.time == time {
                            global_unsavedDatas.remove(at: index)
                        }
                    }
                    print(global_unsavedDatas)
            })
            
        //編集時
        }else{
            //保存先の取得
            let dataRef = Database.database().reference().child(Const.DataPath).child(dataId)
            //上書き
            print("上書き保存")
            dataRef.updateChildValues(
                ["title": newTitleText, "items": newItemArray],
                withCompletionBlock: {_,_ in
                    print("登録完了")
                    print(self.newTitleText)
                    for (index, data) in global_unsavedDatas.enumerated(){
                        if data.time == time {
                            global_unsavedDatas.remove(at: index)
                        }
                    }
                    print(global_unsavedDatas)
            })
        }
    }

    func check() -> Bool{
        var returnFlag = true
        var errors: [String: [String]] = ["title": [], "item": []]
        //タイトルが空白でないか
        if newTitleText == "" {
            errors["title"]?.append("※タイトルを入力してください。")
            //error.append()
            returnFlag = false
        }
        //タイトルが重複していないか（編集時に元データから変更されていない場合はOk）
        if titleArray.contains(newTitleText) && newTitleText != dataTitle {
            errors["title"]?.append("※タイトルが重複しています。変更してください。")
            returnFlag = false
        }
        //アイテムが少なすぎないか
        if newItemArray.count < 2 {
            errors["item"]?.append("※アイテムは２つ以上登録してください。")
            returnFlag = false
        }
        
        //エラーを表示
        showError(errors)
        
        return returnFlag
    }
    
    func showError(_ errors: [String: [String]]){
        var titleErrorText = ""
        for value in errors["title"]!{
            print(value)
            titleErrorText += value
        }
        
        var itemErrorText = ""
        for value in errors["item"]!{
            print(value)
            itemErrorText += value
        }
        
        titleErrorLabel.text = titleErrorText
        itemErrorLabel.text = itemErrorText
        if titleErrorText == ""{
            titleErrorLabel.textColor = UIColor.black
        }else{
            titleErrorLabel.textColor = UIColor.red
        }
        if itemErrorText == ""{
            itemErrorLabel.textColor = UIColor.black
        }else{
            itemErrorLabel.textColor = UIColor.red
        }
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
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("edit appear")
        print(titleArray)
        
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

        titleTextField.text = dataTitle
        titleErrorLabel.text = ""
        itemErrorLabel.text = ""
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
    
    

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    /*
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
     */
    


}
