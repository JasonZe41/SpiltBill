//
//  TextRecognizer.swift
//  SpiltBill
//
//  Created by Jason Ze on 2024/4/30.
//
import UIKit
import Vision

class TextRecognizer {
    func recognizeTextFromImage(_ image: UIImage, completion: @escaping ([String]) -> Void) {
        guard let cgImage = image.cgImage else {
            completion([])
            return
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                completion([])
                return
            }

            let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
            completion(recognizedStrings)
        }

        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"]

        do {
            try requestHandler.perform([request])
        } catch {
            completion([])
        }
    }
}
