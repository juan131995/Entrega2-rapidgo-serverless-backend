const { container } = require('../shared/cosmos');

const TRANSICIONES_VALIDAS = {
  'pendiente': ['asignado', 'cancelado'],
  'asignado': ['recogido', 'cancelado'],
  'recogido': ['enCamino', 'cancelado'],
  'enCamino': ['entregado', 'cancelado'],
  'entregado': [],
  'cancelado': []
};

module.exports = async function (context, req) {
  try {
    const { pedidoId } = context.bindingData;
    const { estado } = req.body || {};

    if (!pedidoId) {
      context.res = {
        status: 400,
        body: { error: 'Se requiere el ID del pedido' }
      };
      return;
    }

    if (!estado) {
      context.res = {
        status: 400,
        body: { error: 'Se requiere el nuevo estado' }
      };
      return;
    }

    const { resource: pedido } = await container.item(pedidoId, 'pedido').read();

    if (!pedido) {
      context.res = {
        status: 404,
        body: { error: 'Pedido no encontrado' }
      };
      return;
    }

    const transicionesPermitidas = TRANSICIONES_VALIDAS[pedido.estado];
    if (!transicionesPermitidas || !transicionesPermitidas.includes(estado)) {
      context.res = {
        status: 400,
        body: {
          error: `Transicion invalida: no se puede cambiar de "${pedido.estado}" a "${estado}"`,
          permitidas: transicionesPermitidas || []
        }
      };
      return;
    }

    const { resource: updated } = await container.item(pedidoId, 'pedido').patch([
      { op: 'replace', path: '/estado', value: estado },
      { op: 'replace', path: '/updatedAt', value: new Date().toISOString() }
    ]);

    context.res = {
      status: 200,
      body: updated
    };
  } catch (error) {
    context.log.error('Error al actualizar estado:', error.message);
    context.res = {
      status: 500,
      body: { error: 'Error interno al actualizar el estado del pedido' }
    };
  }
};
