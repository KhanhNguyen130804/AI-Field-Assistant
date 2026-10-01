[CmdletBinding()]
param(
    [string]$KeystorePath = (Join-Path $env:USERPROFILE 'ai-field-release.jks'),
    [string]$PasswordFile = (Join-Path $env:USERPROFILE '.ai-field-assistant\release-signing-password.dpapi'),
    [string]$KeytoolPath = 'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repoRoot = [IO.Path]::GetFullPath((Split-Path $PSScriptRoot -Parent))
$keystoreFullPath = [IO.Path]::GetFullPath($KeystorePath)
$passwordFullPath = [IO.Path]::GetFullPath($PasswordFile)
foreach ($privatePath in @($keystoreFullPath, $passwordFullPath)) {
    if ($privatePath.StartsWith($repoRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Keep private signing files outside the repository.'
    }
    if (Test-Path -LiteralPath $privatePath) {
        throw 'Signing material already exists. Reuse it; this script never overwrites it.'
    }
}
if (-not (Test-Path -LiteralPath $KeytoolPath)) { throw 'keytool not found.' }

function Protect-PrivateFile([string]$Path) {
    $acl = New-Object Security.AccessControl.FileSecurity
    $acl.SetAccessRuleProtection($true, $false)
    $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User
    $acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule($sid, 'FullControl', 'Allow')))
    $acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule('SYSTEM', 'FullControl', 'Allow')))
    Set-Acl -LiteralPath $Path -AclObject $acl
}

$previousPassword = [Environment]::GetEnvironmentVariable('AI_FIELD_KEYTOOL_PASSWORD', 'Process')
$plainPassword = $null
try {
    $randomBytes = New-Object byte[] 32
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($randomBytes) } finally { $rng.Dispose() }
    $plainPassword = [Convert]::ToBase64String($randomBytes)
    [Array]::Clear($randomBytes, 0, $randomBytes.Length)
    $securePassword = ConvertTo-SecureString -String $plainPassword -AsPlainText -Force
    $passwordDirectory = Split-Path $passwordFullPath -Parent
    if (-not (Test-Path -LiteralPath $passwordDirectory)) {
        New-Item -ItemType Directory -Path $passwordDirectory | Out-Null
    }
    # DPAPI is tied to this Windows account/machine. Keep an independent safe backup.
    ConvertFrom-SecureString -SecureString $securePassword | Set-Content -LiteralPath $passwordFullPath -Encoding UTF8
    Protect-PrivateFile $passwordFullPath
    [Environment]::SetEnvironmentVariable('AI_FIELD_KEYTOOL_PASSWORD', $plainPassword, 'Process')
    $keytoolOutput = & $KeytoolPath -genkeypair -noprompt -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload -dname 'CN=AI Field Assistant, OU=Mobile, O=AI Field Assistant, C=VN' -keystore $keystoreFullPath -storepass:env AI_FIELD_KEYTOOL_PASSWORD -keypass:env AI_FIELD_KEYTOOL_PASSWORD 2>&1
    if ($LASTEXITCODE -ne 0) { throw 'keytool generation failed; private output withheld.' }
    Protect-PrivateFile $keystoreFullPath
    $verificationOutput = & $KeytoolPath -list -alias upload -keystore $keystoreFullPath -storepass:env AI_FIELD_KEYTOOL_PASSWORD 2>&1
    if ($LASTEXITCODE -ne 0) { throw 'Cannot verify the new signing key.' }
    Write-Output 'Release signing key created and verified. Password stored with Windows DPAPI; no secret printed.'
} finally {
    [Environment]::SetEnvironmentVariable('AI_FIELD_KEYTOOL_PASSWORD', $previousPassword, 'Process')
    $plainPassword = $null
    $securePassword = $null
}
