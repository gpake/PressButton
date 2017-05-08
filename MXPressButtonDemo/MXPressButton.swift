//
//  MXPressButton.swift
//  MXPressButtonDemo
//
//  Created by Ashbringer on 5/5/17.
//  Copyright © 2017 wintface.com. All rights reserved.
//

import UIKit
// TODO: - 维护一个 status
// TODO: - 调整默认 ringSize 适应各种 frame
class MXPressButton: UIView {

    enum State {
        case begin
        case pressing
        case moving
        case willCancel
        case didCancel
        case end
        case click
    }
    
    typealias actionState = (_ state: State) -> Void
    
    /// 最小计时时长，低于这个时间会使用 disable 系列的颜色
    var minInterval: Float = 10.0
    /// 最大即使时长，大于这个时间会直接执行 end 操作
    var maxInterval: Float = 30.0

    /// 中间圆心颜色
    var centerColor: UIColor! {
        didSet {
            self.centerLayer.fillColor = centerColor.cgColor
        }
    }
    
    /// 圆环颜色
    var ringColor: UIColor! {
        didSet {
            self.ringLayer.fillColor = ringColor.cgColor
        }
    }
    
    /// 进度条颜色
    var progressColor: UIColor! {
        didSet {
            self.progressLayer.strokeColor = progressColor.cgColor
        }
    }
    
    var progressDisableColor: UIColor?
    var progressNormalColor: UIColor?
    var progressLineWidth: CGFloat? {
        didSet {
            if let width = progressLineWidth {
                self.progressLayer.lineWidth = width
            }
        }
    }
    
    var centerRadiusOrigin: CGFloat = 27.0
    var centerRadiusPressed: CGFloat = 20.0
    
    var ringRadiusOrigin: CGFloat = 37.0
    var ringRadiusPressed: CGFloat = 60.0
    
    fileprivate var buttonAction: actionState?
    
    fileprivate lazy var centerLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        
        layer.frame = self.bounds
        layer.fillColor = UIColor.white.cgColor
        layer.path = self.centerPathOrigin()
        
        return layer
    }()
    
    fileprivate lazy var ringLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        
        layer.frame = self.bounds
        layer.fillColor = UIColor.white.withAlphaComponent(0.8).cgColor
        layer.path = self.ringPathOrigin()
        
        return layer
    }()
    
    fileprivate lazy var progressLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.green.cgColor
        layer.lineWidth = 4
        layer.lineCap = kCALineCapRound
        return layer
    }()
    
    fileprivate lazy var displayLink: CADisplayLink = {
        let link = CADisplayLink(target: self, selector: #selector(displayLinkTick))
//        link.preferredFramesPerSecond = 60
        link.add(to: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        link.isPaused = true
        return link
    }()
    
    fileprivate var animationDuration: CFTimeInterval = 0.2
    // 初始值 -0.2 是因为缩放动画需要执行 0.2s，在此之前不应该显示进度条
    fileprivate var tempInterval: Float = -0.2
    fileprivate var progress: Float = 0.0
    fileprivate var isTimeOut: Bool = false
    fileprivate var isPressed: Bool = false
    fileprivate var isCancel: Bool = false
    fileprivate var ringFrame: CGRect = .zero
    
    public fileprivate(set) var currentInterval: Float = 0.0
    
    private var tapGesture: UITapGestureRecognizer?
    private var longPressGesture: UILongPressGestureRecognizer?
    
    // MARK: - Life Cycle
    deinit {
        print("deinit MXPressButton")
        self.displayLink.invalidate()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        
        self.layer.addSublayer(ringLayer)
        self.layer.addSublayer(centerLayer)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressGestureRecognized(_:)))
        longPress.minimumPressDuration = 0.2
        self.addGestureRecognizer(longPress)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapGestureRecognized(_:)))
        self.addGestureRecognizer(tap)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func actionClosure(_ closure: @escaping actionState) {
        self.buttonAction = closure
    }
}

// MARK: - Calculator
extension MXPressButton {
    fileprivate func frame(insetByRadius radius: CGFloat) -> CGRect {
        let width = self.bounds.width
        let mainWidth = width / 2.0
        let halfWidth = mainWidth / 2.0
        let mainFrame = CGRect(x: halfWidth, y: halfWidth, width: mainWidth, height: mainWidth)
        
        let frame = mainFrame.insetBy(dx: halfWidth - radius, dy: halfWidth - radius);
        
        return frame
    }
    
    fileprivate func ringPathOrigin() -> CGPath {
        let originRingFrame = self.frame(insetByRadius: self.ringRadiusOrigin)
        self.ringFrame = originRingFrame
        let originRingPath = UIBezierPath(roundedRect: originRingFrame, cornerRadius: originRingFrame.width/2.0)
        
        return originRingPath.cgPath
    }
    
    fileprivate func ringPathPressed() -> CGPath {
        let pressedRingFrame = self.frame(insetByRadius: self.ringRadiusPressed)
        let pressedRingPath = UIBezierPath(roundedRect: pressedRingFrame, cornerRadius: pressedRingFrame.width / 2.0)
        
        return pressedRingPath.cgPath
    }
    
    fileprivate func centerPathOrigin() -> CGPath {
        let originCenterFrame = self.frame(insetByRadius: self.centerRadiusOrigin)
        let centerPath = UIBezierPath(roundedRect: originCenterFrame, cornerRadius: originCenterFrame.width / 2.0)
        
        return centerPath.cgPath
    }
    
