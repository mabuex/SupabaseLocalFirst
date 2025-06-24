//
//  Supabase.swift
//  SupabaseLocalFirst
//
//  Created by Marcus Buexenstein on 6/23/25.
//

import Foundation
import Supabase

final class Supabase {
    let client: SupabaseClient
    
    static let shared = Supabase()
   
    private init() {
        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey,
            options: SupabaseClientOptions(
                db: .init(
                    encoder: encoder,
                    decoder: decoder
                )
            )
        )
        
        print("Supabase initialized.")
    }
    
    let supabaseURL: URL = {
        if let urlString = Bundle.main.infoDictionary?["Supabase url"] as? String {
            if let url = URL(string: urlString) {
                return url
            } else {
                fatalError("The Supabase url is in the wrong format.")
            }
        }
        
        fatalError("Please set the correct Supabase url in Supabase.xcconfig file.")
    }()
    
    let supabaseKey: String = {
        if let anonString = Bundle.main.infoDictionary?["Supabase anon key"] as? String {
            return anonString
        }
        
        fatalError("Please set the correct Supabase anon key in Supabase.xcconfig file.")
    }()
    
    let encoder: JSONEncoder = {
        let encoder = PostgrestClient.Configuration.jsonEncoder
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    let decoder: JSONDecoder = {
        let decoder = PostgrestClient.Configuration.jsonDecoder
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
}
