//
//  Decoder.swift
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

public protocol DecoderDelegate: class {
    func outputSynthesized(data:Hypothesis)
    func readyForBuffer()
}

fileprivate enum SpeechStateEnum : CustomStringConvertible {
    case silence
    case speech
    case utterance
    
    var description: String {
        get {
            switch(self) {
            case .silence:
                return "Silence"
            case .speech:
                return "Speech"
            case .utterance:
                return "Utterance"
            }
        }
    }
}


public enum DecodeErrors : Error {
    case CantReadSpeachFile(String)
    case CantSetAudioSession(NSError)
    case CantStartAudioEngine(NSError)
    case CantAddWordsWhileDecodeingSpeech
    case CantConvertAudioFormat
}


public final class Decoder {
    
    fileprivate var psDecoder: OpaquePointer?
    fileprivate var speechState: SpeechStateEnum
    
    public weak var delegate:DecoderDelegate?
    public var data: Data = Data() {
        didSet {
            process_raw(data)
        }
    }
    
    public init?(config: Config) {
        
        speechState = .silence
        psDecoder = config.cmdLnConf.flatMap(ps_init)

        if psDecoder == nil {
            return nil
        }
        
        start_utt()
        
    }
    
    deinit {
        let refCount = ps_free(psDecoder)
        assert(refCount == 0, "Can't free decoder because it's shared among instances")
        print("[ DECODER ] [ DEINIT ]")
    }
    
    @discardableResult fileprivate func process_raw(_ data: Data)-> CInt {
        
        let dataLenght = data.count / 2
        let dataBuffer = data.withUnsafeBytes{ $0.bindMemory(to: Int16.self).baseAddress }
        let numberOfFrames = ps_process_raw(self.psDecoder, dataBuffer, dataLenght, STrue32, SFalse32)
        
        let hasSpeech = in_speech()
        
        switch (speechState) {
        case .silence where hasSpeech:
            speechState = .speech
        case .speech where !hasSpeech:
            speechState = .utterance
        case .utterance where !hasSpeech:
            speechState = .silence
        default:
            break
        }
        

        if speechState == .utterance {
            end_utt()
            if let out = get_hyp() {
                delegate?.outputSynthesized(data: out)
            }
            start_utt()
        }
        
        delegate?.readyForBuffer()
        return numberOfFrames
    }
    
    fileprivate func in_speech() -> Bool {
        return ps_get_in_speech(psDecoder) == STrue
    }
    
    @discardableResult fileprivate func start_utt() -> Bool {
        return ps_start_utt(psDecoder) == 0
    }
    
    @discardableResult fileprivate func end_utt() -> Bool {
        return ps_end_utt(psDecoder) == 0
    }
    
    fileprivate func get_hyp() -> Hypothesis? {
        var score: int32 = 0

        guard let string = ps_get_hyp(psDecoder, &score) else {
            return nil
        }

        if let text = String(validatingUTF8: string) {
            return Hypothesis(text: text, score: Int(score))
        } else {
            return nil
        }
    }

   
    public func add(words:Array<(word: String, phones: String)>) throws {
        
        for (word,phones) in words {
            let update = words.last?.word == word ? STrue32 : SFalse32
            ps_add_word(psDecoder, word, phones, update)
        }
    }

}
