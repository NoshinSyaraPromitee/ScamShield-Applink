// Tiny local stand-in for AppLink's /sms/send so the backend can "send" SMS on
// localhost. It only prints each message. Our own script, not part of
// Applink-as-a-Skill.   Usage: node scripts/mock-sms.js   (listens on :7000)
require('http').createServer((req, res) => {
  let body = '';
  req.on('data', (d) => (body += d));
  req.on('end', () => {
    const j = JSON.parse(body || '{}');
    console.log('SMS ->', j.destinationAddresses, '|', j.message);
    res.setHeader('content-type', 'application/json');
    res.end(JSON.stringify({ statusCode: 'S1000', statusDetail: 'Success' }));
  });
}).listen(7000, () => console.log('mock SMS on :7000'));
