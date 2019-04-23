import Cocoa

class ApplicationDetailFeatureViewController: NSViewController,
  ApplicationDetailInfoViewControllerDelegate,
  SplitViewContainedController,
  NSCollectionViewDelegate {

  weak var listViewController: ApplicationListItemViewController?

  lazy var titleLabel = SmallBoldLabel()
  lazy var titlebarView = NSView()

  private var layoutConstraints = [NSLayoutConstraint]()

  let containerViewController: ApplicationDetailContainerViewController
  let applicationController: ApplicationController
  let backupController: BackupController
  let syncController: SyncController
  let machineController: MachineController

  var application: Application?

  init(applicationController: ApplicationController,
       backupController: BackupController,
       containerViewController: ApplicationDetailContainerViewController,
       machineController: MachineController,
       syncController: SyncController) {
    self.applicationController = applicationController
    self.backupController = backupController
    self.containerViewController = containerViewController
    self.machineController = machineController
    self.syncController = syncController
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    view = containerViewController.view
    view.wantsLayer = true
  }

  override func viewWillLayout() {
    super.viewWillLayout()

    if view.effectiveAppearance.name == .aqua {
      view.layer?.backgroundColor = NSColor.white.cgColor
    } else {
      view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }
  }

  private func render(_ applications: [Application]) {
    containerViewController.applicationInfoViewController.view.isHidden = true
  }

  private func render(_ application: Application) {
    containerViewController.applicationInfoViewController.view.isHidden = false
    containerViewController.applicationInfoViewController.render(application,
                                                                 syncController: syncController,
                                                                 machineController: machineController)
    NSLayoutConstraint.deactivate(layoutConstraints)
    layoutConstraints = []

    titlebarView.subviews.forEach { $0.removeFromSuperview() }
    titleLabel.stringValue = application.propertyList.bundleName
    titleLabel.alignment = .center
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titlebarView.wantsLayer = true
    titlebarView.addSubview(titleLabel)

    layoutConstraints.append(contentsOf: [
      titleLabel.leadingAnchor.constraint(equalTo: titlebarView.leadingAnchor, constant: 10),
      titleLabel.trailingAnchor.constraint(equalTo: titlebarView.trailingAnchor, constant: -10),
      titleLabel.centerYAnchor.constraint(equalTo: titlebarView.centerYAnchor)
      ])

    containerViewController.applicationInfoViewController.delegate = self

    NSLayoutConstraint.activate(layoutConstraints)
  }

  private func refreshApplicationList() {
    guard let locations = try? applicationController.applicationDirectories() else { return }
    applicationController.loadApplications(at: locations)
  }

  private func handleSelections(in collectionView: NSCollectionView) {
    if collectionView.selectionIndexPaths.count > 1 {
      render([])
    } else {
      guard let indexPath = collectionView.selectionIndexPaths.first else { return }
      guard let listViewController = listViewController else { return }

      let application = listViewController.model(at: indexPath).application
      self.application = application
      render(application)
    }
  }

  // MARK: - ApplicationDetailInfoViewControllerDelegate

  func applicationDetailInfoViewController(_ controller: ApplicationDetailInfoViewController,
                                           didTapBackup backupButton: NSButton) {
    guard let application = application else { return }
    guard let backupDestination = UserDefaults.standard.backupDestination else { return }
    try? backupController.runBackup(for: [application], to: backupDestination)
    render(application)
    refreshApplicationList()
  }

  func applicationDetailInfoViewController(_ controller: ApplicationDetailInfoViewController,
                                           didTapSync syncButton: NSButton) {
    guard let application = application else { return }
    try? syncController.enableSync(for: application, on: machineController.machine)
    render(application)
    refreshApplicationList()
  }

  func applicationDetailInfoViewController(_ controller: ApplicationDetailInfoViewController,
                                           didTapUnsync unsyncButton: NSButton) {
    guard let application = application else { return }
    try? syncController.disableSync(for: application, on: machineController.machine)
    render(application)
    refreshApplicationList()

  }

  // MARK: - NSCollectionViewDelegate

  func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
    handleSelections(in: collectionView)
  }

  func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
    handleSelections(in: collectionView)
  }
}
