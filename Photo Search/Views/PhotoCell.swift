//
//  PhotoCell.swift
//  Photo Search
//
//  Created by Dmitry Borodin on 06/06/2019.
//  Copyright © 2019 Dmitry Borodin. All rights reserved.
//

import UIKit

class PhotoCell: UICollectionViewCell {
    
    static var footerHeight: CGFloat {
        get {
            let cell = PhotoCell()
            return cell.space + cell.labelHeight
        }
    }
    
    private let labelHeight: CGFloat = 46
    private let space: CGFloat = 4
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor).isActive = true
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.image = #imageLiteral(resourceName: "PhotoPlaceholder")
        return imageView
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 2
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(imageView)
        addSubview(titleLabel)
        
        imageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        imageView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        imageView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        
        titleLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -space).isActive = true
        titleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: space).isActive = true
        titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: space).isActive = true
        titleLabel.heightAnchor.constraint(equalToConstant: labelHeight).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = #imageLiteral(resourceName: "PhotoPlaceholder")
    }
}
