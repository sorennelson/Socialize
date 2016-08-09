//
//  HomeTableViewController.swift
//  Chat
//
//  Created by Soren Nelson on 3/29/16.
//  Copyright © 2016 SORN. All rights reserved.
//  

import CloudKit
import UIKit

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet var contactView: UIView!
    
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    
    let darkView = UIView()
    
    var requests: [CKReference]?
    var myRequests: [Relationship]?
    var numberInSection:Int?
    var myFriends: [Relationship]?
    var myConversations: [Conversation]?
    var convoRecords: [CKRecord]?
    var passOnConvo: Conversation?
    var convoRecord: CKRecord?
    var contactRelationship: Relationship?
    var addContactIndex:Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBarHidden = false
        setNavBar()
        tableView.reloadData()
    }
    
    @IBAction func unwindToHome(segue: UIStoryboardSegue) {}
 
// MARK: Segmented Control
    
    @IBAction func segmentedControlChanged(sender: AnyObject) {
        tableView.reloadData()
    }

    
// MARK: TableView
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if segmentedControl.selectedSegmentIndex == 0 {
            return 80
            
        } else {
            if indexPath.row == numberInSection {
                
//                fixxxxx
                if (myFriends?.count)! % 3 == 1 {
                    let contactCellHeight = CGFloat(145 * ((myFriends!.count + 2)/3)) + 30
                    return contactCellHeight
                } else if (myFriends?.count)! % 3 == 2 {
                    let contactCellHeight = CGFloat(145 * ((myFriends!.count + 1)/3)) + 30
                    return contactCellHeight
                } else {
                    let contactCellHeight = CGFloat(145 * (myFriends!.count/3)) + 30
                    return contactCellHeight
                }
        
            } else {
                return 87
            }
        }
    }
    
    
