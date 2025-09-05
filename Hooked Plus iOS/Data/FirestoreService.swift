//
//  Firebase.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 9/5/25.
//

import FirebaseFirestore

class FirebaseService {
    let db = Firestore.firestore()
   
    init(collection: String) {
        db.collection(collection).document("sample").setData(["key": "value"]) { error in
            if let error = error {
                print("Error: \(error)")
            } else {
                print("Document added successfully")
            }
        }
    }
}
