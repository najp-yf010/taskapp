//
//  ViewController.swift
//  taskapp
//
//  Created by  NSPC358admin on 2023/11/24.
//

import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate {
    @IBOutlet weak var searchField: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    // Realmインスタンスを取得する
    let realm = try! Realm()
    
    var searchResult = [String]()
    
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.fillerRowHeight = UITableView.automaticDimension
        tableView.delegate = self
        tableView.dataSource = self
        searchField.delegate = self
        
        let tapGR: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
                tapGR.cancelsTouchesInView = false
                self.view.addGestureRecognizer(tapGR)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    @objc func dismissKeyboard() {
            self.view.endEditing(true)
        }
    
    @objc func keyboardWillShow(notification: NSNotification) {
            if !searchField.isFirstResponder {
                return
            }
        
            if self.view.frame.origin.y == 0 {
                if let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                    self.view.frame.origin.y -= keyboardRect.height
                }
            }
        }
        
        @objc func keyboardWillHide(notification: NSNotification) {
            if self.view.frame.origin.y != 0 {
                self.view.frame.origin.y = 0
            }
        }
    
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
        if let word = searchBar.text {
            print(word)
        }
        
        ///-----------------------
        
        searchField.endEditing(true)
        
        //検索結果配列を空にする。
        searchResult.removeAll()
        
        if(searchField.text == "") {
            //検索文字列が空の場合はすべてを表示する。
            taskArray = realm.objects(Task.self)
            
        } else {
            //検索文字列を含むデータを検索結果配列に追加する。
            taskArray = realm.objects(Task.self).where(){
                $0.category == searchField.text!
            }
        }
        
        //テーブルを再読み込みする。
        tableView.reloadData()
        
        ///-----------------------
    }
    
    // データの数（＝セルの数）を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskArray.count
    }
    
    // 各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 再利用可能な cell を得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        // Cellに値を設定する  --- ここから ---
                let task = taskArray[indexPath.row]
                cell.textLabel?.text = task.title

                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm"

                let dateString:String = formatter.string(from: task.date)
                cell.detailTextLabel?.text = dateString
        
                // --- ここまで追加 ---
        
        return cell
    }
    
    // 各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cellSegue", sender: nil)
    }
    
    // セルの削除が可能なことを伝えるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    // Delete ボタンが押された時に呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
                    // 削除するタスクを取得する
                    let task = self.taskArray[indexPath.row]

                    // ローカル通知をキャンセルする
                    let center = UNUserNotificationCenter.current()
                    center.removePendingNotificationRequests(withIdentifiers: [String(task.id.stringValue)])

                    // データベースから削除する
                    try! realm.write {
                        self.realm.delete(task)
                        tableView.deleteRows(at: [indexPath], with: .fade)
                    }

                    // 未通知のローカル通知一覧をログ出力
                    center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                        for request in requests {
                            print("/---------------")
                            print(request)
                            print("---------------/")
                        }
                    }
                }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
            let inputViewController:InputViewController = segue.destination as! InputViewController

            if segue.identifier == "cellSegue" {
                let indexPath = self.tableView.indexPathForSelectedRow
                inputViewController.task = taskArray[indexPath!.row]
            } else {
                inputViewController.task = Task()
            }
        }
    
    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            tableView.reloadData()
        }
    
    
    
}