//  TODO: create sections ??

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
//        see if pass on convo works with multiple convo's
        if segmentedControl.selectedSegmentIndex == 0 {
            let convoCell = tableView.dequeueReusableCellWithIdentifier("conversationCell", forIndexPath: indexPath) as! HomeMessageCell
            let convo = myConversations![indexPath.row]
            convoCell.messageText.text = convo.lastMessage?.messageText
            convoCell.userName.text = convo.convoName
            if let time = convo.lastMessage?.time {
                convoCell.messageTime.text = time
            }
//            TODO: set images
            return convoCell
            
        } else {
            
            if indexPath.row == numberInSection {
                let contactCell = tableView.dequeueReusableCellWithIdentifier("contactCell", forIndexPath: indexPath) as! ContactTableViewCell
                return contactCell
                
            } else {
                let notificationCell = tableView.dequeueReusableCellWithIdentifier("notificationCell", forIndexPath: indexPath) as! NotificationCell
                
//                why???? - 1
                
                notificationCell.acceptButton.tag = indexPath.row
                notificationCell.declineButton.tag = indexPath.row
                if let myRequests = myRequests {
                    if myRequests.count != 0 {
                        let index = indexPath.row
                        let name = myRequests[index].fullName
                        notificationCell.inviteLabel.text = "\(name) sent you a friend request"
                        if let asset = myRequests[index].profilePic {
                            notificationCell.profilePic.image = asset.image
                        }
                    } else {
                        
                    }
                } else {
                    
                }
                return notificationCell
            }
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if segmentedControl.selectedSegmentIndex == 0 {
            if myConversations?.count != 0 {
                return (myConversations?.count)!
            } else {
                return 0
            }
            
        } else {
            if let requests = self.myRequests {
                if requests.count == 0 {
                    self.numberInSection = 0
                    return 1
                    
                } else {
                    let number = requests.count + 1
                    self.numberInSection = number - 1
                    return number
                }
            } else {
                self.numberInSection = 0
                return 1
            }
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if segmentedControl.selectedSegmentIndex == 0 {
            performSegueWithIdentifier("messageSegue", sender: self)
        }
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "messageSegue" {
            let destinationVC = segue.destinationViewController as! MessagingViewController
            if let convoIndex = tableView.indexPathForSelectedRow?.row {
                destinationVC.convoRecord = self.convoRecords![convoIndex]
                if let myConversation = myConversations?[convoIndex] {
                    ConversationController.sharedInstance.grabMessages(myConversation, completion: { (error, conversation, theMessages) in
                        if let error = error {
                            destinationVC.conversation = conversation
                            destinationVC.conversation?.messages = []
                            destinationVC.conversation?.theMessages = []
                            print("ERROR: \(error)")
                        } else {
                            if let messages = myConversation.messages,
                                let theMessages = theMessages {
                                var passOnConversation = Conversation(convoName: conversation?.convoName, users: (conversation?.users)!, messages: messages)
                                passOnConversation.theMessages = theMessages
                                destinationVC.conversation?.theMessages = theMessages
                                destinationVC.conversation?.messages = messages
                                destinationVC.conversation = passOnConversation
                                dispatch_async(dispatch_get_main_queue(), { 
                                    destinationVC.tableView.reloadData()

                                })
                            }
                        }
                    })
                } else {
                    print("ERROR")
                }
            } else {
                print("ERROR")
            }
            
        } else if segue.identifier == "newMessageSegue" {
            let destinationVC = segue.destinationViewController as! MessagingViewController
            destinationVC.conversation = self.passOnConvo
            destinationVC.convoRecord = self.convoRecord
        } else if segue.identifier == "addToGroup" {
            let navController = segue.destinationViewController as! UINavigationController
            let destinationVC = navController.topViewController as! CreateGroupViewController
            destinationVC.contacts = self.myFriends
            destinationVC.initialContact = self.contactRelationship
        }
        
        
    }
    
    
// MARK: Friend Request actions
    
    @IBAction func acceptButtonTapped(sender: AnyObject) {
        if myRequests != nil {
            let requester = myRequests?[sender.tag]
            myRequests!.removeAtIndex(sender.tag)
            for request in self.myRequests! {
                let ref = CKReference(recordID: request.userID.recordID, action: .DeleteSelf)
                requests? += [ref]
            }
            if requests == nil {
                requests = []
            }
            UserController.sharedInstance.saveRecordArray(self.requests!, record: UserController.sharedInstance.myRelationshipRecord!, string: "FriendRequests") { (success) in
                if success {
                    if UserController.sharedInstance.myRelationship?.friends != nil {
                        var friends = UserController.sharedInstance.myRelationship?.friends
                        let ref = CKReference(recordID: requester!.userID.recordID, action: .DeleteSelf)
                        friends? += [ref]
                        UserController.sharedInstance.saveRecordArray(friends!, record: UserController.sharedInstance.myRelationshipRecord!, string: "Friends", completion: { (success) in
                            if success {
                                let record = UserController.sharedInstance.myRelationshipRecord
                                let relationship = Relationship(fullName: record!["FullName"] as! String, userID: record!["UserIDRef"] as! CKReference, requests: nil, friends: nil, profilePic: record!["ImageKey"] as? CKAsset)
                                dispatch_async(dispatch_get_main_queue(), {
                                    //                                TODO: see why not reloading into the tableview
                                    self.myFriends! += [relationship]
                                    self.tableView.reloadData()
                                    let indexPath = NSIndexPath(forRow: self.numberInSection!, inSection: 0)
                                    let cell = self.tableView.cellForRowAtIndexPath(indexPath) as! ContactTableViewCell
                                    cell.collectionView.reloadData()
                                    
                                })
                            } else {
                                
                            }
                        })
                    } else {
                        var friends: [CKReference]
                        let ref = CKReference(recordID: requester!.userID.recordID, action: .DeleteSelf)
                        friends = [ref]
                        UserController.sharedInstance.saveRecordArray(friends, record: UserController.sharedInstance.myRelationshipRecord!, string: "Friends", completion: { (success) in
                            if success {
                                let record = UserController.sharedInstance.myRelationshipRecord
                                let relationship = Relationship(fullName: record!["FullName"] as! String, userID: record!["UserIDRef"] as! CKReference, requests: nil, friends: nil, profilePic: record!["ImageKey"] as? CKAsset)
                                dispatch_async(dispatch_get_main_queue(), {
                                    //                                TODO: see why not reloading into the tableview
                                    self.myFriends! += [relationship]
                                    self.tableView.reloadData()
                                    let cell = ContactTableViewCell()
                                    cell.collectionView.reloadData()
                                })
                            } else {
                                //                            fix
                            }
                        })
                        
                    }
                } else {
                    //                fix
                }
            }
        }
    }

    @IBAction func declineButtonTapped(sender: AnyObject) {
        myRequests?.removeAtIndex(sender.tag)
        for request in self.myRequests! {
            let ref = CKReference(recordID: request.userID.recordID, action: .DeleteSelf)
            requests? += [ref]
        }
        if let requesters = requests {
            UserController.sharedInstance.saveRecordArray(requesters, record: UserController.sharedInstance.myRelationshipRecord!, string: "FriendRequests") { (success) in
                if success {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.tableView.reloadData()
                    })
                } else {
                    NSLog("Didn't save friend requests")
                }
            }
        } else {
            UserController.sharedInstance.saveRecordArray([], record: UserController.sharedInstance.myRelationshipRecord!, string: "FriendRequests") { (success) in
                if success {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.tableView.reloadData()
                    })
                } else {
                    NSLog("Didn't save friend requests")
                }
            }
            NSLog("No Requesters")
            
        }
    }

    
    
