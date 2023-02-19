//
//  ViewController.swift
//  ADEduKitTool
//
//  Created by Schwarze on 24.08.21.
//

import UIKit
import ADEduKit

final class Config {
    var mainLocale: String? = nil
    var mainEnv: String? = nil
}

enum Env: String {
    // These string values must not be changed and must match the ClassKit Catalog API spec:
    // (more info: https://developer.apple.com/documentation/classkitcatalogapi/testing_your_classkit_catalog_implementation)
    case development = "development"
    case production = "production"
}

final class CtxCell : UITableViewCell, ADEduGenericModelDelegate {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var localesSegment: UISegmentedControl!
    @IBOutlet weak var infoStatusGetButton: UIButton!
    @IBOutlet weak var infoStatusPutButton: UIButton!
    @IBOutlet weak var opStateView: UIImageView!
    var selectedLocale: String? = nil
    var model: ADEduGenericModel? = nil
    var meta: ADEduGenericMetadata? = nil
    var config: Config? = nil

    fileprivate func updateOpStateUI() {
        let img: UIImage?
        let col: UIColor?
        if let model = model {
            switch (model.opState) {
            case .idle: (img, col) = (UIImage(systemName: "circle.fill"), UIColor.lightGray)
            case .busy: (img, col) = (UIImage(systemName: "circle.fill"), UIColor.yellow)
            case .ok: (img, col) = (UIImage(systemName: "circle.fill"), UIColor.green)
            case .failed: (img, col) = (UIImage(systemName: "circle.fill"), UIColor.red)
            @unknown default:
                (img, col) = (UIImage(systemName: "circle.fill"), UIColor.lightGray)
            }
        } else {
            (img, col) = (UIImage(systemName: "circle.fill"), UIColor.lightGray)
        }
        opStateView.image = img
        opStateView.tintColor = col
    }

    func gmodelDidUpdate(_ model: ADEduGenericModel) {
        guard self.model != nil, model === self.model else { return }
        DispatchQueue.main.async {
            self.updateOpStateUI()
        }
    }

    @IBAction func getRemote(_ sender: Any) {
        guard let mod = model,
              let loc = selectedLocale ?? config?.mainLocale else {
            Log.log("\(#function): mod or loc missing")
            return
        }
        ClassKitClient.shared.getContext(model: mod, idPath: mod.identifierPath(), locale: loc, env: config?.mainEnv ?? Env.development.rawValue, completion: nil)
    }
    
    @IBAction func putRemote(_ sender: Any) {
        guard let mod = model,
              let met = meta,
              let loc = selectedLocale ?? config?.mainLocale else {
            Log.log("\(#function): mod, met or loc missing")
            return
        }
        let ctxData = ADEduGenericContext.configureFrom(model: mod, meta: met, locale: loc)
        ClassKitClient.shared.putContext(model: mod, idPath: mod.identifierPath(), locale: loc, env: config?.mainEnv ?? Env.development.rawValue, ctxData: ctxData, completion: nil)
    }

    @IBAction func removeRemote(_ sender: Any) {
        guard let mod = model,
              let loc = selectedLocale ?? config?.mainLocale else {
            Log.log("\(#function): mod or loc missing")
            return
        }
        ClassKitClient.shared.removeContext(model: mod, idPath: mod.identifierPath(), locale: loc, env: config?.mainEnv ?? Env.development.rawValue, completion: nil)
    }

    func show(info: String) {
        guard let rootVC = UIApplication.shared.windows.first?.rootViewController else {
            Log.log("\(#function): no root view controller")
            return
        }
        let pvc = rootVC.presentedViewController ?? rootVC
        guard let vc = pvc.storyboard?.instantiateViewController(identifier: "ViewInfoViewController") as? ViewInfoViewController else {
            Log.log("\(#function): ViewInfoViewController not found")
            return
        }

        vc.info = info
        pvc.present(vc, animated: true, completion: nil)
    }

