const app = require('./app');
const { port } = require('./config');
const { startLicenseExpiryCron } = require('./jobs/license-expiry.cron');

app.listen(port, () => {
  startLicenseExpiryCron();
  console.log(`API listening on http://localhost:${port}`);
});
