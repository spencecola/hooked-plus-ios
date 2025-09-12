//
//  HookedAssembly.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 9/5/25.
//

import Swinject

struct HookedAssembly: Assembly {
    private(set) static var resolver: Resolver = Assembler().resolver
    
    func assemble(container: Swinject.Container) {
        HookedAssembly.resolver = container.synchronize()
        
        container.register(AuthManagable.self) { _ in
            AuthManager()
        }.inObjectScope(.container)
        
        container.register((any Repository<UserData>).self) { resolver in
            let authManager = resolver.resolve(AuthManagable.self)!
            return UserRepository(authManager: authManager)
        }
        
        container.register(ProfileViewModel.self) { resolver in
            let repository = resolver.resolve((any Repository<UserData>).self)!
            let authManager = resolver.resolve(AuthManagable.self)!
            return ProfileViewModel(repository: repository, authManager: authManager)
        }
    }
}
