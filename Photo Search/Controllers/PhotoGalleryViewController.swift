//
//  ViewController.swift
//  Photo Search
//
//  Created by Dmitry Borodin on 05/06/2019.
//  Copyright © 2019 Dmitry Borodin. All rights reserved.
//

import UIKit
import CoreData

private let reuseIdentifier = "Cell"

class PhotoGalleryViewController: UICollectionViewController {

    //MARK: properties
    private let service = UnsplashService()
    var photosToShow = [Photo]()
    var savedPhotos = [Photo]()
    private var searchedPhotos = [Photo]()
    private var searchController: UISearchController!
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    //child context to create searched objects. Only selected (saved) objects go to parent context
    private lazy var childContext:  NSManagedObjectContext = {
        let childContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        childContext.parent = self.context
        return childContext
    }()
    
    //MARK: methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView!.register(PhotoCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        navigationItem.title = "Поиск Фото"
        setSearchController()
        loadSavedPhotos()
        showKeyboardIfNoPhotos() //For better UX. If there are no saved photos yet, show keyboard to search
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        collectionViewLayout.invalidateLayout()
    }
    
    private func loadSavedPhotos() {
        do {
            let fetchRequest: NSFetchRequest = Photo.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: "dateAdded", ascending: true)
            fetchRequest.sortDescriptors = [sortDescriptor]
            savedPhotos = try context.fetch(fetchRequest)
            photosToShow = savedPhotos
            collectionView.reloadData()
        } catch {
            print("fetch error")
        }
    }
    
    private func showKeyboardIfNoPhotos() {
        if savedPhotos.isEmpty {
            DispatchQueue.main.async { [unowned self] in
                self.searchController.searchBar.becomeFirstResponder()
            }
        }
    }
    
    private func configurePhotoCell(_ cell: PhotoCell, with photo: Photo) {
        //setting image of cell
        if photo.managedObjectContext == childContext {
            //photo object from search
            photo.loadImage(size: .small) { (image, error) in
                if error != nil {
                    cell.imageView.image = #imageLiteral(resourceName: "PhotoPlaceholder")
                }
                
                if let image = image {
                    cell.imageView.image = image
                }
            }
        } else {
            //saved photo
            cell.imageView.image = photo.smallPhoto
        }
        //setting title of cell
        cell.titleLabel.text = "By \(photo.userName)"
    }
}


// MARK: UICollectionView
extension PhotoGalleryViewController: UICollectionViewDelegateFlowLayout {
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photosToShow.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoCell
        configurePhotoCell(cell, with: photosToShow[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = UIDevice.current.orientation.isLandscape ? view.frame.width / 6 - 1 : view.frame.width / 3 - 1 //to make nearly same cells for bothe orientations; 1 = line space between items
        let height = width + PhotoCell.footerHeight
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vc = PhotoDetailsViewController()
        let photo = photosToShow[indexPath.item]
        vc.photo = photo //photo, which will be shown
        vc.savedPhotos = savedPhotos //to check if photo already saved
        self.navigationController?.show(vc, sender: nil)
    }

}


//MARK: Search
extension PhotoGalleryViewController: UISearchControllerDelegate, UISearchBarDelegate {
    
    func setSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        navigationItem.searchController = searchController
        definesPresentationContext = true
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "Поиск фото"
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        photosToShow = []
        searchedPhotos = []
        collectionView.reloadData()
        addLoadingView(to: view)
        guard let query = searchBar.text else { return }
//        searchBar.showsCancelButton = false
        
        service.searchPhotos(query) { [ unowned self ] (response, error) in
            if let error = error {
                self.handleError(error)
            }
            
            if let response = response {
                for photoData in response.results {
                    let photo = Photo(context: self.childContext)
                    photo.setFrom(photoData: photoData)
                    self.searchedPhotos.append(photo)
                }
                
                if self.searchedPhotos.isEmpty {
                    DispatchQueue.main.async {
                        self.showAlertWith(title: "Ничего не найдено", message: "Попробуйте сделать другой запрос")
                    }
                }
            }
            
            if self.searchedPhotos.isEmpty {
                self.photosToShow = self.savedPhotos
                self.searchController.dismiss(animated: true, completion: nil)
            } else {
                
                self.photosToShow = self.searchedPhotos
            }
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                self.removeLoadingView()
            }
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        UnsplashService.task.cancel()
        loadSavedPhotos()
        collectionView.reloadData()
    }
}


