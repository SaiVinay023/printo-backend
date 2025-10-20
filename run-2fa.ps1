# Step 1: Register user
$response_register = Invoke-RestMethod -Method Post http://127.0.0.1:8000/api/register `
  -Headers @{"Content-Type"="application/json"} `
  -Body '{
    "name": "janedoe",
    "email": "jane@example.com",
    "password": "supersecret1",
    "password_confirmation": "supersecret1",
    "first_name": "Jane",
    "last_name": "Doe",
    "full_address": "456 Another St, Example City",
    "street_address": "456 Another St",
    "city": "Example City",
    "country": "Examplestan",
    "zip_code": "67890",
    "mobile_phone_number": "555-5678"
  }'

# Step 2: Login and get access token
$response_login = Invoke-RestMethod -Method Post http://127.0.0.1:8000/api/login `
  -Headers @{"Content-Type"="application/json"} `
  -Body '{"email":"jane@example.com","password":"supersecret1"}'
$access_token = $response_login.access_token

# Step 3: Setup 2FA
$response_2fa = Invoke-RestMethod -Method Post http://127.0.0.1:8000/api/setup-2fa `
  -Headers @{
    "Authorization" = "Bearer $access_token"
    "Content-Type" = "application/json"
  }
$secret = $response_2fa.secret
$qr_image = $response_2fa.qr
$otpauth_url = $response_2fa.otpauth_url

# Save QR code PNG to a file
# Remove the "data:image/png;base64," prefix to get just the base64 data
$base64 = $qr_image -replace '^data:image/png;base64,', ''
[System.IO.File]::WriteAllBytes("2fa-qr.png", [Convert]::FromBase64String($base64))

Write-Host "QR code saved as 2fa-qr.png"
Write-Host "Scan this with Google Authenticator!"
Write-Host "Secret: $secret"
Write-Host "otpauth:// url: $otpauth_url"

# Step 4: Login again to trigger 2FA
$response_login2 = Invoke-RestMethod -Method Post http://127.0.0.1:8000/api/login `
  -Headers @{"Content-Type"="application/json"} `
  -Body '{"email":"jane@example.com","password":"supersecret1"}'
$user_id = $response_login2.user_id
Write-Host "User ID for 2FA verification: $user_id"

# Step 5: Verify 2FA (replace "123456" with your authenticator code!)
$response_verify = Invoke-RestMethod -Method Post http://127.0.0.1:8000/api/verify-2fa `
  -Headers @{"Content-Type"="application/json"} `
  -Body "{""user_id"":$user_id,""code"":""123456""}"
$new_access_token = $response_verify.access_token

# Step 6: Get profile
$response_profile = Invoke-RestMethod http://127.0.0.1:8000/api/profile `
  -Headers @{"Authorization"="Bearer $new_access_token"}
$response_profile | ConvertTo-Json | Write-Host
