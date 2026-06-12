const express = require('express');
const { requireAuth, clientIp } = require('../middleware/auth.middleware');
const { requireCsrf } = require('../middleware/csrf.middleware');
const { requireSuperadmin } = require('../middleware/roles.middleware');
const auditService = require('../services/audit.service');
const authService = require('../services/auth.service');
const superadminService = require('../services/superadmin.service');
const superadminPlansService = require('../services/superadmin-plans.service');

const router = express.Router();

router.use(requireAuth, requireSuperadmin);

router.get('/plans', async (req, res, next) => {
  try {
    const rows = await superadminService.listPlans();
    res.json(rows);
  } catch (e) {
    next(e);
  }
});

router.get('/plans/all', async (req, res, next) => {
  try {
    res.json(await superadminPlansService.listAllPlans());
  } catch (e) {
    next(e);
  }
});

router.get('/plans/:planId/impact', async (req, res, next) => {
  try {
    res.json(await superadminPlansService.getPlanImpact(req.params.planId));
  } catch (e) {
    if (e.status) return res.status(e.status).json({ message: e.message });
    next(e);
  }
});

router.post('/plans', requireCsrf, async (req, res, next) => {
  try {
    const row = await superadminPlansService.createPlan(req.body || {});
    auditService.logSecurityEvent({
      eventType: 'superadmin_plan_created',
      userId: req.user.id,
      clientId: null,
      ipAddress: clientIp(req),
      userAgent: req.headers['user-agent'] || null,
      metadata: { planId: row.id, planName: row.name },
    });
    res.status(201).json(row);
  } catch (e) {
    if (e.status) return res.status(e.status).json({ message: e.message });
    next(e);
  }
});

router.patch('/plans/:planId', requireCsrf, async (req, res, next) => {
  try {
    const row = await superadminPlansService.updatePlan(req.params.planId, req.body || {}, {
      acknowledgeAffectedClients: req.body?.acknowledge_affected_clients === true,
    });
    auditService.logSecurityEvent({
      eventType: 'superadmin_plan_updated',
      userId: req.user.id,
      clientId: null,
      ipAddress: clientIp(req),
      userAgent: req.headers['user-agent'] || null,
      metadata: { planId: row.id, planName: row.name },
    });
    res.json(row);
  } catch (e) {
    if (e.status === 409 && e.code === superadminPlansService.PLAN_IMPACT_CODE) {
      return res.status(409).json({
        message: e.message,
        code: e.code,
        impact: e.impact,
      });
    }
    if (e.status) return res.status(e.status).json({ message: e.message });
    next(e);
  }
});

router.post('/plans/:planId/deactivate', requireCsrf, async (req, res, next) => {
  try {
    const row = await superadminPlansService.deactivatePlan(req.params.planId, {
      acknowledgeAffectedClients: req.body?.acknowledge_affected_clients === true,
    });
    auditService.logSecurityEvent({
      eventType: 'superadmin_plan_deactivated',
      userId: req.user.id,
      clientId: null,
      ipAddress: clientIp(req),
      userAgent: req.headers['user-agent'] || null,
      metadata: { planId: row.id, planName: row.name },
    });
    res.json(row);
  } catch (e) {
    if (e.status === 409 && e.code === superadminPlansService.PLAN_IMPACT_CODE) {
      return res.status(409).json({
        message: e.message,
        code: e.code,
        impact: e.impact,
      });
    }
    if (e.status) return res.status(e.status).json({ message: e.message });
    next(e);
  }
});

router.get('/clients/:clientId', async (req, res, next) => {
  try {
    res.json(await superadminService.getClientById(req.params.clientId));
  } catch (e) {
    if (e.status) return res.status(e.status).json({ message: e.message });
    next(e);
  }
});

router.patch('/clients/:clientId', requireCsrf, async (req, res, next) => {
  try {
    const row = await superadminService.updateClient({
      clientId: req.params.clientId,
      name: req.body?.name,
    });
    auditService.logSecurityEvent({
      eventType: 'superadmin_client_updated',
      userId: req.user.id,
      clientId: row?.id || null,
      ipAddress: clientIp(req),
      userAgent: req.headers['user-agent'] || null,
      metadata: { clientName: row?.name || null },
    });
    res.json(row);
  } catch (e) {
    if (e.status) return res.status(e.status).json({ message: e.message });
    next(e);
  }
});

