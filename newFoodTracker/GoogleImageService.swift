import Foundation

/// Simple stub to search Google Custom Search for recipe images.
class GoogleImageService {
    static let shared = GoogleImageService()
    private let apiKey = "<YOUR_GOOGLE_API_KEY>"
    private let cx     = "<YOUR_SEARCH_ENGINE_ID>"

    func fetchImageURL(
        forRecipe name: String,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let query = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        let urlStr = "https://www.googleapis.com/customsearch/v1?key=\(apiKey)&cx=\(cx)&searchType=image&q=\(query)&num=1"
        guard let url = URL(string: urlStr) else {
            return completion(.failure(NSError(
                domain: "GoogleImageService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]
            )))
        }

        URLSession.shared.dataTask(with: url) { data, _, err in
            if let e = err { return completion(.failure(e)) }
            guard
                let d = data,
                let json = try? JSONSerialization.jsonObject(with: d) as? [String:Any],
                let items = json["items"] as? [[String:Any]],
                let link = items.first?["link"] as? String,
                let linkURL = URL(string: link)
            else {
                return completion(.failure(NSError(
                    domain: "GoogleImageService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No image found"]
                )))
            }
            completion(.success(linkURL))
        }.resume()
    }
}
