//
//  AnimatedMapRouteLayer.swift
//  RouteAnimationExample
//
//  Created by Stefan Wieland on 07.07.19.
//  Copyright © 2019 allaboutapps GmbH. All rights reserved.
//

import UIKit

class AnimatedMapRouteLayer: CAShapeLayer {
    
    private let animationDuration: CFTimeInterval = 3.0
    private var animations: [CABasicAnimation] = []
    private var currentAnimationIndex: Int = 0
    
    convenience init(path: CGPath) {
        self.init()
        
        self.path = path
        self.strokeColor = UIColor.red.cgColor
        self.lineWidth = 4
        self.lineCap = .round
        self.fillColor = UIColor.clear.cgColor
    }
    
    func startAnimation() {
        let growAnimation: CABasicAnimation = CABasicAnimation(keyPath: "strokeEnd")
        growAnimation.duration = animationDuration
        growAnimation.fromValue = 0.0
        growAnimation.toValue = 1.0
        growAnimation.timingFunction = CAMediaTimingFunction(name: .easeIn)
        growAnimation.delegate = self
        
        let shrinkAnimation: CABasicAnimation = CABasicAnimation(keyPath: "strokeStart")
        shrinkAnimation.duration = animationDuration
        shrinkAnimation.fromValue = 0.0
        shrinkAnimation.toValue = 1.0
        shrinkAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        shrinkAnimation.isRemovedOnCompletion = false
        shrinkAnimation.delegate = self
        
        animations = [growAnimation, shrinkAnimation]
        currentAnimationIndex = 0
        applyNextAnimation()
    }
    
    func stopAnimation() {
        removeAllAnimations()
        animations.removeAll()
    }
    
    private func applyNextAnimation() {
        guard animations.isEmpty == false && animations.count > currentAnimationIndex else { return }
        add(animations[currentAnimationIndex], forKey: "pathAnimation")
    }
    
}

extension AnimatedMapRouteLayer: CAAnimationDelegate {
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        currentAnimationIndex += 1
        if currentAnimationIndex >= animations.count {
            currentAnimationIndex = 0
        }
        applyNextAnimation()
    }
    
}

