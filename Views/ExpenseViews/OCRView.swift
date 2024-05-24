//
//  OCRView.swift
//  SpiltBill
//
//  Created by Jason Ze on 2024/4/30.
//

import SwiftUI
import Vision
import VisionKit

/// A SwiftUI view for OCR (Optical Character Recognition) functionality to scan and process receipts.
struct OCRView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    @State private var inputImage: UIImage?
    @State private var recognizedText: String = ""
    @State private var storeName: String = ""
    @State private var totalAmount: String = ""
    @State private var showingImagePicker = false
    @State private var imagePickerSourceType = UIImagePickerController.SourceType.photoLibrary
    @State private var showingActionSheet = false
    @State private var navigateToAddExpense = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Display the selected image
                if let inputImage = inputImage {
                    Image(uiImage: inputImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 250)
                        .cornerRadius(12)
                        .padding()
                }

                // Text editor to display recognized text
                TextEditor(text: $recognizedText)
                    .padding()
                    .frame(height: 200)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))

                // Display store name
                HStack {
                    Text("Store: ")
                        .font(.headline)
                    Spacer()
                    Text(storeName)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)

                // Display total amount
                HStack {
                    Text("Total: ")
                        .font(.headline)
                    Spacer()
                    Text(totalAmount)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)

                Spacer()

                // Button to process the image
                Button(action: processImage) {
                    Text("Process Image")
                        .bold()
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(inputImage == nil ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(inputImage == nil)

                // Button to navigate to AddExpense view
                Button(action: {
                    let cleanedTotalAmount = cleanAmount(totalAmount)
                    navigateToAddExpense = true
                }) {
                    Text("Add Expense")
                        .bold()
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background((storeName.isEmpty || totalAmount.isEmpty) ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(storeName.isEmpty || totalAmount.isEmpty)
            }
            .padding()
            .navigationTitle("Scan Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Image") {
                        showingActionSheet = true
                    }
                }
            }
            .actionSheet(isPresented: $showingActionSheet) {
                ActionSheet(title: Text("Select Image Source"), message: Text("Choose your image source"), buttons: [
                    .default(Text("Camera")) {
                        self.imagePickerSourceType = .camera
                        self.showingImagePicker = true
                    },
                    .default(Text("Photo Library")) {
                        self.imagePickerSourceType = .photoLibrary
                        self.showingImagePicker = true
                    },
                    .cancel()
                ])
            }
            .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                ImagePicker(image: $inputImage, sourceType: $imagePickerSourceType)
            }
            .background(
                NavigationLink(destination: AddExpense(description: storeName, totalAmount: cleanAmount(totalAmount), receiptImage: inputImage).environmentObject(dataStore), isActive: $navigateToAddExpense) {
                    EmptyView()
                }
            )
        }
    }

    /// Loads the selected image and recognizes text from it.
    private func loadImage() {
        if let inputImage = inputImage {
            recognizeTextFromImage(inputImage)
        }
    }

    /// Processes the selected image to recognize text.
    private func processImage() {
        if let inputImage = inputImage {
            recognizeTextFromImage(inputImage)
        }
    }

    /// Uses Vision framework to recognize text from a given image.
    /// - Parameter image: The image from which text will be recognized.
    private func recognizeTextFromImage(_ image: UIImage) {
        let recognizer = TextRecognizer()
        recognizer.recognizeTextFromImage(image) { lines in
            DispatchQueue.main.async {
                self.recognizedText = lines.joined(separator: "\n")
                self.parseRecognizedText(lines)
            }
        }
    }

    /// Parses recognized text lines to extract store name and total amount.
    /// - Parameter lines: The lines of recognized text.
    private func parseRecognizedText(_ lines: [String]) {
        var storeNameFound = false
        var totalAmountFound = false

        for line in lines {
            if !storeNameFound, let detectedStoreName = detectStoreName(in: line) {
                storeName = detectedStoreName
                storeNameFound = true
            }

            if !totalAmountFound, let detectedTotalAmount = detectTotalAmount(in: line) {
                totalAmount = detectedTotalAmount
                totalAmountFound = true
            }

            if storeNameFound && totalAmountFound {
                break
            }
        }
    }

    /// Detects the store name from a line of text.
    /// - Parameter line: A line of recognized text.
    /// - Returns: The detected store name if found.
    private func detectStoreName(in line: String) -> String? {
        let knownStores = ["Trader Joe's", "Costco", "Walmart", "Target", "Restaurant"]
        for store in knownStores {
            if line.localizedCaseInsensitiveContains(store) {
                return store
            }
        }
        return nil
    }

    /// Detects the total amount from a line of text.
    /// - Parameter line: A line of recognized text.
    /// - Returns: The detected total amount if found.
    private func detectTotalAmount(in line: String) -> String? {
        let pattern = "\\$\\s*\\d+(\\.\\d{2})?"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        
        guard let matches = regex?.matches(in: line, options: [], range: NSRange(line.startIndex..., in: line)),
              let lastMatch = matches.last else {
            return nil
        }
        
        let range = Range(lastMatch.range, in: line)
        return range.map { String(line[$0]) }
    }

    /// Cleans the total amount by removing unwanted characters.
    /// - Parameter amount: The total amount as a string.
    /// - Returns: The cleaned total amount as a string.
    private func cleanAmount(_ amount: String) -> String {
        let cleanedAmount = amount.filter { "0123456789.".contains($0) }
        return cleanedAmount
    }
}
