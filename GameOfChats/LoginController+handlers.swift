//
//  LoginController+handlers.swift
//  GameOfChats
//
//  Created by user on 22/03/17.
//  Copyright © 2017 yangguozhang. All rights reserved.
//

import UIKit
import Firebase

extension LoginController: UINavigationControllerDelegate{
    
    func handleRegister(){
        guard let email = emailTextField.text, let password = passwordTextField.text, let name = nameTextField.text else{
            print("Form is not valid")
            return
        }
        
        FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user: FIRUser?, error) in
            if error != nil{
                print(error!)
                return
            }
            
            guard let uid = user?.uid else{
                return
            }
            
            // Successfully  Authentired user
            let imageName = NSUUID().uuidString
            let storageRef = FIRStorage.storage().reference().child("profile_images").child("\(imageName).jpg")
            
            // Usando Formado JPEG em vez de PNG para poder compactar as imagens
            if let profileImage = self.profileImageView.image, let uploadData = UIImageJPEGRepresentation(self.profileImageView.image!, 0.1) {
                
            //if let uploadData = UIImagePNGRepresentation(self.profileImageView.image!){
                
                storageRef.put(uploadData, metadata: nil, completion: { (metadata, error) in
                    if error != nil{
                        print(error as Any)
                        return
                    }
                    
                    if let profileImageUrl = metadata?.downloadURL()?.absoluteString{
                        let values = ["name": name,"email": email,"profileImageUrl": profileImageUrl  ]
                        self.registerUserIntoDatabaseWithUID(uid: uid, values: values as [String : AnyObject])
                    }
                })
            }
        })
    }
    
    private func registerUserIntoDatabaseWithUID(uid: String, values: [String: AnyObject]){
        let ref = FIRDatabase.database().reference()
        
        let userReference = ref.child("users").child(uid)
        userReference.updateChildValues(values, withCompletionBlock: { (error, ref) in
            if error != nil {
                print(error!)
                return
            }
            
            // self.messagesController?.fetchUserAndSetupNavBarTitle()
            // or
            // self.messagesController?.navigationItem.title = values["name"] as! String?
            let user = User()
            // this setter potenially crashes if keys dont match9
            user.setValuesForKeys(values)
            self.messagesController?.setupNavBarWithUser(user: user)
            
            //print("Saved user successfully into Firebase db")
            self.dismiss(animated: true, completion: nil)
            
        })
    }
    
    func handleSelectProfileImageView(){
        let picker = UIImagePickerController()
        
        picker.delegate = self
        picker.allowsEditing = true
        
        present(picker, animated: true, completion: nil)
    }
 
    
}

extension LoginController: UIImagePickerControllerDelegate{
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage{
            selectedImageFromPicker = editedImage
        }else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage{
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker{
            profileImageView.image = selectedImage
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("Canceled picker")
        dismiss(animated: true, completion: nil)
    }
    
}
