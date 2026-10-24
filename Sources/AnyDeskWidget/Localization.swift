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
    static var updateReady: String { value("Güncelleme hazır", "Update ready", "Mise à jour prête", "Aggiornamento pronto") }
    static var updateReadyVersion: String { value("Sürüm %@ hazır", "Version %@ is ready", "La version %@ est prête", "La versione %@ è pronta") }
    static var updateReadyDetail: String { value("Güncelleme doğrulandı ve arka planda indirildi.", "The update was verified and downloaded in the background.", "La mise à jour a été vérifiée et téléchargée en arrière-plan.", "L’aggiornamento è stato verificato e scaricato in background.") }
    static var updateAndRestart: String { value("Güncelle ve yeniden başlat", "Update and Restart", "Mettre à jour et redémarrer", "Aggiorna e riavvia") }
    static var updateInstalling: String { value("Güncelleme kuruluyor…", "Installing update…", "Installation de la mise à jour…", "Installazione dell’aggiornamento…") }
    static var updateDownloading: String { value("Sürüm %@ arka planda indiriliyor", "Downloading version %@ in the background", "Téléchargement de la version %@ en arrière-plan", "Download della versione %@ in background") }
    static var updateFailed: String { value("Güncelleme başarısız: %@", "Update failed: %@", "Échec de la mise à jour : %@", "Aggiornamento non riuscito: %@") }
    static var updateInvalidResponse: String { value("GitHub geçerli bir yanıt vermedi.", "GitHub returned an invalid response.", "GitHub a renvoyé une réponse non valide.", "GitHub ha restituito una risposta non valida.") }
    static var updateMissingAsset: String { value("Release içinde uygun uygulama paketi yok.", "The release does not contain a compatible app package.", "La version ne contient aucun paquet compatible.", "La release non contiene un pacchetto compatibile.") }
    static var updateMissingDigest: String { value("Release SHA-256 doğrulama özeti içermiyor.", "The release is missing its SHA-256 digest.", "La version ne contient pas de somme SHA-256.", "Nella release manca il digest SHA-256.") }
    static var updateInvalidDigest: String { value("İndirilen dosyanın SHA-256 özeti eşleşmiyor.", "The downloaded file failed SHA-256 verification.", "La vérification SHA-256 du fichier a échoué.", "La verifica SHA-256 del file non è riuscita.") }
    static var updateInvalidArchive: String { value("Güncelleme arşivi açılamadı.", "The update archive could not be extracted.", "L’archive de mise à jour n’a pas pu être extraite.", "Impossibile estrarre l’archivio di aggiornamento.") }
    static var updateInvalidApplication: String { value("Güncelleme paketi bu uygulamayla eşleşmiyor.", "The update package does not match this application.", "Le paquet ne correspond pas à cette application.", "Il pacchetto non corrisponde a questa applicazione.") }
    static var updateInvalidSignature: String { value("Güncellemenin kod imzası doğrulanamadı.", "The update's code signature could not be verified.", "La signature du code n’a pas pu être vérifiée.", "Impossibile verificare la firma del codice.") }
    static var updateCannotInstall: String { value("Uygulama değiştirilemedi. Applications klasöründeki yazma iznini kontrol edin.", "The app could not be replaced. Check write access in the Applications folder.", "L’app n’a pas pu être remplacée. Vérifiez l’accès en écriture au dossier Applications.", "Impossibile sostituire l’app. Controlla l’accesso in scrittura alla cartella Applicazioni.") }
    static var launchAtLogin: String { value("Oturum açıldığında başlat", "Launch at Login", "Ouvrir à la connexion", "Avvia al login") }
    static var launchAtLoginNeedsApproval: String { value("Sistem Ayarları > Genel > Giriş Öğeleri bölümünden izin verin.", "Allow it in System Settings > General > Login Items.", "Autorisez-le dans Réglages Système > Général > Ouverture.", "Consentilo in Impostazioni di Sistema > Generali > Elementi login.") }
    static var launchAtLoginFailed: String { value("Otomatik başlatma ayarlanamadı: %@", "Launch at login could not be configured: %@", "Le lancement à la connexion n’a pas pu être configuré : %@", "Impossibile configurare l’avvio al login: %@") }
    static var updates: String { value("Güncellemeler", "Updates", "Mises à jour", "Aggiornamenti") }
    static var checkForUpdates: String { value("Güncellemeleri Denetle", "Check for Updates", "Rechercher", "Verifica aggiornamenti") }
    static var updateUpToDate: String { value("AnyDesk Widget güncel.", "AnyDesk Widget is up to date.", "AnyDesk Widget est à jour.", "AnyDesk Widget è aggiornato.") }
    static var dropImageHint: String { value("AnyDesk kodu içeren görseli buraya bırakın", "Drop an image containing an AnyDesk ID", "Déposez une image contenant un ID AnyDesk", "Trascina qui un’immagine con un ID AnyDesk") }
    static var dropImageNow: String { value("Görseli bırakın", "Drop the image", "Déposez l’image", "Rilascia l’immagine") }
    static var menuDropHint: String { value("Görseli sürükleyince otomatik açılır", "Opens automatically while dragging an image", "S’ouvre automatiquement lors du glissement d’une image", "Si apre automaticamente mentre trascini un’immagine") }
    static var imageReading: String { value("Görseldeki kod okunuyor…", "Reading the ID from the image…", "Lecture de l’ID dans l’image…", "Lettura dell’ID dall’immagine…") }
    static var imageIDNotFound: String { value("Görselde 9–10 haneli bir AnyDesk kodu bulunamadı.", "No 9–10 digit AnyDesk ID was found in the image.", "Aucun ID AnyDesk de 9 à 10 chiffres n’a été trouvé dans l’image.", "Nell’immagine non è stato trovato un ID AnyDesk di 9–10 cifre.") }
    static var imageUnreadable: String { value("Görsel okunamadı.", "The image could not be read.", "L’image n’a pas pu être lue.", "Impossibile leggere l’immagine.") }

    private static func value(_ tr: String, _ en: String, _ fr: String, _ it: String) -> String {
        switch language { case "tr": tr; case "fr": fr; case "it": it; default: en }
    }
}
