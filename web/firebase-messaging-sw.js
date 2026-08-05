// Service worker Firebase — gère les notifications push reçues quand l'onglet
// ScholarHub est fermé ou en arrière-plan. Requis pour le web push (aucun
// équivalent n'existe côté mobile, où c'est géré nativement par Android/iOS).
//
// ⚠️ À COMPLÉTER : remplace firebaseConfig ci-dessous par la config de ton
// app web Firebase (Firebase Console > Project Settings > tes apps > Web app
// > SDK setup and configuration > Config). Ce sont les MÊMES valeurs que
// celles utilisées dans lib/firebase_options.dart (généré par `flutterfire
// configure`) pour la plateforme web — copie-les depuis là.

importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDWjm9mFHSWRTqbxPcDJo88y0eDAij_YlQ',
  authDomain: 'scholarhub-85477.firebaseapp.com',
  projectId: 'scholarhub-85477',
  storageBucket: 'scholarhub-85477.firebasestorage.app',
  messagingSenderId: '331098715879',
  appId: '1:331098715879:web:81aca332cf21a917cb9442',
});


const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title || 'ScholarHub';
  const options = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
  };
  self.registration.showNotification(title, options);
});
