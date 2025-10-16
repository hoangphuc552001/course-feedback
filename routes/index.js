var express = require('express');
const {fetchInstanceIdentity} = require("../utils/instance-metadata-service");
var router = express.Router();

router.get('/', function(req, res, next) {
  res.render('index', { title: 'Express' });
});

router.get('/health', function(req, res, next) {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

router.get('/whoami', async (req, res) => {
  try {
    const data = await fetchInstanceIdentity();
    res.json({
      ok: true,
      ...data,
      requestId: req.headers['x-amzn-trace-id'] || req.headers['x-request-id'] || null,
      via: req.headers['via'] || null
    });
  } catch (e) {
    res.status(500).json({ ok: false, error: String(e) });
  }
});

module.exports = router;
