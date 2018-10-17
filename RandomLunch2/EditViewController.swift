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

class EditViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var titleTextField: UITextField!
    
    @IBOutlet weak var constantTableViewBottom: NSLayoutConstraint!
    
    var defaultNum = 5 //初期表示するアイテム欄の数
    var addItemNum = 5 //追加ボタンを押した時に、一度に追加するアイテム欄の数
    var displayNum = 0 //現在表示しているアイテム欄の数
    var maxItemNum = 30 //アイテム欄の最大数
    var cells: [editItemTableViewCell] = []
    
    var keepText: TextFieldKeepData!
    var titleArray: [String] = []
    
    var segue: String = ""
    var dataId: String = ""
    var dataTitle: String = ""
    var dataItems: [String] = []
    
    var newTitleText: String = ""
    var newItemArray: [String] = []
    
    var keyboardHeight: CGFloat = 260   //仮
    
    var editingIndex: Int = 0   //入力中のセルインデックスをキープする
    var editingTextField: UITextField?
    
    deinit {
        print("Edit deinit")
    }

    @IBAction func tapSaveButton(_ sender: Any) {
        print(#function)
        
        keepTextField()
        
        //タイトルの読み取り
        newTitleText = ""
        if let text = titleTextField.text{
            newTitleText = text
        }
        
        //アイテムの読み取り
        newItemArray = []
        print(displayNum)
        for i in 0..<displayNum {
            print(i)
            if let text = keepText.keepArray[i] {
                newItemArray.append(text)
            }
        }
        
        print(newTitleText)
        print(newItemArray)
        
        //入力チェック
        guard check() else {return}
        
        //データベースに保存
        saveToDatabase()
        
        //抽選画面へ戻る
        self.dismiss(animated: true, completion: nil)
        
    }

    @IBAction func tapCloseButton(_ sender: Any) {
        print(#function)
        self.dismiss(animated: true, completion: nil)
    }
    
    func saveToDatabase(){
        print(#function)
        //保存先の取得
        let dataRef = Database.database().reference().child(Const.DataPath)
        if dataId == "" {
            print("新規登録")
            //新規登録
            dataRef.childByAutoId().setValue(["title": newTitleText, "items": newItemArray])
        }else{
            //上書き
            print("上書き保存")
            dataRef.child(dataId).updateChildValues(["title": newTitleText, "items": newItemArray])
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
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        print("入力開始時に呼び出し")
        //入力されたtextFieldが存在するセルを取得して、セルが存在するindexを取得
        if let cell = textField.superview?.superview as? editItemTableViewCell,
            let indexPath = tableView.indexPath(for: cell){
            editingIndex = indexPath.row
            editingTextField = textField
            print(editingIndex)
        }
    }
    
    func keepTextField(){
        keepText.update(index: editingIndex, string: editingTextField?.text ?? "")
        print(keepText.keepArray)
    }

    func textFieldDidEndEditing(_ textField:UITextField){
        print("入力完了後に呼び出し")
        keepTextField()
    }
    
    
    /*
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
        constantTableViewBottom.constant = CGFloat(keyboardSize)
    }
    */
    
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
        constantTableViewBottom.constant = keyboardHeight
        /*
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        */
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("edit appear")
        titleTextField.text = dataTitle
        keepText = TextFieldKeepData()
        for (index, string) in dataItems.enumerated() {
            keepText.update(index: index, string: string)
        }
        
        print(keepText.keepArray.count)
        print(keepText.keepArray)
        tableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2    //section0:アイテム入力欄、section1:追加ボタン
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return displayNum
        }else{
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            print("indexPath.row:\(indexPath.row)")
            let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell") as! editItemTableViewCell
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
            if displayNum >= maxItemNum {
                cell.addButton.isEnabled = false
            }
            
            return cell
        }
    }
    
    @objc func handleTapAddButton(){
        keepTextField()
        
        if displayNum >= maxItemNum {
            return
        }
        
        displayNum += addItemNum
        
        if displayNum > maxItemNum {
            displayNum = maxItemNum
        }
        
        tableView.reloadData()
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
