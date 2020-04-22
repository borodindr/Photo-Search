//
//  PhotoDetailsViewController.swift
//  Photo Search
//
//  Created by Dmitry Borodin on 06/06/2019.
//  Copyright © 2019 Dmitry Borodin. All rights reserved.
//

import UIKit

class PhotoDetailsViewController: UIViewController {

    //MARK: Properties
    var photo: Photo!
    var savedPhotos = [Photo]()
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
        if photo.managedObjectContext == context {
            //Preparation for saved photos
            addRightBarButtonWith(title: "Delete".localized(), action: #selector(deletePhoto))
            
            photoDetailsView.imageView.image = photo.fullPhoto
            photoDetailsView.setMetaLabelTextFrom(photo)
        } else {
            //Preparation for NOT saved photos
            addRightBarButtonWith(title: "Save".localized(), action: #selector(savePhoto))
            navigationItem.rightBarButtonItem?.isEnabled = false
            addLoadingView(to: photoDetailsView.imageView)
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
        guard let photoGalleryVC = navigationController?.viewControllers.first as? PhotoGalleryViewController else { return false }
        let savedPhotos = photoGalleryVC.savedPhotos
        for savedPhoto in savedPhotos {
            if savedPhoto.fullPhotoData == photo.fullPhotoData {
                return true
            }
        }
        return false
    }
    
    //actions
    @objc func savePhoto() {
        let photoToSave = Photo(context: context)
        photoToSave.setFrom(photoEntity: photo)
        appDelegate.saveContext()
        
        if let photoGalleryVC = navigationController?.viewControllers.first as? PhotoGalleryViewController {
            photoGalleryVC.savedPhotos.append(photoToSave)
        }
        
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
            
            //preparing PhotoGalleryView to dismiss current view
            if let photoGaleryVC = self.navigationController?.viewControllers.first as? PhotoGalleryViewController {
                guard let index = self.savedPhotos.firstIndex(of: self.photo) else { return }
                print("index: \(index)")
                photoGaleryVC.savedPhotos.remove(at: index)
                photoGaleryVC.photosToShow = photoGaleryVC.savedPhotos
            }
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
