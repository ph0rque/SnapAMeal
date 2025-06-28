const admin = require('firebase-admin');

// Initialize Firebase Admin (uses default project credentials)
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

async function seedDemoNotifications() {
  try {
    console.log('🔔 Seeding demo notifications...');

    // Get demo user UIDs
    const aliceDoc = await db.collection('users').where('email', '==', 'alice.demo@example.com').get();
    const bobDoc = await db.collection('users').where('email', '==', 'bob.demo@example.com').get();
    const charlieDoc = await db.collection('users').where('email', '==', 'charlie.demo@example.com').get();

    if (aliceDoc.empty || bobDoc.empty || charlieDoc.empty) {
      console.error('❌ Demo users not found. Please run seed_demo_accounts.js first.');
      return;
    }

    const aliceId = aliceDoc.docs[0].id;
    const bobId = bobDoc.docs[0].id;
    const charlieId = charlieDoc.docs[0].id;

    console.log(`Found demo users: Alice(${aliceId}), Bob(${bobId}), Charlie(${charlieId})`);

    // Create notifications for Alice
    const aliceNotifications = [
      {
        user_id: aliceId,
        type: 'friendRequest',
        title: 'New Friend Request',
        message: 'Bob wants to be your friend',
        timestamp: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 2 * 60 * 60 * 1000)), // 2 hours ago
        data: {
          sender_id: bobId,
          sender_name: 'Bob',
          action_type: 'friend_request',
        },
        is_read: false,
      },
      {
        user_id: aliceId,
        type: 'unreadMessage',
        title: 'New Message',
        message: 'Charlie: Hey Alice! How\'s your fasting journey going?',
        timestamp: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 30 * 60 * 1000)), // 30 minutes ago
        data: {
          sender_id: charlieId,
          sender_name: 'Charlie',
          chat_room_id: `chat_${aliceId}_${charlieId}`,
          action_type: 'open_chat',
        },
        is_read: false,
      },
      {
        user_id: aliceId,
        type: 'groupInvitation',
        title: 'Group Invitation',
        message: 'Bob invited you to join Intermittent Fasting Support',
        timestamp: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 5 * 60 * 60 * 1000)), // 5 hours ago
        data: {
          group_id: 'intermittent_fasting_group',
          group_name: 'Intermittent Fasting Support',
          inviter_name: 'Bob',
          action_type: 'group_invitation',
        },
        is_read: false,
      },
      {
        user_id: aliceId,
        type: 'aiAdvice',
        title: 'New Health Insight',
        message: 'Your fasting consistency has improved by 25% this week!',
        timestamp: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 1 * 60 * 60 * 1000)), // 1 hour ago
        data: {
          advice_type: 'fasting_progress',
          action_type: 'view_advice',
        },
        is_read: false,
      },
    ];

    // Create notifications for Bob
    const bobNotifications = [
      {
        user_id: bobId,
        type: 'unreadMessage',
        title: 'New Message',
        message: 'Alice: Thanks for the friend request! 😊',
        timestamp: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 15 * 60 * 1000)), // 15 minutes ago
        data: {
          sender_id: aliceId,
          sender_name: 'Alice',
          chat_room_id: `chat_${aliceId}_${bobId}`,
          action_type: 'open_chat',
        },
        is_read: false,
      },
      {
        user_id: bobId,
        type: 'groupMessage',
        title: 'Fitness Motivation Squad',
        message: 'Charlie: Just finished a great workout! Who\'s joining me tomorrow?',
        timestamp: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 45 * 60 * 1000)), // 45 minutes ago
        data: {
          sender_id: charlieId,
          sender_name: 'Charlie',
          chat_room_id: 'fitness_group_chat',
          group_name: 'Fitness Motivation Squad',
          action_type: 'open_chat',
        },
        is_read: false,
      },
    ];

    // Create notifications for Charlie
    const charlieNotifications = [
      {
        user_id: charlieId,
        type: 'friendRequest',
        title: 'New Friend Request',
        message: 'Alice wants to be your friend',
        timestamp: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 3 * 60 * 60 * 1000)), // 3 hours ago
        data: {
          sender_id: aliceId,
          sender_name: 'Alice',
          action_type: 'friend_request',
        },
        is_read: true, // Charlie has read this one
      },
      {
        user_id: charlieId,
        type: 'aiAdvice',
        title: 'Weekly Progress Report',
        message: 'Your meal logging streak is at 7 days! Keep it up!',
        timestamp: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 12 * 60 * 60 * 1000)), // 12 hours ago
        data: {
          advice_type: 'meal_logging_streak',
          action_type: 'view_advice',
        },
        is_read: false,
      },
    ];

    // Seed notifications to Firestore
    const batch = db.batch();

    // Add Alice's notifications
    aliceNotifications.forEach((notification, index) => {
      const docRef = db.collection('demo_notifications').doc(`alice_notification_${index + 1}`);
      batch.set(docRef, notification);
    });

    // Add Bob's notifications
    bobNotifications.forEach((notification, index) => {
      const docRef = db.collection('demo_notifications').doc(`bob_notification_${index + 1}`);
      batch.set(docRef, notification);
    });

    // Add Charlie's notifications
    charlieNotifications.forEach((notification, index) => {
      const docRef = db.collection('demo_notifications').doc(`charlie_notification_${index + 1}`);
      batch.set(docRef, notification);
    });

    await batch.commit();

    console.log('✅ Demo notifications seeded successfully!');
    console.log(`   - Alice: ${aliceNotifications.length} notifications (${aliceNotifications.filter(n => !n.is_read).length} unread)`);
    console.log(`   - Bob: ${bobNotifications.length} notifications (${bobNotifications.filter(n => !n.is_read).length} unread)`);
    console.log(`   - Charlie: ${charlieNotifications.length} notifications (${charlieNotifications.filter(n => !n.is_read).length} unread)`);

    // Also create some demo friend requests for the notification count
    console.log('🤝 Creating demo friend requests...');

    const friendRequestBatch = db.batch();

    // Create pending friend request from Bob to Alice
    friendRequestBatch.set(db.collection('demo_friend_requests').doc(`${aliceId}_${bobId}`), {
      senderId: bobId,
      receiverId: aliceId,
      status: 'pending',
      timestamp: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 2 * 60 * 60 * 1000)),
    });

    // Create pending friend request from Alice to Charlie
    friendRequestBatch.set(db.collection('demo_friend_requests').doc(`${aliceId}_${charlieId}`), {
      senderId: aliceId,
      receiverId: charlieId,
      status: 'pending',
      timestamp: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 3 * 60 * 60 * 1000)),
    });

    await friendRequestBatch.commit();

    console.log('✅ Demo friend requests created!');
    console.log('🎉 Notification system demo data setup complete!');

  } catch (error) {
    console.error('❌ Error seeding demo notifications:', error);
  }
}

// Run the seeding function
seedDemoNotifications()
  .then(() => {
    console.log('🏁 Seeding completed');
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Seeding failed:', error);
    process.exit(1);
  }); 