//
//  Notebook+Extensions.swift
//  Mooskine
//
//  Created by Justin Viasus on 12/11/21.
//  Copyright © 2021 Udacity. All rights reserved.
//

import Foundation
import CoreData

extension Notebook {
    // sets the creationDate on Note initialization, and it's cleaner doing this during initialization than after.
    public override func awakeFromInsert() {
        // we don't want to override the default implementation, we want to just add to it. So we call super.
        super.awakeFromInsert()
        // sets creationDate to the current date
        self.creationDate = Date()
    }
}
