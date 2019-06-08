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
    private var service: UnsplashService!
    private var photosToShow = [Photo]()
    var savedPhotos = [Photo]()
    private var searchedPhotos = [Photo]()
    private var searchController: UISearchController!
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
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
        showKeyboardIfNoPhotos()
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
            DispatchQueue.main.async {
                self.searchController.searchBar.becomeFirstResponder()
            }
            
        }
    }
    
    private func searchPhotos(_ query: String, completion: @escaping () -> Void) {
        service = UnsplashService()
        self.searchedPhotos = []
        service.searchPhotos(query) { (response, error) in
            if let error = error as NSError? {
                self.handleError(error)
                DispatchQueue.main.async {
                    completion()
                }
                return
            }
            
            if let response = response {
                for photoData in response.results {
                    let photo = Photo(context: self.childContext)
                    photo.setFrom(photoData: photoData)
                    self.searchedPhotos.append(photo)
                }
            }
            self.photosToShow = self.searchedPhotos
            DispatchQueue.main.async {
                completion()
            }
        }
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
    
    private func configurePhotoCell(_ cell: PhotoCell, with photo: Photo) {
        cell.imageView.image = photo.smallPhoto
        if photo.managedObjectContext == childContext {
            photo.loadImage(size: .small) { (image, error) in
                if let error = error {
                    self.handleError(error)
                }
                cell.imageView.image = image
            }
        } else {
            cell.imageView.image = photo.smallPhoto
        }
        cell.titleLabel.text = "By \(photo.userName)"
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = UIDevice.current.orientation.isPortrait ? view.frame.width / 3 - 1 : view.frame.width / 6 - 1
        let height = width + 50
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
        vc.photo = photo
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
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "Поиск фото"
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        photosToShow = []
        collectionView.reloadData()
        addLoadingView(to: view)
        guard let query = searchBar.text else { return }
        searchPhotos(query) {
            self.collectionView.reloadData()
            self.removeLoadingView()
        }
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        loadSavedPhotos()
        collectionView.reloadData()
    }
}

