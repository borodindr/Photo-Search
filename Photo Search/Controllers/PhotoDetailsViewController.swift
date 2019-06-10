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
        view.backgroundColor = .white
        addTapGesture()
        navigationItem.largeTitleDisplayMode = .never
        if photo.managedObjectContext == context {
            //Preparation for saved photos
            addRightBarButtonWith(title: "Удалить", action: #selector(deletePhoto))
            
            photoDetailsView.imageView.image = photo.fullPhoto
            photoDetailsView.setMetaLabelTextFrom(photo)
        } else {
            //Preparation for NOT saved photos
            addRightBarButtonWith(title: "Сохранить", action: #selector(savePhoto))
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
    
    //Checks if opened photo already saved to avoid dublication
    private func isPhotoAlreadySaved() -> Bool {
        guard let photoGaleryVC = navigationController?.viewControllers.first as? PhotoGalleryViewController else { return false }
        let savedPhotos = photoGaleryVC.savedPhotos
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
        
        if let photoGaleryVC = navigationController?.viewControllers.first as? PhotoGalleryViewController {
            photoGaleryVC.savedPhotos.append(photoToSave)
        }
        
        let alert = UIAlertController(title: "Сохранено", message: "Фото сохранено", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel)
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
        self.navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    @objc func deletePhoto() {
        let alert = UIAlertController(title: "Удалить?", message: "Вы уверены, что хотите удалить изображение?", preferredStyle: .alert)
        let noAction = UIAlertAction(title: "Нет", style: .cancel, handler: nil)
        let yesAction = UIAlertAction(title: "Да", style: .destructive, handler: { [unowned self] (alert) in
            //deleting photo
            self.context.delete(self.photo)
            self.appDelegate.saveContext()
            
            //prepareing PhotoGalleryView to dissmiss current view
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
            view.backgroundColor = .white
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
