const { NotificationHubsClient, createFcmNotification } = require('@azure/notification-hubs');

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

  const notification = createFcmNotification({
    body: JSON.stringify({
      title: titulo,
      body: mensaje,
      data: { pedidoId }
    })
  });

  if (tokens && tokens.length > 0) {
    const result = await client.sendNotification(notification, { type: 'direct', deviceHandles: tokens });
    return { success: true, result: result.trackingId };
  }

  const result = await client.sendNotification(notification, { type: 'broadcast' });
  return { success: true, result: result.trackingId };
}

module.exports = { sendNotification };
