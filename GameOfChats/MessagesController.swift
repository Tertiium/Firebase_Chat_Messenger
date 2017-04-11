//
//  ViewController.swift
//  GameOfChats
//
//  Created by user on 09/03/17.
//  Copyright © 2017 yangguozhang. All rights reserved.
//

import UIKit
import Firebase

class MessagesController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
            
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(self.handleLogout))
        
        // user is not logged in
        if FIRAuth.auth()?.currentUser?.uid == nil{
            perform(#selector(self.handleLogout), with: nil, afterDelay: 0)
        }
        
    }
    
    func handleLogout(){
        
        do{
           try FIRAuth.auth()?.signOut()
        }catch let logoutError {
            print(logoutError.localizedDescription)
        }
        
        let loginController = LoginController()
        present(loginController, animated: true, completion: nil)
    }
}

