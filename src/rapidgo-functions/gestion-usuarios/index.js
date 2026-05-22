const { randomUUID } = require('crypto');
const { container } = require('../shared/cosmos');

module.exports = async function (context, req) {
  try {
    const method = req.method;
    const { id } = context.bindingData;

    switch (method) {
      case 'POST':
        return await crearUsuario(context, req);
      case 'GET':
        if (id) {
          return await obtenerUsuario(context, id);
        }
        return await listarUsuarios(context, req);
      case 'PUT':
        return await actualizarUsuario(context, id, req);
      default:
        context.res = { status: 405, body: { error: 'Metodo no permitido' } };
    }
  } catch (error) {
    context.log.error('Error en gestion de usuarios:', error.message);
    context.res = {
      status: 500,
      body: { error: 'Error interno en la gestion de usuarios' }
    };
  }
};

async function crearUsuario(context, req) {
  const { nombre, email, telefono, rol } = req.body || {};

  if (!nombre || !email || !rol) {
    context.res = {
      status: 400,
      body: { error: 'Faltan campos requeridos: nombre, email, rol' }
    };
    return;
  }

  if (!['cliente', 'repartidor', 'admin'].includes(rol)) {
    context.res = {
      status: 400,
      body: { error: 'Rol invalido. Use: cliente, repartidor o admin' }
    };
    return;
  }

  const usuario = {
    id: randomUUID(),
    tipo: 'usuario',
    nombre,
    email,
    telefono: telefono || '',
    rol,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  };

  const { resource } = await container.items.create(usuario);

  context.res = {
    status: 201,
    body: resource
  };
}

async function listarUsuarios(context, req) {
  const rol = req.query.rol;

  let query = 'SELECT * FROM c WHERE c.tipo = "usuario"';
  const parameters = [];

  if (rol) {
    query += ' AND c.rol = @rol';
    parameters.push({ name: '@rol', value: rol });
  }

  query += ' ORDER BY c.createdAt DESC';

  const { resources: usuarios } = await container.items
    .query({ query, parameters }, { partitionKey: 'usuario' })
    .fetchAll();

  context.res = {
    status: 200,
    body: usuarios
  };
}

async function obtenerUsuario(context, id) {
  const { resource: usuario } = await container.item(id, 'usuario').read();

  if (!usuario || usuario.tipo !== 'usuario') {
    context.res = {
      status: 404,
      body: { error: 'Usuario no encontrado' }
    };
    return;
  }

  context.res = {
    status: 200,
    body: usuario
  };
}

async function actualizarUsuario(context, id, req) {
  const { resource: usuario } = await container.item(id, 'usuario').read();

  if (!usuario || usuario.tipo !== 'usuario') {
    context.res = {
      status: 404,
      body: { error: 'Usuario no encontrado' }
    };
    return;
  }

  const { nombre, email, telefono, rol } = req.body || {};

  const patches = [];
  if (nombre) patches.push({ op: 'replace', path: '/nombre', value: nombre });
  if (email) patches.push({ op: 'replace', path: '/email', value: email });
  if (telefono !== undefined) patches.push({ op: 'replace', path: '/telefono', value: telefono });
  if (rol) {
    if (!['cliente', 'repartidor', 'admin'].includes(rol)) {
      context.res = {
        status: 400,
        body: { error: 'Rol invalido. Use: cliente, repartidor o admin' }
      };
      return;
    }
    patches.push({ op: 'replace', path: '/rol', value: rol });
  }
  patches.push({ op: 'replace', path: '/updatedAt', value: new Date().toISOString() });

  const { resource: updated } = await container.item(id, 'usuario').patch(patches);

  context.res = {
    status: 200,
    body: updated
  };
}
