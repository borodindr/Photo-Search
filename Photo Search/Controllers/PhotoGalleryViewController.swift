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

    //MARK: - Properties
    private let service = UnsplashService()
    var photosToShow = [Photo]()
//    var savedPhotos = [Photo]()
//    private var searchedPhotos = [Photo]()
    private var searchController: UISearchController!
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    private var searchDebounceTimer: Timer?
    
    //child context to create searched objects. Only selected (saved) objects go to parent context
    private lazy var childContext:  NSManagedObjectContext = {
        let childContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        childContext.parent = self.context
        return childContext
    }()
    
    //MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView!.register(PhotoCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        title = "Photo Search".localized()
        setSearchController()
//        loadSavedPhotos()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let searchText = searchController.searchBar.text
        if searchText == nil || searchText == "" {
            loadSavedPhotos()
        }
        showKeyboardIfNoPhotos() //For better UX. If there are no saved photos yet, show keyboard to search
//        collectionView.reloadData()
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
            photosToShow = try context.fetch(fetchRequest)
            collectionView.reloadData()
            clearChildContext()
        } catch {
            print("fetch error:", error)
        }
    }
    
    private func showKeyboardIfNoPhotos() {
        if photosToShow.isEmpty {
            DispatchQueue.main.async { [weak self] in
                self?.searchController.searchBar.becomeFirstResponder()
            }
        }
    }
    
    private func configurePhotoCell(_ cell: PhotoCell, with photo: Photo) {
        //setting image of cell
        if let savedPhoto = photo.smallPhoto {
            cell.imageView.image = savedPhoto
        } else {
            //photo object from search
            cell.imageView.image = #imageLiteral(resourceName: "PhotoPlaceholder")
            photo.loadImage(size: .small) { [weak cell] (image, error) in
                if error != nil {
                    cell?.imageView.image = #imageLiteral(resourceName: "PhotoPlaceholder")
                }
                
                if let image = image {
                    cell?.imageView.image = image
                }
            }
        }
        //setting title of cell
        cell.titleLabel.text = "By \(photo.userName)"
    }
    
    private func clearChildContext() {
        childContext.insertedObjects.forEach({ childContext.delete($0) })
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
        let width = UIDevice.current.orientation.isLandscape ? view.frame.width / 6 - 1 : view.frame.width / 3 - 1 //to make nearly same cells for both orientations; 1 = line space between items
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
//        vc.savedPhotos = photosToShow //to check if photo already saved
        self.navigationController?.pushViewController(vc, animated: true)
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
        searchController.searchBar.placeholder = "Search".localized()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        let searchText = searchController.searchBar.text
        if searchText == nil || searchText == "" {
            photosToShow = []
            collectionView.reloadData()
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if let timer = searchDebounceTimer, timer.isValid {
            print("Invalidating timer")
            searchDebounceTimer?.invalidate()
        }
        searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] (_) in
            guard let self = self else { return }
            
            self.clearChildContext()
            
            print("Searching:", searchText)
            self.service.searchPhotos(searchText) { [weak self] (response, error) in
                guard let self = self else { return }
                
                if let error = error {
                    self.handleError(error)
                }
                
                if let response = response {
                    self.photosToShow = response.results.map { [unowned self] photoData in
                        let photo = Photo(context: self.childContext)
                        photo.setFrom(photoData: photoData)
                        return photo
                    }
                    
                    // TODO: show label "No photos found"
                    
                }
                
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    self.removeLoadingView()
                }
            }
            
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        UnsplashService.task.cancel()
        loadSavedPhotos()
    }
}


