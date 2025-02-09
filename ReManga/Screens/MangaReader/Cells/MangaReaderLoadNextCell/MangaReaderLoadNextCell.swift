//
//  MangaReaderLoadNextCell.swift
//  ReManga
//
//  Created by Даниил Виноградов on 17.04.2023.
//

import MvvmFoundation
import UIKit

class MangaReaderLoadNextCell<VM: MangaReaderLoadNextViewModel>: MvvmCollectionViewCell<VM> {
    @IBOutlet private var bottomConstraint: NSLayoutConstraint!
    @IBOutlet private var titleLabel: UILabel!
    private var clicked: Bool = false
    private var nextText: String = ""

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        collectionView?.panGestureRecognizer.addTarget(self, action: #selector(panGesture(_:)))
    }

    override func setup(with viewModel: VM) {
        bind(in: disposeBag) {
            rx.nextText <- viewModel.nextAvailable.map { $0 ? "Потяните, что бы загрузить следующую главу" : "Потяните, что бы закрыть" }
        }
        titleLabel.text = nextText
    }

    @objc func panGesture(_ gesture: UIGestureRecognizer) {
        guard let collectionView = gesture.view as? UICollectionView
        else { return }

        if gesture.state == .changed {
            let offset = collectionView.contentOffset.y
            let maxVal = collectionView.contentSize.height - collectionView.frame.height + collectionView.contentInset.bottom + collectionView.layoutMargins.bottom
            let res = offset - maxVal
            bottomConstraint.constant = max(res, 0)

            if res > 100, !clicked {
                clicked = true
                titleLabel.text = "Отпустите"
                
                #if !os(xrOS)
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                #endif
            } else if res <= 100 {
                titleLabel.text = nextText
                clicked = false
            }
        } else if gesture.state == .ended {
            clicked = false
            titleLabel.text = nextText

            if bottomConstraint.constant > 100 {
                collectionView.setContentOffset(CGPoint(x: 0, y: 44.0), animated: false)
                viewModel.loadNext.accept(())
            }

            UIView.animate(withDuration: 0.3) { [self] in
                bottomConstraint.constant = 0
                layoutIfNeeded()
            }
        }
    }
}

private extension UICollectionViewCell {
    var collectionView: UICollectionView? {
        var view = superview
        while view != nil {
            if let view = view as? UICollectionView {
                return view
            }
            view = view?.superview
        }
        return nil
    }
}
