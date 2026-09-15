/*
 SPDX-License-Identifier: AGPL-3.0-or-later

 Copyright (C) 2025 - 2026 emexlab

 This file is part of Nyxian.

 Nyxian is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 Nyxian is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU Affero General Public License for more details.

 You should have received a copy of the GNU Affero General Public License
 along with Nyxian. If not, see <https://www.gnu.org/licenses/>.
*/

import UIKit
import ObjectiveC.runtime

extension UIViewController {
    func presentConfirmationAlert(
        title: String,
        message: String,
        confirmTitle: String = "Confirm",
        confirmStyle: UIAlertAction.Style = .default,
        confirmHandler: @escaping () -> Void,
        addHandler: Bool = true
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if addHandler {
            alert.addAction(UIAlertAction(title: confirmTitle, style: confirmStyle) { _ in
                confirmHandler()
            })
        }
        
        self.present(alert, animated: true)
    }
}

extension UIBarButtonItem {
    static let swizzleBarButtonitem: Void = {
        let originalSel  = Selector(("init"))
        let swizzledSel  = #selector(UIBarButtonItem.themed_init)

        guard
            let original  = class_getInstanceMethod(UIBarButtonItem.self, originalSel),
            let swizzled  = class_getInstanceMethod(UIBarButtonItem.self, swizzledSel)
        else { return }

        method_exchangeImplementations(original, swizzled)
    }()

    @objc func themed_init() -> UIBarButtonItem {
        let item = self.themed_init()

        if #available(iOS 26.0, *) {
            item.tintColor = LDETheme.currentTheme?.textColor
            // FIXME: notif changes dont work as exptected
        }
        return item
    }
}

extension UIViewController {
    static let swizzlePresentAndDismissOnce: Void = {
        swizzle(UIViewController.self, original: #selector(UIViewController.present(_:animated:completion:)), swizzled: #selector(UIViewController.swizzled_present(_:animated:completion:)))
    }()
    
    private static func swizzle(_ cls: AnyClass, original: Selector, swizzled: Selector) {
        guard let originalMethod = class_getInstanceMethod(cls, original),
              let swizzledMethod = class_getInstanceMethod(cls, swizzled) else { return }
        
        let didAdd = class_addMethod(cls, original, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
        
        if didAdd {
            class_replaceMethod(cls, swizzled, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
    
    @objc func swizzled_present(_ viewControllerToPresent: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        let isSheet = viewControllerToPresent.modalPresentationStyle == .formSheet ||
                      viewControllerToPresent.modalPresentationStyle == .pageSheet
        
        if isSheet {
            NXWindowServer.shared().unfocusFocusedWindow()
        }
        
        swizzled_present(viewControllerToPresent, animated: animated, completion: completion)
    }
}
