import Combine
import _PhotosUI_SwiftUI

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
    
    func refreshProfile() {
        repository.refresh()
    }
    
    func setProfileIcon(selectedItem: PhotosPickerItem) async {
        do {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                state = DataResult.loading(data: state.data)
            }
            
            let updatedUser = try await UserService.uploadProfileIcon(selectedItem: selectedItem)
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                state = DataResult.success(data: updatedUser)
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                state = DataResult.failure(data: state.data, error: error)
            }
            print("Failed to upload profile icon: \(error)")
        }
    }
    
    func signout() {
        authManager.signOut()
    }
}
