//
//  WebViewContainer.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2017-05-02.
//  Copyright © 2017 breadwallet LLC. All rights reserved.
//

import UIKit

class WebViewContainer : UIViewController {

    init(mountPoint: String, walletManager: WalletManager, store: Store, apiClient: BRAPIClient) {
        #if Debug || Testflight
            webView = BRWebViewController(partner: "Simplex", mountPoint: mountPoint, walletManager: walletManager, store: store, noAuthApiClient: apiClient)
        #else
            webView = BRWebViewController(partner: "Simplex", mountPoint: mountPoint, walletManager: walletManager, store: store, noAuthApiClient: apiClient)
        #endif
        webView.preload()
        super.init(nibName: nil, bundle: nil)
    }

    private let webView: BRWebViewController
    let blur = UIVisualEffectView()

    override func viewDidLoad() {
        view.backgroundColor = .clear
        addChildViewController(webView, layout: {
            webView.view.constrain([
                webView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                webView.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                webView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                webView.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor) ])
        })
        addTopCorners()
    }

    private func addTopCorners() {
        let path = UIBezierPath(roundedRect: view.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 6.0, height: 6.0)).cgPath
        let maskLayer = CAShapeLayer()
        maskLayer.path = path
        webView.view.layer.mask = maskLayer
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension WebViewContainer : UIViewControllerTransitioningDelegate {
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissSupportCenterAnimator()
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PresentSupportCenterAnimator()
    }
}

class PresentSupportCenterAnimator : NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let duration = transitionDuration(using: transitionContext)
        guard let toViewController = transitionContext.viewController(forKey: .to) as? WebViewContainer else { assert(false, "Missing to view controller"); return }
        guard let toView = transitionContext.view(forKey: .to) else { assert(false, "Missing to view"); return }
        let container = transitionContext.containerView

        let blur = toViewController.blur
        blur.frame = container.frame
        container.addSubview(blur)

        let finalToViewFrame = toView.frame
        toView.frame = toView.frame.offsetBy(dx: 0, dy: toView.frame.height)
        container.addSubview(toView)


        UIView.spring(duration, animations: {
            blur.effect = UIBlurEffect(style: .dark)
            toView.frame = finalToViewFrame
        }, completion: { _ in
            transitionContext.completeTransition(true)
        })

    }
}

class DismissSupportCenterAnimator : NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard transitionContext.isAnimated else { return }
        let duration = transitionDuration(using: transitionContext)
        guard let fromView = transitionContext.view(forKey: .from) else { assert(false, "Missing from view"); return }
        guard let fromViewController = transitionContext.viewController(forKey: .from) as? WebViewContainer else { assert(false, "Missing to view controller"); return }
        let originalFrame = fromView.frame
        UIView.animate(withDuration: duration, animations: {
            fromViewController.blur.effect = nil
            fromView.frame = fromView.frame.offsetBy(dx: 0, dy: fromView.frame.height)
        }, completion: { _ in
            fromView.frame = originalFrame //Because this view gets reused, it's frame needs to be reset everytime
            transitionContext.completeTransition(true)
        })
    }
}
