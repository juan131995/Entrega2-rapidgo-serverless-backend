// Polyfill global crypto for Node.js 18 (Web Crypto API required by @azure/cosmos v4)
if (!globalThis.crypto) {
  globalThis.crypto = require('crypto').webcrypto;
}

const { CosmosClient } = require('@azure/cosmos');

const client = new CosmosClient(process.env.COSMOS_DB_CONNECTION_STRING);
const database = client.database(process.env.COSMOS_DB_NAME);
const container = database.container(process.env.COSMOS_DB_CONTAINER);

module.exports = { client, database, container };
