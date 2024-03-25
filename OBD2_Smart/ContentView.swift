//
//  ContentView.swift
//  OBD2_Smart
//
//  Created by Dosi Dimitrov on 28.01.24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MainView()
                .tabItem {
                    Label("Connect", systemImage: "externaldrive.connected.to.line.below")
                }

            HelpView()
                .tabItem {
                    Label("Info", systemImage: "info.square")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
