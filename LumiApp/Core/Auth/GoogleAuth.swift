import Foundation
import GoogleSignIn
#if canImport(UIKit)
import UIKit
#endif

/// Вход через Google.
///
/// Client ID не хранится в репозитории: он подставляется в Info.plist из
/// сборочной настройки `GOOGLE_CLIENT_ID` (см. `project.yml` и
/// `docs/setup/google-signin.md`). Пока настройка пустая, `isConfigured`
/// равно `false` — экран знакомства честно говорит об этом и не делает
/// вид, что вход работает.
///
/// Настоящей учётной записи у приложения по-прежнему нет: сервера нет,
/// профиль Google используется только чтобы подставить имя. Токены никуда
/// не отправляются и нигде не сохраняются.
enum GoogleAuth {
    enum Failure: LocalizedError, Equatable {
        case notConfigured
        case noPresenter
        case cancelled
        case failed(String)

        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return "Вход через Google ещё не настроен: в сборке нет Client ID."
            case .noPresenter:
                return "Не удалось открыть окно входа."
            case .cancelled:
                return "Вход отменён."
            case .failed(let message):
                return message
            }
        }
    }

    /// Профиль ровно в том объёме, который нужен приложению.
    struct Account: Equatable {
        let givenName: String?
        let email: String?
    }

    static var clientID: String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        // Пустая строка — это неподставленная сборочная настройка, а не
        // Client ID: в таком виде SDK всё равно работать не станет.
        return trimmed.hasSuffix(".apps.googleusercontent.com") ? trimmed : nil
    }

    static var isConfigured: Bool { clientID != nil }

    /// Вызывается на старте приложения. Без Client ID молча ничего не
    /// делает — падать на запуске из-за ненастроенного входа нельзя.
    static func configure() {
        guard let clientID else { return }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
    }

    /// Возврат из браузера/приложения Google по OAuth-ссылке.
    /// `false` означает «ссылка не наша» — её должен обработать кто-то ещё.
    @discardableResult
    static func handle(_ url: URL) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }

    @MainActor
    static func signIn() async throws -> Account {
        guard isConfigured else { throw Failure.notConfigured }
        configure()
        guard let presenter = topViewController() else { throw Failure.noPresenter }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
            let profile = result.user.profile
            return Account(givenName: profile?.givenName, email: profile?.email)
        } catch let error as NSError {
            if error.domain == kGIDSignInErrorDomain, error.code == GIDSignInError.canceled.rawValue {
                throw Failure.cancelled
            }
            throw Failure.failed(error.localizedDescription)
        }
    }

    /// Выход. Нужен, чтобы «пройти знакомство заново» действительно
    /// начиналось с чистого экрана входа, а не подхватывало прошлую сессию.
    static func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }

    @MainActor
    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
            ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        guard var controller = scene?.keyWindow?.rootViewController else { return nil }
        while let presented = controller.presentedViewController {
            controller = presented
        }
        return controller
    }
}
