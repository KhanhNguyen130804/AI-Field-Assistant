[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$SiteKey,
    [string]$KeystorePath = (Join-Path $env:USERPROFILE 'ai-field-release.jks'),
    [string]$PasswordFile = (Join-Path $env:USERPROFILE '.ai-field-assistant\release-signing-password.dpapi'),
    [string]$KeyAlias = 'upload'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ([string]::IsNullOrWhiteSpace($SiteKey) -or $SiteKey -match '[<>\s]') {
    throw 'Provide the public Android site key registered for this Firebase app, not a placeholder.'
}
if (-not (Test-Path -LiteralPath $KeystorePath) -or -not (Test-Path -LiteralPath $PasswordFile)) {
    throw 'Private signing material missing. Prepare it outside Git first.'
}

$repoRoot = [IO.Path]::GetFullPath((Split-Path $PSScriptRoot -Parent))
$privateKeystore = [IO.Path]::GetFullPath($KeystorePath)
$privatePasswordFile = [IO.Path]::GetFullPath($PasswordFile)
foreach ($privatePath in @($privateKeystore, $privatePasswordFile)) {
    if ($privatePath.StartsWith($repoRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Keep private signing files outside the repository.'
    }
}
$signingVariables = @('AI_FIELD_KEYSTORE_PATH', 'AI_FIELD_KEY_ALIAS', 'AI_FIELD_STORE_PASSWORD', 'AI_FIELD_KEY_PASSWORD')
$previousVariables = @{}
foreach ($variable in $signingVariables) {
    $previousVariables[$variable] = [Environment]::GetEnvironmentVariable($variable, 'Process')
}

Push-Location $repoRoot
$plainPassword = $null
try {
    $encryptedPassword = (Get-Content -LiteralPath $privatePasswordFile -Raw).Trim()
    $securePassword = ConvertTo-SecureString -String $encryptedPassword
    $plainPassword = (New-Object Net.NetworkCredential('', $securePassword)).Password
    [Environment]::SetEnvironmentVariable('AI_FIELD_KEYSTORE_PATH', $privateKeystore, 'Process')
    [Environment]::SetEnvironmentVariable('AI_FIELD_KEY_ALIAS', $KeyAlias, 'Process')
    [Environment]::SetEnvironmentVariable('AI_FIELD_STORE_PASSWORD', $plainPassword, 'Process')
    [Environment]::SetEnvironmentVariable('AI_FIELD_KEY_PASSWORD', $plainPassword, 'Process')
    $flutterOutput = & flutter --suppress-analytics build apk --release --no-pub "--dart-define=APP_CHECK_ANDROID_SITE_KEY=$SiteKey" 2>&1
    $flutterExit = $LASTEXITCODE
    foreach ($line in $flutterOutput) {
        $safeLine = ([string]$line).Replace($SiteKey, '[PUBLIC_SITE_KEY]').Replace($plainPassword, '[REDACTED]')
        if ($safeLine -notmatch '(?i)debug.*token') { Write-Output $safeLine }
    }
    if ($flutterExit -ne 0) { throw ('Release build failed, exit=' + $flutterExit) }

    $apkSource = Join-Path $repoRoot 'build\app\outputs\flutter-apk\app-release.apk'
    if (-not (Test-Path -LiteralPath $apkSource)) { throw 'Release output APK missing.' }
    $versionLine = Get-Content -LiteralPath (Join-Path $repoRoot 'pubspec.yaml') | Where-Object { $_ -match '^version:\s*' }
    $version = ($versionLine -replace '^version:\s*', '').Trim()
    if ($version -notmatch '^\d+\.\d+\.\d+\+\d+$') { throw 'Unexpected application version.' }
    $bundleDirectory = Join-Path $repoRoot 'build\submission'
    if (-not (Test-Path -LiteralPath $bundleDirectory)) { New-Item -ItemType Directory -Path $bundleDirectory | Out-Null }
    $apkDestination = Join-Path $bundleDirectory ("ai-field-assistant-$version.apk")
    Copy-Item -LiteralPath $apkSource -Destination $apkDestination
    $sourceHash = (Get-FileHash -LiteralPath $apkSource -Algorithm SHA256).Hash
    $destinationHash = (Get-FileHash -LiteralPath $apkDestination -Algorithm SHA256).Hash
    if ($sourceHash -ne $destinationHash) { throw 'Copied artifact checksum mismatch.' }
    "$destinationHash  $([IO.Path]::GetFileName($apkDestination))" | Set-Content -LiteralPath (Join-Path $bundleDirectory 'SHA256SUMS.txt') -Encoding UTF8

    # Product file hashes identify the build input even before a final commit.
    $productFiles = & git ls-files --cached --others --exclude-standard -- lib android tools pubspec.yaml pubspec.lock .gitignore
    $productHashes = @($productFiles | Sort-Object -Unique | ForEach-Object {
        if (Test-Path -LiteralPath $_ -PathType Leaf) {
            [ordered]@{path = $_; sha256 = (Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash}
        }
    })
    $sourceRevision = (& git rev-parse HEAD).Trim()
    $metadata = [ordered]@{
        version = $version
        package = 'com.example.ai_field_assistant'
        apk = [IO.Path]::GetFileName($apkDestination)
        bytes = (Get-Item -LiteralPath $apkDestination).Length
        sha256 = $destinationHash
        source_base_commit = $sourceRevision
        source_product_files = $productHashes
        signing = 'dedicated release key; certificate verification required separately'
        app_check = 'Android reCAPTCHA; runtime verification required separately'
        ai_device_verified = $false
    }
    $metadata | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $bundleDirectory 'BUILD_MANIFEST.json') -Encoding UTF8
    Write-Output ('Prepared local APK: ' + $apkDestination)
    Write-Output ('SHA-256: ' + $destinationHash)
} finally {
    foreach ($variable in $signingVariables) {
        [Environment]::SetEnvironmentVariable($variable, $previousVariables[$variable], 'Process')
    }
    $plainPassword = $null
    $securePassword = $null
    Pop-Location
}
