// AppLink callback relay.
// Always answers AppLink with S1000, and forwards the same request
// (same path + body) to our Go backend at BACKEND_URL.
const BACKEND = (process.env.BACKEND_URL || '').trim().replace(/\/$/, '');
const SECRET = (process.env.RELAY_SECRET || '').trim();
const OK = { statusCode: 'S1000', statusDetail: 'Success' };

export default async function handler(req, res) {
  const path = (req.url || '/').split('?')[0];
  const body = req.body ?? {};

  // Never log bodies: subscription/charging notifications can contain
  // the app password, and SMS bodies are user messages.
  console.log(req.method, path, 'keys=' + Object.keys(body).join(','));

  if (BACKEND && req.method === 'POST') {
    try {
      const r = await fetch(BACKEND + path, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          'X-Relay-Secret': SECRET,
        },
        body: JSON.stringify(body),
        signal: AbortSignal.timeout(4000),
      });
      console.log('relay', path, '->', r.status);
    } catch (e) {
      console.log('relay failed', path, e.message);
    }
  }

  res.status(200).json(OK);
}