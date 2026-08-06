import 'dart:js' as js;

/// Déclenche la bannière d'installation PWA (iOS custom ou prompt natif
/// Android) depuis Dart. La logique d'affichage réelle vit en JS dans
/// web/index.html — voir `window.showScholarHubInstallBanner`.
class PwaInstallService {
  static void showInstallBanner() {
    try {
      if (js.context.hasProperty('showScholarHubInstallBanner')) {
        js.context.callMethod('showScholarHubInstallBanner');
      }
    } catch (_) {
      // Ne jamais faire planter l'app pour une bannière d'installation.
    }
  }
}
