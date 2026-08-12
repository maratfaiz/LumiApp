# Дизайн Луми в коде

## Откуда взят дизайн

Визуальный слой приложения перенесён из репозитория
[`maratfaiz/lumidesign`](https://github.com/maratfaiz/lumidesign)
(ветка `claude/swift-design-lumiapp-381xe3`, пакет `Lumi.swiftpm`) — это
Swift-прототип всех экранов и виджетов, собранный по HTML-прототипу из
[`prototype/`](prototype/README.md).

Перенесены **токены, компоненты и вёрстка экранов**. Вся логика рабочего
приложения (SwiftData, серии и заморозки, кризисный детектор, начисление
XP/люменов, уведомления) осталась прежней — менялся только внешний слой.

## Где что лежит

| Что | Где |
|---|---|
| Палитра (`LumiColor`) | `LumiApp/Core/DesignSystem/LumiColor.swift` |
| Градиенты, фон, каркас экрана (`LumiScreen`) | `LumiApp/Core/DesignSystem/LumiTheme.swift` |
| Шрифты (`.lumi(_:weight:)`) | `LumiApp/Core/DesignSystem/LumiTypography.swift` |
| Кнопки, карточки, чипы, прогресс-бары | `LumiApp/Core/DesignSystem/LumiControls.swift` |
| Иконки Phosphor (`LumiIcon`, `LumiGlyph`) | `LumiApp/Core/DesignSystem/LumiIcon.swift` |
| Звёздное поле | `LumiApp/Core/DesignSystem/StarField.swift` |
| Маскот на подсветке (`LumiMascot`) | `LumiApp/Features/Mascot/MascotView.swift` |
| Нижняя навигация | `LumiApp/Features/Navigation/MainTabView.swift` |
| Виджеты | `LumiWidget/` |

Картинки: маскот `mascot-*`, образы `skin-*` и иконки `icon-*` лежат в
`LumiApp/Resources/Assets.xcassets`. Иконки помечены как `template`, то есть
красятся из кода через `.foregroundStyle(...)`.

## Правила, которых стоит держаться

- **Тёмная тема — единственная.** Светлого варианта токенов нет, поэтому
  `RootView` жёстко ставит `.preferredColorScheme(.dark)`. Не добавляйте
  системные `List`/`Form` без `.scrollContentBackground(.hidden)` — они
  принесут свой светлый фон.
- **Никаких «сырых» цветов в экранах.** Всё берётся из `LumiColor`;
  если нужен новый оттенок — сначала добавьте токен.
- **Фиксированные размеры шрифта — только для мелкой обвязки** (чипы,
  таб-бар, подписи). Длинные тексты (уроки, упражнения, дисклеймер)
  используют Dynamic Type (`.lumiBody`, `.lumiHeadline`) — это требование
  доступности из `Lumi_PRD.pdf` §8.
- **Тексты из макета не переносим вслепую.** В макете виджета уведомлений
  осталась запрещённая формулировка «Серия дней под угрозой — вернитесь
  сегодня»; в приложении используется только согласованная, не вызывающая
  тревогу копия (см. `NotificationsView.swift`).

## Виджеты (F24)

Три виджета из макета: «Серия дней» (medium), «Сегодняшний урок» (medium),
«Профиль коротко» (small). Данные они читают напрямую из общего
SwiftData-хранилища через App Group — отдельного снимка в `UserDefaults`,
как в прототипе, нет. Приложение после изменения прогресса вызывает
`WidgetSync.refresh()`.

Виджет «Серия дней» остаётся настраиваемым через App Intents: долгий тап →
выбрать образ Луми.

## Лицензии

- Иконки — [Phosphor Icons](https://phosphoricons.com), MIT,
  см. [`../legal/PHOSPHOR-LICENSE.txt`](../legal/PHOSPHOR-LICENSE.txt).
- Звуки для медитации — см. [`../legal/Audio_Attributions.md`](../legal/Audio_Attributions.md).
