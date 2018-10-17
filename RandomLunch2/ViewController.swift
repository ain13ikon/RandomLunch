//
//  ViewController.swift
//  RandomLunch2
//
//  Created by きたむら on 2018/10/15.
//  Copyright © 2018年 ain13ikon. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var dataId: String = ""
    var dataTitle: String = ""
    var dataItems: [String] = []
    
    var itemAddNum = 5
    
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
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
    
    /*
    func adjustDataItems() -> [String]{
        var items = dataItems
        var loopNum = dataItems.count % itemAddNum
        print(loopNum)
        if loopNum != 0 {
            loopNum = itemAddNum - loopNum
        }
        for _ in 0..<loopNum {
            items.append("")
        }
        print(items)
        return items
    }
    */
    
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
        }
    }

    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tableView.delegate = self
        tableView.dataSource = self
        
        //セルのnib取得
        let nib = UINib(nibName: "mainItemTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "itemCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print(#function)
        print(dataTitle)
        print(dataItems)
        
        titleLabel.text = dataTitle
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as! mainItemTableViewCell
        cell.itemLabel.text = "・" + dataItems[indexPath.row]
        
        return cell
    }


}




private var maxLengths = [UITextField: Int]()

extension UITextField {
    
    @IBInspectable var maxLength: Int {
        get {
            guard let length = maxLengths[self] else {
                return Int.max
            }
            
            return length
        }
        set {
            maxLengths[self] = newValue
            addTarget(self, action: #selector(limitLength), for: .editingChanged)
        }
    }
    
    @objc func limitLength(textField: UITextField) {
        guard let prospectiveText = textField.text, prospectiveText.count > maxLength else {
            return
        }
        
        let selection = selectedTextRange
        let maxCharIndex = prospectiveText.index(prospectiveText.startIndex, offsetBy: maxLength)
        
        //#if swift(>=4.0)
        text = String(prospectiveText[..<maxCharIndex])
        /*
        #else
        text = prospectiveText.substring(to: maxCharIndex)
        #endif
        */
        
        selectedTextRange = selection
    }
    
}
