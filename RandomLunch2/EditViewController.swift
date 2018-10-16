//
//  EditViewController.swift
//  RandomLunch2
//
//  Created by きたむら on 2018/10/15.
//  Copyright © 2018年 ain13ikon. All rights reserved.
//

import UIKit

class EditViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var titleTextField: UITextField!
    
    
    var itemNum = 5 //初期表示するアイテム欄の数
    var addItemNum = 5 //追加ボタンを押した時に、一度に追加するアイテム欄の数
    var maxItemNum = 30 //アイテム欄の最大数
    var cells: [editItemTableViewCell] = []
    var countI = 0
    
    @IBAction func tapSaveButton(_ sender: Any) {
        print(#function)
        
        var newTitleText: String = ""
        if let text = titleTextField.text{
            newTitleText = text
        }
        
        var newItemArray: [String] = []
        print(itemNum)
        for i in 0..<itemNum {
            print(i)
            let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) as! editItemTableViewCell
            if let text = cell.itemTextField.text {
                if text != ""{
                    newItemArray.append(text)
                }
            }
        }
        print(newTitleText)
        print(newItemArray)
        
        guard check(title: newTitleText, items: newItemArray) else {return}
        
        print("保存する")
        
    }

    @IBAction func tapCloseButton(_ sender: Any) {
        print(#function)
        self.dismiss(animated: true, completion: nil)
    }
    
    func check(title: String, items: [String]) -> Bool{
        var returnFlag = true
        if title == "" {
            print("エラー：　タイトルが空白")
            returnFlag = false
        }
        
        if items.count < 2 {
            print("エラー：　アイテムが少ない")
            returnFlag = false
        }
        return returnFlag
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
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2    //section0:アイテム入力欄、section1:追加ボタン
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return itemNum
        }else{
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            countI += 1
            print(countI)
            let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as! editItemTableViewCell
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "addCell", for: indexPath) as! editAddTableViewCell
            cell.addButton.addTarget(self, action:#selector(handleTapAddButton), for: .touchUpInside)
            if itemNum >= maxItemNum {
                cell.addButton.isEnabled = false
            }
            
            return cell
        }
    }
    
    @objc func handleTapAddButton(){
        if itemNum >= maxItemNum {
            return
        }
        
        itemNum += addItemNum
        
        if itemNum > maxItemNum {
            itemNum = maxItemNum
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
