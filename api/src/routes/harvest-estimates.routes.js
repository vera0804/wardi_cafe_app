const express = require('express');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireCsrf } = require('../middleware/csrf.middleware');
const {
  requireRoles,
  requireEffectiveClient,
  requireTenantAdminWrite,
} = require('../middleware/roles.middleware');
const estimatesService = require('../services/harvest-estimates.service');

const router = express.Router();

router.use(
  requireAuth,
  requireRoles(['admin', 'operario', 'tecnico', 'superadmin']),
  requireEffectiveClient
);

router.get('/meta', async (req, res) => {
  try {
    const data = await estimatesService.getMeta({ clientId: req.user.clientId });
    return res.json(data);
  } catch (e) {
    console.error('GET /harvest-estimates/meta', e);
    return res.status(500).json({ message: 'No se pudo cargar metadata de estimaciones.' });
  }
});

router.get('/', async (req, res) => {
  const harvestId = String(req.query.harvest_id || '').trim();
  if (!harvestId) {
    return res.status(400).json({ message: 'harvest_id es obligatorio.' });
  }
  try {
    const data = await estimatesService.listByHarvest({
      clientId: req.user.clientId,
      harvestId,
    });
    return res.json(data);
  } catch (e) {
    if (e.status) return res.status(e.status).json({ message: e.message });
    console.error('GET /harvest-estimates', e);
    return res.status(500).json({ message: 'No se pudieron cargar estimaciones.' });
  }
});

router.put('/lot', requireCsrf, requireTenantAdminWrite, async (req, res) => {
  try {
    const row = await estimatesService.upsertLotEstimate({
      clientId: req.user.clientId,
      userId: req.user.id,
      payload: req.body || {},
    });
    return res.json(row);
  } catch (e) {
    if (e.status) return res.status(e.status).json({ message: e.message });
    console.error('PUT /harvest-estimates/lot', e);
    return res.status(500).json({ message: 'No se pudo guardar la estimación.' });
  }
});

router.delete('/lot', requireCsrf, requireTenantAdminWrite, async (req, res) => {
  const harvestId = String(req.query.harvest_id || '').trim();
  const lotId = String(req.query.lot_id || '').trim();
  if (!harvestId || !lotId) {
    return res.status(400).json({ message: 'harvest_id y lot_id son obligatorios.' });
  }
  try {
    const ok = await estimatesService.deleteLotEstimate({
      clientId: req.user.clientId,
      harvestId,
      lotId,
    });
    if (!ok) return res.status(404).json({ message: 'Estimación no encontrada.' });
    return res.json({ ok: true });
  } catch (e) {
    if (e.status) return res.status(e.status).json({ message: e.message });
    console.error('DELETE /harvest-estimates/lot', e);
    return res.status(500).json({ message: 'No se pudo eliminar la estimación.' });
  }
});

module.exports = router;
