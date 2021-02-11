//
//  Hypothesis.swift
//  TLSphinx
//
//  Created by Bruno Berisso on 6/1/15.
//  Copyright (c) 2015 Bruno Berisso. All rights reserved.
//
//  Created by m4m4 on 09.01.20.
//  Copyright © 2020 mainvolume. All rights reserved.
//

public struct Hypothesis {
    public let text: String
    public let score: Int
}

extension Hypothesis : CustomStringConvertible {
    
    public var description: String {
        get {
            return "Text: \(text) - Score: \(score)"
        }
    }
    
}

extension Hypothesis {
    static func +(lhs: Hypothesis, rhs: Hypothesis) -> Hypothesis {
        return Hypothesis(text: lhs.text + " " + rhs.text, score: (lhs.score + rhs.score) / 2)
    }
}

func +(lhs: Hypothesis?, rhs: Hypothesis?) -> Hypothesis? {
    if let _lhs = lhs, let _rhs = rhs {
        return _lhs + _rhs
    } else {
        if let _lhs = lhs {
            return _lhs
        } else {
            return rhs
        }
    }
}
