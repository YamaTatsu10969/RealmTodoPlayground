//
//  TodoListViewController.swift
//  RealmTodoPlayground
//
//  Created by yamamototatsuya on 2019/11/13.
//  Copyright © 2019 yamamototatsuya. All rights reserved.
//

import UIKit
import RealmSwift

class TodoListViewController: UIViewController {
    
    private var realm: Realm!
    private var todoList: Results<TodoItem>!
    private var token: NotificationToken!
    @IBOutlet weak var tableView: UITableView!
    
    deinit {
        token.invalidate()
    }
    
    // MARK: LifeSycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Todoリスト"
        setupRealm()
        setupTableView()
        setupNavigationBar()
        /// N をキーボードから押したら ダイアログが出る！！
        addKeyCommand(UIKeyCommand(title: "test", action: #selector(addButtonTapped(_:)), input: "N"))
    }
}

// MARK: Setup
private extension TodoListViewController {
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func setupRealm() {
        // RealmのTodoList を取得し、更新を監視
        realm = try! Realm()
        todoList = realm.objects(TodoItem.self)
        token = todoList.observe{ [weak self] _ in
            self?.tableView.reloadData()
        }
    }
    
    func setupNavigationBar() {
        let rightAddButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped(_:)))
        navigationItem.setRightBarButton(rightAddButtonItem, animated: true)
    }
    
    @objc func addButtonTapped(_ sender: Any) {
        let dialog = UIAlertController(title: "新規Todo", message: "", preferredStyle: .alert)
        dialog.addTextField(configurationHandler: nil)
        dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            if let text = dialog.textFields![0].text, !text.isEmpty {
                self.addTodoItem(title: text)
            }
        }))
        present(dialog, animated: true)
    }

}

private extension TodoListViewController {
    /// 追加処理
    func addTodoItem(title: String) {
        try! realm.write {
            realm.add(TodoItem(value: ["title": title]))
        }
    }
    /// 消去
    func deleteTodoItem(at index: Int) {
        try! realm.write {
            // オブジェクトそのまま送るだけで削除できるのか！すごい。
            realm.delete(todoList[index])
        }
    }
    
    func updateTodoItem(at index: Int, title: String) {
        // クエリの発行の仕方 →　https://swift.hiros-dot.net/?p=632#toc5
        // これも参考になる →　https://dev.classmethod.jp/smartphone/realmswift-introduction/
        // 公式ドキュメント　→　https://realm.io/docs/swift/latest/#queries
        let result = realm.objects(TodoItem.self).filter("title == '\(todoList[index].title)'")
        try! realm.write {
            result.setValue(title, forKey: "title")
        }
    }

}

extension TodoListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todoList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        cell.textLabel?.text = todoList[indexPath.row].title
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        deleteTodoItem(at: indexPath.row)
    }
}

extension TodoListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let dialog = UIAlertController(title: "Todo更新", message: "", preferredStyle: .alert)
        dialog.addTextField { textField in
            textField.text = self.todoList[indexPath.row].title
        }
        dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            if let text = dialog.textFields![0].text, !text.isEmpty {
                self.updateTodoItem(at: indexPath.row, title: text)
            }
        }))
        present(dialog, animated: true)
    }
}
