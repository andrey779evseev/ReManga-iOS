//
//  DownloadDetailsViewController.swift
//  ReManga
//
//  Created by Даниил Виноградов on 08.05.2023.
//

import UIKit
import MvvmFoundation

class DownloadDetailsViewController<VM: DownloadDetailsViewModel>: BaseViewController<VM> {
    @IBOutlet private var collectionView: UICollectionView!
    private lazy var dataSource = MvvmCollectionViewDataSource(collectionView: collectionView)

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never

        collectionView.dataSource = dataSource
        collectionView.collectionViewLayout = MvvmCollectionViewLayout(dataSource)

        bind(in: disposeBag) {
            dataSource.applyModels <- viewModel.items
            viewModel.itemSelected <- dataSource.modelSelected
            dataSource.deselectItems <- viewModel.deselectItems
        }
        
        dataSource.trailingSwipeActionsConfigurationProvider = { indexPath in
            .init(actions: [.init(style: .destructive, title: "Удалить", handler: { [unowned self] _, _, _ in
                let model = dataSource.snapshot().sectionIdentifiers[indexPath.section].items[indexPath.item]
                viewModel.deleteModel(model)
            })])
        }
    }

}
