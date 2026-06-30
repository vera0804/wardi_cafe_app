const express = require('express');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireRoles } = require('../middleware/roles.middleware');
const { requireCsrf } = require('../middleware/csrf.middleware');
const appContract = require('../services/appContract.service');

const router = express.Router();

/**
 * GET /api/contracts/status
 * Indica si el rol actual debe aceptar términos antes de usar el panel admin.
 */
router.get('/status', requireAuth, async (req, res, next) => {
  try {
    const fields = await appContract.getContractGateFields(req.user?.clientId, req.user?.role);
    return res.json(fields);
  } catch (e) {
    next(e);
  }
});

/**
 * POST /api/contracts/accept { version }
 * Solo administrador de la organización; registra aceptación a nivel cliente.
 */
router.post('/accept', requireAuth, requireRoles(['admin']), requireCsrf, async (req, res, next) => {
  try {
    const clientId = req.user?.clientId;
    if (clientId == null || !String(clientId).trim()) {
      return res.status(400).json({ message: 'Organización no disponible en esta sesión.' });
    }
    await appContract.recordContractAcceptance({
      clientId: String(clientId),
      userId: String(req.user.id),
      version: req.body?.version,
    });
    const profile = await appContract.enrichUserProfile(req.user);
    return res.json(profile);
  } catch (e) {
    const status = Number(e.status);
    if (status === 400) {
      return res.status(400).json({ message: e.message });
    }
    next(e);
  }
});

module.exports = router;
