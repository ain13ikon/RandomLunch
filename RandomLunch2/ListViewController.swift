//
//  ListViewController.swift
//  RandomLunch2
//
//  Created by きたむら on 2018/10/15.
//  Copyright © 2018年 ain13ikon. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var unsavedLabel: UILabel!
    
    var dataArray: [Data] = []              //全てのデータ
    var displayedDataArray: [Data] = []     //表示するデータ(検索にヒットしたデータ)
    
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
            }else if partialMatchInArray(searchWord, data_.items!){
                resultArray.append(data_)
            }
        }
        
        for data_ in resultArray {
            print(data_.title!)
        }
        
        return resultArray
    }

    //配列に含まれるか（部分一致）
    func partialMatchInArray(_ keyword: String, _ array: [String]) -> Bool{
        for value in array{
            if value.contains(keyword){
                return true
            }
        }
        return false
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
        print("searchBar.text: \(searchBar.text!)")
        print("searchText: \(searchText)")
        displayedDataArray = search(searchBar.text!)
        tableView.reloadData()
    }
    
    //入力途中に呼ばれる
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        print("入力途中")
        print("text: \(text)")
        print("searchBar.text: \(searchBar.text!)")
        var searchText = searchBar.text! + text
        if text == "" {
            let kari = searchText.dropLast()
            print("kari: \(kari)")
            searchText = String(searchText.dropLast())
        }
        print("searchText: \(searchText)")
        displayedDataArray = search(searchText)
        tableView.reloadData()
        return true
    }
    
    // 検索キーが押された時に呼ばれる
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
        //searchBar.showsCancelButton = false
        print(searchBar.text!)
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
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshControlValueChanged(sender:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
        //tableView.addSubview(refreshControl)
        
        
        //セルのnib取得
        let nib = UINib(nibName: "listTitleTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "titleCell")
        
        unsavedLabel.textColor = UIColor.orange
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.view.endEditing(true)
    }
    
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedDataArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "titleCell", for: indexPath) as! listTitleTableViewCell
        //文字サイズを調整して全表示にする
        cell.titleLabel.adjustsFontSizeToFitWidth = true
        cell.titleLabel.text = displayedDataArray[indexPath.row].title!
        
        //未保存のタイトルはオレンジ色で表示する
        if global_unsavedTitleArray.contains(dataArray[indexPath.row].title!){
            cell.titleLabel.textColor = UIColor.orange
        }else{
            cell.titleLabel.textColor = UIColor.black
        }
        //未保存データがある場合に注釈を表示する
        if global_unsavedTitleArray.count > 0 {
            unsavedLabel.isHidden = false
        }else{
            unsavedLabel.isHidden = true
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath.row)
        
        let vc = self.presentingViewController as! ViewController
        vc.nowDataIndex = dataArray.index(of: displayedDataArray[indexPath.row])!
        print(vc.nowDataIndex)
        self.dismiss(animated: true, completion: nil)
    }

    @objc func refreshControlValueChanged(sender: UIRefreshControl) {
        tableView.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            sender.endRefreshing()
        })
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
