import AppKit
import Vision

enum ImageIDRecognizer {
    private static let groupedPattern = #"(?<![0-9])(?:[0-9]{9,10}|[0-9]{3}[\s.\-]+[0-9]{3}[\s.\-]+[0-9]{3}|[0-9][\s.\-]+[0-9]{3}[\s.\-]+[0-9]{3}[\s.\-]+[0-9]{3})(?![0-9])"#

    static func numericID(in image: NSImage) async throws -> String? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        return try await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            let handler = VNImageRequestHandler(cgImage: cgImage)
            try handler.perform([request])

            let lines = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
            for line in lines {
                if let id = firstID(in: line) { return id }
            }
            return firstID(in: lines.joined(separator: " "))
        }.value
    }

    static func firstID(in text: String) -> String? {
        guard let range = text.range(of: groupedPattern, options: .regularExpression) else { return nil }
        let normalized = text[range].filter(\.isNumber)
        return (9...10).contains(normalized.count) ? normalized : nil
    }
}
