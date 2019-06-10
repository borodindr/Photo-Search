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
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        let blackColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
        layer.colors = [UIColor.clear.cgColor, blackColor.cgColor]
        layer.locations = [0.8, 1]
        return layer
    }()
    
    private let metaLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.textColor = .white
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.adjustsFontSizeToFitWidth = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        addTapGesture()
        navigationItem.largeTitleDisplayMode = .never
        if photo.managedObjectContext == context {
            //Preparation for saved photos
            addRightBarButtonWith(title: "Удалить", action: #selector(deletePhoto))
            
            imageView.image = photo.fullPhoto
            setMetaLabelTextFrom(photo)
        } else {
            //Preparation for NOT saved photos
            addRightBarButtonWith(title: "Сохранить", action: #selector(savePhoto))
            navigationItem.rightBarButtonItem?.isEnabled = false
            addLoadingView(to: imageView)
            photo.loadImage(size: .full) { (image, error) in
                if let error = error {
                    self.handleError(error)
                }
                if let image = image {
                    self.imageView.image = image
                    self.setMetaLabelTextFrom(self.photo)
                    self.navigationItem.rightBarButtonItem?.isEnabled = !self.isPhotoAlreadySaved()
                }
                self.removeLoadingView()
            }
        }
    }
    
    override func loadView() {
        super.loadView()
        addImageView()
    }
    
    override func viewDidLayoutSubviews() {
        if imageView.image != nil {
            setGradientLayer()
            setMetaLabel()
        }
    }
    
    private func addTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tap)
    }
    
    private func addRightBarButtonWith(title: String, action: Selector) {
        let button = UIBarButtonItem(title: title, style: .plain, target: self, action: action)
        navigationItem.rightBarButtonItem = button
    }
    
    private func addImageView() {
        view.addSubview(imageView)
        imageView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        imageView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
    
    //gradientLabel methods
    private func setGradientLayer() {
        let gradientLayerBounds = imageBounds(in: imageView)
        gradientLayer.frame = gradientLayerBounds
        
        //Add layer only if it exists
        if let imageViewLayers = imageView.layer.sublayers {
            if imageViewLayers.contains(gradientLayer) {
                return
            }
        } else {
            imageView.layer.addSublayer(gradientLayer)
        }
    }
    
    //metaLabel methods
    private func setMetaLabel() {
        imageView.subviews.contains(metaLabel) ? updateMetalabel() : addMetaLabel()
    }
    
    private func addMetaLabel() {
        imageView.addSubview(metaLabel)
        metaLabel.centerXAnchor.constraint(equalTo: imageView.centerXAnchor).isActive = true
        metaLabel.widthAnchor.constraint(equalToConstant: imageBounds(in: imageView).width - 16).isActive = true
        let bottomSpaceBetweenImageAndView = (imageView.bounds.height - imageBounds(in: imageView).height) / 2
        metaLabel.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: bottomSpaceBetweenImageAndView * -1 - 8).isActive = true
    }
    
    private func updateMetalabel() {
        //updating metaLabel bottom ancher
        for constraint in imageView.constraints {
            if constraint.firstAttribute == .bottom {
                let bottomSpaceBetweenImageAndView = (imageView.bounds.height - imageBounds(in: imageView).height) / 2
                constraint.constant = bottomSpaceBetweenImageAndView * -1 - 8
            }
        }
        
        //updating metaLabel width
        for constraint in metaLabel.constraints {
            if constraint.firstAttribute == .width {
                constraint.constant = imageBounds(in: imageView).width - 16
            }
        }
    }
    
    private func setMetaLabelTextFrom(_ photo: Photo) {
        let userName = photo.userName
        metaLabel.text = "Автор: \(userName)"
        
        if let dateAdded = photo.dateAdded {
            let dateFormater = DateFormatter()
            dateFormater.locale = Locale(identifier: "ru_RU")
            dateFormater.dateFormat = "d MMMM yyyy г. в HH:mm"
            let dateString = dateFormater.string(from: dateAdded)
            metaLabel.text?.append(contentsOf: "\nСохранено: \(dateString)")
        }
    }
    
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
            self.context.delete(self.photo)
            self.appDelegate.saveContext()
            
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
    
    @objc func handleTap() {
        if navigationController!.isNavigationBarHidden {
            view.backgroundColor = .white
            metaLabel.isHidden = false
            gradientLayer.isHidden = false
            PhotoDetailsViewController.loadingIndicator.style = .gray
            navigationController?.setNavigationBarHidden(false, animated: true)
        } else {
            view.backgroundColor = .black
            metaLabel.isHidden = true
            gradientLayer.isHidden = true
            PhotoDetailsViewController.loadingIndicator.style = .white
            navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }
    
    //helper to get bounds of photo
    private func imageBounds(in imageView: UIImageView) -> CGRect {
        guard let image = imageView.image else { return CGRect(x: 0, y: 0, width: 0, height: 0) }
        let imageViewRatio = imageView.bounds.height / imageView.bounds.width
        let imageRatio = image.size.height / image.size.width
        
        //Calculating scale ratio to find image size on screen
        let scale: CGFloat
        //Defining which sides clip to bounds of imageView
        if imageRatio < imageViewRatio {
            scale = imageView.bounds.width / image.size.width
        } else {
            scale = imageView.bounds.height / image.size.height
        }
        let imageSizeOnScreen = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        
        //Calculating coordinates of image
        let x = (imageView.bounds.width - imageSizeOnScreen.width) / 2
        let y = (imageView.bounds.height - imageSizeOnScreen.height) / 2
        return CGRect(x: x, y: y, width: imageSizeOnScreen.width, height: imageSizeOnScreen.height)
    }
}
