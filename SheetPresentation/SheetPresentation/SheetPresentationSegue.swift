//
//  SheetPresentationSegue.swift
//  SheetPresentation
//
//  Created by Artem Shimanski on 11/30/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

open class SheetPresentationSegue: UIStoryboardSegue, UIViewControllerTransitioningDelegate {
	let presentationController: SheetPresentationController
	
	public override init(identifier: String?, source: UIViewController, destination: UIViewController) {
		presentationController = SheetPresentationController(presentedViewController: destination, presenting: source)
		destination.modalPresentationStyle = .custom
		destination.transitioningDelegate = presentationController
		super.init(identifier: identifier, source: source, destination: destination)
	}
	
	open override func perform() {
		source.present(destination, animated: true, completion: nil)
	}
	
}
