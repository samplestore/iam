//
//  CategoryListViewModel.swift
//  iam
//
//  Created by HoJun Lee on 2017. 11. 24..
//  Copyright © 2017년 HoJun Lee. All rights reserved.
//

import Domain
import Worker
import RxSwift
import RxCocoa

final class CategoryListViewModel: ViewModelType {
    struct Input {
        // realm 기능 테스트 용
        let title: Driver<String>
        let details: Driver<String>
        let saveTrigger: Driver<Void>
        let cancelTrigger: Driver<Void>
        // 원래 기능
        let trigger: Driver<Void>
        let selection: Driver<IndexPath>
    }
    struct Output {
        // Realm test
        let saved: Driver<Bool>
        let saveEnabled: Driver<Bool>
        // Originality
        let fetching: Observable<Bool>
        let categories: Driver<[IamCategory]>
//        let selectedCategory: Driver<IamCategory>
    }
    
    private let useCase: CategoryUseCase
    private let flowController: CategoryListFlowController
    
    init(useCase: CategoryUseCase, flowController: CategoryListFlowController) {
        self.useCase = useCase
        self.flowController = flowController
    }
    
    func OutputTransformer(input: Input) -> Output {
        let activityIndicator = ActivityIndicator()

        let content = Driver.combineLatest(input.title, input.details ) { (title, detail) in
            return (title, detail)
        }
        
        let save = input.saveTrigger.withLatestFrom(content)
            .map { (title, content) in
                return IamCategory(id: "1", name: "work", depiction: "worker holic", aa: "bb")
            }
            .flatMapLatest { [unowned self] in
                return self.useCase.save(item: $0)
                    .trackActivity(activityIndicator)
                    .asDriverOnErrorJustComplete()
        }
        
        let saved = Driver.combineLatest(save, activityIndicator.asDriver()) {
            return !$0.isEmpty && !$1
        }
        
        let canSave = Driver.combineLatest(content, activityIndicator.asDriver()) {
            return !$0.0.isEmpty && !$0.1.isEmpty && !$1
        }

        let fetching = activityIndicator.asObservable()
        let cates = input.trigger.flatMapLatest { _ in
            return self.useCase
                .categories()
                .trackActivity(activityIndicator)
                .asDriverOnErrorJustComplete()
                .map { $0 }
        }
        return Output(saved: saved, saveEnabled: canSave, fetching: fetching, categories: cates)
    }
}
