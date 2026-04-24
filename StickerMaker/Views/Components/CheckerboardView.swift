//
//  CheckerboardView.swift
//  StickerMaker
//
//  Renders a checkerboard pattern to indicate transparency.
//

import SwiftUI

struct CheckerboardView: View {
    let tileSize: CGFloat = 18

    var body: some View {
        Canvas { context, size in
            let rows = Int(ceil(size.height / tileSize))
            let cols = Int(ceil(size.width / tileSize))

            for row in 0..<rows {
                for col in 0..<cols {
                    let isLight = (row + col) % 2 == 0
                    let rect = CGRect(
                        x: CGFloat(col) * tileSize,
                        y: CGFloat(row) * tileSize,
                        width: tileSize,
                        height: tileSize
                    )
                    context.fill(
                        Path(rect),
                        with: .color(isLight ? Color(red: 0.105, green: 0.105, blue: 0.11) : Color(red: 0.075, green: 0.075, blue: 0.08))
                    )
                }
            }
        }
        .background(Color(red: 0.075, green: 0.075, blue: 0.08))
    }
}
