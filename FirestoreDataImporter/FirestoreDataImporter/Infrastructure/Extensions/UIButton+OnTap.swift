//
//  UIButton+OnTap.swift
//  FirestoreDataImporter
//
//  Created by Matvei Khlestov on 06.01.2026.
//


import UIKit

extension UIButton {
    func onTap(_ target: Any?, action: Selector) {
        self.addTarget(target, action: action, for: .touchUpInside)
    }
}