// MARK: Collection View
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let item = collectionView.dequeueReusableCellWithReuseIdentifier("contactItem", forIndexPath: indexPath) as! ContactCollectionCell
        let index = indexPath.item
        item.contactName.text = myFriends![index].fullName
        if let asset = myFriends![index].profilePic {
            item.contactImage.image = asset.image
        } else {
            item.contactImage.image = UIImage.init(named: "Contact")
        }
        return item
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return myFriends!.count
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let size = CGSize(width:(self.view.bounds.width / 3) - 20, height:143)
        return size
    }
    
//    
//    
//    
//    
//    TODO:
    @IBOutlet var bigProfilePic: UIImageView!
    @IBOutlet var bigName: UILabel!

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        contactView.center.x = view.center.x
        contactView.center.y = view.center.y - 40
        bigName.text = myFriends![indexPath.item].fullName
        contactRelationship = myFriends![indexPath.item]
        if let asset = myFriends![indexPath.item].profilePic {
            bigProfilePic.image = asset.image
        }
        darkView.frame = CGRectMake(0, 0, view.frame.size.width, view.frame.size.height)
        darkView.backgroundColor = UIColor.blackColor()
        darkView.alpha = 0.5
        
        view.addSubview(darkView)
        view.addSubview(contactView)
        
    }
    
// MARK: Contact View
    
    @IBAction func contactDismissButtonTapped(sender: AnyObject) {
        contactView.removeFromSuperview()
        darkView.removeFromSuperview()
    }
    
    @IBAction func addToGroupButtonPressed(sender: AnyObject) {
        dispatch_async(dispatch_get_main_queue()) {
            self.contactView.removeFromSuperview()
            self.darkView.removeFromSuperview()
            self.performSegueWithIdentifier("addToGroup", sender: self)
            
//            let destinationVC = CreateGroupViewController()
//            destinationVC.contacts = self.myFriends
//            destinationVC.initialContact = self.contactRelationship
        }
    }
    
    
    
    @IBAction func sendMessageButtonTapped(sender: AnyObject) {
        let myRelationship = UserController.sharedInstance.myRelationship
//        TODO: fix name of convo
        let conversation = Conversation.init(convoName: contactRelationship!.fullName, users: [myRelationship!.userID, contactRelationship!.userID], messages: [])
        ConversationController.createConversation(conversation) { (success, record) in
            if success {
                self.convoRecord = record
                self.passOnConvo = conversation
                if self.myConversations?.count == 0 {
                    self.myConversations = [conversation]
                } else {
                    self.myConversations! += [conversation]
                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.contactView.removeFromSuperview()
                    self.darkView.removeFromSuperview()
                    self.performSegueWithIdentifier("newMessageSegue", sender: self)

                })
                
            } else {
                print("Not this time")
            }
            
        }
    }
}

extension UIViewController {
    
    func setNavBar() {
        navigationController?.navigationBar.barTintColor = UIColor.init(red: 0, green: 0.384, blue: 0.608, alpha: 1.0)
        navigationController?.navigationBar.translucent = false
        navigationController?.navigationBar.barStyle = UIBarStyle.Black
        navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        let iconImage = UIImage.init(named: "Little White Icon")
        let imageView = UIImageView(frame: CGRect(x: 0, y: -5, width: 30, height: 30))
        imageView.contentMode = .ScaleAspectFit
        imageView.image = iconImage
        navigationItem.titleView = imageView
    }
}


