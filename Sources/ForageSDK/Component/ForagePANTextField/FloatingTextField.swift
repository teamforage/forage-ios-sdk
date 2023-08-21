//
//  FloatingTextField.swift
//  
//
//  Created by Milos Bogdanovic on 08/16/23.
//

import UIKit

public class FloatingTextField: UITextField {
    
    public enum FloatingDisplayStatus {
        case always
        case never
        case defaults
    }
    
    // MARK: - Properties
    
    private var floatingPlaceholderLabel: UILabel = UILabel()
    private var floatPlaceholderColor: UIColor = UIColor.gray
    private var floatPlaceholderActiveColor: UIColor = UIColor.gray
    private var floatingLabelShowAnimationDuration = 0.3
    private var floatingDisplayStatus: FloatingDisplayStatus = .defaults
    private var paddingX: CGFloat = 10
    private var isFloatLabelShowing: Bool = false
    private var animateFloatPlaceholder: Bool = true
    
    public var borderWidth: CGFloat = 0.1 {
        didSet { layer.borderWidth = borderWidth }
    }
    
    public var borderColor: UIColor = .black {
        didSet { layer.borderColor = borderColor.cgColor }
    }
    
    public var borderCornerRadius: CGFloat = 4
    {
        didSet { layer.cornerRadius = borderCornerRadius }
    }
    
    public var floatPlaceholderFont = UIFont.systemFont(ofSize: 10.0) {
        didSet {
            floatingPlaceholderLabel.font = floatPlaceholderFont
            invalidateIntrinsicContentSize()
        }
    }
    
    public var paddingYFloatLabel: CGFloat = 4 {
        didSet { invalidateIntrinsicContentSize() }
    }
    
    public var placeholderColor: UIColor? {
        didSet {
            guard let color = placeholderColor else { return }
            attributedPlaceholder = NSAttributedString(string: placeholderFinal,
                                                       attributes: [NSAttributedString.Key.foregroundColor:color])
        }
    }
    
    private var x: CGFloat {
        if let leftView = leftView {
            return leftView.frame.origin.x + leftView.bounds.size.width - paddingX
        }
        
        return paddingX
    }
    
    private var floatLabelWidth: CGFloat {
        var width = bounds.size.width
        
        if let leftViewWidth = leftView?.bounds.size.width {
            width -= leftViewWidth
        }
        
        if let rightViewWidth = rightView?.bounds.size.width {
            width -= rightViewWidth
        }
        
        return width - (self.x * 2)
    }
    
    private var placeholderFinal: String {
        if let attributed = attributedPlaceholder { return attributed.string }
        return placeholder ?? " "
    }
    
    // MARK: - Initialization
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        floatingPlaceholderLabel.frame = CGRect.zero
        floatingPlaceholderLabel.alpha = 0.0
        floatingPlaceholderLabel.font = floatPlaceholderFont
        floatingPlaceholderLabel.text = placeholderFinal
        
        font = UIFont.systemFont(ofSize: 14, weight: .regular)
        clearButtonMode = .whileEditing
        
        layer.borderWidth = borderWidth
        layer.cornerRadius = borderCornerRadius
        layer.borderColor = borderColor.cgColor
        
