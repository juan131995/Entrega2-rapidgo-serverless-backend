// Polyfill global crypto for Node.js 18 (Web Crypto API required by @azure/notification-hubs)
if (!globalThis.crypto) {
  globalThis.crypto = require('crypto').webcrypto;
}

const { NotificationHubsClient, createFcmLegacyNotification } = require('@azure/notification-hubs');

let hubClient = null;

function getHubClient() {
  if (!hubClient) {
    const connStr = process.env.NOTIFICATION_HUB_CONNECTION_STRING;
    const hubName = process.env.NOTIFICATION_HUB_NAME;
    if (!connStr || !hubName) {
      return null;
    }
    hubClient = new NotificationHubsClient(connStr, hubName);
  }
  return hubClient;
}

async function sendNotification(pedidoId, titulo, mensaje, tokens) {
  const client = getHubClient();
  if (!client) {
    return { success: false, error: 'Notification Hubs no configurado' };
  }

  const notification = createFcmLegacyNotification({
    body: JSON.stringify({
      notification: { title: titulo, body: mensaje },
      data: { pedidoId }
    })
  });

  try {
    if (tokens && tokens.length > 0) {
      const result = await client.sendNotification(notification, { type: 'direct', deviceHandles: tokens });
      return { success: true, result: result.trackingId };
    }

    const result = await client.sendNotification(notification, { type: 'broadcast' });
    return { success: true, result: result.trackingId };
  } catch (err) {
    // NH sin credenciales FCM o sin dispositivos registrados — no es error crítico
    if (err.message && err.message.includes('no target applications')) {
      return { success: true, result: 'sin-dispositivos-registrados' };
    }
    throw err;
  }
}

module.exports = { sendNotification };
