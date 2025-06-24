import {setGlobalOptions} from "firebase-functions/v2";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";

setGlobalOptions({maxInstances: 10});

admin.initializeApp();
const db = admin.firestore();
const storage = admin.storage();

/**
 * Triggered when a snap is updated. If the 'isViewed' field is changed to
 * true, the snap document and the corresponding image are deleted.
 */
export const onSnapViewed = onDocumentUpdated(
  "users/{userId}/snaps/{snapId}", async (event) => {
    logger.info("onSnapViewed event", {params: event.params});

    const change = event.data;
    if (!change) {
      logger.warn("No data associated with the event");
      return;
    }

    const beforeData = change.before.data();
    const afterData = change.after.data();

    if (beforeData?.isViewed === false && afterData?.isViewed === true) {
      logger.log(
        `Snap ${event.params.snapId} for user ${event.params.userId} ` +
        "has been viewed. Deleting."
      );

      // Delete the image from Storage
      if (afterData.imageUrl) {
        try {
          const fileUrl = decodeURIComponent(afterData.imageUrl);
          const filePath = fileUrl.split("/o/")[1].split("?")[0];
          await storage.bucket().file(filePath).delete();
          logger.log(`Successfully deleted image at ${filePath}`);
        } catch (error) {
          logger.error(
            `Failed to delete image for snap ${event.params.snapId}`,
            error
          );
        }
      }

      // Delete the Firestore document
      return change.after.ref.delete();
    }

    return;
  }
);

/**
 * A scheduled function that runs every hour to delete snaps that are
 * older than 24 hours and have not been viewed.
 */
export const deleteOldSnaps = onSchedule("every 1 hours", async () => {
  logger.info("Running deleteOldSnaps scheduled function");
  const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

  const oldUnreadSnaps = await db
    .collectionGroup("snaps")
    .where("isViewed", "==", false)
    .where("timestamp", "<=", twentyFourHoursAgo)
    .get();

  if (oldUnreadSnaps.empty) {
    logger.log("No old, unread snaps to delete.");
    return;
  }

  const batch = db.batch();
  for (const doc of oldUnreadSnaps.docs) {
    const data = doc.data();
    if (data.imageUrl) {
      try {
        const fileUrl = decodeURIComponent(data.imageUrl);
        const filePath = fileUrl.split("/o/")[1].split("?")[0];
        await storage.bucket().file(filePath).delete();
        logger.log(`Successfully deleted image at ${filePath}`);
      } catch (error) {
        logger.error(`Failed to delete image for snap ${doc.id}`, error);
      }
    }
    batch.delete(doc.ref);
  }

  await batch.commit();

  logger.log(
    `Deleted ${oldUnreadSnaps.size} old, unread snaps.`
  );
});
