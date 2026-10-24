import Foundation

enum Copy {
    private static let language: String = {
        let preferred = Locale.preferredLanguages.first?.lowercased() ?? "en"
        if preferred.hasPrefix("tr") { return "tr" }
        if preferred.hasPrefix("fr") { return "fr" }
        if preferred.hasPrefix("it") { return "it" }
        return "en"
    }()

    static var menuTitle: String { value("AnyDesk Bağlan", "Connect with AnyDesk", "Connexion AnyDesk", "Connetti con AnyDesk") }
    static var heading: String { value("AnyDesk'e Bağlan", "Connect with AnyDesk", "Se connecter avec AnyDesk", "Connetti con AnyDesk") }
    static var placeholder: String { value("AnyDesk ID veya alias", "AnyDesk ID or alias", "ID AnyDesk ou alias", "ID AnyDesk o alias") }
    static var quit: String { value("Çıkış", "Quit", "Quitter", "Esci") }
    static var connect: String { value("Bağlan", "Connect", "Connexion", "Connetti") }
    static var settings: String { value("Ayarlar", "Settings", "Réglages", "Impostazioni") }
    static var back: String { value("Geri", "Back", "Retour", "Indietro") }
    static var done: String { value("Bitti", "Done", "Terminé", "Fine") }
    static var globalShortcut: String { value("Genel klavye kısayolu", "Global keyboard shortcut", "Raccourci clavier global", "Scorciatoia da tastiera globale") }
    static var shortcutHint: String { value("Düğmeye tıklayın, ardından istediğiniz tuş birleşimine basın.", "Click the button, then press your preferred key combination.", "Cliquez sur le bouton, puis appuyez sur la combinaison souhaitée.", "Fai clic sul pulsante, quindi premi la combinazione desiderata.") }
    static var recordShortcut: String { value("Kısayola basın…", "Press shortcut…", "Appuyez sur le raccourci…", "Premi la scorciatoia…") }
    static var resetShortcut: String { value("Varsayılana dön", "Reset to Default", "Réinitialiser", "Ripristina") }
    static var shortcutUnavailable: String { value("Bu kısayol başka bir uygulama tarafından kullanılıyor.", "This shortcut is already used by another app.", "Ce raccourci est déjà utilisé par une autre app.", "Questa scorciatoia è già usata da un'altra app.") }
    static var clipboardDetection: String { value("Kopyalanan AnyDesk ID'lerini algıla", "Detect copied AnyDesk IDs", "Détecter les ID AnyDesk copiés", "Rileva gli ID AnyDesk copiati") }
    static var clipboardHint: String { value("9–10 haneli bir ID kopyalandığında widget otomatik açılır.", "The widget opens automatically when you copy a 9–10 digit ID.", "Le widget s’ouvre automatiquement lors de la copie d’un ID de 9 à 10 chiffres.", "Il widget si apre automaticamente quando copi un ID di 9–10 cifre.") }
    static var emptyAddress: String { value("Bir AnyDesk ID veya alias girin.", "Enter an AnyDesk ID or alias.", "Saisissez un ID AnyDesk ou un alias.", "Inserisci un ID AnyDesk o un alias.") }
    static var invalidAddress: String { value("Geçerli bir AnyDesk ID veya alias girin.", "Enter a valid AnyDesk ID or alias.", "Saisissez un ID AnyDesk ou un alias valide.", "Inserisci un ID AnyDesk o un alias valido.") }
    static var anyDeskMissing: String { value("AnyDesk bulunamadı. Önce AnyDesk'i yükleyin.", "AnyDesk was not found. Install AnyDesk first.", "AnyDesk est introuvable. Installez d'abord AnyDesk.", "AnyDesk non è stato trovato. Installa prima AnyDesk.") }

    private static func value(_ tr: String, _ en: String, _ fr: String, _ it: String) -> String {
        switch language { case "tr": tr; case "fr": fr; case "it": it; default: en }
    }
}
