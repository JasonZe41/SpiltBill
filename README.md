# SplitBill

## Table of Contents
- [Introduction](#introduction)
- [Features](#features)
- [Technologies](#technologies)
- [Installation](#installation)
- [Usage](#usage)
- [Screenshots](#screenshots)
- [Contributing](#contributing)
- [License](#license)

## Introduction
SplitBill is an iOS application designed to simplify the process of splitting expenses among friends. It integrates with Firebase for backend services and offers various features to manage expenses efficiently, including authentication, CRUD operations, OCR for receipts, and integration with Venmo for payments. The app also comes with an Apple WatchOS companion app.

## Features
- **User Authentication**: Sign in with email or phone number using Firebase Authentication.
- **CRUD Operations**: Create, read, update, and delete expenses and friends.
- **Search Friends**: Find friends by phone number or email.
- **Bill Splitting**: Split expenses in three different ways.
- **Venmo Integration**: Pay bills through Venmo, directing users to the Venmo app for transactions.
- **OCR Technology**: Extract necessary information from uploaded receipts.
- **Apple WatchOS App**: View expense lists, details, friend lists, and friend details on Apple Watch.
- **Automatic Calculation**: Automatically calculate the total amounts owed or to be received from friends across multiple expenses.

## Technologies
- **iOS Development**: Swift
- **Backend**: Firebase (Authentication, Firestore)
- **Payment Integration**: Venmo API
- **OCR**: Optical Character Recognition for receipt processing
- **Wearable**: WatchOS app

## Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/JasonZe41/SplitBill.git
   ```
2. Navigate to the project directory:
   ```bash
   cd SplitBill
   ```
3. Open the project in Xcode:
   ```bash
   open SplitBill.xcodeproj
   ```
4. Install dependencies using CocoaPods:
   ```bash
   pod install
   ```
5. Set up Firebase:
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/).
   - Add an iOS app to your Firebase project.
   - Download the `GoogleService-Info.plist` file and add it to the Xcode project.

## Usage
1. Run the app on an iOS simulator or device.
2. Sign up or log in using email or phone number.
3. Add friends by searching their phone number or email.
4. Create and manage expenses.
5. Split bills using the provided methods.
6. Use Venmo integration for payments.
7. Upload receipts to automatically extract expense details.
8. View and manage expenses and friends on the Apple WatchOS companion app.

## Screenshots
![IMG_4310](https://github.com/JasonZe41/SpiltBill/assets/146677208/31faccfa-8ca8-4849-a228-89c25a31f9fa)
![IMG_4311](https://github.com/JasonZe41/SpiltBill/assets/146677208/d72f6934-8c94-43a3-9858-852066c552b5)
![IMG_4312](https://github.com/JasonZe41/SpiltBill/assets/146677208/ba4a3b56-1949-4d89-9b00-3a4060882aa4)
![IMG_4313](https://github.com/JasonZe41/SpiltBill/assets/146677208/dbe984b3-7945-4fc7-809c-58e61578911b)
![IMG_4314](https://github.com/JasonZe41/SpiltBill/assets/146677208/58420f82-7e41-4494-9241-7b25b0279a93)
![IMG_4315](https://github.com/JasonZe41/SpiltBill/assets/146677208/7501675c-dcc4-461c-b598-d832644183e9)
![IMG_4316](https://github.com/JasonZe41/SpiltBill/assets/146677208/4f05aeb6-9014-4a5b-b4c0-b7a5806bf885)
![IMG_4317](https://github.com/JasonZe41/SpiltBill/assets/146677208/a05cb54a-89be-4ac6-94f3-e4491cbc0ad5)
![IMG_4318](https://github.com/JasonZe41/SpiltBill/assets/146677208/5191b75b-91ea-4117-8a6a-e0e155bbd94c)
![IMG_4319](https://github.com/JasonZe41/SpiltBill/assets/146677208/51dc547f-a256-47ae-9def-8229921e9ad0)



## Contributing
1. Fork the repository.
2. Create your feature branch:
   ```bash
   git checkout -b feature/YourFeature
   ```
3. Commit your changes:
   ```bash
   git commit -m 'Add some feature'
   ```
4. Push to the branch:
   ```bash
   git push origin feature/YourFeature
   ```
5. Open a pull request.

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

