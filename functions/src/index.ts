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

/**
 * Scheduled function to manage story expiration based on logarithmic permanence
 * Runs every hour to check and expire stories that have passed their dynamic expiration time
 */
export const manageStoryExpiration = onSchedule("every 1 hours", async () => {
  logger.info("Running manageStoryExpiration scheduled function");

  try {
    const now = new Date();

    // Find all expired stories across all users
    const expiredStoriesQuery = await db
      .collectionGroup("stories")
      .where("permanence.expiresAt", "<=", now)
      .get();

    if (expiredStoriesQuery.empty) {
      logger.log("No expired stories found.");
      return;
    }

    const batch = db.batch();
    let deletedCount = 0;
    let archivedCount = 0;

    for (const storyDoc of expiredStoriesQuery.docs) {
      const storyData = storyDoc.data();
      const permanence = storyData.permanence || {};
      const tier = permanence.tier || "standard";

      // Archive milestone stories instead of deleting them
      if (tier === "milestone" || tier === "monthly") {
        // Move to archived stories collection
        const userId = storyDoc.ref.parent.parent?.id;
        if (userId) {
          const archivedStoryRef = db
            .collection("users")
            .doc(userId)
            .collection("archived_stories")
            .doc(storyDoc.id);

          batch.set(archivedStoryRef, {
            ...storyData,
            archivedAt: admin.firestore.FieldValue.serverTimestamp(),
            originalStoryId: storyDoc.id,
          });

          batch.delete(storyDoc.ref);
          archivedCount++;
        }
      } else {
        // Delete regular expired stories and their media
        await deleteStoryMedia(storyData);
        batch.delete(storyDoc.ref);
        deletedCount++;
      }
    }

    await batch.commit();

    logger.log(
      `Story expiration completed: ${deletedCount} stories deleted, ` +
      `${archivedCount} stories archived`
    );
  } catch (error) {
    logger.error("Error in manageStoryExpiration:", error);
  }
});

/**
 * Function to recalculate story permanence when engagement is updated
 * Triggered when story engagement collection is updated
 */
export const recalculateStoryPermanence = onDocumentUpdated(
  "story_engagement/{engagementId}",
  async (event) => {
    logger.info("Story engagement updated, recalculating permanence");

    const change = event.data;
    if (!change) {
      logger.warn("No data associated with engagement event");
      return;
    }

    const engagementData = change.after.data();
    const storyId = engagementData.storyId;
    const storyOwnerId = engagementData.storyOwnerId;

    if (!storyId || !storyOwnerId) {
      logger.warn("Missing storyId or storyOwnerId in engagement data");
      return;
    }

    try {
      // Get the story document
      const storyRef = db
        .collection("users")
        .doc(storyOwnerId)
        .collection("stories")
        .doc(storyId);

      const storyDoc = await storyRef.get();
      if (!storyDoc.exists) {
        logger.warn(`Story ${storyId} not found for user ${storyOwnerId}`);
        return;
      }

      const storyData = storyDoc.data()!;
      const engagement = storyData.engagement || {};
      const totalScore = storyData.totalEngagementScore || 0;
      const timestamp = storyData.timestamp;

      if (!timestamp) {
        logger.warn("Story missing timestamp");
        return;
      }

      // Calculate new permanence duration
      const permanenceDuration = calculateLogarithmicDuration(
        totalScore,
        engagement.views || 0,
        engagement.likes || 0,
        engagement.comments || 0,
        engagement.shares || 0,
      );

      // Calculate new expiration time
      const storyCreatedAt = timestamp.toDate();
      const expiresAt = new Date(
        storyCreatedAt.getTime() + permanenceDuration
      );

      // Determine permanence tier
      const permanenceTier = getPermanenceTier(permanenceDuration);

      // Update story permanence
      await storyRef.update({
        "permanence.duration": permanenceDuration / 1000,
        "permanence.expiresAt": admin.firestore.Timestamp.fromDate(expiresAt),
        "permanence.tier": permanenceTier,
        "permanence.calculatedAt": admin.firestore.FieldValue.serverTimestamp(),
        "permanence.isExtended": permanenceDuration > 24 * 60 * 60 * 1000,
      });

      const hours = Math.round(permanenceDuration / (60 * 60 * 1000));
      logger.log(
        `Updated story ${storyId} permanence: ${hours} hours ` +
        `(tier: ${permanenceTier})`
      );
    } catch (error) {
      logger.error("Error recalculating story permanence:", error);
    }
  }
);

/**
 * Calculate logarithmic duration based on engagement metrics
 * @param {number} totalScore - Total weighted engagement score
 * @param {number} views - Number of views
 * @param {number} likes - Number of likes
 * @param {number} comments - Number of comments
 * @param {number} shares - Number of shares
 * @return {number} Duration in milliseconds
 */
