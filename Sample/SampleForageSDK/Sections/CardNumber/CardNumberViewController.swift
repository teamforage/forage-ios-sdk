//
//  CardNumberViewController.swift
//  SampleForageSDK
//
//  Created by Tiago Oliveira on 18/10/22.
//  Copyright © 2022-Present Forage Technology Corporation. All rights reserved.
//

import UIKit
import ForageSDK

class CardNumberViewController: BaseViewCodeViewController<CardNumberView> {
    // MARK: Lifecycle Methods
    var cardNumber: String = ""

    override func loadView() {
        super.loadView()
        customView.backgroundColor = .white
        customView.render()
        customView.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        customView.foragePanTextField.becomeFirstResponder()
    }
}

// MARK: - CardNumberViewDelegate

extension CardNumberViewController: CardNumberViewDelegate {
    func goToBalance(_ view: CardNumberView) {
        let requestBalanceViewController = RequestBalanceViewController()
        navigationController?.pushViewController(requestBalanceViewController, animated: true)
    }
    
    func openImagePicker() {
        let photoPickerViewController = PhotoPickerViewController()
        photoPickerViewController.delegate = self
        navigationController?.pushViewController(photoPickerViewController, animated: true)
    }
    
    func getCardNumber() -> String {
        return self.cardNumber
    }
    
    func setCardNumber(_ num: String) {
        self.cardNumber = num
    }
}

class PhotoPickerViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var delegate: CardNumberViewDelegate?
    
    let imageView = UIImageView()
    let selectPhotoButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        view.backgroundColor = .white
        
        // Configure ImageView
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        // Configure Button
        selectPhotoButton.setTitle("Select Photo", for: .normal)
        selectPhotoButton.addTarget(self, action: #selector(selectPhotoTapped), for: .touchUpInside)
        selectPhotoButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(selectPhotoButton)
        
        // Layout Constraints
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            imageView.widthAnchor.constraint(equalToConstant: 300),
            imageView.heightAnchor.constraint(equalToConstant: 300),
            
            selectPhotoButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            selectPhotoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    @objc func selectPhotoTapped() {
        let alert = UIAlertController(title: "Select Photo", message: "Choose a source", preferredStyle: .actionSheet)
        
        // Camera Option
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
                self.openImagePicker(sourceType: .camera)
            }))
        }
        
        // Photo Library Option
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { _ in
            self.openImagePicker(sourceType: .photoLibrary)
        }))
        
        // Cancel Option
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true)
    }
    
    func openImagePicker(sourceType: UIImagePickerController.SourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = sourceType
        imagePicker.delegate = self
//        imagePicker.allowsEditing = true  // Allow cropping/editing
        present(imagePicker, animated: true)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        var delegate: CardNumberViewDelegate?
        
        if let editedImage = info[.editedImage] as? UIImage {
            imageView.image = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            imageView.image = originalImage
        }
        
        if let theImage = imageView.image {
            recognizeCardText(from: theImage) { [self] result in
//                    self.cardNumber = result
                DispatchQueue.main.async {
                    switch result {
                    case let .success(response):
                        self.delegate?.setCardNumber(response ?? "")
                    case let .failure(error):
                        print("oh no")
                    }
                }
            }
        }
        
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
