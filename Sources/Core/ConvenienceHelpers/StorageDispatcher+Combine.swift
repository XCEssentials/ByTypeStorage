import Combine

//---

public
extension Publisher where Output == StorageDispatcher.AccessEventReport, Failure == Never
{
    var onProcessed: AnyPublisher<StorageDispatcher.ProcessedAccessEventReport, Failure>
    {
        return self
            .compactMap {
                
                switch $0.outcome
                {
                    case .processed(let mutations):
                        
                        return .init(
                            mutations: mutations,
                            storage: $0.storage,
                            env: $0.env
                        )
                        
                    default:
                        
                        return nil
                }
            }
            .eraseToAnyPublisher()
    }
    
    var onRejected: AnyPublisher<StorageDispatcher.RejectedAccessEventReport, Failure>
    {
        return self
            .compactMap {
                
                switch $0.outcome
                {
                    case .rejected(let reason):
                        
                        return .init(
                            reason: reason,
                            storage: $0.storage,
                            env: $0.env
                        )
                        
                    default:
                        
                        return nil
                }
            }
            .eraseToAnyPublisher()
    }
}

//---

public
extension Publisher where Output == StorageDispatcher.ProcessedAccessEventReport, Failure == Never
{
    var mutation: AnyPublisher<ByTypeStorage.MutationAttemptOutcome, Failure>
    {
        self
            .flatMap(
                \.mutations.publisher
            )
            .map(
                \.outcome
            )
            .eraseToAnyPublisher()
    }
    
    func mutation<T: SomeMutationDecriptor>(
        _: T.Type
    ) -> AnyPublisher<T, Failure> {
        
        mutation
            .compactMap(
                T.init(from:)
            )
            .eraseToAnyPublisher()
    }
}
