# Cómo Remover Spending Limit (Mantener $200 USD)

Tu cuenta tiene $200 USD de crédito pero las cuotas de recursos están limitadas.

## Pasos para activar la cuenta completa:

### Opción 1: Azure Portal (5 minutos)
1. Ir a: https://portal.azure.com/#view/Microsoft_Azure_GTM/ModernBillingMenuBlade/~/Overview
2. Click en tu suscripción "Azure subscription 1"
3. En el menú izquierdo → **"Payment methods"**
4. Agregar tarjeta de crédito (solo para validación)
5. Ir a **"Spending limit"** → Click **"Remove spending limit"**
6. **IMPORTANTE**: Seleccionar "Remove spending limit indefinitely"

### ¿Perderé mis $200 USD?
❌ NO - Los $200 USD se mantienen
✅ Solo se activa la capacidad de usar todos los recursos
✅ Seguirás usando primero los $200 gratis
✅ Solo te cobrarán después de gastarlos (si llegas a eso)

### ¿Me cobrarán?
- **Consumption Plan** (Y1) es GRATIS hasta 1M ejecuciones/mes
- **Cosmos DB** tiene tier gratuito (1000 RU/s)
- **Blob Storage** es muy barato (~$0.02/GB)
- **API Management** Developer tier ~$50/mes (viene de tus $200)

**Total estimado:** ~$50-70/mes (sale de tus $200 USD)

---

## Opción 2: CLI (si prefieres)
```bash
# Esto requiere permisos de Owner en la suscripción
az account management-group subscription add \
  --name "YourManagementGroup" \
  --subscription "378e3d41-24e6-42ee-af96-9f64c25d1a61"
```

---

## Después de remover spending limit:

Espera 5-10 minutos y ejecuta:
```bash
git push origin develop
```

El deployment funcionará porque tendrás cuota de VMs disponible.
