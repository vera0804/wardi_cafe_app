const express = require('express');
const config = require('../config');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireRoles, requireEffectiveClient } = require('../middleware/roles.middleware');
const statsService = require('../services/stats.service');

const router = express.Router();

router.get(
  '/overview',
  requireAuth,
  requireRoles(['admin', 'superadmin']),
  requireEffectiveClient,
  async (req, res, next) => {
    try {
      const data = await statsService.getOverview({
        ...req.query,
        clientId: req.user.clientId,
      });
      return res.json(data);
    } catch (e) {
      if (e.status) return res.status(e.status).json({ message: e.message });
      console.error('GET /stats/overview', e);
      return res.status(500).json({
        message: 'No se pudieron calcular las estadísticas.',
        detail: !config.isProd ? e.message : undefined,
      });
    }
  }
);

module.exports = router;
