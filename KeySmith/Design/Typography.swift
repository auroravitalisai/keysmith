import SwiftUI

enum Typography {
    static let display = Font.largeTitle.bold()
    static let headline = Font.title2.bold()
    static let subheadline = Font.title3.weight(.semibold)
    static let body = Font.body
    static let caption = Font.caption
    static let mono = Font.system(.body, design: .monospaced)
    static let monoLarge = Font.system(.title3, design: .monospaced)
    static let monoSmall = Font.system(.caption, design: .monospaced)
}
