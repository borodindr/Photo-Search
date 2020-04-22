//
//  Extensions.swift
//  Photo Search
//
//  Created by Dmitry Borodin on 07/06/2019.
//  Copyright © 2019 Dmitry Borodin. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    
    static let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.style = .gray
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    func addLoadingView(to view: UIView) {
        view.addSubview(UIViewController.loadingIndicator)
        UIViewController.loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        UIViewController.loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        UIViewController.loadingIndicator.startAnimating()
    }
    
    func removeLoadingView() {
        UIViewController.loadingIndicator.removeFromSuperview()
        UIViewController.loadingIndicator.stopAnimating()
    }
    
    func handleError(_ error: NSError) {
        let errorCode = error.code
        DispatchQueue.main.async { [unowned self] in
            switch errorCode {
            case -1009:
                //No internet connection
                self.showAlertWith(title: "No internet connection".localized(), message: "Please check internet connection or try later".localized())
            case -1001:
                //Request time out
                self.showAlertWith(title: "Bad connection".localized(), message: "Please check internet connection or try later".localized())
            case -999:
                //Canceled task
                return
            default:
                //Other errors
                self.showAlertWith(title: "Unknown error".localized(), message: "Please try again later".localized())
            }
        }
    }
    
    func showAlertWith(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
    
    
}
