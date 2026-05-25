const cron = require('node-cron');
const config = require('../config');
const { processExpiredLicenses } = require('../services/client-license.service');

let started = false;

function startLicenseExpiryCron() {
  if (started) return;
  if (config.licenseCronEnabled === false) {
    console.log('[license-cron] deshabilitado (LICENSE_CRON_ENABLED=0)');
    return;
  }

  const schedule = config.licenseCronSchedule;
  const timezone = config.licenseTimezone;

  if (!cron.validate(schedule)) {
    console.error(`[license-cron] expresión cron inválida: ${schedule}`);
    return;
  }

  cron.schedule(
    schedule,
    async () => {
      try {
        const result = await processExpiredLicenses();
        if (result.processed > 0) {
          console.log(
            `[license-cron] ${result.processed} cliente(s) con licencia vencida; sesiones revocadas (${result.today})`
          );
        }
      } catch (e) {
        console.error('[license-cron] error', e);
      }
    },
    { timezone }
  );

  started = true;
  console.log(`[license-cron] programado "${schedule}" (${timezone})`);
}

module.exports = { startLicenseExpiryCron };
