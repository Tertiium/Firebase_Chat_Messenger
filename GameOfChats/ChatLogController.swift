//
//  ChatLogController.swift
//  GameOfChats
//
//  Created by user on 30/03/17.
//  Copyright © 2017 yangguozhang. All rights reserved.
//

import UIKit
import Firebase

class ChatLogController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    var user : User?{
        didSet{
            navigationItem.title = user?.name
            
            observeMessages()
        }
    }
    
    var messages = [Message]()
    
    let cellId = "cellId"
    
    lazy var inputTextField : UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter message..."
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        return textField
    }()
    
    private func estimateFrameForText(text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    func observeMessages() {
        guard let uid = FIRAuth.auth()?.currentUser?.uid, let toId = user?.id else {
            return
        }
        
        let userMessagesRef = FIRDatabase.database().reference().child("user-messages").child(uid).child(toId)
        userMessagesRef.observe(.childAdded, with: { (snapshot) in
            
            let messageId = snapshot.key
            let messagesRef = FIRDatabase.database().reference().child("messages").child(messageId)
            
            messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
                
                guard let dictionary = snapshot.value as? [String: AnyObject] else {
                    return
                }
                
                // Do we need to attempt filtering anymore?
                self.messages.append(Message(dictionary: dictionary))
                
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                    // scroll to the last index
                    let indexPath = NSIndexPath(item: self.messages.count-1, section: 0)
                    self.collectionView?.scrollToItem(at: indexPath as IndexPath, at: .bottom, animated: true)
                }
                
            }, withCancel: nil)
            
        }, withCancel: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.contentInset = UIEdgeInsetsMake(8, 0, 8, 0)
        //collectionView?.scrollIndicatorInsets = UIEdgeInsetsMake(8, 0, 50, 0)
        collectionView?.alwaysBounceVertical = true
        collectionView?.backgroundColor = UIColor.white
        collectionView?.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        
        collectionView?.keyboardDismissMode = .interactive
        
        self.setupKeyboardObservers()
        
    }
    
    // Função: Readaptar os messages mesmo mundando de angulo
    
    lazy var inputContainerView: UIView = {
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50)
        containerView.backgroundColor = UIColor.white
        
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        containerView.addSubview(sendButton)
        
        let updateImageView = UIImageView()
        updateImageView.isUserInteractionEnabled = true
        updateImageView.image = UIImage(named: "upload_image_icon")
        updateImageView.translatesAutoresizingMaskIntoConstraints = false
        updateImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleUploadTap)))
        containerView.addSubview(updateImageView)
        
        // x, y, width, height
        updateImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        updateImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        updateImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        updateImageView.heightAnchor.constraint(equalToConstant: 44).isActive = true

        // x, y, width, height
        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        //
        
        containerView.addSubview(self.inputTextField)
        
        // x, y, width, height
        self.inputTextField.leftAnchor.constraint(equalTo: updateImageView.rightAnchor, constant: 8).isActive = true
        self.inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        self.inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor).isActive = true
        self.inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        //
        
        let separatorLineView = UIView()
        separatorLineView.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(separatorLineView)
        
        // x, y, width, height
        separatorLineView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        separatorLineView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        separatorLineView.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        separatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        
        return containerView
    }()
    
    override var inputAccessoryView: UIView? {
        get {
            return inputContainerView
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatMessageCell
        
        let message = messages[indexPath.item]
        cell.textView.text = message.text
        
        setupCell(cell: cell, message: message)
        
        if let text = message.text{
            cell.bubbleWidthAnchor?.constant = estimateFrameForText(text: text).width + 32
        } else if message.imageUrl != nil {
            // fall in here if its an image message
            
            cell.bubbleWidthAnchor?.constant = 200
        }
        
        return cell
    }
    
    private func setupCell(cell : ChatMessageCell,  message: Message) {
        
        if let profileImageUrl = self.user?.profileImageUrl {
            cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
        }
        
        if message.fromId == FIRAuth.auth()?.currentUser?.uid {
            // outgoing blue
            cell.bubbleView.backgroundColor = ChatMessageCell.blueColor
            cell.textView.textColor = UIColor.white
            cell.profileImageView.isHidden = true
            
            cell.bubbleViewRightAnchor?.isActive = true
            cell.bubbleViewLeftAnchor?.isActive = false
        }else {
            // incoming gray
            cell.bubbleView.backgroundColor = UIColor(r: 240, g: 240, b: 240)
            cell.textView.textColor = UIColor.black
            cell.profileImageView.isHidden = false
            
            cell.bubbleViewRightAnchor?.isActive = false
            cell.bubbleViewLeftAnchor?.isActive = true
        }
        
        if let messageImageUrl = message.imageUrl {
            cell.messageImageView.loadImageUsingCacheWithUrlString(urlString: messageImageUrl)
            cell.messageImageView.isHidden = false
            cell.bubbleView.backgroundColor = UIColor.clear
        }else {
            cell.messageImageView.isHidden = true
        }
    }
    
    // Função que pertence ao: UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height : CGFloat = 80
        
        let message = messages[indexPath.item]
        if let text = message.text {
            height = estimateFrameForText(text: text).height + 20
        } else if let imageWidth = message.imageWidth?.floatValue, let imageHeight = message.imageHeight?.floatValue {
            
            // h1 / w1 = h2 / w2
            // solve for h1
            // h1 = h2 / w2 * w1
            
            height = CGFloat(imageHeight / imageWidth * 200)
            
        }
        
        let width = UIScreen.main.bounds.width
        return CGSize(width: width, height: height)
    }
    
    // MARK: - Function
    
    func handleUploadTap() {
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        present(imagePickerController, animated: true, completion: nil)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage{
            selectedImageFromPicker = editedImage
        }else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage{
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker{
            uploadToFirebaseStorageUsingImage(image: selectedImage)
        }
        
        dismiss(animated: true, completion: nil)
        
    }
    
    private func uploadToFirebaseStorageUsingImage(image: UIImage) {
        let imageName = NSUUID().uuidString
        let ref = FIRStorage.storage().reference().child("message_images").child(imageName)
        
        if let uploadData = UIImageJPEGRepresentation(image, 0.2) {
            ref.put(uploadData, metadata: nil, completion: { (metadata, error) in
                
                if error != nil {
                    print("Failed to upload image:", error!)
                    return
                }
                
                if let imageUrl = metadata?.downloadURL()?.absoluteString {
                    self.sendMessageWithImageUrl(imageUrl: imageUrl,image: image)
                }
                
                print(metadata?.downloadURL()?.absoluteString ?? "")
                
            })
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: .UIKeyboardDidShow, object: nil)
        
//        NotificationCenter.default.addObserver(self , selector: #selector(handleKeyboardWillShow), name: .UIKeyboardWillShow , object: nil)
//        
//        NotificationCenter.default.addObserver(self , selector: #selector(handleKeyboardWillHide), name: .UIKeyboardWillHide , object: nil)
    }
    
    func handleKeyboardDidShow(){
        if messages.count > 0{
            let indexPath = NSIndexPath(item: messages.count-1, section: 0)
            collectionView?.scrollToItem(at: indexPath as IndexPath, at: .top, animated: true)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    func handleKeyboardWillHide(notification: NSNotification) {
        
        let keyBoardDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
        
        // move the input area up somehow??
        containerViewBottomAnchor?.constant = 0
        UIView.animate(withDuration: keyBoardDuration!) {
            self.view.layoutIfNeeded()
        }
        
    }
    
    func handleKeyboardWillShow(notification: NSNotification) {
        
        let keyBoardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
        let keyBoardDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
        
        // move the input area up somehow??
        containerViewBottomAnchor?.constant = -(keyBoardFrame?.height)!
        UIView.animate(withDuration: keyBoardDuration!) { 
            self.view.layoutIfNeeded()
        }
        
    }
    
    var containerViewBottomAnchor: NSLayoutConstraint?
    
    func handleSend() {
        
        let properties: [String: AnyObject] = ["text": inputTextField.text! as AnyObject]
        sendMessageWithProperties(properties: properties)
    }
    
    private func sendMessageWithImageUrl(imageUrl: String, image: UIImage) {
        let properties: [String: AnyObject] = ["imageUrl": imageUrl, "imageWidth": image.size.width, "imageHeight": image.size.height] as [String: AnyObject]
        
        sendMessageWithProperties(properties: properties)
    }
    
    private func sendMessageWithProperties(properties: [String: AnyObject]) {
        let ref = FIRDatabase.database().reference().child("messages")
        let childRef =  ref.childByAutoId()
        // is it there best thing to include the name insideof the message node
        let toId = user!.id!
        let fromId = FIRAuth.auth()!.currentUser!.uid
        let timestamp = NSDate().timeIntervalSince1970
        
        var values = ["toId": toId, "fromId": fromId, "timestamp": timestamp] as [String : Any]
        
        // append properties dictionary onto values somehow??
        // key $0, value $1
        properties.forEach({values[$0] = $1})
        
        childRef.updateChildValues(values) { (error, ref) in
            
            if error != nil {
                print(error!)
                return
            }
            
            self.inputTextField.text = nil
            
            let userMessagesRef = FIRDatabase.database().reference().child("user-messages").child(fromId).child(toId)
            
            let messageId = childRef.key
            userMessagesRef.updateChildValues([messageId: 1])
            
            let recipientUserMessagesRef = FIRDatabase.database().reference().child("user-messages").child(toId).child(fromId)
            recipientUserMessagesRef.updateChildValues([messageId: 1])
        }
    }
    
}

extension ChatLogController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }
}

