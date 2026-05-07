const { sendNotification } = require('../shared/notification');

module.exports = async function (context, req) {
  try {
    const { pedidoId, titulo, mensaje, tokens } = req.body || {};

    if (!pedidoId || !titulo || !mensaje) {
      context.res = {
        status: 400,
        body: { error: 'Faltan campos requeridos: pedidoId, titulo, mensaje' }
      };
      return;
    }

    const result = await sendNotification(pedidoId, titulo, mensaje, tokens || []);

    if (!result.success) {
      context.res = {
        status: 502,
        body: { error: result.error }
      };
      return;
    }

    context.res = {
      status: 200,
      body: {
        message: 'Notificacion enviada correctamente',
        trackingId: result.result
      }
    };
  } catch (error) {
    context.log.error('Error al enviar notificacion:', error.message);
    context.res = {
      status: 500,
      body: { error: 'Error interno al enviar la notificacion' }
    };
  }
};
