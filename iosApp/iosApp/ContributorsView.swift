//
//  ContributorsView.swift
//  SampleiOS
//
//  Created by Michał Laskowski on 24/03/2020.
//  Copyright © 2020 Michał Laskowski. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import shared

struct Contributor: Codable {
    let login: String
    let contributions: Int
}

protocol ContributorsProviding {
    func contributors(owner: String, repo: String) -> AnyPublisher<[Contributor], Error>
}

class ContributorsProvider: ContributorsProviding {

    private let baseUrl = URL(string: UserDefaults.standard.string(forKey: "contributors_url") ?? "http://api.github.com")!

    func contributors(owner: String, repo: String) -> AnyPublisher<[Contributor], Error> {
        let url = baseUrl.appendingPathComponent("/repos/\(owner)/\(repo)/contributors")
        return URLSession.shared.dataTaskPublisher(for: url).tryMap { (data, _) -> [Contributor] in
            try JSONDecoder().decode([Contributor].self, from: data)
        }.eraseToAnyPublisher()
    }
    // not used, but kept if we need to remove Combine (for iOS < 13)
    func contributors(owner: String, repo: String,
                      callback: @escaping ([Contributor]) -> Void) {
        let url = baseUrl.appendingPathComponent("/repos/\(owner)/\(repo)/contributors")

        let request = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                assertionFailure(error.localizedDescription)
                callback([])
                return
            }

            guard let data = data else {
                assertionFailure("Missing data but no error")
                callback([])
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode([Contributor].self, from: data)
                callback(decodedResponse)
            } catch {
                assertionFailure("Failed to decode response: \(error.localizedDescription)")
                callback([])
            }
        }

        request.resume()
    }
}


