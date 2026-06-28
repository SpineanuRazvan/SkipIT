import Foundation

class GeminiParserService {
    static let shared = GeminiParserService()
    
    private let apiKey = //insert api key
    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
    
    func parseSchedule(fileURL: URL, studentGroup: String, completion: @escaping (Result<[DecodableSubject], Error>) -> Void) {
        guard fileURL.startAccessingSecurityScopedResource() else {
            completion(.failure(NSError(domain: "SecurityError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to access file context"])))
            return
        }
        
        defer { fileURL.stopAccessingSecurityScopedResource() }
        
        guard let fileData = try? Data(contentsOf: fileURL) else {
            completion(.failure(NSError(domain: "DataError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Could not read file data"])))
            return
        }
        
        let mimeType = fileURL.pathExtension.lowercased() == "pdf" ? "application/pdf" : "image/\(fileURL.pathExtension.lowercased())"
        let base64String = fileData.base64EncodedString()
        
        guard let url = URL(string: "\(endpoint)?key=\(apiKey)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let promptText = """
        You are an expert university schedule parser. Analyze this document and extract classes ONLY for student group: "\(studentGroup)".
        
        CRITICAL FILTERING RULES:
        1. Include all general Lectures (Cursuri) that apply to the entire year, major, or section.
        2. For Seminars and Labs (Laboratoare), ONLY include them if they are explicitly assigned to group "\(studentGroup)" or its sub-groups.
        3. Absolutely IGNORE and EXCLUDE any classes that belong strictly to other groups (e.g., if the user is in group 'A1', do not extract classes meant for 'A2', 'B1', 'Group 3', etc.).
        
        You must return a JSON object with a single key "subjects" containing an array of objects matching this exact schema:
        {
          "name": "Full Subject Name",
          "type": "Lecture" or "Seminar" or "Lab",
          "dayOfWeek": 1 for Monday through 7 for Sunday,
          "startTime": "HH:mm" (24h format),
          "endTime": "HH:mm" (24h format),
          "room": "Room code or name",
          "frequency": "Weekly" or "Every two weeks"
        }
        Be precise with time slots and room assignments. Do not make up any data.
        """
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": promptText],
                        [
                            "inlineData": [
                                "mimeType": mimeType,
                                "data": base64String
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "responseMimeType": "application/json"
            ]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else { return }
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                Task { @MainActor in completion(.failure(error)) }
                return
            }
            
            guard let data = data else {
                Task { @MainActor in completion(.failure(NSError(domain: "NoData", code: -3, userInfo: nil))) }
                return
            }
            
            // 👇 NOU: Printează răspunsul brut primit de la Google în consolă pentru investigație
            if let rawResponseString = String(data: data, encoding: .utf8) {
                print("🔴 GEMINI RAW RESPONSE: \(rawResponseString)")
            }
            
            if let rawJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = rawJson["candidates"] as? [[String: Any]],
               let firstCandidate = candidates.first,
               let content = firstCandidate["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let firstPart = parts.first,
               let textResponse = firstPart["text"] as? String {
                
                if let cleanJsonData = textResponse.data(using: .utf8) {
                    Task { @MainActor in
                        do {
                            let decodedRoot = try JSONDecoder().decode(GeminiResponseRoot.self, from: cleanJsonData)
                            completion(.success(decodedRoot.subjects))
                        } catch {
                            completion(.failure(error))
                        }
                    }
                }
            } else {
                Task { @MainActor in
                    completion(.failure(NSError(domain: "ParsingError", code: -4, userInfo: [NSLocalizedDescriptionKey: "Invalid Gemini JSON response format"])))
                }
            }
        }.resume()
    }
}
