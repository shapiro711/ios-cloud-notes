# 동기화 메모장



## 구현 화면

![stpe-2-2-2](/Users/kimdohyung/Desktop/stpe-2-2-2.gif)

![step-2-2](/Users/kimdohyung/Desktop/step-2-2.gif)



## 주요 학습 개념

----

1. 스토리보드를 쓰지 않고 코드만으로 UI 구현
2. Split View를 이용하여 Size Class 대응
3. CoreData를 사용한 CRUD 구현



## 1. 스토리보드를 쓰지 않고 코드만으로 UI 구현

---

평소에 큰틀을 스토리보드로 잡고 세세한 부분을 코드로 잡는 방향으로 UI를 구현했었다.

하지만 스토리보드는 협업시에 merge 하기가 어려워 조직마다 다르지만 사용하지 않는 조직도 많다고 한다.

코드, 스토리보드 둘다 익숙해지기 위해 이번 프로젝트는 순수하게 코드로만 UI를 구현해보았다.



### 구현중 문제점

1. RootView를 어떻게 설정해주는가?

2. 코드만으로 Auto Layout 설정할때 문제점

   

### 1. SceneDelegate에서 window의 rootViewController 설정

처음 스토리보드를 삭제하고 화면 자체가 나오지 않아, 문제를 해결하기 위해서 찾아보았다.

전에 WWDC 영상을 보면서 iOS13부터 UI LifeCycle을 관리하는 주체가 AppDelegate에서 SceneDelegate로 변경이 되었다고 했던 것이 기억나서 SceneDelegate에서 어떻게 window를 설정해 주는지 찾아보았다.

window를 붙여주기 위해서 SceneDelegate의 scene메서드를 사용하였다.

```swift
func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = SplitViewController()
        window.backgroundColor = .white
        window.makeKeyAndVisible()
        
        self.window = window
        
        guard let _ = (scene as? UIWindowScene) else { return }
    }
```



### 2. Auto Layout

오토레이아웃을 설정할때 가장 큰 문제점이 눈에 보이지 않는 다는 것이었다.

처음 무작정 짜보았다가 레이아웃이 깨지는 현상이 나타나서 하나의 View를 기준으로 설정을 해주면서 같이 들어갈 View들을 넣어주었다.

기준이 되는 뷰의 top, buttom, leading, trailing 을 어떻게 설정해야 할지 정하고 연관되는 View들을 손으로 그리면서 코드를 짜보니 한결 수월했다.

```swift
private func configureAutoLayout() {
        let margin: CGFloat = 10
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: margin / 2),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            dateLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -margin / 2),
           
            
            shortDiscriptionLabel.topAnchor.constraint(equalTo: dateLabel.topAnchor),
            shortDiscriptionLabel.leadingAnchor.constraint(equalTo: dateLabel.trailingAnchor, constant: margin),
            shortDiscriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            shortDiscriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -margin / 2)
        ])
    }
```



## 2. Split View의 사용

---

Split View를 구현하면서 어떤 Style, Display Mode를 사용할지 결정해야 했다.

각각 어떤 특성이 있는지 확인하고 프로젝트에 가장 적합해보이는 doubleColumn, oneBesideSecondary를 사용했다.



### 구현중 문제점

1. compact size일때 DetailView가 보이는 문제
2. 자식 ViewController간의 통신
3. Split View와 자식 View의 Navigation Controller



### 1. compact size일때 DetailView가 보이는 문제

처음 구현을 했을때 화면이 compact size이면 항상 Detail View 를 보여주는 문제가 있었다.

compact size일때 첫 화면은 list를 보여주는 View가 나와야한다. 그리고 regular size에서 detailView를 보고있지 않는다면 compact로 변경이 되었을때 list를 보여주는 화면이 나와야한다고 판단했다.

위의 문제를  SplitViewControllerDelegate 메서드와 처음 셀을 선택한 이후에 regular size에서는 항상 detailView가 화면에서 표시되고 있을 거라는 생각을 하여 isFirstCellSelection flag를 통해 처리했다.

