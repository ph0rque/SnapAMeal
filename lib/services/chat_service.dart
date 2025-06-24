import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get message stream
  Stream<QuerySnapshot> getMessages(String receiverId) {
    final String currentUserId = _auth.currentUser!.uid;

    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join('_');

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Send a message
  Future<void> sendMessage(String receiverId, String message) async {
    final String currentUserId = _auth.currentUser!.uid;
    final Timestamp timestamp = Timestamp.now();

    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join('_');

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'senderId': currentUserId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'isViewed': false,
    });
  }

  // Mark messages as viewed
  Future<void> markMessagesAsViewed(String receiverId) async {
    final String currentUserId = _auth.currentUser!.uid;

    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join('_');

    final querySnapshot = await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isViewed', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'isViewed': true});
    }
    await batch.commit();
  }
} 