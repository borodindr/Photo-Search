//
//  PhotoDetailsViewController.swift
//  Photo Search
//
//  Created by Dmitry Borodin on 06/06/2019.
//  Copyright © 2019 Dmitry Borodin. All rights reserved.
//

import UIKit
import CoreData

class PhotoDetailsViewController: UIViewController {

    //MARK: Properties
    var photo: Photo!
//    var savedPhotos = [Photo]()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    private var photoDetailsView: PhotoDetailsView {
        return self.view as! PhotoDetailsView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        addTapGesture()
        navigationItem.largeTitleDisplayMode = .never
        setRightBarButton()
        setPhoto()
    }
    
    deinit {
        print("VC deinit")
    }
    
    override func loadView() {
        super.loadView()
        view = PhotoDetailsView(frame: UIScreen.main.bounds)
    }
    
    override func viewDidLayoutSubviews() {
        photoDetailsView.setView()
    }
    
    private func addTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tap)
    }
    
    private func addRightBarButtonWith(title: String, action: Selector) {
        let button = UIBarButtonItem(title: title, style: .plain, target: self, action: action)
        navigationItem.rightBarButtonItem = button
    }
    
    //Checks if opened photo already saved to avoid duplication
    private func isPhotoAlreadySaved() -> Bool {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "%K = %@", argumentArray: [#keyPath(Photo.id), photo.id as Any])
        fetchRequest.predicate = predicate
        
        guard let photosCount = try? context.count(for: fetchRequest) else { return false }
        print("Count:", photosCount)
        return photosCount > 0
    }
    
    private func setRightBarButton() {
        if photo.managedObjectContext == context {
            // Delete button if photo was saved
            addRightBarButtonWith(title: "Delete".localized(), action: #selector(deletePhoto))
        } else {
            // Save button if new photo
            addRightBarButtonWith(title: "Save".localized(), action: #selector(savePhoto))
        }
    }
    
    private func setPhoto() {
        if let savedPhoto = photo.fullPhoto {
            //Preparation for saved photos
            photoDetailsView.imageView.image = savedPhoto
            photoDetailsView.setMetaLabelTextFrom(photo)
            
            if !(photo.managedObjectContext == context) {
                self.navigationItem.rightBarButtonItem?.isEnabled = !self.isPhotoAlreadySaved()
            }
        } else {
            //Preparation for NOT saved photos
            addLoadingView(to: photoDetailsView.imageView)
            navigationItem.rightBarButtonItem?.isEnabled = false
            photo.loadImage(size: .full) { (image, error) in
                if let error = error {
                    self.handleError(error)
                }
                if let image = image {
                    self.photoDetailsView.imageView.image = image
                    self.photoDetailsView.setMetaLabelTextFrom(self.photo)
                    self.navigationItem.rightBarButtonItem?.isEnabled = !self.isPhotoAlreadySaved()
                }
                self.removeLoadingView()
            }
        }
    }
    
    //actions
    @objc func savePhoto() {
        let photoToSave = Photo(context: context)
        photoToSave.setFrom(photoEntity: photo)
        appDelegate.saveContext()
        
        let alert = UIAlertController(title: "Saved".localized(), message: "Photo saved".localized(), preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel)
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
        self.navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    @objc func deletePhoto() {
        let alert = UIAlertController(title: "Delete?".localized(), message: "Are you sure you want to delete the photo?".localized(), preferredStyle: .alert)
        let noAction = UIAlertAction(title: "No".localized(), style: .cancel, handler: nil)
        let yesAction = UIAlertAction(title: "Yes".localized(), style: .destructive, handler: { [unowned self] (alert) in
            //deleting photo
            self.context.delete(self.photo)
            self.appDelegate.saveContext()
            
            self.navigationController?.popViewController(animated: true)
        })
        alert.addAction(noAction)
        alert.addAction(yesAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    //removes or restores all except image form view
    @objc func handleTap() {
        if navigationController!.isNavigationBarHidden {
            if #available(iOS 13.0, *) {
                view.backgroundColor = .systemBackground
            } else {
                view.backgroundColor = .white
            }
            photoDetailsView.hideViews(false)
            PhotoDetailsViewController.loadingIndicator.style = .gray
            navigationController?.setNavigationBarHidden(false, animated: true)
        } else {
            view.backgroundColor = .black
            photoDetailsView.hideViews(true)
            PhotoDetailsViewController.loadingIndicator.style = .white
            navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }
}
