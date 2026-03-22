//
//  ContentView.swift
//  Family Hub
//
//  Created by Amanda Chappell on 3/22/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Supabase Integration Ready!")
                .font(.headline)
            Text("Add the supabase-swift package to resolve build errors.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
