const { randomUUID } = require('crypto');
const { container } = require('../shared/cosmos');

module.exports = async function (context, req) {
  try {
    const { usuarioId, origen, destino, producto } = req.body || {};

    if (!usuarioId || !origen || !destino || !producto) {
      context.res = {
        status: 400,
        body: { error: 'Faltan campos requeridos: usuarioId, origen, destino, producto' }
      };
      return;
    }

    const pedido = {
      id: randomUUID(),
      tipo: 'pedido',
      usuarioId,
      origen: {
        direccion: origen.direccion,
        lat: origen.lat,
        lng: origen.lng
      },
      destino: {
        direccion: destino.direccion,
        lat: destino.lat,
        lng: destino.lng
      },
      producto: {
        nombre: producto.nombre,
        descripcion: producto.descripcion || ''
      },
      estado: 'pendiente',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    const { resource } = await container.items.create(pedido);

    context.res = {
      status: 201,
      body: resource
    };
  } catch (error) {
    context.log.error('Error al registrar pedido:', error.message);
    context.res = {
      status: 500,
      body: { error: 'Error interno al registrar el pedido' }
    };
  }
};
