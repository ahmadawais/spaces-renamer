//
//  DesktopSnippetView.swift
//  SpacesRenamer
//
//  A single desktop/space card shown in the rename UI.
//

import SwiftUI

struct DesktopSnippetView: View {
    let index: Int
    let isCurrent: Bool
    @Binding var name: String

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Image(isCurrent ? "MonitorSelected" : "Monitor")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 70)

                Text("\(index)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(isCurrent ? .blue : .secondary)
            }

            TextField("Desktop \(index)", text: $name)
                .textFieldStyle(.roundedBorder)
                .frame(width: 120)
                .multilineTextAlignment(.center)
        }
        .frame(width: 130)
    }
}
