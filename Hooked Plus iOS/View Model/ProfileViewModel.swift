//
//  ProfileViewModel.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 9/12/25.
//

import Combine

class ProfileViewModel: ObservableObject {
    
    @Published var state: DataResult<UserData> = .uninitialized
    
    private var repository: any Repository<UserData>
    
    private var authManager: AuthManagable
    
    init(repository: any Repository<UserData>, authManager: AuthManagable) {
        self.repository = repository
        self.authManager = authManager
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        repository.data.assign(to: &$state)
    }
    
    func setFirstName(firstName: String) {
        guard var userData = state.data else {
            return
        }
        
        userData.firstName = firstName
        repository.put(data: userData)
    }
    
    func setLastName(lastName: String) {
        guard var userData = state.data else {
            return
        }
        
        userData.lastName = lastName
        repository.put(data: userData)
    }
    
    func signout() {
        authManager.signOut()
    }
}
