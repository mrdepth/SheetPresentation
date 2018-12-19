//
//  SheetPresentationController.swift
//  SheetPresentation
//
//  Created by Artem Shimanski on 11/30/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

open class SheetPresentationController: UIPresentationController, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning {
	
	open var sourceView: UIView?
	open var sourceRect: CGRect?
	
	open var backgroundColor: UIColor?
	open var cornerRadius: CGFloat = 16
	open var maskedCorners: UIRectCorner = [.topLeft, .topRight]
	open var shadowColor: UIColor?
	open var shadowOpacity: Float = 0.44
	open var shadowOffset: CGSize = CGSize(width: 0, height: -6)
	open var shadowRadius: CGFloat = 13.0
	open var insets: UIEdgeInsets = .zero
	open var dimmingColor: UIColor?

	private var dimmingView: UIView?
	private var presentationWrappingView: UIView?
	private var presentationRoundedCornerView: ClippingView?
	private var presentedViewControllerWrappingView: UIView?
	private var keyboardFrame: CGRect = .zero
	private var interactiveTransition: SlideDownDismissalInteractiveTransitioning?
	private var arrowView: ArrowView?

	override public init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
		presentedViewController.modalPresentationStyle = .custom
		super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
	}
	
	override open var presentedView: UIView? {
		return presentationWrappingView
	}
	
	override open func presentationTransitionWillBegin() {
		guard let presentedViewControllerView = super.presentedView else {return}
		guard let containerView = self.containerView else {return}
		
		//containerView -> presentationWrappingView -> presentationRoundedCornerView -> presentedViewControllerWrappingView -> presentedViewControllerView
		
		do {
			let presentationWrappingView = UIView(frame: frameOfPresentedViewInContainerView)
			presentationWrappingView.layer.shadowOpacity = shadowOpacity
			presentationWrappingView.layer.shadowRadius = shadowRadius
			presentationWrappingView.layer.shadowOffset = shadowOffset
			presentationWrappingView.layer.shadowColor = shadowColor?.cgColor ?? UIColor.black.cgColor
			self.presentationWrappingView = presentationWrappingView
			
			let presentationRoundedCornerView = ClippingView(frame: presentationWrappingView.bounds)
			presentationRoundedCornerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			
			presentationRoundedCornerView.cornerRadius = cornerRadius
			presentationRoundedCornerView.maskedCorners = isPopoverStyle ? UIRectCorner.allCorners : maskedCorners
			presentationRoundedCornerView.layer.masksToBounds = true
			presentationRoundedCornerView.backgroundColor = backgroundColor ?? .white
			
			self.presentationRoundedCornerView = presentationRoundedCornerView
			
			let presentedViewControllerWrappingView = UIView(frame: presentationRoundedCornerView.bounds.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)))
			presentedViewControllerWrappingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			self.presentedViewControllerWrappingView = presentedViewControllerWrappingView
			
			presentedViewControllerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			presentedViewControllerView.frame = presentedViewControllerWrappingView.bounds
			presentedViewControllerWrappingView.addSubview(presentedViewControllerView)
			
			presentationRoundedCornerView.addSubview(presentedViewControllerWrappingView)
			presentationWrappingView.addSubview(presentationRoundedCornerView)
			
			interactiveTransition = SlideDownDismissalInteractiveTransitioning(viewController: presentedViewController)
		}
		
		do {
			let dimmingView = UIView(frame: containerView.bounds)
			dimmingView.backgroundColor = dimmingColor ?? UIColor(white: 0.0, alpha: 0.5)
			dimmingView.isOpaque = false
			dimmingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			dimmingView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dimmingViewTapped(_:))))
			self.dimmingView = dimmingView
			containerView.addSubview(dimmingView)
			
			dimmingView.alpha = 0
			presentingViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
				dimmingView.alpha = 1.0
			}, completion: nil)
		}
		
		let center = NotificationCenter.default
		center.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
		center.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
		center.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

	}
	
	override open func presentationTransitionDidEnd(_ completed: Bool) {
		if !completed {
			presentationWrappingView = nil;
			dimmingView = nil;
		}
	}
	
	override open func dismissalTransitionWillBegin() {
		presentingViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
			self.dimmingView?.alpha = 0.0
		}, completion: nil)
	}
	
	override open func dismissalTransitionDidEnd(_ completed: Bool) {
		if completed {
			presentationWrappingView = nil
			dimmingView = nil
			NotificationCenter.default.removeObserver(self)
		}
	}
	
	override open func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
		super.preferredContentSizeDidChange(forChildContentContainer: container)
		if (container === presentedViewController) {
			containerView?.setNeedsLayout()
		}
	}
	
	var isPopoverStyle: Bool {
		return traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular && sourceView != nil
	}
	
	override open func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
		if (container === presentedViewController) {
			var size = container.preferredContentSize
			size.height = max(size.height, 50)
			if !isPopoverStyle {
				size.width = min(parentSize.width, parentSize.height)
			}
			return size
		}
		else {
			return super.size(forChildContentContainer: container, withParentContainerSize: parentSize)
		}
	}
	
	override open var frameOfPresentedViewInContainerView: CGRect {
		guard let containerView = self.containerView else {return .zero}
		let containerViewBounds = containerView.bounds
		let presentedViewContentSize = size(forChildContentContainer: presentedViewController, withParentContainerSize: containerViewBounds.inset(by: insets).size)
		
		var presentedViewControllerFrame = containerViewBounds
		presentedViewControllerFrame.size = presentedViewContentSize
		
		if !isPopoverStyle {
			presentedViewControllerFrame.origin.y = containerViewBounds.maxY - presentedViewContentSize.height - insets.bottom
			presentedViewControllerFrame.origin.x = (containerViewBounds.maxX - presentedViewContentSize.width) / 2
//			presentedViewControllerFrame.size.height += cornerRadius * 2
			
			presentedViewControllerFrame.origin.y -= keyboardFrame.size.height;
			if (presentedViewControllerFrame.origin.y <= 40) {
				presentedViewControllerFrame.size.height -= 40 - presentedViewControllerFrame.origin.y;
				presentedViewControllerFrame.origin.y = 40;
			}
			
			
		}
		else {
			assert(sourceView != nil)
			
			let safeArea: CGRect
			if #available(iOS 11.0, *) {
				safeArea = presentingViewController.view.convert(presentingViewController.view.bounds.inset(by: presentingViewController.view.safeAreaInsets), to: containerView)
			} else {
				safeArea = presentingViewController.view.convert(presentingViewController.view.bounds.inset(by: UIEdgeInsets(top: presentingViewController.topLayoutGuide.length, left: 0, bottom: presentingViewController.bottomLayoutGuide.length, right: 0)), to: containerView)
			}
			
			let sourceRect = sourceView!.convert(sourceView!.bounds, to: containerView)
			
			let arrowHeight = arrowView?.height ?? 0
			
			//Find preffer popover location
			
			let xLeft = sourceRect.minX - presentedViewContentSize.width - arrowHeight
			let xRight = sourceRect.maxX
			
			if xLeft > safeArea.minX {
				presentedViewControllerFrame.origin.x = xLeft
				presentedViewControllerFrame.size.width = presentedViewContentSize.width + arrowHeight
				presentedViewControllerFrame.origin.y = (sourceRect.midY - presentedViewControllerFrame.height / 2).clamped(to: safeArea.minY...min((safeArea.maxY - presentedViewContentSize.height), safeArea.height))
				arrowView?.arrowDirection = .right
			}
			else if xRight + presentedViewContentSize.width + arrowHeight < safeArea.maxX {
				presentedViewControllerFrame.origin.x = xRight
				presentedViewControllerFrame.size.width = presentedViewContentSize.width + arrowHeight
				presentedViewControllerFrame.origin.y = (sourceRect.midY - presentedViewControllerFrame.height / 2).clamped(to: safeArea.minY...min((safeArea.maxY - presentedViewContentSize.height), safeArea.height))
				arrowView?.arrowDirection = .left
			}
			else {
				if safeArea.midY < sourceRect.midY {
					arrowView?.arrowDirection = .down
					presentedViewControllerFrame.origin.y = sourceRect.minY - presentedViewContentSize.height - arrowHeight
				}
				else {
					arrowView?.arrowDirection = .up
					presentedViewControllerFrame.origin.y = sourceRect.maxY
				}
				presentedViewControllerFrame.origin.x = (sourceRect.midX - presentedViewControllerFrame.width / 2).clamped(to: safeArea.minX...min((safeArea.maxX - presentedViewContentSize.width), safeArea.width))
				presentedViewControllerFrame.size.height = presentedViewContentSize.height + arrowHeight
			}
			
			presentedViewControllerFrame.origin.y -= max(presentedViewControllerFrame.maxY + max(insets.bottom, 15) - (containerView.bounds.maxY - keyboardFrame.size.height), 0)
			
			//Reduce height if needed
			if presentedViewControllerFrame.minY < safeArea.minY {
				presentedViewControllerFrame.origin.y = safeArea.minY
				presentedViewControllerFrame.size.height -= safeArea.minY - presentedViewControllerFrame.minY
			}
			if presentedViewControllerFrame.maxY > safeArea.maxY {
				let dh = presentedViewControllerFrame.maxY - safeArea.maxY
				presentedViewControllerFrame.origin.y -= dh
				presentedViewControllerFrame.size.height -= dh
			}
		}
		
		return presentedViewControllerFrame;
	}
	
	private var arrowPosition: CGPoint {
		guard let arrowView = arrowView, let presentationWrappingView = presentationWrappingView, let sourceView = sourceView else {return .zero}
		
		var position = presentationWrappingView.convert(sourceView.center, from: sourceView.superview)
		position.x = position.x.clamped(to: (arrowView.height/2)...(presentationWrappingView.bounds.maxX - arrowView.height / 2))
		let minY = (cornerRadius + arrowView.width/2)
		let maxY = (presentationWrappingView.bounds.maxY - arrowView.width / 2 - cornerRadius)
		position.y = minY <= maxY ? position.y.clamped(to: minY...maxY) : presentationWrappingView.bounds.midY
		
		return position
	}
	
	override open func containerViewWillLayoutSubviews() {
		super.containerViewWillLayoutSubviews()

		let containerView = self.containerView
		sequence(first: sourceView, next: {$0 === containerView ? nil : $0?.superview}).reversed().forEach {
			$0?.layoutIfNeeded()
		}
		
		let animateArrow = arrowView != nil
		if isPopoverStyle {
			if arrowView == nil {
				UIView.performWithoutAnimation {
					let arrowView = ArrowView(frame: .zero)
					arrowView.sizeToFit()
					presentationWrappingView?.insertSubview(arrowView, at: 0)
					self.arrowView = arrowView
				}
			}
		}
		else if let arrowView = arrowView, !isPopoverStyle {
			arrowView.removeFromSuperview()
			self.arrowView = nil
		}
		

		if let view = super.presentedView, let presentedViewControllerWrappingView = presentedViewControllerWrappingView, view.superview != presentedViewControllerWrappingView {
			presentedViewControllerWrappingView.addSubview(view)
			view.frame = presentedViewControllerWrappingView.bounds
		}


		if let containerView = self.containerView {
			dimmingView?.frame = containerView.bounds
		}
		if let presentationWrappingView = presentationWrappingView {
			presentationWrappingView.frame = frameOfPresentedViewInContainerView
			
			if let presentationRoundedCornerView = presentationRoundedCornerView {
				if let arrowView = arrowView {
					
					switch arrowView.arrowDirection {
					case .left:
						presentationRoundedCornerView.frame = presentationWrappingView.bounds.inset(by: UIEdgeInsets(top: 0, left: arrowView.height, bottom: 0, right: 0))
					case .right:
						presentationRoundedCornerView.frame = presentationWrappingView.bounds.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: arrowView.height))
					case .up:
						presentationRoundedCornerView.frame = presentationWrappingView.bounds.inset(by: UIEdgeInsets(top: arrowView.height, left: 0, bottom: 0, right: 0))
					case .down:
						presentationRoundedCornerView.frame = presentationWrappingView.bounds.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: arrowView.height, right: 0))
					}

					let fitArrow = {
						self.arrowView?.sizeToFit()
						arrowView.center = self.arrowPosition
					}

					if animateArrow {
						fitArrow()
					}
					else {
						UIView.performWithoutAnimation(fitArrow)
					}
				}
				else {
					presentationRoundedCornerView.frame = presentationWrappingView.bounds
				}
			}
		}
	}
	
	open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		self.presentationRoundedCornerView?.maskedCorners = isPopoverStyle ? UIRectCorner.allCorners : maskedCorners
	}
	
	//MARK: - UIViewControllerAnimatedTransitioning
	
	open func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		return transitionContext?.isAnimated == true ? 0.25 : 0.0
	}
	
	open func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		guard let fromViewController = transitionContext.viewController(forKey: .from) else {return}
		guard let toViewController = transitionContext.viewController(forKey: .to) else {return}
		
		let toView = transitionContext.view(forKey: .to)
		let containerView = transitionContext.containerView
		let fromView = transitionContext.view(forKey: .from)
		let isPresenting = fromViewController === presentingViewController
		
