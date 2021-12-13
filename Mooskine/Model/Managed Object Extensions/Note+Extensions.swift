//
//  Note+Extensions.swift
//  Mooskine
//
//  Created by Justin Viasus on 12/11/21.
//  Copyright © 2021 Udacity. All rights reserved.
//

import Foundation
import CoreData

// we had to create extensions because the original Note file is tucked away in derived data, and remember that any changes to that file will be overriden.

extension Note {
    // called when the object is initially created. Sets its creation date when it is first created. 
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        self.creationDate = Date()
    }
}
