// Generated using Sourcery 0.16.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Cocoa

class ApplicationListItemViewController: NSViewController, Component {
  private let layout: NSCollectionViewFlowLayout
  private let dataSource: ApplicationListItemDataSource
  lazy var scrollView = NSScrollView()
  let collectionView: NSCollectionView

  init(title: String? = nil,
  layout: NSCollectionViewFlowLayout,
  iconStore: IconStore,
  collectionView: NSCollectionView? = nil) {
    self.layout = layout
    self.dataSource = ApplicationListItemDataSource(title: title, iconStore: iconStore)
    if let collectionView = collectionView {
      self.collectionView = collectionView
    } else {
      self.collectionView = NSCollectionView()
    }
    self.collectionView.collectionViewLayout = layout
    super.init(nibName: nil, bundle: nil)
    self.title = title
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - View lifecycle

  override func loadView() {
    self.view = scrollView
    scrollView.documentView = collectionView
    collectionView.isSelectable = true
    collectionView.allowsMultipleSelection = false
    collectionView.allowsEmptySelection = false
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    collectionView.dataSource = dataSource
    let itemIdentifier = NSUserInterfaceItemIdentifier.init("ApplicationListItem")
    collectionView.register(ApplicationListItem.self, forItemWithIdentifier: itemIdentifier)

    if title != nil {
      layout.headerReferenceSize.height = 60
    }
  }

  // MARK: - Public API

  func indexPath(for item: NSCollectionViewItem) -> IndexPath? {
    return collectionView.indexPath(for: item)
  }

  func model(at indexPath: IndexPath) -> ApplicationListItemModel {
    return dataSource.model(at: indexPath)
  }

  func reload(with models: [ApplicationListItemModel], completion: (() -> Void)? = nil) {
    dataSource.reload(collectionView, with: models, then: completion)
  }
}

class ApplicationListItemDataSource: NSObject, NSCollectionViewDataSource {

  private var title: String?
  private var models = [ApplicationListItemModel]()
  private let iconStore: IconStore

  init(title: String? = nil,
  models: [ApplicationListItemModel] = [],
  iconStore: IconStore) {
    self.title = title
    self.models = models
    self.iconStore = iconStore
    super.init()
  }

  // MARK: - Public API

  func model(at indexPath: IndexPath) -> ApplicationListItemModel {
    return models[indexPath.item]
  }

  func reload(_ collectionView: NSCollectionView,
  with models: [ApplicationListItemModel],
  then handler: (() -> Void)? = nil) {
    self.models = models
    collectionView.reloadData()
    handler?()
  }

  // MARK: - NSCollectionViewDataSource

  func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
    return models.count
  }

  func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
    let identifier = NSUserInterfaceItemIdentifier.init("ApplicationListItem")
    let itemView = collectionView.makeItem(withIdentifier: identifier, for: indexPath)
    let model = self.model(at: indexPath)

    if let item = itemView as? ApplicationListItem {
      iconStore.loadIcon(at: model.url("path"), for: model.string("bundleIdentifier")) { image in item.image("iconView").image = image }
      item.button("checkbox").state = model.bool("enabled") ? .on : .off
      item.label("subtitleLabel").stringValue = model.string("subtitle")
      item.label("titleLabel").stringValue = model.string("title")
    }

    return itemView
  }
}

struct ApplicationListItemModel {
  var data: [String: AnyHashable]

  func string(_ key: String) -> String { return (data[key] as? String) ?? "" }
  func url(_ key: String) -> URL { return (data[key] as? URL) ?? URL(string: "")! }
  func bool(_ key: String) -> Bool { return (data[key] as? Bool) ?? false }
}

