import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get chat stream for the current user
  Stream<QuerySnapshot> getChatsStream() {
    final String currentUserId = _auth.currentUser!.uid;
    return _firestore
        .collection('chat_rooms')
        .where('members', arrayContains: currentUserId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots();
  }

  // Get message stream for a specific chat room
  Stream<QuerySnapshot> getMessages(String chatRoomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Send a message to a specific chat room
  Future<void> sendMessage(String chatRoomId, String message) async {
    final String currentUserId = _auth.currentUser!.uid;
    final Timestamp timestamp = Timestamp.now();

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'senderId': currentUserId,
      'message': message,
      'timestamp': timestamp,
      'isViewed': false, // Note: isViewed logic will need to be updated for groups
    });

    // Also update the last message timestamp on the chat room for sorting
    await _firestore.collection('chat_rooms').doc(chatRoomId).update({
      'lastMessageTimestamp': timestamp,
    });
  }

  // Create a new group chat
  Future<String> createGroupChat(List<String> memberIds) async {
    final String currentUserId = _auth.currentUser!.uid;
    if (!memberIds.contains(currentUserId)) {
      memberIds.add(currentUserId);
    }

    final chatRoomRef = await _firestore.collection('chat_rooms').add({
      'members': memberIds,
      'isGroup': memberIds.length > 2,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'createdBy': currentUserId,
    });

    return chatRoomRef.id;
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