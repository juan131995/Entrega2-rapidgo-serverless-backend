# Auth0 Setup Guide

## ⚠️ Estado Actual

**JWT Validation está DESHABILITADA temporalmente** para permitir que el despliegue funcione.

El error que se estaba produciendo:
```
Unable to obtain configuration from: 'https://rapidgo.auth0.com/.well-known/openid-configuration'
Error: 404 Not Found
```

**Causa:** El tenant Auth0 `rapidgo.auth0.com` no existe o no está configurado.

---

## 🚀 Habilitar JWT Validation en Producción

### Paso 1: Crear Tenant Auth0

1. **Ir a [Auth0.com](https://auth0.com/) y registrarse**
2. **Crear un nuevo tenant:**
   - Nombre: `rapidgo` (o el nombre que desees)
   - Región: Selecciona la más cercana (ej: US, EU)
   - Tipo: Development (puedes cambiar después)

3. **Anotar el dominio del tenant:**
   ```
   https://YOUR-TENANT.auth0.com
   ```

### Paso 2: Crear API en Auth0

1. **Ir a Applications > APIs**
2. **Click en "Create API"**
3. **Configurar:**
   - **Name:** RapidGo API
   - **Identifier:** `https://api.rapidgo.app`
   - **Signing Algorithm:** RS256

4. **Click en "Create"**

### Paso 3: Configurar Permisos y Scopes

1. **En la pestaña "Permissions":**
   - Agregar scopes como:
     - `read:orders`
     - `write:orders`
     - `manage:deliveries`
     - etc.

2. **En "Settings":**
   - Habilitar **"Allow Offline Access"** si necesitas refresh tokens
   - Configurar **Token Expiration** según tus necesidades

### Paso 4: Crear Aplicación Cliente

1. **Ir a Applications > Applications**
2. **Click en "Create Application"**
3. **Configurar:**
   - **Name:** RapidGo Mobile App (o Web App)
   - **Type:** Native (móvil) o Single Page Application (web)

4. **En Settings:**
   - **Allowed Callback URLs:**
     ```
     rapidgo://callback
     https://rapidgo.app/callback
     ```
   - **Allowed Logout URLs:**
     ```
     rapidgo://logout
     https://rapidgo.app
     ```
   - **Allowed Web Origins:**
     ```
     https://rapidgo.app
     ```

5. **Autorizar la aplicación para usar tu API:**
   - Ir a APIs > RapidGo API > Machine to Machine Applications
   - Habilitar tu aplicación
   - Seleccionar los scopes necesarios

### Paso 5: Actualizar Plantilla ARM

1. **Editar `src/infra-arm/main.json`:**

   Buscar el parámetro `jwtOpenIdConfigUrl` (línea ~28):
   ```json
   "jwtOpenIdConfigUrl": {
     "type": "string",
     "defaultValue": "https://YOUR-TENANT.auth0.com/.well-known/openid-configuration",
     ...
   }
   ```

2. **Actualizar `jwtIssuer` (línea ~42):**
   ```json
   "jwtIssuer": {
     "type": "string",
     "defaultValue": "https://YOUR-TENANT.auth0.com/",
     ...
   }
   ```

3. **Descomentar la política de JWT en la plantilla (línea ~661):**

   Buscar:
   ```xml
   <!-- JWT Validation temporarily disabled for development -->
   <!-- To enable: Configure Auth0 tenant and uncomment below -->
   <!--
   <validate-jwt ...>
   ...
   </validate-jwt>
   -->
   ```

   Reemplazar por:
   ```xml
   <validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Unauthorized: Invalid or expired JWT token">
     <openid-config url="{{jwtOpenIdConfigUrl}}" />
     <required-claims>
       <claim name="aud" match="all">
         <value>{{jwtAudience}}</value>
       </claim>
     </required-claims>
   </validate-jwt>
   ```

### Paso 6: Verificar Configuración

Antes de redesplegar, verifica que la URL de OpenID funciona:

```bash
# Reemplaza YOUR-TENANT con tu tenant real
curl https://YOUR-TENANT.auth0.com/.well-known/openid-configuration

# Debe retornar un JSON con:
# - issuer
# - authorization_endpoint
# - token_endpoint
# - jwks_uri
# etc.
```

### Paso 7: Redesplegar

```bash
git add src/infra-arm/main.json
git commit -m "feat: enable JWT validation with Auth0"
git push origin develop
```

---

## 🧪 Alternativa: Mock OIDC Provider (Solo para Testing)

Si solo necesitas probar el despliegue sin configurar Auth0, puedes usar un proveedor OIDC mock:

### Opción 1: Microsoft Identity Platform (Gratuito)

```json
"jwtOpenIdConfigUrl": {
  "defaultValue": "https://login.microsoftonline.com/common/v2.0/.well-known/openid-configuration"
},
"jwtIssuer": {
  "defaultValue": "https://login.microsoftonline.com/{tenant}/v2.0"
},
"jwtAudience": {
  "defaultValue": "api://rapidgo"
}
```

### Opción 2: Keycloak (Self-hosted)

Si tienes una instancia de Keycloak:

```json
"jwtOpenIdConfigUrl": {
  "defaultValue": "https://your-keycloak.com/realms/rapidgo/.well-known/openid-configuration"
}
```

---

## 📝 Configuración por Ambiente

Para tener diferentes configuraciones por ambiente:

### Opción 1: Parámetros Override

```bash
# Desarrollo (sin JWT)
az deployment group create \
  --parameters jwtOpenIdConfigUrl="" \
  ...

# Producción (con Auth0)
az deployment group create \
  --parameters jwtOpenIdConfigUrl="https://rapidgo.auth0.com/.well-known/openid-configuration" \
  ...
```

### Opción 2: Archivos de Parámetros Separados

Crear `parameters.prod.json`:
```json
{
  "parameters": {
    "environmentName": { "value": "prod" },
    "jwtOpenIdConfigUrl": { "value": "https://rapidgo.auth0.com/.well-known/openid-configuration" },
    "jwtAudience": { "value": "https://api.rapidgo.app" },
    "jwtIssuer": { "value": "https://rapidgo.auth0.com/" }
  }
}
```

---

## 🔐 Buenas Prácticas de Seguridad

1. **No uses el mismo tenant para DEV y PROD**
   - DEV: `rapidgo-dev.auth0.com`
   - PROD: `rapidgo.auth0.com`

2. **Configura Rate Limiting en Auth0:**
   - Dashboard > Security > Attack Protection
   - Habilitar "Brute Force Protection"
   - Habilitar "Suspicious IP Throttling"

3. **Habilita MFA para usuarios admin:**
   - Dashboard > Security > Multi-factor Auth

4. **Rota secrets regularmente:**
   - Client Secrets
   - API Keys
   - Signing Keys

5. **Monitorea logs de Auth0:**
   - Dashboard > Monitoring > Logs
   - Configura alertas para intentos de login fallidos

---

## 📚 Recursos Útiles

- [Auth0 Quickstart](https://auth0.com/docs/quickstart)
- [Auth0 API Authentication](https://auth0.com/docs/api-auth)
- [Azure APIM + Auth0](https://docs.microsoft.com/azure/api-management/api-management-howto-protect-backend-with-aad)
- [OpenID Connect Spec](https://openid.net/specs/openid-connect-core-1_0.html)

---

## 🐛 Troubleshooting

### Error: "Unable to obtain configuration"

**Causa:** Tenant no existe o URL incorrecta

**Solución:**
```bash
# Verifica que la URL funciona:
curl https://YOUR-TENANT.auth0.com/.well-known/openid-configuration
```

### Error: "Audience validation failed"

**Causa:** El `aud` claim en el token no coincide con `jwtAudience`

**Solución:**
- Verifica que tu API en Auth0 tiene el mismo "Identifier"
- Verifica que tu aplicación solicita tokens para esa API

### Error: "Issuer validation failed"

**Causa:** El `iss` claim no coincide con `jwtIssuer`

**Solución:**
- Debe ser exactamente: `https://YOUR-TENANT.auth0.com/` (con trailing slash)

---

## ✅ Checklist de Producción

Antes de ir a producción con JWT habilitado:

- [ ] Tenant Auth0 creado y configurado
- [ ] API creada en Auth0 con Identifier correcto
- [ ] Aplicación cliente autorizada
- [ ] URL de OpenID verificada (curl exitoso)
- [ ] Parámetros ARM actualizados con tenant real
- [ ] JWT validation descomentada en política APIM
- [ ] Tested con token real de Auth0
- [ ] Rate limiting configurado
- [ ] MFA habilitado para admins
- [ ] Logs y monitoreo configurados

---

## 🎯 Estado Actual del Proyecto

**Para este despliegue:**
- ✅ JWT Validation **DESHABILITADA** (comentada en política APIM)
- ✅ El despliegue funcionará sin Auth0
- ⚠️ **API NO tiene autenticación** - Solo para desarrollo
- ⚠️ **NO usar en producción** sin habilitar JWT

**Para habilitar autenticación:**
1. Seguir Paso 1-6 de esta guía
2. Uncommentar JWT validation en la plantilla
3. Redesplegar

---

**Última actualización:** 2026-05-16