```Swift
extension SplitViewController: UISplitViewControllerDelegate {
    
    func splitViewController(_ svc: UISplitViewController, topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column {
 
        if isFirstCellSelection == false {
             return .primary
         } else {
             return .secondary
         }
     }
}
```



### 2. 자식 ViewController간의 통신

메모의 CRUD를 처리하면서 list를 보여주는 view와 detail을 보여주는 view간의 통신이 필요했다.

처음 생각한 방법은

1. 각각의 delegate를 자식들이 서로 가지고 weak로 순환 참조를 막는다.
2. 콜백 클로저를 사용한다.
3. Notification Center를 사용한다. 
4. SplitView를 통해서 서로 전달하고 받는다.

정도를 생각했었다.

최종적으로는 SplitView가 자식 ViewController의 delegate를 가지고 통신하는 방법을 택했다.

```swift
extension SplitViewController: MemoListDelegate {
    
    func showDetail(data: Memo, index: IndexPath) {
        detailMemoViewController.index = index
        detailMemoViewController.memo = data
        showDetailViewController(detailMemoViewController, sender: nil)
        detailMemoViewController.ableUserInteraction()
    }
}

extension SplitViewController: DetailMemoDelegate {

    func saveMemo(with newMemo: Memo, index: IndexPath) {
        memoListViewController.memoList[index.row].title = newMemo.title
        memoListViewController.memoList[index.row].body = newMemo.body
        memoListViewController.memoList[index.row].date = newMemo.date
        coreDataManager.editMemo(newMemo)
        memoListViewController.tableView.reloadRows(at: [index], with: .automatic)
    }
    
    func deleteMemo(index: IndexPath) {
        memoListViewController.deleteMemo(index: index)
        detailMemoViewController.memo = nil
    }
}
```



위의 방법을 성택한 가장 큰 이유는 공식문서에서 자식간의 소통은 SplitView를 거쳐서 하는 것이 좋다는 공식문서를 보았기 때문이다.

![132133016-d394cf0c-bdaf-435c-8ed4-a3abab92335a](/Users/kimdohyung/Desktop/132133016-d394cf0c-bdaf-435c-8ed4-a3abab92335a.png)



### 3. Split View와 자식 View의 Navigation Controller

SplitView 에서 자식 view controller를 가지고 있다.

MasterView에서 DetailView로 넘어갈때 showDetail 메서드를 사용했을때 modal 방식이 아닌 navigation 방식으로 화면 이동이 되었다. 

의아했지만 일단 넘어갔었는데 문제가 DetailView에서 MasterView로 넘어갈때 발생했다.

단순히 pop을 하면 되나? 싶어 해보았지만 작동하지 않아 어떻게 관리가 되고있는지 알아보았다.

![스크린샷 2021-09-18 오후 6.15.12](/Users/kimdohyung/Desktop/스크린샷 2021-09-18 오후 6.15.12.png)

SplitView의 문서에서 위의 내용을 확인 할 수 있었다. 자식뷰들의 네비게이션 컨트롤러를 설정해주지 않아도 네비게이션 컨트롤러 안에 감싸서 관리해준다는 내용이었다. 때문에 showDetail 메서드로 화면이동을 했을때 modal 방식이 아닌 navigation 방식으로 화면 이동이 된다는 사실을 알았다.

그렇다면 compact size에서 DetailView에서 MasterView로 넘어갈때 DetailView의 Navigation Controller를 통해 MasterView Navigation Controller에 접근하여 해결이 가능할 것이라고 판단하고 아래의 코드로 해결했다.

```swift
private func moveToMasterViewInCompact() {
        if UITraitCollection.current.horizontalSizeClass == .compact {
            if let masterViewNavigationController = self.navigationController?.parent as? UINavigationController {
                masterViewNavigationController.popToRootViewController(animated: true)
            }
        }
    }
```



## 3. CoreData 구현, 메모 CRUD 구현

코어데이터를 사용하기 위해 모델과 entitiy를 정의하였다.

