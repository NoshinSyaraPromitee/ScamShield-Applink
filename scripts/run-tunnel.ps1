# Zero-cost hosting: expose the laptop backend to the Vercel relay with a free
# Cloudflare quick tunnel. Run run-live.ps1 in another window first.
#   1. winget install Cloudflare.cloudflared      (once)
#   2. powershell -ExecutionPolicy Bypass -File scripts\run-tunnel.ps1
#   3. Copy the https://xxxx.trycloudflare.com URL into the Vercel env var
#      BACKEND_URL and redeploy callbacks/. The URL changes on every run.
# Outbound AppLink calls leave from this machine's public IP, which must be in
# the AppLink "Allowed Host Address(es)". Re-check it before the demo.
param([int]$Port = 8080)
Write-Host "Public IP (must be allowed in AppLink): $(Invoke-RestMethod https://api.ipify.org)" -ForegroundColor Yellow
cloudflared tunnel --url "http://localhost:$Port"
