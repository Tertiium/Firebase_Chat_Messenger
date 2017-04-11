//
//  NewMessageController.swift
//  GameOfChats
//
//  Created by user on 21/03/17.
//  Copyright © 2017 yangguozhang. All rights reserved.
//

import UIKit
import Firebase

class NewMessageController: UITableViewController {

    let cellID = "cellId"
    
    var users = [User]()
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(self.handleCancel))
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellID)
        
        fetchUser()
    }
    
    // MARK: - Functions
    func fetchUser() {
        FIRDatabase.database().reference().child("users").observe(.childAdded, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject]{
                let user = User()
                user.id = snapshot.key
                
                // if you use this setter, your app will crash if your class properties don't exactly match up with the firebase dictionary keys
                user.setValuesForKeys(dictionary)
                
                self.users.append(user)
                
                // This will crash bacause of background thread, so lets use dispatch_async to fix
                DispatchQueue.main.async{
                    self.tableView.reloadData()
                }
            }
            
            //
            //print("User found")
            //print(snapshot)
            
        }, withCancel: nil)
    }
    
    func handleCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID , for: indexPath) as? UserCell
        
        let user = users[indexPath.row]
        cell?.textLabel?.text = user.name
        cell?.detailTextLabel?.text = user.email
        
        if let profileImageUrl = user.profileImageUrl{
            
            cell?.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
        }
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    var messagesController: MessagesController?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true) { 
            print("Dismiss completed")
            let user = self.users[indexPath.row]
            self.messagesController?.showChatControllerForUser(user: user )
        }
    }
}