        addSubview(floatingPlaceholderLabel)
    }
    
    // MARK: - Private API
    
    private func setFloatLabelAlignment() {
        var newFrame = floatingPlaceholderLabel.frame
        
        if textAlignment == .right {
            newFrame.origin.x = bounds.width - paddingX - newFrame.size.width
        } else if textAlignment == .left {
            newFrame.origin.x = paddingX
        } else if textAlignment == .center {
            newFrame.origin.x = (bounds.width / 2.0) - (newFrame.size.width / 2.0)
        } else if textAlignment == .natural {
            if UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft {
                newFrame.origin.x = bounds.width - paddingX - newFrame.size.width
            }
        }
        
        floatingPlaceholderLabel.frame = newFrame
    }
    
    private func showFloatingLabel(_ animated: Bool) {
        let animations: (() -> Void) = {
            self.floatingPlaceholderLabel.alpha = 1.0
            self.floatingPlaceholderLabel.frame = CGRect(x: self.floatingPlaceholderLabel.frame.origin.x,
                                                         y: self.paddingYFloatLabel,
                                                         width: self.floatingPlaceholderLabel.bounds.size.width,
                                                         height: self.floatingPlaceholderLabel.bounds.size.height)
        }
        
        if animated && animateFloatPlaceholder {
            UIView.animate(withDuration: floatingLabelShowAnimationDuration,
                           delay: 0.0,
                           options: [.beginFromCurrentState,.curveEaseOut],
                           animations: animations) { status in
                DispatchQueue.main.async {
                    self.layoutIfNeeded()
                }
            }
        } else {
            animations()
        }
    }
    
    private func hideFlotingLabel(_ animated: Bool) {
        let animations: (() -> Void) = {
            self.floatingPlaceholderLabel.alpha = 0.0
            self.floatingPlaceholderLabel.frame = CGRect(x: self.floatingPlaceholderLabel.frame.origin.x,
                                                         y: self.floatingPlaceholderLabel.font.lineHeight,
                                                         width: self.floatingPlaceholderLabel.bounds.size.width,
                                                         height: self.floatingPlaceholderLabel.bounds.size.height)
        }
        
        if animated && animateFloatPlaceholder {
            UIView.animate(withDuration: floatingLabelShowAnimationDuration,
                           delay: 0.0,
                           options: [.beginFromCurrentState,.curveEaseOut],
                           animations: animations) { status in
                DispatchQueue.main.async {
                    self.layoutIfNeeded()
                }
            }
        } else {
            animations()
        }
    }
    
    private func insetRectForEmptyBounds(rect: CGRect) -> CGRect {
        return CGRect(x: x, y: 0, width: rect.width - x - paddingX, height: rect.height)
    }
    
    private func insetForSideView(forBounds bounds: CGRect) -> CGRect {
        var rect = bounds
        rect.origin.y = 0
        rect.size.height = bounds.height
        return rect
    }
    
    private func insetRectForBounds(rect: CGRect) -> CGRect {
        guard let placeholderText = floatingPlaceholderLabel.text, !placeholderText.isEmptyString else {
            return insetRectForEmptyBounds(rect: rect)
        }
        
        if floatingDisplayStatus == .never {
            return insetRectForEmptyBounds(rect: rect)
        } else {
            if let text = text, text.isEmptyString && floatingDisplayStatus == .defaults {
                return insetRectForEmptyBounds(rect: rect)
            } else {
                let topInset = paddingYFloatLabel + floatingPlaceholderLabel.bounds.size.height
                let textOriginalY = rect.height / 2.0
                var textY = topInset - textOriginalY
                
                if textY < 0 { textY = topInset }
                
                return CGRect(x: x, y: ceil(textY), width: rect.size.width - x - paddingX, height: rect.height - topInset)
            }
        }
    }
    
    // MARK: - UITextField override properties
    
    override public var borderStyle: UITextField.BorderStyle {
        didSet {
            guard borderStyle != oldValue else { return }
            borderStyle = .none
        }
    }
    
    override public var textAlignment: NSTextAlignment {
        didSet { setNeedsLayout() }
    }
    
    override public var placeholder: String? {
        didSet {
            guard let color = placeholderColor else {
                floatingPlaceholderLabel.text = placeholderFinal
                return
            }
            
            attributedPlaceholder = NSAttributedString(string: placeholderFinal,
                                                       attributes: [NSAttributedString.Key.foregroundColor:color])
        }
    }
    
    override public var attributedPlaceholder: NSAttributedString? {
        didSet { floatingPlaceholderLabel.text = placeholderFinal }
    }
    
    // MARK: - UITextField override methods
    
    override public func textRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.textRect(forBounds: bounds)
        return insetRectForBounds(rect: rect)
    }
    
    override public func editingRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.editingRect(forBounds: bounds)
        return insetRectForBounds(rect: rect)
    }
    
    override public func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.leftViewRect(forBounds: bounds)
        return insetForSideView(forBounds: rect)
    }
    
    override public func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.rightViewRect(forBounds: bounds)
        return insetForSideView(forBounds: rect)
    }
    
    override public func clearButtonRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.clearButtonRect(forBounds: bounds)
        rect.origin.y = (bounds.height - rect.size.height) / 2
        rect.origin.x = bounds.width - rect.size.width - paddingX
        return rect
    }
    
    // MARK: - UIView override layout
    
    override public var intrinsicContentSize: CGSize {
        self.layoutIfNeeded()

        let textFieldIntrinsicContentSize = super.intrinsicContentSize
        let height = textFieldIntrinsicContentSize.height + floatingPlaceholderLabel.bounds.size.height

        return CGSize(width: textFieldIntrinsicContentSize.width, height: height)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        CATransaction.commit()
        
        let floatingLabelSize = floatingPlaceholderLabel.sizeThatFits(floatingPlaceholderLabel.superview!.bounds.size)
        
        floatingPlaceholderLabel.frame = CGRect(x: x,
                                                y: floatingPlaceholderLabel.frame.origin.y,
                                                width: floatingLabelSize.width,
                                                height: floatingLabelSize.height)
        
        setFloatLabelAlignment()
        floatingPlaceholderLabel.textColor = isFirstResponder ? floatPlaceholderActiveColor : floatPlaceholderColor
        
        switch floatingDisplayStatus {
        case .never:
            hideFlotingLabel(isFirstResponder)
        case .always:
            showFloatingLabel(isFirstResponder)
        default:
            if let enteredText = text,!enteredText.isEmptyString {
                showFloatingLabel(isFirstResponder)
            } else {
                hideFlotingLabel(isFirstResponder)
            }
        }
    }
}
