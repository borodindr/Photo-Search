//
//  String+Extension.swift
//  Photo Search
//
//  Created by Dmitry Borodin on 22.04.2020.
//  Copyright © 2020 Dmitry Borodin. All rights reserved.
//

import Foundation

extension String {
    func localized() -> String {
        NSLocalizedString(self, comment: self)
    }
    
    func localized(with arguments: [CVarArg]) -> String {
        String(format: self.localized(), arguments: arguments)
    }
    
}
