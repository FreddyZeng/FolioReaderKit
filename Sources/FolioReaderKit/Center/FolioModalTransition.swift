//
//  FolioModalTransition.swift
//  FolioReaderKit
//
//  Created by Gemini on 2026/03/22.
//

import UIKit

public enum FolioModalTransitionDirection {
    case bottom
}

public class FolioModalTransitionAnimator: NSObject, UIViewControllerTransitioningDelegate {
    
    public var isDragable: Bool = false
    public var bounces: Bool = false
    public var behindViewAlpha: CGFloat = 1.0
    public var behindViewScale: CGFloat = 1.0
    public var transitionDuration: TimeInterval = 0.6
    public var direction: FolioModalTransitionDirection = .bottom
    
    private let modalViewController: UIViewController
    private var transitionInteractionController: FolioModalInteractiveTransition?
    
    public init(modalViewController: UIViewController) {
        self.modalViewController = modalViewController
        super.init()
    }
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if isDragable {
            transitionInteractionController = FolioModalInteractiveTransition(viewController: presented, direction: direction)
        }
        return FolioModalAnimator(type: .present, duration: transitionDuration, direction: direction, behindViewScale: behindViewScale, behindViewAlpha: behindViewAlpha, bounces: bounces)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FolioModalAnimator(type: .dismiss, duration: transitionDuration, direction: direction, behindViewScale: behindViewScale, behindViewAlpha: behindViewAlpha, bounces: bounces)
    }
    
    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if let interactionController = transitionInteractionController, interactionController.isInteracting {
            return interactionController
        }
        return nil
    }
}

class FolioModalInteractiveTransition: UIPercentDrivenInteractiveTransition {
    var isInteracting = false
    private var shouldComplete = false
    private weak var viewController: UIViewController?
    private let direction: FolioModalTransitionDirection
    
    init(viewController: UIViewController, direction: FolioModalTransitionDirection) {
        self.viewController = viewController
        self.direction = direction
        super.init()
        prepareGestureRecognizer(in: viewController.view)
    }
    
    private func prepareGestureRecognizer(in view: UIView) {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        view.addGestureRecognizer(panGesture)
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view?.superview else { return }
        
        let translation = gesture.translation(in: view)
        var fraction = translation.y / view.bounds.height
        fraction = max(0, min(fraction, 1))
        
        switch gesture.state {
        case .began:
            isInteracting = true
            viewController?.dismiss(animated: true, completion: nil)
        case .changed:
            shouldComplete = fraction > 0.5
            update(fraction)
        case .ended, .cancelled:
            isInteracting = false
            if !shouldComplete || gesture.state == .cancelled {
                cancel()
            } else {
                finish()
            }
        default:
            break
        }
    }
}

class FolioModalAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    enum TransitionType {
        case present
        case dismiss
    }
    
    let type: TransitionType
    let duration: TimeInterval
    let direction: FolioModalTransitionDirection
    let behindViewScale: CGFloat
    let behindViewAlpha: CGFloat
    let bounces: Bool
    
    init(type: TransitionType, duration: TimeInterval, direction: FolioModalTransitionDirection, behindViewScale: CGFloat, behindViewAlpha: CGFloat, bounces: Bool) {
        self.type = type
        self.duration = duration
        self.direction = direction
        self.behindViewScale = behindViewScale
        self.behindViewAlpha = behindViewAlpha
        self.bounces = bounces
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to) else {
            return
        }
        
        let containerView = transitionContext.containerView
        
        let isPresenting = type == .present
        let modalVC = isPresenting ? toVC : fromVC
        let backgroundVC = isPresenting ? fromVC : toVC
        
        if isPresenting {
            modalVC.view.transform = .identity
            modalVC.view.frame = containerView.bounds
            containerView.addSubview(modalVC.view)
            modalVC.view.transform = CGAffineTransform(translationX: 0, y: containerView.bounds.height)
        }
        
        let options: UIView.AnimationOptions = bounces ? .curveEaseOut : .curveEaseInOut
        
        UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
            if isPresenting {
                modalVC.view.transform = .identity
                if self.behindViewScale < 1.0 {
                    backgroundVC.view.transform = CGAffineTransform(scaleX: self.behindViewScale, y: self.behindViewScale)
                }
                if self.behindViewAlpha < 1.0 {
                    backgroundVC.view.alpha = self.behindViewAlpha
                }
            } else {
                modalVC.view.transform = CGAffineTransform(translationX: 0, y: containerView.bounds.height)
                backgroundVC.view.transform = .identity
                backgroundVC.view.alpha = 1.0
            }
        }, completion: { finished in
            let wasCancelled = transitionContext.transitionWasCancelled
            if !isPresenting && !wasCancelled {
                modalVC.view.removeFromSuperview()
            }
            transitionContext.completeTransition(!wasCancelled)
        })
    }
}