    func showStatus(op: String) {
        guard let loc = selectedLocale ?? config?.mainLocale else {
            Log.log("\(#function): loc missing")
            return
        }
        let info = model!.stateInfoFor(locale: loc, op: op)
        let infoStr = info?.info() ?? "<no info>"
        Log.log("\(#function): info = \(infoStr)")
        show(info: infoStr)
    }

    @IBAction func showGetStatus(_ sender: Any) {
        showStatus(op: "get")
    }

    @IBAction func showPutStatus(_ sender: Any) {
        showStatus(op: "put")
    }
    @IBAction func showDelStatus(_ sender: Any) {
        showStatus(op: "del")
    }

    @IBAction func localeSegmentsDidChange(_ sender: Any) {
        guard let _ = model else {
            Log.log("\(#function): mod missing")
            return
        }
        let loc = localesSegment.titleForSegment(at: localesSegment.selectedSegmentIndex)
        selectedLocale = loc
    }

    func updateForModel(_ model: ADEduGenericModel, meta: ADEduGenericMetadata, config: Config) {
        if let m = self.model {
            m.delegate = nil
        }
        self.model = model
        if let m = self.model {
            m.delegate = self
        }
        self.meta = meta
        self.config = config

        titleLabel.text = model.collapsedIdentifierPath()

        localesSegment.removeAllSegments()
        let locs = model.allLocales()
        var index = 0
        for l in locs {
            localesSegment.insertSegment(withTitle: l, at: index, animated: false)
            index += 1
        }

        updateOpStateUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        model?.delegate = nil
        model = nil
        meta = nil
        config = nil
    }
}

final class CtxPropCell : UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var localValueLabel: UILabel!
    @IBOutlet weak var remoteValueLabel: UILabel!
    
    func updateForModel(_ model: ADEduGenericModel?, key: String, locale: String) {
        if let m = model {
            nameLabel.text = key
            localValueLabel.text = m.localValueStringFor(key: key, locale: locale)
            remoteValueLabel.text = m.remoteValueStringFor(key: key, locale: locale)
        } else {
            nameLabel.text = "--"
            localValueLabel.text = "--"
            remoteValueLabel.text = "--"
        }
    }
}

