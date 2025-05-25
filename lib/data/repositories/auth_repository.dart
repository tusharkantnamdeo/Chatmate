import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:messaging_app/data/services/base_repository.dart';
import '../models/user_model.dart';

class AuthRepository extends BaseRepository{

  Stream<User?> get authStateChanges =>auth.authStateChanges();

  Future<UserModel> signUp({
    required String fullName,
    required String username,
    required String email,
    required String phoneNumber,
    required String password,

  }) async{
    try{
      final formattedPhoneNumber=phoneNumber.replaceAll(RegExp(r'\s+'),"".trim());

      final  emailExists = await checkEmailExists(email, password);
      if(emailExists){
        throw "An account with the same email already exists";
      }

      final phoneNumberExists = await checkPhoneExists(formattedPhoneNumber);
      if(phoneNumberExists){
        throw "An account with the same phone already exists";
      }

      final userCredential = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password
      );
      if(userCredential.user == null){
        throw "Failed to create user";
      }
      //create a user model and save the user in db firestore
      final user = UserModel(
          uid: userCredential.user!.uid,
          username: username,
          fullName: fullName,
          email: email,
          phoneNumber: formattedPhoneNumber,
      );
      await saveUserData(user);
      return user;
    } catch(e){
      log(e.toString()); // for this we need library import 'dart:developer'; as it is from developer
      rethrow;
    }
  }

  Future<bool> checkEmailExists(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password, // We don't know the user's real password
      );
      return true; // If sign-in succeeds, email exists
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return false; // Email does NOT exist
      } else if (e.code == 'wrong-password') {
        return true; // Email exists but wrong password
      } else {
        print("Error checking email: $e");
        return false;
      }
    }
  }


  // Future<bool> checkEmailExists(String email) async {  // this is commented thing for above code or first  it is written but some property is depricated here  so replaced all these
  //   try{
  //     final methods = await auth.fetchSignInMethodsForEmail(email);
  //     return methods.isNotEmpty;
  //   }catch(e){
  //     print(("Error checking email: $e"));
  //     return false;
  //   }
  // }

  Future<bool> checkPhoneExists(String phoneNumber) async {
    try{
      final formattedPhoneNumber =
           phoneNumber.replaceAll(RegExp(r'\s+'), "".trim());
      final querySnapShot = await firestore
          .collection("users")
          .where("phoneNumber", isEqualTo: formattedPhoneNumber)
          .get();
      return querySnapShot.docs.isNotEmpty;
    }catch(e){
      print(("Error checking phoneNumber: $e"));
      return false;
    }
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  })async{
    try{
      final userCredential = await auth.signInWithEmailAndPassword(email: email, password: password); //We can SignIn using this
      if(userCredential.user == null){
        throw "User not found";
      }
      final userData = await getUserData(userCredential.user!.uid);
      return userData;
    }catch(e){
      log(e.toString());
      rethrow;
    }
  }

  Future<void> signOut() async {
    await auth.signOut();
  }

  Future<void> saveUserData(UserModel user)async{
    try{
      firestore.collection("users").doc(user.uid).set(user.toMap());
    } catch(e){
      throw "Failed to save user data";
    }
  }

  Future<UserModel> getUserData(String uid) async{
    try{
      final doc = await firestore.collection("users").doc(uid).get();
      if(!doc.exists){
        throw "user data not found";
      }
      log(doc.id);
      return UserModel.fromFirestore(doc);
    }catch(e){
      throw "Failed to save user data";
    }
  }
}