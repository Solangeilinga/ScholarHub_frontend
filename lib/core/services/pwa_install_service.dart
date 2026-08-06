// Sur mobile natif (Android/iOS via APK), cette classe ne fait rien —
// le concept de "bannière d'installation PWA" n'a de sens que sur web.
// `dart.library.html` n'existe que pour les builds web, donc le compilateur
// choisit automatiquement la bonne implémentation selon la plateforme cible.
export 'pwa_install_service_stub.dart'
    if (dart.library.html) 'pwa_install_service_web.dart';
