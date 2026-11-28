# Runs the ScamShield backend against LIVE AppLink.
# Usage (from backend\):  powershell -ExecutionPolicy Bypass -File .\run-live.ps1 [-DemoGuard]
# The API key is asked for every time and never written to disk or git.
param([switch]$DemoGuard)

$ip = Invoke-RestMethod https://api.ipify.org
Write-Host "Public IP: $ip  (must be in AppLink 'Allowed Host Address(es)', else E1303)" -ForegroundColor Yellow

$secure = Read-Host "AppLink API key" -AsSecureString
$env:APPLINK_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
$env:APPLINK_APP_ID = "APP_019198"

$base = "https://api.applink.com.bd"
$env:APPLINK_SMS_URL = "$base/sms/send"
$env:APPLINK_OTP_REQUEST_URL = "$base/otp/request"
$env:APPLINK_OTP_VERIFY_URL = "$base/otp/verify"
$env:APPLINK_SUBSCRIPTION_SEND_URL = "$base/subscription/send"

if ($DemoGuard) { $env:GUARD_REQUIRE_SUB = "false" }

Set-Location $PSScriptRoot
go run ./cmd/server