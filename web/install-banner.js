(function () {
  var isIOS = /iphone|ipad|ipod/i.test(navigator.userAgent);
  var isStandalone = window.navigator.standalone === true ||
    window.matchMedia('(display-mode: standalone)').matches;
  var deferredPrompt = null;

  window.addEventListener('beforeinstallprompt', function (event) {
    event.preventDefault();
    deferredPrompt = event;
  });

  window.addEventListener('appinstalled', function () {
    localStorage.setItem('sh_android_banner_dismissed', '1');
    var element = document.getElementById('android-install-banner');
    if (element) element.classList.remove('visible');
  });

  var iosClose = document.getElementById('ios-install-close');
  if (iosClose) {
    iosClose.addEventListener('click', function () {
      document.getElementById('ios-install-banner')?.classList.remove('visible');
      localStorage.setItem('sh_ios_banner_dismissed', '1');
    });
  }

  var androidClose = document.getElementById('android-install-close');
  if (androidClose) {
    androidClose.addEventListener('click', function () {
      document.getElementById('android-install-banner')?.classList.remove('visible');
      localStorage.setItem('sh_android_banner_dismissed', '1');
    });
  }

  var installButton = document.getElementById('android-install-btn');
  if (installButton) {
    installButton.addEventListener('click', function () {
      document.getElementById('android-install-banner')?.classList.remove('visible');
      if (!deferredPrompt) return;
      deferredPrompt.prompt();
      deferredPrompt.userChoice.then(function () {
        deferredPrompt = null;
      });
    });
  }

  window.showScholarHubInstallBanner = function () {
    if (isStandalone) return;
    if (isIOS) {
      if (localStorage.getItem('sh_ios_banner_dismissed') === '1') return;
      document.getElementById('ios-install-banner')?.classList.add('visible');
    } else if (deferredPrompt) {
      if (localStorage.getItem('sh_android_banner_dismissed') === '1') return;
      document.getElementById('android-install-banner')?.classList.add('visible');
    }
  };
})();