    fileprivate func centerPathPressed() -> CGPath {
        let pressedCenterFrame = self.frame(insetByRadius: self.centerRadiusPressed)
        let centerPath = UIBezierPath(roundedRect: pressedCenterFrame, cornerRadius: pressedCenterFrame.width / 2.0)
        
        return centerPath.cgPath
    }
}

// MARK: - Actions
extension MXPressButton {
    @objc fileprivate func didTapGestureRecognized(_ gesture: UITapGestureRecognizer) {
        if let closure = self.buttonAction {
            closure(.click)
        }
    }
    
    @objc fileprivate func didLongPressGestureRecognized(_ gesture: UILongPressGestureRecognizer) {
        
        switch gesture.state {
        case .began:
            
            self.displayLink.isPaused = false
            self.isPressed = true
            self.isCancel = false
            self.layer.addSublayer(self.progressLayer)
            
            self.ringLayer.path = self.ringPathPressed()
            let ringAnimation = self.makePathAnimation(fromValue: self.ringPathOrigin, toValue: self.ringPathPressed)
            self.ringLayer.add(ringAnimation, forKey: "path")
            
            self.centerLayer.path = self.centerPathPressed()
            let centerAnimation = self.makePathAnimation(fromValue: self.centerPathOrigin, toValue: self.centerPathPressed)
            self.centerLayer.add(centerAnimation, forKey: "path")
            
            if let closure = self.buttonAction {
                closure(.begin)
            }
        case .changed:
            let point = gesture.location(in: self)
            if self.ringFrame.contains(point) {
                self.isCancel = false
                if let closure = self.buttonAction {
                    closure(.moving)
                }
            } else {
                self.isCancel = true
                if let closure = self.buttonAction {
                    closure(.willCancel)
                }
            }
        //            self.currentInterval = 0.0
        case .ended:
            self.stop()
            if self.isCancel {
                if let closure = self.buttonAction {
                    closure(.didCancel)
                }
            } else if self.isTimeOut == false {
                if let closure = self.buttonAction {
                    closure(.end)
                }
            }
            
            self.currentInterval = 0.0
            self.isTimeOut = false
            
            self.ringLayer.path = self.ringPathOrigin()
            let ringAnimation = self.makePathAnimation(fromValue: self.ringPathPressed, toValue: self.ringPathOrigin)
            self.ringLayer.add(ringAnimation, forKey: "path")
            
            self.centerLayer.path = self.centerPathOrigin()
            let centerAnimation = self.makePathAnimation(fromValue: self.centerPathPressed, toValue: self.centerPathOrigin)
            self.centerLayer.add(centerAnimation, forKey: "path")
            
        default:
            self.stop()
            self.isCancel = true
            if let closure = self.buttonAction {
                closure(.didCancel)
            }
        }
        
        self.setNeedsDisplay()
    }
}

// MARK: - Drawing
extension MXPressButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if self.isPressed {} else {
            self.centerLayer.frame = self.bounds
            self.centerLayer.path = self.centerPathOrigin()
            
            self.ringLayer.frame = self.bounds
            self.ringLayer.path = self.ringPathOrigin()
        }
    }
    
    @objc fileprivate func displayLinkTick() {
        
        tempInterval += 1 / 60.0
        self.currentInterval = tempInterval
        progress = tempInterval / maxInterval
        
        if tempInterval >= maxInterval {
            
            self.stop()
            isTimeOut = true
            if let closure = self.buttonAction {
                closure(.end)
            }
            
            self.currentInterval = 0.0
        }
        
        if self.progress > 0 {
            self.setNeedsDisplay()
        }
    }
    
    func stop() {
        isPressed = false
//        tempInterval = 0.0
        // 为了让动画结束以后才开始计时
        tempInterval = -0.2
        progress = 0.0
        
        self.progressLayer.strokeEnd = 0;
        self.progressLayer.removeFromSuperlayer()
        self.displayLink.isPaused = true
        self.setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        // Drawing code
        if self.isPressed {
            let ringFrame = self.frame(insetByRadius: self.ringRadiusPressed)
            
            var progressFrame: CGRect = .zero
            if let width = self.progressLineWidth {
                let radius = width / 2.0
                progressFrame = ringFrame.insetBy(dx: radius, dy: radius)
            } else {
                progressFrame = ringFrame.insetBy(dx: 2.0, dy: 2.0)
            }
            let progressPath = UIBezierPath(roundedRect: progressFrame, cornerRadius: progressFrame.width/2.0)
            self.progressLayer.path = progressPath.cgPath
            self.progressLayer.strokeEnd = CGFloat(self.progress)
            
            if self.progress < (self.minInterval / self.maxInterval) {
                if let color = self.progressDisableColor {
                    self.progressLayer.strokeColor = color.cgColor
                }
            } else {
                if let color = self.progressNormalColor {
                    self.progressLayer.strokeColor = color.cgColor
                }
            }
        }
    }
}

// MARK: - Helpers
extension MXPressButton {
    fileprivate func makePathAnimation(fromValue: Any?, toValue: Any?) -> CAAnimation {
        let animation = CABasicAnimation(keyPath: "path")
        
        animation.fromValue = fromValue
        animation.toValue = toValue
        animation.duration = self.animationDuration
        animation.isRemovedOnCompletion = true
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        
        return animation
    }
}

