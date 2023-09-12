importScripts("https://www.gstatic.com/firebasejs/7.20.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/7.20.0/firebase-messaging.js");

//Using singleton breaks instantiating messaging()
// App firebase = FirebaseWeb.instance.app;


firebase.initializeApp({
    apiKey: "AIzaSyDLzaPBswS6nmwG0QtW7CHwLeyl8TYHsMA",
  authDomain: "saloncantontest.firebaseapp.com",
  databaseURL: "https://salon-canton-default-rtdb.firebaseio.com",
  projectId: "saloncantontest",
  storageBucket: "saloncantontest.appspot.com",
  messagingSenderId: "847314641119",
  appId: "1:847314641119:web:596d80bf7b1ac42474096a",
  measurementId: "G-TR5HXHXCFB"
});

const messaging = firebase.messaging();
messaging.setBackgroundMessageHandler(function (payload) {
    const promiseChain = clients
        .matchAll({
            type: "window",
            includeUncontrolled: true
        })
        .then(windowClients => {
            for (let i = 0; i < windowClients.length; i++) {
                const windowClient = windowClients[i];
                windowClient.postMessage(payload);
            }
        })
        .then(() => {
            return registration.showNotification("New Message");
        });
    return promiseChain;
});
self.addEventListener('notificationclick', function (event) {
    console.log('notification received: ', event)
});