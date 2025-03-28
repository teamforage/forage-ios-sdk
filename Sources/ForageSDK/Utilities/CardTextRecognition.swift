import UIKit
import Vision

public func recognizeCardText(from uiImage: UIImage, completion: @escaping (Result<String?, Error>) -> Void) {
        
    // 1. Convert UIImage to CGImage
    guard let cgImage = uiImage.cgImage else {
        let error = NSError(domain: "VisionErrorDomain",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Unable to create CGImage from UIImage."])
        completion(.failure(error))
        return
    }
    
    // 2. Create a text recognition request
    let request = VNRecognizeTextRequest { request, error in
        
        if let error = error {
            completion(.failure(error))
            return
        }
        
        // 3. Process the recognized text
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            let error = NSError(domain: "VisionErrorDomain",
                                code: -2,
                                userInfo: [NSLocalizedDescriptionKey: "No text observations found."])
            completion(.failure(error))
            return
        }
        
        // 4. Extract text from each observation
        let recognizedStrings: [String] = observations.compactMap { observation in
            return observation.topCandidates(1).first?.string
        }
        
        // 5. Look for card number pattern in recognized text
        let cardNumberRegex = #"\b(?:\d[ -]*?){16,19}\b"#
        
        for line in recognizedStrings {
            if let range = line.range(of: cardNumberRegex, options: .regularExpression) {
                // Extract just the digits from the matched card number
                let cardNumber = line[range].components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                completion(.success(cardNumber))
                return
            }
        }
        
        // No card number found
        completion(.success(nil))
    }

    // Configure request properties
    request.recognitionLevel = .accurate
    request.usesCPUOnly = false
    
    // 6. Create a request handler and perform request
    let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    
    DispatchQueue.global(qos: .userInitiated).async {
        do {
            try requestHandler.perform([request])
        } catch {
            completion(.failure(error))
        }
    }
}
