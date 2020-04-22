//
//  PhotoDetailsView.swift
//  Photo Search
//
//  Created by Dmitry Borodin on 10/06/2019.
//  Copyright © 2019 Dmitry Borodin. All rights reserved.
//

import UIKit

class PhotoDetailsView: UIView {
    
    let imageView: UIImageView = {
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
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addImageView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func hideViews(_ isHide: Bool) {
        if isHide {
            metaLabel.isHidden = true
            gradientLayer.isHidden = true
        } else {
            metaLabel.isHidden = false
            gradientLayer.isHidden = false
        }
    }
    
    private func addImageView() {
        addSubview(imageView)
        imageView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        imageView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        imageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
    
    func setView() {
        if imageView.image != nil {
            setGradientLayer()
            setMetaLabel()
        }
    }
    
    
    //gradientLabel methods
    private func setGradientLayer() {
        let gradientLayerBounds = imageBounds(in: imageView)
        gradientLayer.frame = gradientLayerBounds
        
        //Add layer only if it is not exists yet
        if let imageViewLayers = imageView.layer.sublayers,
           imageViewLayers.contains(gradientLayer) {
            return
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
    
    //updates constraints if device changed orientation
    private func updateMetalabel() {
        //updating metaLabel bottom anchor
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
    
    func setMetaLabelTextFrom(_ photo: Photo) {
        let userName = photo.userName
        metaLabel.text = "Author: %@".localized(with: [userName])
        
        //called only with saved photos, which have dateAdded
        if let dateAdded = photo.dateAdded {
            let dateFormater = DateFormatter()
            dateFormater.locale = Locale.current
            dateFormater.dateStyle = .long
            dateFormater.timeStyle = .short
            let dateString = dateFormater.string(from: dateAdded)
            let savedText = "Saved: %@".localized(with: [dateString])
            metaLabel.text?.append("\n\(savedText)")
        }
    }
    
    //helper to get bounds of photo inside imageView
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
