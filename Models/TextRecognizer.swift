//
//  TextRecognizer.swift
//  SpiltBill
//
//  Created by Jason Ze on 2024/4/30.
//

import UIKit
import Vision

/// A class responsible for recognizing text from images using the Vision framework.
class TextRecognizer {
    
    /// Recognizes text from a given UIImage.
    /// - Parameters:
    ///   - image: The UIImage from which to recognize text.
    ///   - completion: A closure that gets called with the recognized text strings.
    func recognizeTextFromImage(_ image: UIImage, completion: @escaping ([String]) -> Void) {
        
        // Ensure the UIImage has a valid CGImage representation.
        guard let cgImage = image.cgImage else {
            completion([])
            return
        }

        // Create a VNImageRequestHandler with the CGImage.
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // Create a VNRecognizeTextRequest to recognize text in the image.
        let request = VNRecognizeTextRequest { (request, error) in
            // Ensure the request results are valid VNRecognizedTextObservation instances.
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                completion([])
                return
            }

            // Extract the recognized text strings from the observations.
            let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
            completion(recognizedStrings)
        }

        // Set the recognition level to accurate and the recognition language to English (US).
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"]

        // Perform the text recognition request.
        do {
            try requestHandler.perform([request])
        } catch {
            completion([])
        }
    }
}
