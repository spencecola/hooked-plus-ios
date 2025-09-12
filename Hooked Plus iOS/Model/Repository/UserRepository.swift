//
//  UserRepository.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 9/12/25.
//

import Combine
import FirebaseFirestore

class UserRepository: Repository {
    private let db = Firestore.firestore()
    private var authManager: AuthManagable
    var data: AnyPublisher<DataResult<UserData>, Never>
    
    init(authManager: AuthManagable) {
        self.authManager = authManager
        self.data = UserRepository.userDataPipeline(db: db, authManager: authManager)
    }
    
    func put(data: UserData) {
        guard case .authenticated(let user) = authManager.state else {
            return
        }
        
        // update the firestore user's document
        db.collection("users").document(user.uid).setData(data.toDictionary())
    }
    
    /// A data pipeline which will create a publisher off of user ID for updating user data based off of the user document
    static func userDataPipeline(db: Firestore, authManager: AuthManagable) -> AnyPublisher<DataResult<UserData>, Never> {
        authManager.statePublisher.compactMap { state in
            if case .authenticated(let user) = state {
                return user.uid
            } else {
                return nil
            }
        }.flatMap { (userId: String) in
            let subject = CurrentValueSubject<DataResult<UserData>, Never>(DataResult.uninitialized)
            let listener = db.collection("users").document(userId).addSnapshotListener { document, error in
                
                subject.send(DataResult.loading(data: subject.value.data))
                
                // if error is present, send failure
                if let error {
                    subject.send(DataResult.failure(data: subject.value.data, error: error))
                    return
                }
                
                guard let documentData = document?.data() else {
                    return
                }
                // send success with data
                subject.send(DataResult.success(data: UserData(dictionary: documentData)))
            }
            return subject
                .compactMap { $0 }
                .handleEvents(receiveCancel: { listener.remove() })
                .eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
}
