//
//  TextRecognizer.swift
//  SpiltBill
//
//  Created by Jason Ze on 2024/4/30.
//
import Foundation
import Vision
import UIKit

class TextRecognizer {
    // Modify the function to use a completion handler that returns an array of strings
    func recognizeTextFromImage(_ image: UIImage, completion: @escaping ([String]) -> Void) {
        guard let cgImage = image.cgImage else {
            completion([])
            return
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("OCR Error: \(error.localizedDescription)")
                completion([])
                return
            }

            var lines = [String]()
            // Extract lines of text rather than aggregating into a single string
            for observation in request.results as? [VNRecognizedTextObservation] ?? [] {
                for text in observation.topCandidates(1) {
                    lines.append(text.string)
                }
            }
            completion(lines)
        }
        
        // You might want to use .accurate for better accuracy as receipts can have small fonts
        request.recognitionLevel = .accurate
        
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform OCR: \(error.localizedDescription)")
            completion([])
        }
    }
}
