//
//  OCRView.swift
//  SpiltBill
//
//  Created by Jason Ze on 2024/4/30.
//
import SwiftUI
import Vision
import VisionKit

struct OCRView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    @State private var inputImage: UIImage?
    @State private var recognizedText: String = ""
    @State private var showingImagePicker = false
    @State private var imagePickerSourceType = UIImagePickerController.SourceType.photoLibrary
    @State private var showingActionSheet = false

    var body: some View {
        NavigationView {
            VStack {
                if let inputImage = inputImage {
                    Image(uiImage: inputImage)
                        .resizable()
                        .scaledToFit()
                }

                TextEditor(text: $recognizedText)
                    .padding()

                Button("Process Image") {
                    if let inputImage = inputImage {
                        recognizeTextFromImage(inputImage)
                    }
                }
                .disabled(inputImage == nil)
            }
            .navigationTitle("Scan Receipt")
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
        }
    }

    private func loadImage() {
        // This function will be called after the image picker is dismissed
        if let inputImage = inputImage {
            // Optionally process the image immediately after loading
            recognizeTextFromImage(inputImage)
        }
    }

    private func recognizeTextFromImage(_ image: UIImage) {
        let recognizer = TextRecognizer()
        recognizer.recognizeTextFromImage(image) { lines in
            // Handle the lines of text here
            // For example, you might update the UI or process each line
            DispatchQueue.main.async {
                self.recognizedText = lines.joined(separator: "\n")
            }
        }
    }

}
