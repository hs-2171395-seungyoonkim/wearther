import SwiftUI

struct MarkdownText: View {
    let text: String
    var fontSize: CGFloat = 14
    var textColor: Color = .gray

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(parsedBlocks().enumerated()), id: \.offset) { _, block in
                renderBlock(block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private enum Block {
        case h1(String), h2(String), h3(String)
        case bullet(String)
        case paragraph(String)
    }

    private func parsedBlocks() -> [Block] {
        var result: [Block] = []
        var pending: [String] = []

        func flush() {
            let joined = pending.joined(separator: " ").trimmingCharacters(in: .whitespaces)
            if !joined.isEmpty { result.append(.paragraph(joined)) }
            pending = []
        }

        for line in text.components(separatedBy: "\n") {
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.isEmpty { flush() }
            else if t.hasPrefix("### ") { flush(); result.append(.h3(String(t.dropFirst(4)))) }
            else if t.hasPrefix("## ")  { flush(); result.append(.h2(String(t.dropFirst(3)))) }
            else if t.hasPrefix("# ")   { flush(); result.append(.h1(String(t.dropFirst(2)))) }
            else if t.hasPrefix("- ") || t.hasPrefix("* ") {
                flush(); result.append(.bullet(String(t.dropFirst(2))))
            }
            else { pending.append(t) }
        }
        flush()
        return result
    }

    @ViewBuilder
    private func renderBlock(_ block: Block) -> some View {
        switch block {
        case .h1(let s):
            formatted(s)
                .font(.system(size: fontSize + 4, weight: .bold))
                .foregroundColor(AppColor.darkText)
        case .h2(let s):
            formatted(s)
                .font(.system(size: fontSize + 2, weight: .bold))
                .foregroundColor(AppColor.darkText)
        case .h3(let s):
            formatted(s)
                .font(.system(size: fontSize + 1, weight: .semibold))
                .foregroundColor(AppColor.darkText)
        case .bullet(let s):
            HStack(alignment: .top, spacing: 6) {
                Text("•")
                    .font(.system(size: fontSize, weight: .medium))
                    .foregroundColor(AppColor.primary)
                formatted(s)
                    .font(.system(size: fontSize, weight: .medium))
                    .foregroundColor(textColor)
            }
        case .paragraph(let s):
            formatted(s)
                .font(.system(size: fontSize, weight: .medium))
                .foregroundColor(textColor)
                .lineSpacing(4)
        }
    }

    private func formatted(_ string: String) -> Text {
        if let attr = try? AttributedString(
            markdown: string,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return Text(attr)
        }
        return Text(string)
    }
}
