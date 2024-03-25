//
//  HelpView.swift
//  OBD2_Smart
//
//  Created by Dosi Dimitrov on 28.01.24.
//

import SwiftUI

struct HelpView: View {
    var body: some View {
        ZStack {
            Color.yellow
                .opacity(0.2)
                .ignoresSafeArea()
            Text("Help View")
        }
    }
}

struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView()
    }
}
