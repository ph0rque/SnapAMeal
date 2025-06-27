import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Search for users by username
  Stream<List<Map<String, dynamic>>> searchUsers(String query) {
    if (query.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => doc.data())
              .where(
                (user) => user['uid'] != _auth.currentUser!.uid,
              ) // Exclude self on the client
              .toList();
        });
  }

  // Send a friend request
  Future<void> sendFriendRequest(String receiverId) async {
    final String currentUserId = _auth.currentUser!.uid;

    // create a unique doc id for the friend request
    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");

    await _firestore.collection('friend_requests').doc(chatRoomId).set({
      'senderId': currentUserId,
      'receiverId': receiverId,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Get friend requests for the current user
  Stream<QuerySnapshot> getFriendRequests() {
    final String currentUserId = _auth.currentUser!.uid;
    return _firestore
        .collection('friend_requests')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // Accept a friend request
  Future<void> acceptFriendRequest(String senderId) async {
    final String currentUserId = _auth.currentUser!.uid;

    // Get the friend request doc id
    List<String> ids = [currentUserId, senderId];
    ids.sort();
    String chatRoomId = ids.join("_");

    await _firestore.runTransaction((transaction) async {
      // 1. Update the friend request status
      final requestDoc = _firestore
          .collection('friend_requests')
          .doc(chatRoomId);
      transaction.update(requestDoc, {'status': 'accepted'});

      // 2. Add sender to current user's friend list
      final currentUserDoc = _firestore.collection('users').doc(currentUserId);
      transaction.update(currentUserDoc, {
        'friends': FieldValue.arrayUnion([senderId]),
      });

      // 3. Add current user to sender's friend list
      final senderUserDoc = _firestore.collection('users').doc(senderId);
      transaction.update(senderUserDoc, {
        'friends': FieldValue.arrayUnion([currentUserId]),
      });

      // 4. Create friend document in sender's friends subcollection
      final senderFriendDoc = _firestore
          .collection('users')
          .doc(senderId)
          .collection('friends')
          .doc(currentUserId);
      transaction.set(senderFriendDoc, {
        'friendId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'streakCount': 0,
        'lastSnapTimestamp': null,
      });

      // 5. Create friend document in current user's friends subcollection
      final currentUserFriendDoc = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(senderId);
      transaction.set(currentUserFriendDoc, {
        'friendId': senderId,
        'timestamp': FieldValue.serverTimestamp(),
        'streakCount': 0,
        'lastSnapTimestamp': null,
      });
    });
  }

  // Decline a friend request
  Future<void> declineFriendRequest(String senderId) async {
    final String currentUserId = _auth.currentUser!.uid;

    List<String> ids = [currentUserId, senderId];
    ids.sort();
    String chatRoomId = ids.join("_");

    await _firestore.collection('friend_requests').doc(chatRoomId).delete();
  }

  // Get user data from Firestore
  Future<DocumentSnapshot> getUserData(String userId) {
    return _firestore.collection('users').doc(userId).get();
  }

  // Get the current user's friends stream
  Stream<List<String>> getFriendsStream() {
    final String currentUserId = _auth.currentUser!.uid;
    return _firestore.collection('users').doc(currentUserId).snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data();
      if (data != null && data['friends'] != null) {
        return List<String>.from(data['friends']);
      }
      return [];
    });
  }

  // Get a specific friend's document stream
  Stream<DocumentSnapshot> getFriendDocStream(String friendId) {
    final currentUserId = _auth.currentUser!.uid;
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .doc(friendId)
        .snapshots()
        .handleError((error) {
          Logger.d('Error getting friend doc stream for $friendId: $error');
          return null;
        });
  }

  // Get a specific friend's document (one-time read)
  Future<DocumentSnapshot?> getFriendDoc(String friendId) async {
    final currentUserId = _auth.currentUser!.uid;
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(friendId)
          .get();
      return doc;
    } catch (e) {
      Logger.d('Error getting friend doc for $friendId: $e');
      return null;
    }
  }

  // Ensure current user's friend document exists (create if missing)
  Future<void> ensureCurrentUserFriendDocExists(String friendId) async {
    final currentUserId = _auth.currentUser!.uid;

    try {
      final currentUserFriendDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(friendId)
          .get();

      if (!currentUserFriendDoc.exists) {
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('friends')
            .doc(friendId)
            .set({
              'friendId': friendId,
              'timestamp': FieldValue.serverTimestamp(),
              'streakCount': 0,
              'lastSnapTimestamp': null,
            });
      }
    } catch (e) {
      Logger.d('Error ensuring current user friend document exists: $e');
    }
  }

  // Get or create a one-on-one chat room
  Future<String> getOrCreateOneOnOneChatRoom(String friendId) async {
    final currentUserId = _auth.currentUser!.uid;
    final members = [currentUserId, friendId]
      ..sort(); // Sort to ensure consistent ordering

    // Check if a chat room already exists with these members
    final existingChatQuery = await _firestore
        .collection('chatRooms')
        .where('members', isEqualTo: members)
        .where('isGroup', isEqualTo: false)
        .limit(1)
        .get();

    if (existingChatQuery.docs.isNotEmpty) {
      return existingChatQuery.docs.first.id;
    }

    // Create a new chat room
    final chatRoomDoc = await _firestore.collection('chatRooms').add({
      'members': members,
      'isGroup': false,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    return chatRoomDoc.id;
  }
}
