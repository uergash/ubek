import SwiftUI
import UIKit
import CoreText

// Fraunces is a variable serif with four axes: opsz (9–144), wght (100–900),
// SOFT (0–100), and WONK (0–1). The brand uses high SOFT and WONK on the
// wordmark for a hand-tied feel; subtler SOFT on body headings. SwiftUI's
// `Font.custom` doesn't expose variation axes, so we build a UIFont with
// the axes set via `kCTFontVariationAttribute` and wrap it as a Font.
extension Font {
    /// Brand display serif (Fraunces variable).
    /// Defaults match the wordmark spec: opsz 144, weight 600, SOFT 100, WONK 1.
    static func fraunces(
        size: CGFloat,
        weight: CGFloat = 600,
        opsz: CGFloat = 144,
        soft: CGFloat = 100,
        wonk: CGFloat = 1
    ) -> Font {
        Font(UIFont.fraunces(size: size, weight: weight, opsz: opsz, soft: soft, wonk: wonk))
    }
}

extension UIFont {
    static func fraunces(
        size: CGFloat,
        weight: CGFloat,
        opsz: CGFloat,
        soft: CGFloat,
        wonk: CGFloat
    ) -> UIFont {
        let variations: [Int: CGFloat] = [
            fourCharCode("opsz"): opsz,
            fourCharCode("wght"): weight,
            fourCharCode("SOFT"): soft,
            fourCharCode("WONK"): wonk,
        ]
        let attributes: [UIFontDescriptor.AttributeName: Any] = [
            .name: "Fraunces",
            UIFontDescriptor.AttributeName(rawValue: kCTFontVariationAttribute as String): variations,
        ]
        let descriptor = UIFontDescriptor(fontAttributes: attributes)
        return UIFont(descriptor: descriptor, size: size)
    }

    private static func fourCharCode(_ tag: String) -> Int {
        var code: Int = 0
        for byte in tag.utf8 { code = (code << 8) | Int(byte) }
        return code
    }
}
