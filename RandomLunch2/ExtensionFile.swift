//
//  ExtensionFile.swift
//  RandomLunch2
//
//  Created by きたむら on 2018/10/19.
//  Copyright © 2018年 ain13ikon. All rights reserved.
//
import UIKit

@IBDesignable
extension UIView {
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
            // 本来は label.layer.masksToBounds = true
            // 条件式でnewValue>0の時trueが入る
        }
    }
    
    @IBInspectable
    var borderWidth: CGFloat {
        get {
            return self.layer.borderWidth
        }
        set {
            self.layer.borderWidth = newValue
        }
    }
    
    @IBInspectable
    var borderColor: UIColor? {
        get {
            return UIColor(cgColor: self.layer.borderColor!)
        }
        set {
            self.layer.borderColor = newValue?.cgColor
        }
    }
    
}

@IBDesignable
class PaddingLabel: UILabel {
    @IBInspectable var paddingX: CGFloat = 0
    @IBInspectable var paddingY: CGFloat = 0
    
    override func drawText(in rect: CGRect) {
        let contentSize = super.intrinsicContentSize    //labelテキストの(width, height)を取得
        let newRect = CGRect(                           //UILabelに対するテキストの描画位置を指定
            x: paddingX,                //左右の余白
            y: paddingY,                //上下の余白
            width: contentSize.width,   //テキストの横幅
            height:contentSize.height   //テキストの縦幅
        )
        super.drawText(in: newRect)     //テキストを描画
    }
}


private var maxLengths = [UITextField: Int]()

extension UITextField {
    
    @IBInspectable var maxLength: Int {
        get {
            guard let length = maxLengths[self] else {
                return Int.max
            }
            
            return length
        }
        set {
            maxLengths[self] = newValue
            addTarget(self, action: #selector(limitLength), for: .editingChanged)
        }
    }
    
    @objc func limitLength(textField: UITextField) {
        guard let prospectiveText = textField.text, prospectiveText.count > maxLength else {
            return
        }
        
        let selection = selectedTextRange
        let maxCharIndex = prospectiveText.index(prospectiveText.startIndex, offsetBy: maxLength)
        
        //#if swift(>=4.0)
        text = String(prospectiveText[..<maxCharIndex])
        /*
         #else
         text = prospectiveText.substring(to: maxCharIndex)
         #endif
         */
        
        selectedTextRange = selection
    }
    
}

