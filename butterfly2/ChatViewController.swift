//
//  ChatViewController.swift
//  butterfly2
//
//  Created by Alan Jaw on 9/15/16.
//  Copyright © 2016 Alan Jaw. All rights reserved.
//

import Foundation
import JSQMessagesViewController
import FirebaseAuth

class ChatViewController: JSQMessagesViewController {
    
    var senderAvatar: UIImage!
    var recipientAvatar: UIImage!
    
    var chatID: String?
    var withUserID: String?
    var messages: [JSQMessage] = []
    
    var chatActive = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupBackButton()
        // Set sender information: you’ll need to set initial values for senderId and senderDisplayName so the JSQMessagesViewController can uniquely identify the sender of the messages
        self.senderId = Constants.userID
        self.senderDisplayName = "Me"
 
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        observeChatActiveStatusFor(chatID: chatID!, callback: {
            chatActive in
            if !chatActive {
                self.showChatClosedNotification()
            }
        })
    
        loadAvatarPhotos()

        observeMessagesFor(chatID: chatID!, callback: { (newMessage) in
            self.messages.append(JSQMessage(senderId: newMessage.senderId, displayName: newMessage.senderId, text: newMessage.message))
            
            self.finishReceivingMessage()
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }
    
    
    // Mark: JSQMessagesViewController required methods
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        let data = self.messages[indexPath.item]
        return data
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        return nil
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        var imgAvatar = JSQMessagesAvatarImage.avatar(with: JSQMessagesAvatarImageFactory.circularAvatarImage( UIImage(named: "profile-header"), withDiameter: 60 ))
        if (self.messages[indexPath.row].senderId == self.senderId)
        {
            if (self.senderAvatar != nil)
            {
                imgAvatar = JSQMessagesAvatarImage.avatar(with: JSQMessagesAvatarImageFactory.circularAvatarImage( self.senderAvatar, withDiameter: 60 ))
            }
            else
            {

            }
        }
        else
        {
            if (self.recipientAvatar != nil)
            {
                imgAvatar = JSQMessagesAvatarImage.avatar(with: JSQMessagesAvatarImageFactory.circularAvatarImage( self.recipientAvatar, withDiameter: 60 ))
            }
            else
            {

            }
        }
        return imgAvatar

    }
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        return nil
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        return nil
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        return nil
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        
        if chatActive {
            createChatsMessagesFor(self.chatID!, senderId: senderId, withUserID: withUserID!, text: text)
            finishSendingMessage(animated: true)
        }
        else {
            showChatClosedNotification()
        }

    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        //
    }
    
    // Mark: UICollectionView
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        
        let message = messages[indexPath.item]
        
        if message.senderId == senderId {
            cell.textView.textColor = UIColor.black
        }
        else {
            cell.textView.textColor = UIColor.red
            
        }
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return messages.count
    }

    
    func loadAvatarPhotos() {
        getFBProfilePicFor(userID: Constants.userID, callback: {
            
            image in
            self.senderAvatar = image
            super.collectionView.reloadData()

        })
            
        getFBProfilePicFor(userID: withUserID!, callback: {
            image in
            self.recipientAvatar = image
            super.collectionView.reloadData()
        })
    }
    
    func updateAvatarImageForIndexPath( indexPath: IndexPath, avatarImage: UIImage) {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        cell.avatarImageView!.image = JSQMessagesAvatarImageFactory.circularAvatarImage( avatarImage, withDiameter: 60 )
    }
    
    func setupBackButton() {
        let backButton = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.plain, target: self, action: #selector(backButtonTapped))
        navigationItem.leftBarButtonItem = backButton
    }
    func backButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    func showChatClosedNotification () {
        print ("chat closed")
        let alertController = UIAlertController(title: "Closed", message: "This chat was closed", preferredStyle: .alert)

        let okAction = UIAlertAction(title: "Aww, OK...", style: .cancel) { (action) in
            self.backButtonTapped()
        }
        alertController.addAction(okAction)
        topMostController().present(alertController, animated: true, completion: nil)

    }

}
