//
//  BaseSampleView.swift
//  SampleForageSDK
//
//  Created by Danilo Joksimovic on 2023-12-13.
//

import Foundation
import UIKit

class BaseSampleView: UIView {
    func anchorContentViewSubviews(contentView: UIView, subviews: [UIView]) {
        for (index, view) in subviews.enumerated() {
            view.anchor(
                top:
                index == 0 ?
                    contentView.safeAreaLayoutGuide.topAnchor
                    : subviews[index - 1].safeAreaLayoutGuide.bottomAnchor,
                leading: contentView.safeAreaLayoutGuide.leadingAnchor,
                bottom: nil,
                trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
                centerXAnchor: contentView.centerXAnchor,
                padding: UIEdgeInsets(top: index == 0 ? 0 : 24, left: 24, bottom: 0, right: 24)
            )
        }
    }
}
