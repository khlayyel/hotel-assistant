// Import Firebase scripts
importScripts('https://www.gstatic.com/firebasejs/10.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.0.0/firebase-messaging-compat.js');

// Initialize Firebase with your project's configuration
firebase.initializeApp({
  apiKey: "AIzaSyA75pJqdvaqsFk5Qma_IhepyzDKFi1iIeU", // Your Firebase API key
  authDomain: "chatbot-f5969.firebaseapp.com", // Your Firebase Project ID
  projectId: "chatbot-f5969",
  storageBucket: "chatbot-f5969.firebasestorage.app",
  messagingSenderId: "1026738841199",
  appId: "1:1026738841199:web:d6572c4bab74d220418f9a"
});

// Get an instance of Firebase Messaging
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage(function(payload) {
  console.log('Received background message ', payload);

  const notificationTitle = 'Background Message Title';
  const notificationOptions = {
    body: payload.body,
    icon: '/firebase-logo.png' // You can change this to your icon
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
