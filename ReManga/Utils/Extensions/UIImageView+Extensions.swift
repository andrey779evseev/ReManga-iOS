//
//  UIImageView+Extensions.swift
//  ReManga
//
//  Created by Даниил Виноградов on 12.04.2023.
//

import UIKit
import Kingfisher
import RxSwift

extension UIImageView {

    func setImage(_ url: String?, completion: (() -> Void)? = nil) {
        guard let url else {
            image = nil
            completion?()
            return
        }

        kf.setImage(with: URL(string: url)) { _ in
            completion?()
        }

    }
}

extension Reactive where Base: UIImageView {
    public func imageUrl(with activityIndicator: UIActivityIndicatorView? = nil, auth modifier: AnyModifier? = nil) -> Binder<String?> {
        Binder(self.base) { imageView, image in
            guard let image else { return }
            activityIndicator?.startAnimating()

            var options: KingfisherOptionsInfo = [.diskCacheExpiration(.seconds(60*5))]
            if let modifier {
                options.append(.requestModifier(modifier))
            }
            
            imageView.kf.setImage(with: URL(string: image), options: options) { _ in
                activityIndicator?.stopAnimating()
            }
        }
    }
}
