import SwiftUI

/// Text styles built on Dynamic Type text styles (not fixed point sizes) —
/// Dynamic Type + VoiceOver support is a stated non-functional requirement
/// (Lumi_PRD.pdf §8).
extension Font {
    static let lumiTitle = Font.title.bold()
    static let lumiHeadline = Font.headline
    static let lumiBody = Font.body
    static let lumiCaption = Font.caption
}
