//
//  KeyboardService.swift
//  RandomLunch2
//
//  Created by きたむら on 2018/10/18.
//  Copyright © 2018年 ain13ikon. All rights reserved.
//

import UIKit

class KeyboardService: NSObject, UITextFieldDelegate {
    static var serviceSingleton = KeyboardService()
    var measuredSize: CGRect = CGRect.zero
    
    @objc class func keyboardHeight() -> CGFloat {
        let keyboardSize = KeyboardService.keyboardSize()
        
        
        //keyboardSize
        return keyboardSize.size.height
    }
    
    @objc class func keyboardSize() -> CGRect {
        return serviceSingleton.measuredSize
    }
        
    private func observeKeyboardNotifications() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(self.keyboardChange), name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    private func observeKeyboard() {
        let field = UITextField()
        field.delegate = self
        UIApplication.shared.windows.first?.addSubview(field)
        field.becomeFirstResponder()    //キーボードを開く(最初のレスポンダ)
        field.resignFirstResponder()    //キーボードを閉じる
        field.removeFromSuperview()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        print(#function)
    }
    
    @objc private func keyboardChange(_ notification: Notification) {
        guard measuredSize == CGRect.zero, let info = notification.userInfo,
            let value = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
            else { return }
        
        measuredSize = value.cgRectValue
    }
    
    override init() {
        super.init()
        observeKeyboardNotifications()
        observeKeyboard()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
