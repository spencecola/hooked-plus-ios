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
    
    func setProfileIcon(selectedItem: PhotosPickerItem) async {
        do {
            let profileIcon = try await UserService.uploadProfileIcon(selectedItem: selectedItem)
            guard var userData = state.data else {
                return
            }
            userData.profileIcon = profileIcon
//            repository.put(data: userData)
        } catch {
            print("Failed to upload profile icon: \(error)")
        }
    }
    
    func signout() {
        authManager.signOut()
    }
}
