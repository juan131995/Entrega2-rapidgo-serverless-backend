const { container } = require('../shared/cosmos');

module.exports = async function (context, req) {
  try {
    const usuarioId = req.query.usuarioId;
    const estado = req.query.estado;

    let query = 'SELECT * FROM c WHERE c.tipo = "pedido"';
    const parameters = [];

    if (usuarioId) {
      query += ' AND c.usuarioId = @usuarioId';
      parameters.push({ name: '@usuarioId', value: usuarioId });
    }

    if (estado) {
      query += ' AND c.estado = @estado';
      parameters.push({ name: '@estado', value: estado });
    }

    query += ' ORDER BY c.createdAt DESC';

    const { resources: pedidos } = await container.items
      .query({ query, parameters }, { partitionKey: 'pedido' })
      .fetchAll();

    context.res = {
      status: 200,
      body: pedidos
    };
  } catch (error) {
    context.log.error('Error al consultar historial:', error.message);
    context.res = {
      status: 500,
      body: { error: 'Error interno al consultar el historial' }
    };
  }
};
