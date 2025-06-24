import {setGlobalOptions} from "firebase-functions/v2";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {onCall} from "firebase-functions/v2/https";

setGlobalOptions({maxInstances: 10});

admin.initializeApp();
const db = admin.firestore();
const storage = admin.storage();

/**
 * Helper function to delete a file from Firebase Storage by URL
 * @param {string} fileUrl - The Firebase Storage URL of the file to delete
 * @param {string} fileType - The type of file (for logging purposes)
 * @return {Promise<void>} Promise that resolves when deletion is complete
 */
async function deleteFileFromStorage(
  fileUrl: string,
  fileType: string
): Promise<void> {
  try {
    const decodedUrl = decodeURIComponent(fileUrl);
    const filePath = decodedUrl.split("/o/")[1].split("?")[0];
    await storage.bucket().file(filePath).delete();
    logger.log(`Successfully deleted ${fileType} at ${filePath}`);
  } catch (error) {
    logger.error(`Failed to delete ${fileType}`, error);
  }
}

/**
 * Triggered when a snap is updated. If the 'replayed' field is changed to
 * true, the snap document and the corresponding media files are deleted.
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

    if (beforeData?.replayed === false && afterData?.replayed === true) {
      logger.log(
        `Snap ${event.params.snapId} for user ${event.params.userId} ` +
        "has been replayed. Deleting."
      );

      // Delete the main media file (image or video)
      if (afterData.mediaUrl) {
        const mediaType = afterData.isVideo ? "video" : "image";
        await deleteFileFromStorage(afterData.mediaUrl, mediaType);
      } else if (afterData.imageUrl) {
        // Fallback for legacy snaps
        await deleteFileFromStorage(afterData.imageUrl, "image");
      }

      // Delete the thumbnail if it exists (for videos)
      if (afterData.thumbnailUrl) {
        await deleteFileFromStorage(afterData.thumbnailUrl, "thumbnail");
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
    
    // Delete the main media file
    if (data.mediaUrl) {
      const mediaType = data.isVideo ? "video" : "image";
      await deleteFileFromStorage(data.mediaUrl, mediaType);
    } else if (data.imageUrl) {
      // Fallback for legacy snaps
      await deleteFileFromStorage(data.imageUrl, "image");
    }

    // Delete the thumbnail if it exists (for videos)
    if (data.thumbnailUrl) {
      await deleteFileFromStorage(data.thumbnailUrl, "thumbnail");
    }

    batch.delete(doc.ref);
  }

  await batch.commit();

  logger.log(
    `Deleted ${oldUnreadSnaps.size} old, unread snaps.`
  );
});

/**
 * Cloud Function for server-side thumbnail generation
 * This is a backup function for generating thumbnails if client-side fails
 */
export const generateVideoThumbnail = onCall(async (request) => {
  const {videoUrl, userId} = request.data;

  if (!videoUrl || !userId) {
    throw new Error("Missing required parameters: videoUrl and userId");
  }

  try {
    logger.info(`Generating thumbnail for video: ${videoUrl}`);
    
    // Extract file path from URL
    const decodedUrl = decodeURIComponent(videoUrl);
    const videoPath = decodedUrl.split("/o/")[1].split("?")[0];
    
    // Download video file temporarily (simplified approach)
    // In a real implementation, you would use FFmpeg or similar
    // For now, we'll return a placeholder response
    
    const thumbnailFileName = `${Date.now()}_thumb.jpg`;
    const thumbnailPath = `snaps/${userId}/thumbnails/${thumbnailFileName}`;
    
    // Placeholder: In production, implement actual thumbnail generation
    // This would involve downloading the video, extracting a frame,
    // and uploading the thumbnail
    
    logger.info(`Thumbnail generation completed for ${videoPath}`);
    
    return {
      success: true,
      thumbnailPath: thumbnailPath,
      message: "Thumbnail generation initiated (placeholder implementation)"
    };
  } catch (error) {
    logger.error("Error generating video thumbnail:", error);
    throw new Error("Failed to generate video thumbnail");
  }
});

export const sendScreenshotNotification = onCall(async (request) => {
  const {snap, viewerUsername} = request.data;
  const senderId = snap.senderId;

  // Get sender's FCM token
  const userDoc = await db.collection("users").doc(senderId).get();
  const userData = userDoc.data();
  if (!userData || !userData.fcmToken) {
    logger.error("Sender FCM token not found.");
    return;
  }
  const fcmToken = userData.fcmToken;

  // Send notification
  const payload = {
    notification: {
      title: "Snap Screenshot!",
      body: `${viewerUsername} took a screenshot of your snap!`,
    },
    token: fcmToken,
  };

  try {
    await admin.messaging().send(payload);
    logger.log("Successfully sent screenshot notification.");
  } catch (error) {
    logger.error("Error sending screenshot notification:", error);
  }
});