final class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var detailTableView: UITableView!
    @IBOutlet weak var detailsLocalesSwitch: UISegmentedControl!
    @IBOutlet weak var opQueueProgressView: UIProgressView!
    @IBOutlet weak var localesSegment: UISegmentedControl!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var getAllButton: UIButton!
    @IBOutlet weak var putAllButton: UIButton!
    @IBOutlet weak var delAllButton: UIButton!

    var client = ClassKitClient()
    var config = Config()

    var model : ADEduGenericModel? = nil
    var meta : ADEduGenericMetadata? = nil
    var modelList : [ADEduGenericModel] = []
    var selectedModel: ADEduGenericModel? = nil
    var selectedLocale: String? = nil
    var detailsSelectedLocale: String? = nil
    var selectedEnv: String = Env.development.rawValue

    var opQueue : ClassKitOpQueue? = nil

    @IBAction func didChangeEnv(_ sender: Any) {
        if let seg = sender as? UISegmentedControl {
            if seg.selectedSegmentIndex == 0 {
                selectedEnv = Env.development.rawValue
            } else {
                selectedEnv = Env.production.rawValue
            }
            config.mainEnv = selectedEnv
        }
    }
    
    @IBAction func didChangeLocale(_ sender: Any) {
        if let seg = sender as? UISegmentedControl {
            let index = seg.selectedSegmentIndex
            if let loc = model?.allLocales()[index] {
                selectedLocale = loc
            }
            config.mainLocale = selectedLocale
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        config.mainEnv = Env.development.rawValue

        tableView.delegate = self
        tableView.dataSource = self
        detailTableView.delegate = self
        detailTableView.dataSource = self

        let modelName = "musicnotes"

        let root = ADEduGenericModel.load(name: modelName + "_model")
        let rootStr = root?.description ?? ""
        Log.log("\(#function): root = \(rootStr)")
        model = root
        modelList = root!.deepChildList()
        meta = ADEduGenericMetadata.load(name: modelName + "_meta")

        if let m = model {
            var index = 0
            localesSegment.removeAllSegments()
            for l in m.allLocales() {
                localesSegment.insertSegment(withTitle: l, at: index, animated: false)
                index += 1
            }
        }
    }

    @IBAction func detailsLocaleChanged(_ sender: Any) {
        detailsSelectedLocale = selectedModel?.allLocales()[detailsLocalesSwitch.selectedSegmentIndex] ?? "en"
        detailTableView.reloadData()
    }

    func markQueue(busy: Bool) {
        self.cancelButton.isEnabled = busy
        self.getAllButton.isEnabled = !busy
        self.putAllButton.isEnabled = !busy
        self.delAllButton.isEnabled = !busy
    }

    @IBAction func doGetAll(_ sender: Any) {
        if selectedLocale == nil {
            Log.log("\(#function): missing locale")
            return
        }
        guard opQueue == nil else { return }

        _doAll(op: "get")
    }
    @IBAction func doPutAll(_ sender: Any) {
        if selectedLocale == nil {
            Log.log("\(#function): missing locale")
            return
        }
        guard opQueue == nil else { return }

        _doAll(op: "put")
    }
    @IBAction func doDelAll(_ sender: Any) {
        if selectedLocale == nil {
            Log.log("\(#function): missing locale")
            return
        }
        _doAll(op: "del")
    }
    
    private func _doAll(op: String) {
        markQueue(busy: true)
        let q = ClassKitOpQueue(client: client, models: modelList, meta: meta!, locale: selectedLocale!, env: selectedEnv)
        opQueue = q
        q.run(op: op, update: { (progress) -> Void in
            self.opQueueProgressView.progress = progress
            if progress >= 1.0 {
                self.opQueue = nil
                self.markQueue(busy: false)
            }
        })
    }

    @IBAction func doCancel(_ sender: Any) {
        if let oq = opQueue {
            oq.cancel()
            opQueue = nil
            markQueue(busy: false)
        }
    }

    @IBAction func doShowContext(_ sender: Any) {
        guard let mod = selectedModel else { return }
        guard let met = meta else { return }
        guard let loc = selectedLocale else { return }

        let gctx = ADEduGenericContext.configureFrom(model: mod, meta: met, locale: loc)
        guard let json = try? JSONSerialization.data(withJSONObject: gctx, options: .prettyPrinted) else { return }
        guard let vc = self.storyboard?.instantiateViewController(identifier: "ViewInfoViewController") as? ViewInfoViewController else { return }

        let str = String(data: json, encoding: .utf8)
        vc.info = str
        present(vc, animated: true, completion: nil)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if (tableView === self.tableView) {
            return 1
        } else {
            return 1
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (tableView === self.tableView) {
            return modelList.count
        } else {
            return selectedModel?.allKeys().count ?? 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (tableView === self.tableView) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CtxCell") as! CtxCell
            let m = modelList[indexPath.row]
            cell.updateForModel(m, meta: meta!, config: config)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CtxPropCell") as! CtxPropCell
            let key = selectedModel?.allKeys()[indexPath.row] ?? "none"
            cell.updateForModel(selectedModel, key: key, locale: detailsSelectedLocale ?? "en")
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (tableView === self.tableView) {
            selectedModel = modelList[indexPath.row]
            let locales = selectedModel?.allLocales() ?? ["en"]
            detailsLocalesSwitch.removeAllSegments()
            var index = 0
            for l in locales {
                detailsLocalesSwitch.insertSegment(withTitle: l, at: index, animated: false)
                index += 1
            }
            detailTableView.reloadData()
        } else {
            // nothing for the other tableview
        }
    }
}

