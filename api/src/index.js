const app = require('./app');
const { port } = require('./config');
const { startLicenseExpiryCron } = require('./jobs/license-expiry.cron');

app.listen(port, () => {
  startLicenseExpiryCron();
  const publicDir = require('path').join(__dirname, '..', 'public');
  const hasPwa = require('fs').existsSync(publicDir);
  console.log(
    `Wardi escuchando en puerto ${port} (API${hasPwa ? ' + PWA estática en /public' : ''})`
  );
});
