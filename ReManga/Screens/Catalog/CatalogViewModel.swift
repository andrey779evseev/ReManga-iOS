//
//  CatalogViewModel.swift
//  ReManga
//
//  Created by Даниил Виноградов on 07.04.2023.
//

import MvvmFoundation
import RxSwift
import RxRelay

struct CatalogViewConfig {
    var title: String
    var isSearchAvailable: Bool
    var isFiltersAvailable: Bool
    var isApiSwitchAvailable: Bool
    var filters: [ApiMangaTag]
    var apiKey: ContainerKey.Backend?

    static var `default`: CatalogViewConfig {
        .init(title: "Каталог", isSearchAvailable: true, isFiltersAvailable: true, isApiSwitchAvailable: true, filters: [], apiKey: nil)
    }
}

protocol CatalogViewModelProtocol: BaseViewModelProtocol {
    var items: Observable<[MangaCellViewModel]> { get }
    var searchQuery: BehaviorRelay<String?> { get }
    var isSearchAvailable: BehaviorRelay<Bool> { get }
    var isFiltersAvailable: BehaviorRelay<Bool> { get }
    var filters: BehaviorRelay<[ApiMangaTag]> { get }

    func loadNext()
    func showDetails(for model: MangaCellViewModel)
    func showFilters()
}

class CatalogViewModel: BaseViewModelWith<CatalogViewConfig>, CatalogViewModelProtocol {
    public let allItems = BehaviorRelay<[MangaCellViewModel]>(value: [])
    public let searchItems = BehaviorRelay<[MangaCellViewModel]>(value: [])
    public let searchQuery = BehaviorRelay<String?>(value: "")
    public let isSearchAvailable = BehaviorRelay<Bool>(value: true)
    public let isFiltersAvailable = BehaviorRelay<Bool>(value: true)
    public let filters = BehaviorRelay<[ApiMangaTag]>(value: [])

    private var currentSearchTask: Task<Void, Never>?

    public var items: Observable<[MangaCellViewModel]> {
        Observable.combineLatest(allItems, searchItems).map { [unowned self] (all, search) in
            if searchQuery.value.isNilOrEmpty {
                return all
            }
            return search
        }
    }

    override func binding() {
        super.binding()

        if apiKey == nil {
            ($apiKey <- Properties.shared.$backendKey).disposed(by: disposeBag)
        }

        bind(in: disposeBag) {
            searchQuery.bind { [unowned self] _ in
                currentSearchTask?.cancel()
                currentSearchTask = Task {
                    await fetchSearchItems()
                }
            }

            $apiKey.bind { [unowned self] key in
                api = Mvvm.shared.container.resolve(key: key?.key)
                resetVM()
            }
        }
    }

    override func prepare(with model: CatalogViewConfig) {
        apiKey = model.apiKey
        title.accept(model.title)
        isSearchAvailable.accept(model.isSearchAvailable)
        isFiltersAvailable.accept(model.isFiltersAvailable)
        filters.accept(model.filters)
        state.accept(.loading)
    }

    func loadNext() {
        guard searchQuery.value.isNilOrEmpty
        else { return }

        currentFetchTask = Task { await fetchItems() }
    }

    func showDetails(for model: MangaCellViewModel) {
        navigate(to: MangaDetailsViewModel.self, with: .init(id: model.id.value, apiKey: api.key), by: .show)
    }

    func showFilters() {
        navigate(to: CatalogFiltersViewModel.self, with: .init(apiKey: api.key, filters: filters), by: .present(wrapInNavigation: true))
    }

    // MARK: - Private
    private var isLoading = false
    private var page = 0
    private var currentFetchTask: Task<(), Never>?
    private var api: ApiProtocol = Mvvm.shared.container.resolve()
    @Binding private var apiKey: ContainerKey.Backend?
}

// MARK: - Private functions
extension CatalogViewModel {
    private func resetVM() {
        isLoading = false
        page = 0
        allItems.accept([])
        currentFetchTask?.cancel()
        loadNext()
    }

    private func fetchItems() async {
        if isLoading { return }
        isLoading = true
        
        page += 1
        await performTask { [self] in
            let res = try await api.fetchCatalog(page: page, filters: filters.value)
            allItems.accept(allItems.value + res.map { $0.cellModel })
            isLoading = false
            state.accept(.default)
        }
    }

    private func fetchSearchItems() async {
        await performTask { [self] in
            guard let query = searchQuery.value,
                  !query.isEmpty
            else { return searchItems.accept([]) }

            let res = try await api.fetchSearch(query: query, page: 1)
            searchItems.accept(res.map { $0.cellModel })
            state.accept(.default)
        }
    }
}

private extension ApiMangaModel {
    var cellModel: MangaCellViewModel {
        let res = MangaCellViewModel()
        res.prepare(with: self)
        return res
    }
}