//		let fromViewInitialFrame = transitionContext.initialFrame(for: fromViewController)
		var fromViewFinalFrame = transitionContext.finalFrame(for: fromViewController)
		var toViewInitialFrame = transitionContext.initialFrame(for: toViewController)
		let toViewFinalFrame = transitionContext.finalFrame(for: toViewController)
		
		if let toView = toView {
			containerView.addSubview(toView)
		}
		
		let isPopoverStyle = self.isPopoverStyle
		
		if isPopoverStyle {
			if isPresenting {
				toView?.frame = toViewFinalFrame
				toView?.alpha = 0.0
			}
		}
		else {
			if isPresenting {
				toViewInitialFrame.origin =  CGPoint(x: toViewFinalFrame.origin.x, y: containerView.bounds.maxY)
				toViewInitialFrame.size = toViewFinalFrame.size
				toView?.frame = toViewInitialFrame
			}
			else {
				fromViewFinalFrame.origin =  CGPoint(x: fromView?.frame.origin.x ?? 0, y: containerView.bounds.maxY)
			}
		}
		
		let transitionDuration = self.transitionDuration(using: transitionContext)
		UIView.animate(withDuration: transitionDuration, delay: 0, options: interactiveTransition?.isInteractive == true ? [.curveLinear] : [.curveEaseOut], animations: {
			if isPopoverStyle {
				if isPresenting {
					toView?.alpha = 1.0
				}
				else {
					fromView?.alpha = 0.0
				}
			}
			else {
				if isPresenting {
					toView?.frame = toViewFinalFrame
				}
				else {
					fromView?.frame = fromViewFinalFrame
				}
			}
		}) { _ in
			let wasCancelled = transitionContext.transitionWasCancelled
			transitionContext.completeTransition(!wasCancelled)
		}
	}
	
	//MARK: - UIViewControllerTransitioningDelegate
	
	open func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
		assert(presentedViewController === presented)
		return self
	}
	
	open func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return self
	}
	
	open func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return self
	}
	
	open func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		return interactiveTransition?.isInteractive == true ? interactiveTransition : nil
	}
	
	//MARK: - Notifications
	
	@objc private func keyboardWillShow(_ note: Notification) {
		
	}
	
	@objc private func keyboardWillHide(_ note: Notification) {
		
	}
	
	@objc private func keyboardWillChangeFrame(_ note: Notification) {
		self.keyboardFrame = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect).flatMap{containerView?.convert($0, from: nil)} ?? .zero
		containerView?.setNeedsLayout()
		containerView?.layoutIfNeeded()
	}
	
	@IBAction private func dimmingViewTapped(_ sender: UITapGestureRecognizer) {
		presentingViewController.dismiss(animated: true, completion: nil)
	}
	
}

