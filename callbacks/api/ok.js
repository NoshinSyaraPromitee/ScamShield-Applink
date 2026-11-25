export default function handler(req, res) {
  console.log(req.method, req.url, JSON.stringify(req.body ?? {}));
  res.status(200).json({ statusCode: 'S1000', statusDetail: 'Success' });
}
