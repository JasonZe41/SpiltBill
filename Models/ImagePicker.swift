//
//  ImagePicker.swift
//  SpiltBill
//
//  Created by Jason Ze on 2024/4/30.
//

import SwiftUI

/// A SwiftUI view that wraps a UIImagePickerController to allow for image picking in a SwiftUI context.
struct ImagePicker: UIViewControllerRepresentable {
    
    /// Binding to store the selected image.
    @Binding var image: UIImage?
    
    /// Binding to store the source type of the image picker (camera or photo library).
    @Binding var sourceType: UIImagePickerController.SourceType
    
    /// Creates the UIImagePickerController.
    /// - Parameter context: The context used to coordinate with the SwiftUI view.
    /// - Returns: A configured UIImagePickerController instance.
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }

    /// Updates the UIImagePickerController.
    /// - Parameters:
    ///   - uiViewController: The UIImagePickerController to update.
    ///   - context: The context used to coordinate with the SwiftUI view.
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No update needed for this view controller
    }
    
    /// Creates a Coordinator instance to handle UIImagePickerController delegate methods.
    /// - Returns: A Coordinator instance.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    /// A Coordinator class to handle UIImagePickerController delegate methods.
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        
        /// The parent ImagePicker instance.
        let parent: ImagePicker
        
        /// Initializes a Coordinator instance.
        /// - Parameter parent: The parent ImagePicker instance.
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        /// Called when the user finishes picking an image.
        /// - Parameters:
        ///   - picker: The UIImagePickerController instance.
        ///   - info: A dictionary containing the picked image and other relevant info.
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true)
        }
    }
}
