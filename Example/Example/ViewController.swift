//
//  ViewController.swift
//  Example
//
//  Created by Artem Shimanski on 11/30/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import UIKit
import SheetPresentation

class ViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		let presentationController = segue.destination.presentationController as? SheetPresentationController
		presentationController?.sourceView = sender as? UIView
		
		if segue.identifier == "Insets" {
			presentationController?.maskedCorners = .allCorners
			presentationController?.insets = UIEdgeInsets(top: 0, left: 15, bottom: 40, right: 15)
		}
	}

}

extension UIViewController {
	@IBAction func dismiss() {
		dismiss(animated: true, completion: nil)
	}
}
