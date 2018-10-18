//
//  ListViewController.swift
//  RandomLunch2
//
//  Created by きたむら on 2018/10/15.
//  Copyright © 2018年 ain13ikon. All rights reserved.
//

import UIKit
//import Firebase
//import FirebaseDatabase

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var dataArray: [Data] = []
    
    deinit {
        print("List deinit")
    }

    @IBAction func tapCloseButton(_ sender: Any) {
        print(#function)
        self.dismiss(animated: true, completion: nil)
    }
    
    func sarch(){
        var resultArray: [Data] = []
        let sarchWord = "あ"
        
        for data_ in dataArray {
            if data_.title!.contains(sarchWord) {
                resultArray.append(data_)
            }else if data_.items!.contains(sarchWord) {
                resultArray.append(data_)
            }
        }
        
        for data_ in resultArray {
            print(data_.title)
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        tableView.delegate = self
        tableView.dataSource = self
        
        //セルのnib取得
        let nib = UINib(nibName: "listTitleTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "titleCell")
        
        sarch()
    }
    
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "titleCell", for: indexPath) as! listTitleTableViewCell
        //文字サイズを調整して全表示にする
        cell.titleLabel.adjustsFontSizeToFitWidth = true
        cell.titleLabel.text = dataArray[indexPath.row].title!
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath.row)
        
        let vc = self.presentingViewController as! ViewController
        //vc.dataId = dataArray[indexPath.row].id!
        //vc.dataTitle = dataArray[indexPath.row].title!
        //vc.dataItems = dataArray[indexPath.row].items!
        
        vc.nowDataIndex = indexPath.row
        self.dismiss(animated: true, completion: nil)
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
