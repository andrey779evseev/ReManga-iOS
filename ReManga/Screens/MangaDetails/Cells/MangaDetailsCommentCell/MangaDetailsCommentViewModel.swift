//
//  MangaDetailsCommentViewModel.swift
//  ReManga
//
//  Created by Даниил Виноградов on 16.04.2023.
//

import MvvmFoundation
import RxRelay

class MangaDetailsCommentViewModel: BaseViewModelWith<ApiMangaCommentModel> {
    private var id: String = ""
    let name = BehaviorRelay<String?>(value: nil)
    let date = BehaviorRelay<String?>(value: nil)
    let image = BehaviorRelay<String?>(value: nil)
    let score = BehaviorRelay<Int>(value: 0)
    let moreButtonText = BehaviorRelay<String?>(value: nil)
    let content = BehaviorRelay<NSAttributedString?>(value: nil)
    let hierarchy = BehaviorRelay<Int>(value: 0)
    let isExpanded = BehaviorRelay<Bool>(value: false)
    let isPinned = BehaviorRelay<Bool>(value: false)
    let isLiked = BehaviorRelay<Bool?>(value: nil)
    let children = BehaviorRelay<[MangaDetailsCommentViewModel]>(value: [])
    let expandedChanged = PublishRelay<Bool>()

    @Injected var api: ApiProtocol

    override func prepare(with model: ApiMangaCommentModel) {
        id = model.id
        name.accept(model.name)
        image.accept(model.imagePath)
        score.accept(model.likes - model.dislikes)
        name.accept(model.name)
        content.accept(model.text)
        hierarchy.accept(model.hierarchy)
        isPinned.accept(model.isPinned)
        isLiked.accept(model.isLiked)
        children.accept(model.children.map { .init(with: $0) })
        
        if model.children.count > 0 {
            moreButtonText.accept("Ответы (\(model.allChildrenCount))")
        } else {
            moreButtonText.accept(nil)
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        date.accept(dateFormatter.string(from: model.date))
    }

    override func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    override func isEqual(to other: MvvmViewModel) -> Bool {
        guard let other = other as? Self else { return false }
        return id == other.id
    }

    func toggleLike() {
        Task {
            let value = isLiked.value == true ? nil : true
            let score = try await api.markComment(id: id, value)
            self.isLiked.accept(value)
            self.score.accept(score)
        }
    }

    func toggleDislike() {
        Task {
            let value = isLiked.value == false ? nil : false
            let score = try await api.markComment(id: id, value)
            self.isLiked.accept(value)
            self.score.accept(score)
        }
    }
}

extension MangaDetailsCommentViewModel {
    var allChildren: [MangaDetailsCommentViewModel] {
        var res: [MangaDetailsCommentViewModel] = []
        res.append(self)
        children.value.forEach { item in
            res.append(contentsOf: item.allChildren)
        }
        return res
    }

    var allExpandedChildren: [MangaDetailsCommentViewModel] {
        var res: [MangaDetailsCommentViewModel] = []
        res.append(self)
        if isExpanded.value {
            children.value.forEach { item in
                res.append(contentsOf: item.allExpandedChildren)
            }
        }
        return res
    }

}
