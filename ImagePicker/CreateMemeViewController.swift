//
//  CreateMemeViewController.swift
//  ImagePicker
//
//  Created by Austin Levine on 5/25/16.
//  Copyright © 2016 Austin Levine. All rights reserved.
//

import UIKit

class CreateMemeViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    var memesArray: [Meme] {
        return (UIApplication.sharedApplication().delegate as! AppDelegate).memes
    }
    
    let memeTextAttributes = [
        NSStrokeColorAttributeName : UIColor.blackColor(),
        NSForegroundColorAttributeName : UIColor.whiteColor(),
        NSFontAttributeName : UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
        NSStrokeWidthAttributeName : -3.0
    ]
    
    @IBOutlet weak var topTextField: UITextField!
    @IBOutlet weak var bottomTextField: UITextField!
    @IBOutlet weak var imagePickerView: UIImageView!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var topToolbar: UIToolbar!
    @IBOutlet weak var bottomToolBar: UIToolbar!
    
    
    func setupTextField(textField: UITextField, defaultText: String) {
        textField.text = defaultText
        textField.defaultTextAttributes = memeTextAttributes
        textField.textAlignment = NSTextAlignment.Center
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set delegates
        self.topTextField.delegate = self
        self.bottomTextField.delegate = self
        // Hide some stuff
        self.topTextField.hidden = true
        self.bottomTextField.hidden = true
//        self.topToolbar.hidden = true
        self.imagePickerView.hidden = true
    }
    
    override func viewWillAppear(animated: Bool) {
        self.subscribeToKeyboardNotifications()
        cameraButton.enabled = UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)
        // Setup text fields
        setupTextField(self.topTextField, defaultText: "TOP")
        setupTextField(self.bottomTextField, defaultText: "BOTTOM")
        self.navigationController?.tabBarController?.tabBar.hidden = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.unsubscribeFromKeyboardNotifications()
        self.navigationController?.tabBarController?.tabBar.hidden = false
    }
    
    
    // MARK: TextFieldDelegate functions
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        var newText: NSString = textField.text!
        newText = newText.stringByReplacingCharactersInRange(range, withString: string)
        
        return true
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        if textField.text == "TOP" || textField.text == "BOTTOM" {
            textField.text = ""
        }
        self.topToolbar.hidden = true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        self.topToolbar.hidden = false
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true;
    }
    
    
    // MARK: Image Picking
    
    func presentImagePicker(source: UIImagePickerControllerSourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = source
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }

    @IBAction func pickAnImageFromAlbum(sender: AnyObject) {
        presentImagePicker(.PhotoLibrary)
    }
    
    @IBAction func pickAnImageFromCamera(sender: AnyObject) {
        presentImagePicker(.Camera)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.imagePickerView.hidden = false
            self.imagePickerView.image = image
            self.topTextField.hidden = false
            self.bottomTextField.hidden = false
            self.topToolbar.hidden = false
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // MARK: Keyboard Notification
    
    func keyboardWillShow(notification: NSNotification) {
        if self.bottomTextField.isFirstResponder() {
            self.view.frame.origin.y =  getKeyboardHeight(notification) * -1

        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        self.view.frame.origin.y = 0
    }
    
    func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.CGRectValue().height
    }
    
    func subscribeToKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CreateMemeViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CreateMemeViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    
    // MARK: Meme Sharing
    
    func save() {
        //Create the meme
        let meme = Meme( topText: self.topTextField.text!, bottomText: self.bottomTextField.text!, originalImage:
            self.imagePickerView.image!, memedImage: generateMemedImage())
        
        // Add it to the memes array in the Application Delegate
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.memes.append(meme)
    }
    
    func generateMemedImage() -> UIImage {
        
        bottomToolBar.hidden = true
        topToolbar.hidden = true
        UIApplication.sharedApplication().statusBarHidden = true
        
        // Render view to an image
        UIGraphicsBeginImageContext(self.view.frame.size)
        view.drawViewHierarchyInRect(self.view.frame, afterScreenUpdates: true)
        let memedImage : UIImage =
            UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        
        bottomToolBar.hidden = false
        topToolbar.hidden = false
        UIApplication.sharedApplication().statusBarHidden = false
        
        return memedImage
    }
    
    @IBAction func shareButtonPressed(sender: AnyObject) {
        
        let memedImage = self.generateMemedImage()
        
        let activityViewController = UIActivityViewController(activityItems: [memedImage], applicationActivities: nil)
        presentViewController(activityViewController, animated: true, completion: nil)
        
        activityViewController.completionWithItemsHandler = {(activityType, completed: Bool, returnedItems: [AnyObject]?, error: NSError?) in
            if completed {
                self.save()
                self.dismissViewControllerAnimated(true, completion: nil)
            }
        }
        
    }
    
    @IBAction func memeCanceled(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    

}

