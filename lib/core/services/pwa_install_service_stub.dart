/// No-op sur Android/iOS natif — la notion de bannière d'installation
/// n'existe que pour la version web (PWA).
class PwaInstallService {
  static void showInstallBanner() {
    // Rien à faire hors web.
  }
}
