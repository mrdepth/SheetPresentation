//
//  ModalViewController.swift
//  Example
//
//  Created by Artem Shimanski on 11/30/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import UIKit


class ModalViewController: UIViewController {
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		let bounds = navigationController?.presentationController?.containerView?.bounds ?? UIScreen.main.bounds
		var size = view.systemLayoutSizeFitting(bounds.size)
		size.height -= navigationController?.navigationBar.bounds.height ?? 0
		navigationController?.preferredContentSize = .zero //strange behavior of UINavigationController
		preferredContentSize = size
	}
}
