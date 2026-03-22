//
//  Family_HubApp.swift
//  Family Hub
//
//  Created by Amanda Chappell on 3/22/26.
//

import SwiftUI
import Supabase

let supabase: SupabaseClient = {
    guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
          let dict = NSDictionary(contentsOfFile: path),
          let urlString = dict["SUPABASE_URL"] as? String,
          let key = dict["SUPABASE_ANON_KEY"] as? String,
          let url = URL(string: urlString) else {
        fatalError("Supabase configuration missing in Secrets.plist")
    }
    return SupabaseClient(supabaseURL: url, supabaseKey: key)
}()

@main
struct Family_HubApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