router.post('/clients/:clientId/status', requireCsrf, async (req, res, next) => {
  try {
    const row = await superadminService.setClientStatus({
      clientId: req.params.clientId,
      status: req.body?.status,
    });
    auditService.logSecurityEvent({
      eventType: 'superadmin_client_status_changed',
      userId: req.user.id,
      clientId: row?.id || null,
      ipAddress: clientIp(req),
      userAgent: req.headers['user-agent'] || null,
      metadata: { clientName: row?.name || null, status: row?.status || null },
    });
    res.json(row);
  } catch (e) {
    if (e.status) return res.status(e.status).json({ message: e.message });
    next(e);
  }
});

router.get('/clients', async (req, res, next) => {
  try {
    const rows = await superadminService.listClients();
    res.json(rows);
  } catch (e) {
    next(e);
  }
});

router.post('/clients', requireCsrf, async (req, res, next) => {
  try {
    const b = req.body || {};
    const row = await superadminService.createClientWithAdmin({
      clientName: b.client_name,
      planId: b.plan_id,
      licenseStartsOn: b.license_starts_on,
      billingAnchorDay: b.billing_anchor_day,
      trialDaysOverride: b.trial_days_override,
      adminEmail: b.admin_email,
      adminPasswordPlain: b.admin_password,
      adminFirstName: b.admin_first_name,
      adminLastName1: b.admin_last_name_1,
      adminLastName2: b.admin_last_name_2,
      createdBySuperadminUserId: req.user.id,
    });
    auditService.logSecurityEvent({
      eventType: 'superadmin_client_created',
      userId: req.user.id,
      clientId: row?.id || null,
      identifier: b.admin_email,
      ipAddress: clientIp(req),
      userAgent: req.headers['user-agent'] || null,
      metadata: {
        clientName: row?.name || null,
        planId: row?.plan_id || null,
      },
    });
    res.status(201).json(row);
  } catch (e) {
    if (e.status) return res.status(e.status).json({ message: e.message });
    next(e);
  }
});

router.post('/clients/:clientId/license/renew', requireCsrf, async (req, res, next) => {
  try {
    const row = await superadminService.renewClientLicense({
      clientId: req.params.clientId,
      planId: req.body?.plan_id,
      licenseStartsOn: req.body?.license_starts_on,
      billingAnchorDay: req.body?.billing_anchor_day,
      trialDaysOverride: req.body?.trial_days_override,
    });
    auditService.logSecurityEvent({
      eventType: 'superadmin_license_renewed',
      userId: req.user.id,
      clientId: row?.id || null,
      ipAddress: clientIp(req),
      userAgent: req.headers['user-agent'] || null,
      metadata: {
        planId: row?.plan_id || null,
        licenseExpiresOn: row?.license_expires_on || null,
      },
    });
    res.json(row);
  } catch (e) {
    if (e.status) return res.status(e.status).json({ message: e.message });
    next(e);
  }
});

router.post('/session/tenant', requireCsrf, async (req, res, next) => {
  const clientId = String(req.body?.client_id || '').trim();
  if (!clientId) {
    return res.status(400).json({ message: 'client_id es obligatorio.' });
  }
  try {
    const ok = await authService.setSessionActingClient({
      sessionId: req.auth.sessionId,
      superadminUserId: req.user.id,
      actingClientId: clientId,
    });
    if (!ok) {
      return res.status(404).json({ message: 'No se pudo asignar la organización (sesión o cliente inválido).' });
    }
    const tokenHash = req.auth.tokenHash;
    const row = await authService.findActiveSessionByTokenHash(tokenHash);
    if (!row) {
      return res.status(401).json({ message: 'Sesión inválida.' });
    }
    auditService.logSecurityEvent({
      eventType: 'superadmin_tenant_selected',
      userId: req.user.id,
      clientId: clientId,
      ipAddress: clientIp(req),
      userAgent: req.headers['user-agent'] || null,
      metadata: { actingClientId: clientId },
    });
    return res.json(authService.mapUserPayloadFromSessionRow(row));
  } catch (e) {
    next(e);
  }
});

router.delete('/session/tenant', requireCsrf, async (req, res, next) => {
  const clearedActingClientId = req.user?.actingClientId || null;
  try {
    await authService.clearSessionActingClient({
      sessionId: req.auth.sessionId,
      superadminUserId: req.user.id,
    });
    const tokenHash = req.auth.tokenHash;
    const row = await authService.findActiveSessionByTokenHash(tokenHash);
    if (!row) {
      return res.status(401).json({ message: 'Sesión inválida.' });
    }
    auditService.logSecurityEvent({
      eventType: 'superadmin_tenant_cleared',
      userId: req.user.id,
      clientId: clearedActingClientId,
      ipAddress: clientIp(req),
      userAgent: req.headers['user-agent'] || null,
      metadata: { clearedActingClientId },
    });
    return res.json(authService.mapUserPayloadFromSessionRow(row));
  } catch (e) {
    next(e);
  }
});

module.exports = router;