function calculateLogarithmicDuration(
  totalScore: number,
  views: number,
  likes: number,
  comments: number,
  shares: number
): number {
  // Base duration: 24 hours in milliseconds
  const baseDuration = 24 * 60 * 60 * 1000;
  
  // Calculate engagement multiplier using logarithmic scale
  const engagementMultiplier = Math.log(1 + totalScore) * 0.5;
  
  // Calculate view velocity bonus (views in first hour)
  const viewVelocityBonus = Math.min(views / 10.0, 2.0); // Max 2x bonus
  
  // Calculate interaction quality bonus
  const interactionQuality = (likes * 0.3) + (comments * 0.5) + (shares * 0.7);
  const qualityMultiplier = Math.log(1 + interactionQuality) * 0.3;
  
  // Total multiplier (capped at 30 days max)
  const totalMultiplier = Math.min(
    1 + engagementMultiplier + viewVelocityBonus + qualityMultiplier,
    30.0 // Max 30x = 30 days
  );
  
  return Math.round(baseDuration * totalMultiplier);
}

/**
 * Get permanence tier based on duration
 * @param {number} durationMs - Duration in milliseconds
 * @return {string} Permanence tier
 */
function getPermanenceTier(durationMs: number): string {
  const hours = durationMs / (60 * 60 * 1000);
  
  if (hours <= 24) return 'standard';
  if (hours <= 72) return 'extended';
  if (hours <= 168) return 'weekly';
  if (hours <= 720) return 'monthly';
  return 'milestone';
}

/**
 * Delete story media files from Firebase Storage
 * @param {any} storyData - Story document data
 */
async function deleteStoryMedia(storyData: any): Promise<void> {
  try {
    // Delete main media file
    if (storyData.mediaUrl) {
      const mediaType = storyData.isVideo ? "video" : "image";
      await deleteFileFromStorage(storyData.mediaUrl, mediaType);
    }

    // Delete thumbnail if it exists
    if (storyData.thumbnailUrl) {
      await deleteFileFromStorage(storyData.thumbnailUrl, "thumbnail");
    }
  } catch (error) {
    logger.error("Error deleting story media:", error);
  }
}

/**
 * Cloud Function to get story analytics and permanence insights
 */
export const getStoryInsights = onCall(async (request) => {
  const {userId, storyId} = request.data;

  if (!userId || !storyId) {
    throw new Error("Missing required parameters: userId and storyId");
  }

  try {
    // Get story data
    const storyDoc = await db
      .collection('users')
      .doc(userId)
      .collection('stories')
      .doc(storyId)
      .get();

    if (!storyDoc.exists) {
      throw new Error("Story not found");
    }

    const storyData = storyDoc.data()!;
    
    // Get engagement events
    const engagementEvents = await db
      .collection('story_engagement')
      .where('storyId', '==', storyId)
      .orderBy('timestamp', 'desc')
      .get();

    // Calculate insights
    const insights = {
      story: storyData,
      analytics: {
        totalEngagement: storyData.totalEngagementScore || 0,
        engagement: storyData.engagement || {},
        permanence: storyData.permanence || {},
        engagementEvents: engagementEvents.docs.length,
        uniqueViewers: getUniqueViewers(engagementEvents.docs),
        engagementRate: calculateEngagementRate(storyData.engagement),
        timeToExpiry: getTimeToExpiry(storyData.permanence),
      },
    };

    return insights;
  } catch (error) {
    logger.error("Error getting story insights:", error);
    throw new Error("Failed to get story insights");
  }
});

/**
 * Calculate unique viewers from engagement events
 */
function getUniqueViewers(events: admin.firestore.QueryDocumentSnapshot[]): number {
  const uniqueViewers = new Set<string>();
  
  for (const event of events) {
    const data = event.data();
    const viewerId = data.viewerId;
    if (viewerId) {
      uniqueViewers.add(viewerId);
    }
  }
  
  return uniqueViewers.size;
}

/**
 * Calculate engagement rate (interactions / views)
 */
function calculateEngagementRate(engagement: any): number {
  if (!engagement) return 0.0;
  
  const views = engagement.views || 0;
  if (views === 0) return 0.0;
  
  const interactions = (engagement.likes || 0) +
                      (engagement.comments || 0) +
                      (engagement.shares || 0);
  
  return interactions / views;
}

/**
 * Get time remaining until story expires
 */
function getTimeToExpiry(permanence: any): number {
  if (!permanence || !permanence.expiresAt) return 0;
  
  const now = new Date();
  const expiresAt = permanence.expiresAt.toDate();
  
  return Math.max(0, expiresAt.getTime() - now.getTime());
}
