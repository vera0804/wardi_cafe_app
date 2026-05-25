const express = require('express');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireCsrf } = require('../middleware/csrf.middleware');
const {
  requireRoles,
  requireEffectiveClient,
  requireTenantAdminWrite,
} = require('../middleware/roles.middleware');
const harvestsService = require('../services/harvests.service');

const router = express.Router();

router.use(
  requireAuth,
  requireRoles(['admin', 'operario', 'tecnico', 'superadmin']),
  requireEffectiveClient
);

router.get('/', async (req, res) => {
  try {
    const rows = await harvestsService.listHarvests({
      clientId: req.user.clientId,
      filters: {
        active: harvestsService.parseActive(req.query.active),
        year: req.query.year,
        fromDate: req.query.from_date,
        toDate: req.query.to_date,
      },
    });
    return res.json(rows);
  } catch (e) {
    if (e.status) return res.status(e.status).json({ message: e.message });
    console.error('GET /harvests', e);
    return res.status(500).json({ message: 'No se pudieron listar las cosechas.' });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const row = await harvestsService.getHarvestById({
      id: req.params.id,
      clientId: req.user.clientId,
    });
    if (!row) return res.status(404).json({ message: 'Cosecha no encontrada.' });
    return res.json(row);
  } catch (e) {
    if (e.status) return res.status(e.status).json({ message: e.message });
    console.error('GET /harvests/:id', e);
    return res.status(500).json({ message: 'No se pudo cargar la cosecha.' });
  }
});

router.post('/', requireCsrf, requireTenantAdminWrite, async (req, res) => {
  try {
    const row = await harvestsService.createHarvest({
      clientId: req.user.clientId,
      userId: req.user.id,
      payload: req.body || {},
    });
    return res.status(201).json(row);
  } catch (e) {
    if (e.status) return res.status(e.status).json({ message: e.message });
    console.error('POST /harvests', e);
    return res.status(500).json({ message: 'No se pudo crear la cosecha.' });
  }
});

router.patch('/:id', requireCsrf, requireTenantAdminWrite, async (req, res) => {
  try {
    const result = await harvestsService.updateHarvest({
      id: req.params.id,
      clientId: req.user.clientId,
      userId: req.user.id,
      payload: req.body || {},
    });
    if (!result) return res.status(404).json({ message: 'Cosecha no encontrada.' });
    return res.json(result);
  } catch (e) {
    if (e.status) return res.status(e.status).json({ message: e.message });
    console.error('PATCH /harvests/:id', e);
    return res.status(500).json({ message: 'No se pudo actualizar la cosecha.' });
  }
});

router.patch('/:id/active', requireCsrf, requireTenantAdminWrite, async (req, res) => {
  const hasIsActive = Object.prototype.hasOwnProperty.call(req.body || {}, 'is_active');
  if (!hasIsActive || typeof req.body.is_active !== 'boolean') {
    return res.status(400).json({ message: 'is_active debe ser booleano.' });
  }
  try {
    const row = await harvestsService.setHarvestActive({
      id: req.params.id,
      clientId: req.user.clientId,
      userId: req.user.id,
      isActive: req.body.is_active,
    });
    if (!row) return res.status(404).json({ message: 'Cosecha no encontrada.' });
    return res.json(row);
  } catch (e) {
    if (e.status) return res.status(e.status).json({ message: e.message });
    console.error('PATCH /harvests/:id/active', e);
    return res.status(500).json({ message: 'No se pudo actualizar estado de la cosecha.' });
  }
});

module.exports = router;
