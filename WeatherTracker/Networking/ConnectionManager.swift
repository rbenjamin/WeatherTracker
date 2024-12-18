//
//  ConnectionManager.swift
//  WeatherTracker
//
//  Created by Ben Davis on 12/17/24.
//

import Foundation
import UIKit
import UniformTypeIdentifiers

enum Request: String {
    case currentWeather = "current"
    case search = "search"
}

enum ConnectionError: Error {
    case incorrectResponse(response: String)
}


actor ConnectionManager<T: Connection> {
    
    typealias CompletionResult = @Sendable (Result<Data?, Error>) -> Void
    
    let connection: T
    let jsonDecoder = JSONDecoder()

    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true
        
        return URLSession(configuration: config)
    }()
    
    private var activeDownloads = [URL : URLSessionDataTask]()
    
    private var iconCache = NSCache<NSString, UIImage>()
    
    init(connection: T) {
        self.connection = connection
    }
    // MARK: - URL Resolution -
    
    fileprivate func resolveURLForRequest(_ request: Request,
                                      coordinates: WeatherCoordinates,
                                      days: Int = 1) throws -> URL? {
        
        let requestURL = URL(string: self.connection.baseURL)?.appendingPathComponent(request.rawValue,
                                                                                      conformingTo: connection.requestType)
        
        guard let requestURL else {
            throw URLError(.badURL)
        }
        guard var components = URLComponents(url: requestURL,
                                             resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        
        components.queryItems = [URLQueryItem(name: "key",
                                              value: self.connection.apiKey),
                                 URLQueryItem(name: "q",
                                              value: "\(coordinates.latitude),\(coordinates.longitude)")
                                ]
        return components.url
    }
    
    fileprivate func resolveURLForRequest(_ request: Request,
                                      query: String,
                                      days: Int = 1) throws -> URL? {
        
        let requestURL = URL(string: self.connection.baseURL)?.appendingPathComponent(request.rawValue,
                                                                                      conformingTo: connection.requestType)
        
        guard let requestURL else {
            throw URLError(.badURL)
        }
        guard var components = URLComponents(url: requestURL,
                                             resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        
        components.queryItems = [URLQueryItem(name: "key",
                                              value: self.connection.apiKey),
                                 URLQueryItem(name: "q",
                                              value: query)]
        
        return components.url
    }

    // MARK: - Download calls (private) -
    
    fileprivate func downloadData(forURL url: URL, mimeType: String) async throws -> Data? {
        guard activeDownloads[url] == nil else {
            return nil
        }
        let result = try await withCheckedThrowingContinuation { continuation in
            self.downloadData(forURL: url, mimeType: mimeType) { result in
                switch result {
                case .success(let successData):
                    guard let successData else {
                        return
                    }
                    continuation.resume(returning: successData)
                case .failure(let failure):
                    continuation.resume(throwing: failure)
                }
            }
        }
        self.activeDownloads.removeValue(forKey: url)
        return result
    }
    
    fileprivate func downloadData(forURL url: URL, mimeType: String, completion: @escaping CompletionResult) {
        
        let task = self.urlSession.dataTask(with: URLRequest(url: url)) { data, response, error in
            
            let response = response as! HTTPURLResponse
            
            guard (200 ... 299) ~= response.statusCode,
                mimeType == response.mimeType else {
                completion(.failure(ConnectionError.incorrectResponse(response: "Connection failed with response: \(response.statusCode) mimeType: \(response.mimeType ?? "<N/A: No mime-type returned with request>")")))
                return
            }
            if let error {
                completion(.failure(error))
            }
            
            completion(.success(data))
        }
        activeDownloads[url] = task
        task.resume()
    }
    
}

extension ConnectionManager {
    
    public func icon(fromURL url: URL) async throws -> UIImage? {
        let cacheKey = url.absoluteString as NSString
        if let existingImage = self.iconCache.object(forKey: cacheKey) {
            return existingImage
        }
        guard let imageData = try await downloadData(forURL: url,
                                                 mimeType: "image/png") else {
            return nil
        }
        guard let image = UIImage(data: imageData) else { return nil }
        self.iconCache.setObject(image, forKey: cacheKey)
        return image
    }
    
    // MARK: - Public Functions -
    public func weather(for location: WeatherCoordinates) async throws -> WeatherData? {
        
        guard let url = try self.resolveURLForRequest(.currentWeather,
                                                      coordinates: location) else {
            return nil
        }
        let preferredType = connection.requestType.preferredMIMEType ?? "application/json"
        guard let data = try await downloadData(forURL: url,
                                                mimeType: preferredType) else {
             return nil
        }
        
        let weather = try self.jsonDecoder.decode(WeatherData.self,
                                                  from: data)
        return weather
    }
    
    public func search(for locationName: String) async throws -> [WeatherLocation]? {
        guard let url = try self.resolveURLForRequest(.search, query: locationName) else {
            return nil
        }
        let preferredType = connection.requestType.preferredMIMEType ?? "application/json"
        guard let data = try await downloadData(forURL: url,
                                                mimeType: preferredType) else {
            return nil
        }
//        if let asString = String(data: data, encoding: .utf8) {
//            print(asString)
//        }
        
        let locations = try self.jsonDecoder.decode([WeatherLocation].self, from: data)
        return locations
    }

}
