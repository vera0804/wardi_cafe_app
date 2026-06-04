const express = require('express');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireCsrf } = require('../middleware/csrf.middleware');
const { requireRoles, requireEffectiveClient } = require('../middleware/roles.middleware');
const productionService = require('../services/lot-production.service');

const router = express.Router();

function parseActive(value) {
  const v = String(value || '').trim().toLowerCase();
  if (!v || v === 'all') return undefined;
  if (v === 'true') return true;
  if (v === 'false') return false;
  const err = new Error('El filtro active debe ser true, false o all.');
  err.status = 400;
  throw err;
}

function requireProductionWrite(req, res, next) {
  const role = String(req.user?.role || '').trim().toLowerCase();
  if (role === 'operario' || role === 'tecnico') {
    return res.status(403).json({ message: 'Tu rol solo tiene permisos de consulta en producción de café.' });
  }
  return next();
}

router.use(
  requireAuth,
  requireRoles(['admin', 'operario', 'tecnico', 'superadmin']),
  requireEffectiveClient
);

router.get('/meta', async (req, res) => {
  try {
    const data = await productionService.getMeta({ clientId: req.user.clientId });
    return res.json(data);
  } catch (e) {
    console.error('GET /lot-production/meta', e);
    return res.status(500).json({ message: 'No se pudo cargar metadata de producción.' });
  }
});

router.get('/', async (req, res) => {
  try {
    const rows = await productionService.listProductions({
      clientId: req.user.clientId,
      filters: {
        fromDate: req.query.from_date,
        toDate: req.query.to_date,
        farmId: req.query.farm_id,
        lotId: req.query.lot_id,
        active: parseActive(req.query.active),
      },
    });
    return res.json(rows);
  } catch (e) {
    if (e.status) return res.status(e.status).json({ message: e.message });
    console.error('GET /lot-production', e);
    return res.status(500).json({ message: 'No se pudo listar producción de café.' });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const row = await productionService.getProductionById({
      id: req.params.id,
      clientId: req.user.clientId,
    });
    if (!row) return res.status(404).json({ message: 'Registro de producción no encontrado.' });
    return res.json(row);
  } catch (e) {
    if (e.status) return res.status(e.status).json({ message: e.message });
    console.error('GET /lot-production/:id', e);
    return res.status(500).json({ message: 'No se pudo cargar la producción.' });
  }
});

router.post('/bulk', requireCsrf, requireProductionWrite, async (req, res) => {
  try {
    const rows = await productionService.createProductionBulk({
      clientId: req.user.clientId,
      userId: req.user.id,
      payload: req.body || {},
    });
    return res.status(201).json(rows);
  } catch (e) {
    if (e.status) return res.status(e.status).json({ message: e.message });
    console.error('POST /lot-production/bulk', e);
    return res.status(500).json({ message: 'No se pudo crear la carga masiva de producción.' });
  }
});

router.post('/', requireCsrf, requireProductionWrite, async (req, res) => {
  try {
    const row = await productionService.createProduction({
      clientId: req.user.clientId,
      userId: req.user.id,
      payload: req.body || {},
    });
    return res.status(201).json(row);
  } catch (e) {
    if (e.status) return res.status(e.status).json({ message: e.message });
    console.error('POST /lot-production', e);
    return res.status(500).json({ message: 'No se pudo crear producción.' });
  }
});

router.patch('/:id', requireCsrf, requireProductionWrite, async (req, res) => {
  try {
    const row = await productionService.updateProduction({
      id: req.params.id,
      clientId: req.user.clientId,
      userId: req.user.id,
      payload: req.body || {},
    });
    if (!row) return res.status(404).json({ message: 'Registro de producción no encontrado.' });
    return res.json(row);
  } catch (e) {
    if (e.status) return res.status(e.status).json({ message: e.message });
    console.error('PATCH /lot-production/:id', e);
    return res.status(500).json({ message: 'No se pudo actualizar producción.' });
  }
});

router.patch('/:id/active', requireCsrf, requireProductionWrite, async (req, res) => {
  const hasIsActive = Object.prototype.hasOwnProperty.call(req.body || {}, 'is_active');
  if (!hasIsActive || typeof req.body.is_active !== 'boolean') {
    return res.status(400).json({ message: 'is_active debe ser booleano.' });
  }
  try {
    const row = await productionService.setProductionActive({
      id: req.params.id,
      clientId: req.user.clientId,
      userId: req.user.id,
      isActive: req.body.is_active,
    });
    if (!row) return res.status(404).json({ message: 'Registro de producción no encontrado.' });
    return res.json(row);
  } catch (e) {
    if (e.status) return res.status(e.status).json({ message: e.message });
    console.error('PATCH /lot-production/:id/active', e);
    return res.status(500).json({ message: 'No se pudo actualizar estado de producción.' });
  }
});

module.exports = router;
