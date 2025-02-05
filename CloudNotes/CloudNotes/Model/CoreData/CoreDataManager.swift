//
//  CoreDataManager.swift
//  CloudNotes
//
//  Created by Kim Do hyung on 2021/09/14.
//

import Foundation
import CoreData

final class CoreDataManager {
    
    static var shared = CoreDataManager ()
    private let entitiyName = "MemoData"
    
    private var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CoreDataModel")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("\(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    private var context: NSManagedObjectContext {
        return self.persistentContainer.viewContext
    }
    
    private init() { }
    
    func fetchLastMemo() -> Memo {
        var memo = Memo(title: "", body: "", date: 0, identifier: nil)
        let fetchRequest: NSFetchRequest<MemoData> = MemoData.fetchRequest()
        
        do {
            let fetchResult = try self.context.fetch(fetchRequest)
            
            if let lastMemo = fetchResult.last, let title = lastMemo.title, let body = lastMemo.body {

                let identifier = lastMemo.objectID
                let date = lastMemo.date
                
                memo = Memo(title: title, body: body, date: date, identifier: identifier)
            }
        } catch {
            print(error.localizedDescription)
            return memo
        }
        
        return memo
    }
    
    func fetchMemoList() -> [Memo] {
        var memoList = [Memo]()
        let fetchRequest: NSFetchRequest<MemoData> = MemoData.fetchRequest()
        
        do {
            let fetchResult = try self.context.fetch(fetchRequest)
            for memo in fetchResult {
                let title = memo.title
                let body = memo.body
                let date = memo.date
                let identifier = memo.objectID
                
                guard let unwraapedTitle = title, let unwraapedBody = body else {
                    return []
                }
                
                let model = Memo(title: unwraapedTitle, body: unwraapedBody, date: date, identifier: identifier)
                memoList.append(model)
            }
        } catch {
            print(error.localizedDescription)
            return []
        }
        
        return memoList
    }
    
    func editMemo(_ memo: Memo) {
        guard let identifier = memo.identifier else {
            return
        }
        
        let editedMemo = self.context.object(with: identifier)
        editedMemo.setValue(memo.title, forKey: "title")
        editedMemo.setValue(memo.body, forKey: "body")
        editedMemo.setValue(memo.date, forKey: "date")
        
        do {
            try self.context.save()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func insertMemo(_ memo: Memo) {
        let entity = NSEntityDescription.entity(forEntityName: entitiyName, in: self.context)
        if let entity = entity {
            let managedObject = NSManagedObject(entity: entity, insertInto:self.context)
            managedObject.setValue(memo.title, forKey: "title")
            managedObject.setValue(memo.body, forKey: "body")
            managedObject.setValue(memo.date, forKey: "date")
            
            do {
                try self.context.save()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func delete(identifier: NSManagedObjectID) {
        let memo = self.context.object(with: identifier)
        self.context.delete(memo)
        do {
            try self.context.save()
        } catch {
            print(error.localizedDescription)
        }
    }
}
