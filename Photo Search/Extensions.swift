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
        switch errorCode {
        case -1009:
            //No internet connection
            showAlertWith(title: "Нет интернет соединения", message: "Проверьте соединение с интернетом")
        case -1001:
            //Request time out
            showAlertWith(title: "Плохое соединене", message: "Проверьте соединение с интернетом или попробуйте позже")
        default:
            //Other errors
            showAlertWith(title: "Неизвестная ошибка", message: "Попробуйте позже")
        }
    }
    
    func showAlertWith(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
    
    
}
