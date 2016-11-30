//
//  MatchesTableViewController.swift
//  butterfly2
//
//  Created by Alan Jaw on 9/15/16.
//  Copyright © 2016 Alan Jaw. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth

class MatchesTableViewController: UITableViewController {
    
    var chatsMeta = [ChatsMeta]()
    var chatImages = [UIImage?]()
    var chatNames = [String?]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Matches"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);


        fetchChatsMeta({
            chatsMeta in // (from callback)
            self.chatsMeta = chatsMeta
            self.tableView.reloadData()
        })
    }

    func goToMeetVC(_ button: UIBarButtonItem) {
        
        tabBarController?.selectedViewController = tabBarController?.viewControllers![2]
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return chatsMeta.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatUserCell", for: indexPath) as! ChatUserCell

        
        let withUserID = chatsMeta[(indexPath as NSIndexPath).row].withUserID
        let lastMsg = chatsMeta[(indexPath as NSIndexPath).row].lastMessage
        let unread = chatsMeta[(indexPath as NSIndexPath).row].unread
        let lastSenderID = chatsMeta[(indexPath as NSIndexPath).row].lastSender

        var withUserName  = chatsMeta[(indexPath as NSIndexPath).row].withUserName
        
        let fontHelveticaBoldSize20 = UIFont(name: "Helvetica-Bold", size: 20.0)
        let fontHelveticaSize20 = UIFont(name: "Helvetica", size: 20.0)

        
        // You've MATCHED! Code
        if lastSenderID == "none" {
            if (unread == true) {
                cell.nameLabel.font = fontHelveticaBoldSize20
            }
            else {
                cell.nameLabel.font = fontHelveticaSize20
            }
            
            cell.nameLabel.textColor = UIColor.red
            cell.nameLabel.text = "\(lastMsg)"
        }
            
        // ALREADY MATCHED
        else {
            if (unread == true) {
                if (lastSenderID != Constants.userID) {
                    cell.nameLabel.font = fontHelveticaBoldSize20
                    cell.nameLabel.textColor = UIColor.purple
                    cell.nameLabel.text = "\(withUserName): \(lastMsg)"
                }
            }
            else {
                if lastSenderID == Constants.userID {
                    cell.nameLabel.font = fontHelveticaSize20
                    cell.nameLabel.textColor = UIColor.black
                    cell.nameLabel.text = "You: \(lastMsg)"
                }
                else {
                    cell.nameLabel.font = fontHelveticaSize20
                    cell.nameLabel.textColor = UIColor.black
                    cell.nameLabel.text = "\(withUserName): \(lastMsg)"
                }
            }
        }
        getFBProfilePicFor(userID: withUserID, callback: {
            image in
            cell.avatarImageView.image = image
//            self.tableView.reloadData() LEAVING THIS HERE AS A REMINDER TO NOT NOT NOT CALL RELOAD DATA INSIDE THIS METHOD as it WILL BE AN ENDLESS LOOP OF CALLING reloadData(), then the cell dequeueing, then calling getFBProfilePicFor, to loop again
        })
    
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
//        performSegue(withIdentifier: "ShowChatMessages", sender: indexPath)
//        
//        tableView.deselectRow(at: indexPath, animated: true)
        let chatVc = ChatViewController()
        let chat = chatsMeta[(indexPath as NSIndexPath).row]
        
        // update "unread" to false in chats_meta
        updateChatsMetaLastMessageReadFor(chat.key)

        chatVc.chatID = chat.key
        chatVc.title = chat.withUserName
        chatVc.withUserID = chat.withUserID
        let chatNavigationController = UINavigationController(rootViewController: chatVc)
        present(chatNavigationController, animated: true, completion: nil)
        
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let chat = chatsMeta[(indexPath as NSIndexPath).row]
        
        
        if editingStyle == .delete {
            showConfirmDeleteNotificationFor(indexPath: indexPath, chat: chat)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let indexPath = sender as? IndexPath {
            
            // works for ChatViewController whether it's embedded in UINavigationController or not
            var destination = segue.destination as? UIViewController
            if let navVc = destination as? UINavigationController {
                destination = navVc.visibleViewController
            }
            
            if let chatVc = destination as? ChatViewController {
                let chat = chatsMeta[(indexPath as NSIndexPath).row]
                chatVc.chatID = chat.key
                chatVc.title = chat.withUserID

            }
        }
    }
    
    func showConfirmDeleteNotificationFor(indexPath: IndexPath, chat: ChatsMeta) {
        let alertController = UIAlertController(title: "Delete Chat", message: "Are you sure you want to close this chat? You can still match with this user later", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
            
        }
        let deleteAction = UIAlertAction(title: "Close this Chat",
                                       style: .default) { [unowned self](action: UIAlertAction) -> Void in
                                        self.deleteChatAt(indexPath: indexPath, chat: chat)
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        topMostController().present(alertController, animated: true, completion: nil)
    }

    func deleteChatAt(indexPath: IndexPath, chat: ChatsMeta) {
        chatsMeta.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
        deleteChatFor(chatID: chat.key, matchedUserID: chat.withUserID)
    }
}
