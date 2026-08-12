import Foundation

/// Куда ведёт тап по виджету. Раньше виджеты открывали приложение «в
/// никуда» — всегда на главной, хотя виджет урока обещал конкретный урок.
///
/// Схема `lumi://` объявлена в project.yml (CFBundleURLTypes); ссылка
/// собирается в расширении виджета и разбирается в `RootView`.
enum DeepLink: String, CaseIterable {
    case home
    case lesson
    case streak
    case profile
    case journal

    private static let scheme = "lumi"

    var url: URL {
        URL(string: "\(Self.scheme)://\(rawValue)") ?? URL(string: "\(Self.scheme)://home")!
    }

    init?(url: URL) {
        guard url.scheme == Self.scheme else { return nil }
        // Хост для lumi://lesson, путь — на случай lumi:///lesson.
        let name = url.host ?? url.pathComponents.last ?? ""
        self.init(rawValue: name)
    }
}
