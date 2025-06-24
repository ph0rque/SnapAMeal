/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {setGlobalOptions} from "firebase-functions";
import {onRequest} from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { onUpdate } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

// export const helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

admin.initializeApp();

const db = admin.firestore();

/**
 * Triggered when a message is updated. If the 'isViewed' field is changed to
 * true, the message document is deleted.
 */
export const onMessageViewed = functions.firestore
  .document("chat_rooms/{chatRoomId}/messages/{messageId}")
  .onUpdate(async (
    change: functions.Change<functions.firestore.DocumentSnapshot>,
    context: functions.EventContext
  ) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();

    if (!beforeData || !afterData) {
      functions.logger.log("Data not found in event.");
      return;
    }

    if (!beforeData.isViewed && afterData.isViewed) {
      functions.logger.log(
        `Message ${context.params.messageId} in chat ` +
        `${context.params.chatRoomId} has been viewed. Deleting.`
      );
      return change.after.ref.delete();
    }

    return null;
  });

/**
 * A scheduled function that runs every hour to delete messages that are
 * older than 24 hours and have not been viewed.
 */
export const deleteOldMessages = functions.pubsub
  .schedule("every 1 hours")
  .onRun(async () => {
    const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

    const oldUnreadMessages = await db
      .collectionGroup("messages")
      .where("isViewed", "==", false)
      .where("timestamp", "<=", twentyFourHoursAgo)
      .get();

    if (oldUnreadMessages.empty) {
      functions.logger.log("No old, unread messages to delete.");
      return null;
    }

    const batch = db.batch();
    oldUnreadMessages.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();

    functions.logger.log(
      `Deleted ${oldUnreadMessages.size} old, unread messages.`
    );
    return null;
  });
