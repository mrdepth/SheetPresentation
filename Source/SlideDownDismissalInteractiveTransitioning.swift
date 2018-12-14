//
//  SlideDownDismissalInteractiveTransitioning.swift
//  SheetPresentation
//
//  Created by Artem Shimanski on 11/30/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

open class SlideDownDismissalInteractiveTransitioning: UIPercentDrivenInteractiveTransition {
	static var associationKey = "slideDownDismissalInteractiveTransitioning"
	weak var viewController: UIViewController?
	
	open class func add(to viewController: UIViewController) {
		let interactor = SlideDownDismissalInteractiveTransitioning(viewController: viewController)
		viewController.transitioningDelegate = interactor
		objc_setAssociatedObject(viewController, &SlideDownDismissalInteractiveTransitioning.associationKey, interactor, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
	}
	
	public init(viewController: UIViewController) {
		self.viewController = viewController
		super.init()
		let recognizer = UIPanGestureRecognizer(target: self, action: #selector(onPan(_:)))
		recognizer.delegate = self
		viewController.view.addGestureRecognizer(recognizer)
	}
	
	fileprivate(set) var isInteractive: Bool = false
	
	override open func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
		super.startInteractiveTransition(transitionContext)
	}
	
	@objc func onPan(_ recognizer: UIPanGestureRecognizer) {
		switch recognizer.state {
		case .began:
			break
		case .changed:
			let t = recognizer.translation(in: nil)
			if viewController?.transitionCoordinator == nil {
				if abs(t.x) > 10 && abs(t.x) > t.y {
					recognizer.isEnabled = false
					recognizer.isEnabled = true
				}
				else {
					if (viewController?.presentationController as? SheetPresentationController)?.isPopoverStyle != true {
						isInteractive = true
						viewController?.dismiss(animated: true, completion: nil)
					}
				}
			}
			else {
				update(t.y / recognizer.view!.bounds.size.height)
			}
			
		case .ended:
			guard isInteractive else {break}
			let v = recognizer.velocity(in: recognizer.view)
			let t = recognizer.translation(in: recognizer.view)
			if v.y >= 0 && t.y > 40 {
				finish()
			}
			else {
				cancel()
			}
			isInteractive = false
		case .cancelled:
			guard isInteractive else {break}
			cancel()
			isInteractive = false
		default:
			break
		}
	}
}

extension SlideDownDismissalInteractiveTransitioning: UIViewControllerTransitioningDelegate {
	
	public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return isInteractive ? self : nil
	}
	
	public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		return isInteractive ? self : nil
	}
}

extension SlideDownDismissalInteractiveTransitioning: UIViewControllerAnimatedTransitioning {
	public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		return transitionContext?.isAnimated == true ? 0.25 : 0
	}
	
	public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		guard let from = transitionContext.view(forKey: .from),
			let fromVC = transitionContext.viewController(forKey: .from)
			else {return}
		let to = transitionContext.view(forKey: .to)
		if let to = to, let toVC = transitionContext.viewController(forKey: .to) {
			transitionContext.containerView.insertSubview(to, belowSubview: from)
			to.frame = transitionContext.finalFrame(for: toVC)
		}
		
		UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: [.curveLinear], animations: {
			from.frame.origin.y = transitionContext.finalFrame(for: fromVC).maxY
		}, completion: { finished in
			transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
		})
	}
}

extension SlideDownDismissalInteractiveTransitioning: UIGestureRecognizerDelegate {
	
	public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		if viewController?.presentationController is UIPopoverPresentationController && viewController?.traitCollection.userInterfaceIdiom == .pad && viewController?.presentingViewController?.traitCollection.horizontalSizeClass == .regular {
			return false
		}
		
		guard let recognizer = gestureRecognizer as? UIPanGestureRecognizer else {return true}
		let t = recognizer.translation(in: nil)
		guard t.y > 0 else {return false}
		guard (viewController?.children.last as? UITableViewController)?.refreshControl == nil else {return false}
		
		let hitTest = gestureRecognizer.view?.hitTest(gestureRecognizer.location(in: gestureRecognizer.view), with: nil)
		if let scrollView = sequence(first: hitTest, next: {$0?.superview}).first(where: {($0 as? UIScrollView)?.isScrollEnabled == true}) as? UIScrollView,
			scrollView.contentOffset.y > -scrollView.contentInset.top {
			return false
		}
		
		return hitTest?.ancestor(of: UIPickerView.self) == nil
	}
	
	public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return true
	}
	
	public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		guard otherGestureRecognizer is UIPanGestureRecognizer else {return false}
		return true
	}
}
