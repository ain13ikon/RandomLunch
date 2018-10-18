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

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var dataArray: [Data] = []
    var displayedDataArray: [Data] = []
    //var searchWord: String!
    
    deinit {
        print("List deinit")
    }

    @IBAction func tapCloseButton(_ sender: Any) {
        print(#function)
        self.dismiss(animated: true, completion: nil)
    }
    
    func search(_ searchWord: String) -> [Data]{
        print("search: \(searchWord)")
        
        if searchWord == "" {
            return dataArray
        }

        var resultArray: [Data] = []
        for data_ in dataArray {
            if data_.title!.contains(searchWord) {
                resultArray.append(data_)
            }else if data_.items!.contains(searchWord) {
                resultArray.append(data_)
            }
        }
        
        for data_ in resultArray {
            print(data_.title!)
        }
        
        return resultArray
    }

    // 検索欄入力開始前に呼ばれる
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        print("検索欄の表示変更")
        searchBar.showsCancelButton = true
        return true
    }

    //入力確定後に呼ばれる
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print("入力確定")
        print(searchBar.text!)
        displayedDataArray = search(searchBar.text!)
        tableView.reloadData()
    }
    
    //入力途中に呼ばれる
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        print("入力途中")
        displayedDataArray = search(searchBar.text! + text)
        tableView.reloadData()
        return true
    }
    
    // 検索キーが押された時に呼ばれる
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
        searchBar.showsCancelButton = true
        displayedDataArray = search(searchBar.text!)
        tableView.reloadData()
    }
    
    // キャンセルボタンが押された時に呼ばれる
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        self.view.endEditing(true)
        searchBar.text = ""
        displayedDataArray = search("")
        tableView.reloadData()
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        
        //セルのnib取得
        let nib = UINib(nibName: "listTitleTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "titleCell")
        
    }
    
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedDataArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "titleCell", for: indexPath) as! listTitleTableViewCell
        //文字サイズを調整して全表示にする
        cell.titleLabel.adjustsFontSizeToFitWidth = true
        cell.titleLabel.text = displayedDataArray[indexPath.row].title!
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath.row)
        
        let vc = self.presentingViewController as! ViewController
        //vc.dataId = dataArray[indexPath.row].id!
        //vc.dataTitle = dataArray[indexPath.row].title!
        //vc.dataItems = dataArray[indexPath.row].items!
        
        vc.nowDataIndex = dataArray.index(of: displayedDataArray[indexPath.row])!
        print(vc.nowDataIndex)
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
