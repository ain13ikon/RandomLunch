//
//  ViewController.swift
//  RandomLunch2
//
//  Created by きたむら on 2018/10/15.
//  Copyright © 2018年 ain13ikon. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    

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

    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tableView.delegate = self
        tableView.dataSource = self
        
        //セルのnib取得
        let nib = UINib(nibName: "mainItemTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "itemCell")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as! mainItemTableViewCell
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