그리고 메모앱에서 CRUD가 전반적으로 이루어져, 싱글톤으로 CoreData에 접근하여 CRUD 로직을 가지고 있는 CoreDataManager 클래스를 구현하였다.



### 구현중 문제점

1. Core Data Stack의 이해
2. 잦은 수정으로 인한 큰틀의 무너짐



### 1. Core Data Stack의 이해

코어데이터의 model을 만든후에 이에 접근하고 사용하기 위한 로직을 구현하던 도중에

NSPersistentContainer, NSManagedObjectContext 등등 한번 확인은 했지만 정확히 어떤 일을 하는지 정리가 되있지 않아 구현에 많은 어려움을 겪었었다. 

Core Data Stack은 아래와 같이 이루어져있다.

![스크린샷 2021-09-19 오후 3.05.51](/Users/kimdohyung/Desktop/스크린샷 2021-09-19 오후 3.05.51.png)

1. NSPersistentContainer - Core Data Stack을 나타내는 필요한 모든 객체를 담고 있다.
2. NSManagedObjectContext - managed objects를 생성하고, 저장하고, 가져오는 작업을 한다.
3. NSPersistentStoreCoordinator - 저장소와 모델을 연결하는 역할을 한다.
4. NSManagedObjectModel - 데이터 베이스의 스키마

위와 같이 역할을 정리하고 CRUD 로직을 어떻게 만들 수 있을지 생각해보았다.

1. NSPersistentContainer 생성

   ```swift
    private var persistentContainer: NSPersistentContainer = {
           let container = NSPersistentContainer(name: "CoreDataModel")
           container.loadPersistentStores(completionHandler: { (storeDescription, error) in
               if let error = error as NSError? {
                   fatalError("\(error), \(error.userInfo)")
               }
           })
           return container
       }() 
   ```

2. NSManagedObjectContext 가져오기

3. entity 가져오기

4. NSManagedObject 생성 또는 가져오기

5. NSManagedObject 값 변경

6. NSManagedObjectContext 저장



### 2. 잦은 수정으로 인한 큰틀의 무너짐

여기 고치고 저기 고치고 하다보니 큰틀이 무너지는 느낌이 들었다.

1. size class에 따라 다르게 작동하는 ui -  사용자가 어떤 화면을 보고 있는지에 따라 어떤 ui를 보여줄것인지, 화면전환은 어떻게 할것인지 등등
2. 각각의 CRUD 메서드를 정의하고 불러와서 사용했지만 controller에서 결국 얽혀 수정하면 다른 쪽에서 버그가 발생하는 상황 - CoreDataManager의 메서드를 사용하는 controller에서 서로 얽혀, CoreDataManager 메서드를 수정하면 다른쪽에서 문제가 발생
3. 메모앱 사용자의 반응에 따른 분기 처리 - 메모를 생성하고 아무런 행동을 하지 않았을때 저장할것인가? 와 같은 문제

사실 이번 프로젝트에서는 시작할때 꼼꼼하게 설계를 하지 못했다는 생각이 들었다. 이런 상황을 겪지 않기 위해서는 어떻게 해야 할지 생각을 해보았다.

1. **unit test를 통한 확신을 가지고 기능을 사용** - test를 통해서 해당 기능이 확실하게 작동이 되는지 여러방면을 테스트했다면 해당 기능을 사용하는 타입이 더 확실하게 작동될 수 있었을 것이다.
2. **필요한 기능들의 리스트를 만든 후에 설계** - 굵직한 기능 뿐만 아니라 세세하게 어떤 기능이 들어가있을지에 대한 생각을 하고, 리스트를 만들어 설계를 했다면 잦은 수정을 방지할 수 있겠다는 생각이 들었다.
3. **POP 지향** - 기능의 모듈화를 조금 더 명확하게 할 수 있었을 것이다. 그리고 1번과의 연장으로 의존성 주입을 해주면서 테스트가 가능하여 조금 더 테스트에 용이한 코드가 될 수 있었을 거라고 생각한다.