class ArrowView: UIView {
	enum ArrowDirection {
		case up
		case down
		case left
		case right
	}
	var arrowDirection = ArrowDirection.up {
		didSet {
			invalidateIntrinsicContentSize()
		}
	}
	
	var width: CGFloat = 25
	var height: CGFloat = 10
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		layer.mask = CAShapeLayer()
		layer.mask?.frame = layer.bounds
		backgroundColor = .white
		(layer.mask as? CAShapeLayer)?.path = path.cgPath
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		layer.mask = CAShapeLayer()
		layer.mask?.frame = layer.bounds
		(layer.mask as? CAShapeLayer)?.path = path.cgPath
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		layer.mask?.frame = layer.bounds
		(layer.mask as? CAShapeLayer)?.path = path.cgPath
	}
	
	var path: UIBezierPath {
		let a: CGFloat = 0.35
		let b: CGFloat = 0.15
		
		let path = UIBezierPath()
		path.move(to: CGPoint(x: -0.5, y: 0))
		path.addCurve(to: CGPoint(x: 0, y: 1), controlPoint1: CGPoint(x: -a, y: 0), controlPoint2: CGPoint(x: -b, y: 1))
		path.addCurve(to: CGPoint(x: 0.5, y: 0), controlPoint1: CGPoint(x: b, y: 1), controlPoint2: CGPoint(x: a, y: 0))
		
		let transform: CGAffineTransform
		
		switch arrowDirection {
		case .up:
			transform = CGAffineTransform(translationX: 0.5, y: 1).scaledBy(x: 1, y: -1)
		case .down:
			transform = CGAffineTransform(translationX: 0.5, y: 0)
		case .left:
			transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2).translatedBy(x: 0.5, y: -1)
		case .right:
			transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2).translatedBy(x: -0.5, y: 0)
		}
		
		path.apply(transform.concatenating(CGAffineTransform(scaleX: bounds.width, y: bounds.height)))
		path.close()
		return path
	}
	
	override var intrinsicContentSize: CGSize {
		switch arrowDirection {
		case .up, .down:
			return CGSize(width: width, height: height)
		case .left, .right:
			return CGSize(width: height, height: width)
		}
	}
	
	override func sizeThatFits(_ size: CGSize) -> CGSize {
		return intrinsicContentSize
	}
}

