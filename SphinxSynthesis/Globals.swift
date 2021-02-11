//
//  NSFileHandle+Extension.swift
//  TLSphinx
//
//  Created by Bruno Berisso on 5/29/15.
//  Copyright (c) 2015 Bruno Berisso. All rights reserved.
//
//  Created by m4m4 on 09.01.20.
//  Copyright © 2020 mainvolume. All rights reserved.
//

import Foundation
import Sphinx

let STrue: uint8 = 1
let SFalse: uint8 = 0

let STrue32: CInt = 1
let SFalse32: CInt = 0

extension FileHandle {
    
    func reduceChunks<T>(_ size: Int, initial: T, reducer: (Data, T) -> T) -> T {
        
        var reduceValue = initial
        var chuckData = readData(ofLength: size)
        
        while chuckData.count > 0 {
            reduceValue = reducer(chuckData, reduceValue)
            chuckData = readData(ofLength: size)
        }
        
        return reduceValue
    }
    
}
