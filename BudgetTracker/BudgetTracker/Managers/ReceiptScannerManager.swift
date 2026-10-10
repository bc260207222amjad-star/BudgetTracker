//
//  ReceiptScannerManager.swift
//  BudgetTracker
//
//  Created by ali on 10/10/2026.
//

import UIKit
import Vision

public struct ScannedReceiptData {
    public let merchant: String?
    public let amount: Double?
    public let date: Date?
    public let rawText: String
}

public class ReceiptScannerManager {
    public static let shared = ReceiptScannerManager()
    
    private init() {}
    
    // MARK: - Vision OCR
    
    public func scanReceiptImage(_ image: UIImage, completion: @escaping (ScannedReceiptData) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(ScannedReceiptData(merchant: nil, amount: nil, date: nil, rawText: ""))
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                DispatchQueue.main.async {
                    completion(ScannedReceiptData(merchant: nil, amount: nil, date: nil, rawText: ""))
                }
                return
            }
            
            var textLines: [String] = []
            for observation in observations {
                if let candidate = observation.topCandidates(1).first {
                    textLines.append(candidate.string)
                }
            }
            
            let fullText = textLines.joined(separator: "\n")
            let parsed = self.parseReceiptText(lines: textLines, rawText: fullText)
            
            DispatchQueue.main.async {
                completion(parsed)
            }
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                print("Failed to perform OCR request: \(error)")
                DispatchQueue.main.async {
                    completion(ScannedReceiptData(merchant: nil, amount: nil, date: nil, rawText: ""))
                }
            }
        }
    }
    
    // MARK: - Text Parsing Heuristics
    
    private func parseReceiptText(lines: [String], rawText: String) -> ScannedReceiptData {
        var detectedMerchant: String?
        var detectedAmount: Double?
        var detectedDate: Date?
        
        // 1. Merchant: Look at top 3 lines (ignoring noise/dates/receipt labels)
        for line in lines.prefix(4) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count >= 3 &&
                !trimmed.lowercased().contains("receipt") &&
                !trimmed.lowercased().contains("welcome") &&
                !trimmed.lowercased().contains("store #") &&
                !trimmed.lowercased().contains("tax") &&
                !trimmed.lowercased().contains("tel") &&
                !trimmed.lowercased().contains("phone") {
                detectedMerchant = trimmed
                break
            }
        }
        
        // 2. Amount: Look for lines with "total", "amount", "balance", or currency symbols
        var highestAmount: Double = 0.0
        let totalRegex = try? NSRegularExpression(pattern: #"(?:total|amount|due|balance|subtotal|paid)?\s*[:$€£₨]?\s*([0-9]+[.,][0-9]{2})"#, options: [.caseInsensitive])
        
        for line in lines {
            let nsLine = line as NSString
            let range = NSRange(location: 0, length: nsLine.length)
            if let match = totalRegex?.firstMatch(in: line, options: [], range: range) {
                if match.numberOfRanges > 1 {
                    let amountStr = nsLine.substring(with: match.range(at: 1)).replacingOccurrences(of: ",", with: ".")
                    if let val = Double(amountStr) {
                        if line.lowercased().contains("total") {
                            detectedAmount = val
                            break
                        }
                        if val > highestAmount {
                            highestAmount = val
                        }
                    }
                }
            }
        }
        
        if detectedAmount == nil && highestAmount > 0 {
            detectedAmount = highestAmount
        }
        
        // 3. Date detection: Look for standard date patterns
        let dateDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        let matches = dateDetector?.matches(in: rawText, options: [], range: NSRange(location: 0, length: (rawText as NSString).length))
        if let firstDateMatch = matches?.first, let date = firstDateMatch.date {
            detectedDate = date
        }
        
        return ScannedReceiptData(
            merchant: detectedMerchant,
            amount: detectedAmount,
            date: detectedDate,
            rawText: rawText
        )
    }
    
    // MARK: - File Management
    
    public func saveReceiptImage(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let receiptsDir = docs.appendingPathComponent("Receipts", isDirectory: true)
        try? FileManager.default.createDirectory(at: receiptsDir, withIntermediateDirectories: true)
        
        let fileName = "\(UUID().uuidString).jpg"
        let fileURL = receiptsDir.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL.path
        } catch {
            print("Failed to save receipt image: \(error)")
            return nil
        }
    }
    
    public func loadThumbnail(from path: String, maxDimension: CGFloat = 160) -> UIImage? {
        guard FileManager.default.fileExists(atPath: path),
              let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil) else {
            return nil
        }
        
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ]
        
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return UIImage(contentsOfFile: path)
        }
        
        return UIImage(cgImage: thumbnail)
    }
}
