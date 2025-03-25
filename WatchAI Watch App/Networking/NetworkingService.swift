import Foundation
import Combine

/// Service für die Netzwerk-Kommunikation mit URLSession und Combine
final class NetworkingService {
    static let shared = NetworkingService()
    
    private let session: URLSession
    private let decoder: JSONDecoder
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = Constants.requestTimeout
        configuration.timeoutIntervalForResource = Constants.requestTimeout
        
        self.session = URLSession(configuration: configuration)
        self.decoder = JSONDecoder()
    }
    
    /// Führt einen POST-Request aus und gibt einen Publisher zurück
    func post<T: Decodable>(url: URL, headers: [String: String], body: [String: Any]) -> AnyPublisher<T, Error> {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw AppError.invalidResponse
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 401:
                    throw AppError.authenticationError
                case 429:
                    throw AppError.rateLimitExceeded
                case 500...599:
                    throw AppError.serverError
                default:
                    throw AppError.networkError(NSError(domain: "NetworkingService", code: httpResponse.statusCode))
                }
            }
            .decode(type: T.self, decoder: decoder)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// Führt einen GET-Request aus und gibt einen Publisher zurück
    func get<T: Decodable>(url: URL, headers: [String: String]) -> AnyPublisher<T, Error> {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw AppError.invalidResponse
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 401:
                    throw AppError.authenticationError
                case 429:
                    throw AppError.rateLimitExceeded
                case 500...599:
                    throw AppError.serverError
                default:
                    throw AppError.networkError(NSError(domain: "NetworkingService", code: httpResponse.statusCode))
                }
            }
            .decode(type: T.self, decoder: decoder)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
} 