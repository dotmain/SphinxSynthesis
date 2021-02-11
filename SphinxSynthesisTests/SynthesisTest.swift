//
//  SynthesisTest.swift
//  SynthesisTest
//
//  Created by m4m4 on 09.01.20.
//  Copyright © 2020 mainvolume. All rights reserved.
//
 
import XCTest
import CoreSynthetis
import SynthesisFramework

class LiveSynthesisTest: XCTestCase {
   
    let format = SynthesisFormat(sr: kSamplesRate, cc: 1, l: kSamplesPerBuffer)
    let que = DispatchQueue(label: "SS")
    var synthesis: AudioSynthesis?
    var decode: CoreSynthetis.Decoder?
    var expected: XCTestExpectation?
    
    func testSynthesis() {
        initSphinx()
        initSynthesis()
        expected = expectation(description: "mainvolume.timout.expected")
        waitForExpectations(timeout: NSTimeIntervalSince1970)
    }
    
    private func initSynthesis() {
        synthesis = AudioSynthesis(ƒ: format)
        synthesis?.delegate = self
        synthesis?.synthesize()
    }
    
    private func initSphinx() {
        guard let modelPath = getModelPath() else {
            XCTFail("Can't access pocketsphinx model. Bundle root: \(Bundle.main)")
            return
        }
        let hmm = modelPath.appendingPathComponent("en-us")
        let lm = modelPath.appendingPathComponent("en-us.lm.dmp")
        let dict = modelPath.appendingPathComponent("cmudict-en-us.dict")
        guard let config = Config(args: ("-hmm", hmm),
                                  ("-lm", lm), ("-dict", dict),
                                  ("-samprate", "\(Int(kSamplesRate))") ) else {
            XCTFail("Can't run test without a valid config")
            return
        }
        config.showDebugInfo = true
        guard let decoder = Decoder(config:config) else {
            XCTFail("Can't run test without a decoder")
            return
        }
        decode = decoder
        decode?.delegate = self
    }
    
    private func getModelPath() -> NSString? {
        return Bundle(for: LiveSynthesisTest.self).path(forResource: "model/en-us", ofType: nil) as NSString?
    }
}

extension LiveSynthesisTest: DecoderDelegate {
    
    func outputSynthesized(data: Hypothesis) {
        if !data.text.isEmpty {
            print("[ SphinxSynthesis ] [ OUTPUT ] : \(data.text)")
            expected?.fulfill()
        }
    }
}

extension LiveSynthesisTest: AudioSynthesisDelegate {
    
    func readyForBuffer() {}
    
    func outDataSynthesized(data: SynthesisBuffer) {
        synthesis?.synthesize()
        que.async { [weak self, data] in
            self?.decode?.data = Data(bytes: data.data, count: kSamplesPerBuffer)
        }
    }
}