extension Comparable {
	func clamped(to limits: ClosedRange<Self>) -> Self {
		return max(limits.lowerBound, min(limits.upperBound, self))
	}
}

extension UIView {
	func ancestor<T:UIView>(of type: T.Type = T.self) -> T? {
		return self as? T ?? self.superview?.ancestor(of: type)
	}
}

extension UIRectCorner {
	var cornerMask: CACornerMask {
		return CACornerMask(rawValue: rawValue)
	}
}


class ClippingView: UIView {
	
	var maskedCorners: UIRectCorner = [.topLeft, .topRight] {
		didSet {
			if #available(iOS 11.0, *) {
				layer.maskedCorners = maskedCorners.cornerMask
			} else {
				setNeedsLayout()
			}
		}
	}
	
	var maskLayer: CAShapeLayer?
	
	var cornerRadius: CGFloat = 16 {
		didSet {
			if #available(iOS 11.0, *) {
				layer.cornerRadius = cornerRadius
			}
			else {
				setNeedsLayout()
			}
		}
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
		if #available(iOS 11.0, *) {
		}
		else {
			maskLayer = CAShapeLayer()
			maskLayer?.frame = bounds
			layer.mask = maskLayer
		}
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		if #available(iOS 11.0, *) {
		}
		else {
			maskLayer?.frame = layer.bounds
			maskLayer?.path = UIBezierPath(roundedRect: bounds, byRoundingCorners: maskedCorners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)).cgPath
		}
	}
	
	
}
