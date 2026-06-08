import 'package:aerofit/core/firebase/firebase_bootstrap.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseAuthProvider = Provider<FirebaseAuth?>((ref) {
  if (!FirebaseBootstrap.isReady) return null;
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore?>((ref) {
  if (!FirebaseBootstrap.isReady) return null;
  return FirebaseFirestore.instance;
});

final firebaseStorageProvider = Provider<FirebaseStorage?>((ref) {
  if (!FirebaseBootstrap.isReady) return null;
  return FirebaseStorage.instance;
});
