import UIKit

protocol TableViewListManagable: class {
    func updateTableViewList()
    func deleteCell()
    func moveCellToTop()
}

class MemoListTableViewController: UITableViewController {
    private let enrollButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationBar()
        UserDefaults.standard.set(false, forKey: UserDefaultsKeys.isCellSelected.rawValue)
        tableView.register(MemoListTableViewCell.self, forCellReuseIdentifier: "MemoCell")
    }
    
    private func configureNavigationBar() {
        navigationItem.title = "메모"
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: enrollButton)
        enrollButton.setImage(UIImage(systemName: "plus"), for: .normal)
        enrollButton.addTarget(self, action: #selector(createMemo), for: .touchUpInside)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CoreDataSingleton.shared.memoData.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let memo = CoreDataSingleton.shared.memoData[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MemoCell") as? MemoListTableViewCell else {
            return UITableViewCell()
        }
    
        cell.receiveLabelsText(memo: memo)
        return cell
    }
    
    @objc func createMemo(sender: UIButton) {
        do {
            try CoreDataSingleton.shared.save(title: "", body: "")
            let memoContentsViewController = MemoContentsViewController()
            let memoContentsNavigationViewController = UINavigationController(rootViewController: memoContentsViewController)
            memoContentsViewController.receiveText(memo: CoreDataSingleton.shared.memoData[0])
            
            tableView.reloadData()
            self.splitViewController?.showDetailViewController(memoContentsNavigationViewController, sender: nil)
            
            UserDefaults.standard.set(true, forKey: UserDefaultsKeys.isCellSelected.rawValue)
        } catch {
            print(MemoAppError.system.message)
        }
    }
}

// MARK: UITableViewDelegate
extension MemoListTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let memoContentsViewController = MemoContentsViewController()
        let memoContentsNavigationViewController = UINavigationController(rootViewController: memoContentsViewController)
        memoContentsViewController.delegate = self
        
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.isCellSelected.rawValue)
        UserDefaults.standard.set(indexPath.row, forKey: UserDefaultsKeys.selectedMemoIndexPathRow.rawValue)
        
        memoContentsViewController.receiveText(memo: CoreDataSingleton.shared.memoData[indexPath.row])
        self.splitViewController?.showDetailViewController(memoContentsNavigationViewController, sender: nil)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let memoContentsView = MemoContentsViewController()
        if editingStyle == .delete {
            let selectedMemoIndexPathRow = UserDefaults.standard.integer(forKey: UserDefaultsKeys.selectedMemoIndexPathRow.rawValue)
            
            do {
                try CoreDataSingleton.shared.delete(object: CoreDataSingleton.shared.memoData[selectedMemoIndexPathRow])
                CoreDataSingleton.shared.memoData.remove(at: selectedMemoIndexPathRow)
                UserDefaults.standard.set(0, forKey: UserDefaultsKeys.selectedMemoIndexPathRow.rawValue)
                tableView.deleteRows(at: [indexPath], with: .fade)
                
                memoContentsView.receiveText(memo: CoreDataSingleton.shared.memoData[0])
                
                if splitViewController?.traitCollection.horizontalSizeClass == .regular {
                    self.splitViewController?.showDetailViewController(memoContentsView, sender: nil)
                }
            } catch {
                print(MemoAppError.system.message)
            }
        }
    }
}

// MARK: Alert
extension MemoListTableViewController {
    private func showAlertMessage(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: UIAlertController.Style.alert)
        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
}

// MARK: TableViewListManagable
extension MemoListTableViewController: TableViewListManagable {
    func updateTableViewList() {
        tableView.reloadData()
    }
    
    func deleteCell() {
        let selectedMemoIndexPathRow = UserDefaults.standard.integer(forKey: UserDefaultsKeys.selectedMemoIndexPathRow.rawValue)
        let indexPath = IndexPath(row: selectedMemoIndexPathRow, section: 0)
        tableView.deleteRows(at: [indexPath], with: .fade)
        tableView.reloadData()
    }
    
    func moveCellToTop() {
        let selectedMemoIndexPathRow = UserDefaults.standard.integer(forKey: UserDefaultsKeys.selectedMemoIndexPathRow.rawValue)
        let indexPath = IndexPath(row: selectedMemoIndexPathRow, section: 0)
        let firstIndexPath = IndexPath(item: 0, section: 0)
        
        let memo = CoreDataSingleton.shared.memoData.remove(at: selectedMemoIndexPathRow)
        CoreDataSingleton.shared.memoData.insert(memo, at: 0)
        
        self.tableView.moveRow(at: indexPath, to: firstIndexPath)
        UserDefaults.standard.set(0, forKey: UserDefaultsKeys.selectedMemoIndexPathRow.rawValue)
    }
}
