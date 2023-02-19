//
//  ViewInfoViewController.swift
//  ADEduKitTool
//
//  Created by Schwarze on 27.08.21.
//

import UIKit

final class ViewInfoViewController: UIViewController {
    var info: String?

    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        textView.text = info
    }
    
    @IBAction func doClose(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
