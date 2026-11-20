{{flutter_js}}
{{flutter_build_config}}

// Le web de test change souvent : retirer les anciens service workers Flutter
// évite qu'un navigateur continue d'afficher une version périmée du catalogue.
(async () => {
  if ('serviceWorker' in navigator) {
    const registrations = await navigator.serviceWorker.getRegistrations();
    await Promise.all(registrations.map((registration) => registration.unregister()));
  }
  _flutter.loader.load();
})();
