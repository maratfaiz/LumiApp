import SwiftUI
import UIKit

/// Управление текстовым полем снаружи: панель форматирования должна знать,
/// что именно выделено, а у SwiftUI `TextEditor` до iOS 18 нет доступа к
/// выделению. Поэтому под капотом `UITextView`.
@Observable
final class MarkdownEditorController {
    /// Заполняется представлением; слабая ссылка — контроллер живёт дольше.
    weak var textView: UITextView?

    /// Оборачивает выделенный фрагмент парой маркеров. Если ничего не
    /// выделено — вставляет маркеры и ставит курсор между ними, чтобы можно
    /// было сразу печатать.
    func wrap(_ marker: String) {
        guard let textView else { return }
        let range = textView.selectedRange
        let text = textView.text ?? ""
        guard let swiftRange = Range(range, in: text) else { return }

        let selected = String(text[swiftRange])
        let replacement = selected.isEmpty ? marker + marker : marker + selected + marker
        textView.replace(textRange(in: textView, from: range) , withText: replacement)

        let caret = selected.isEmpty
            ? range.location + marker.count
            : range.location + replacement.count
        textView.selectedRange = NSRange(location: caret, length: 0)
        textView.becomeFirstResponder()
    }

    /// Добавляет маркер списка в начало текущей строки.
    func toggleBullet() {
        guard let textView, let text = textView.text else { return }
        let nsText = text as NSString
        let lineRange = nsText.lineRange(for: NSRange(location: textView.selectedRange.location, length: 0))
        let line = nsText.substring(with: lineRange)

        let updated = line.hasPrefix("• ") ? String(line.dropFirst(2)) : "• " + line
        textView.replace(textRange(in: textView, from: lineRange), withText: updated)
        textView.becomeFirstResponder()
    }

    private func textRange(in textView: UITextView, from range: NSRange) -> UITextRange {
        let start = textView.position(from: textView.beginningOfDocument, offset: range.location) ?? textView.beginningOfDocument
        let end = textView.position(from: start, offset: range.length) ?? start
        return textView.textRange(from: start, to: end) ?? textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)!
    }
}

/// Текстовое поле дневника: обычный текст с markdown-разметкой
/// (`**жирный**`, `_курсив_`). Хранится как строка — читается и без
/// приложения, экспортируется как есть.
struct MarkdownTextEditor: UIViewRepresentable {
    @Binding var text: String
    var controller: MarkdownEditorController
    var minHeight: CGFloat = 160

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.delegate = context.coordinator
        view.backgroundColor = .clear
        view.textColor = .white
        view.tintColor = UIColor(LumiColor.purple1)
        view.font = .systemFont(ofSize: 15, weight: .medium)
        view.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        view.isScrollEnabled = false
        view.keyboardDismissMode = .interactive
        controller.textView = view
        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        controller.textView = uiView
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            self._text = text
        }

        func textViewDidChange(_ textView: UITextView) {
            text = textView.text
        }
    }
}

/// Панель форматирования над клавиатурой.
struct MarkdownToolbar: View {
    let controller: MarkdownEditorController

    var body: some View {
        HStack(spacing: 8) {
            button("Ж", weight: .black) { controller.wrap("**") }
            button("К", weight: .bold, italic: true) { controller.wrap("_") }
            button("•", weight: .bold) { controller.toggleBullet() }
            Spacer(minLength: 0)
            Text("**жирный** · _курсив_")
                .font(.lumi(10, weight: .semibold))
                .foregroundStyle(LumiColor.textDim)
        }
    }

    private func button(_ title: String, weight: Font.Weight, italic: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.lumi(15, weight: weight))
                .italic(italic)
                .foregroundStyle(LumiColor.textBright)
                .frame(width: 38, height: 32)
        }
        .buttonStyle(.plain)
        .background(RoundedRectangle(cornerRadius: 10).fill(LumiColor.cardFillLight))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(LumiColor.cardBorder, lineWidth: 1))
    }
}

extension String {
    /// Разметка для показа: `**жирный**` и `_курсив_` превращаются в стили.
    /// Если разметка битая — показываем как есть, а не роняем экран.
    var lumiMarkdown: AttributedString {
        (try? AttributedString(
            markdown: self,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(self)
    }
}
