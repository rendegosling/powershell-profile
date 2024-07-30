# Profile version (Semantic Versioning)
$profileVersion = "1.0.9"

# Constants
if (-not (Get-Variable -Name GITHUB_PROFILE_URL -ErrorAction SilentlyContinue)) {
    $global:GITHUB_PROFILE_URL = "https://raw.githubusercontent.com/rendegosling/powershell-profile/main/Microsoft.Powershell_profile.ps1"
}

# Flag to prevent infinite loop
if (-not (Get-Variable -Name ProfileUpdated -ErrorAction SilentlyContinue)) {
    $global:ProfileUpdated = $false
}

# Function to ping GitHub and display result
function Test-GitHubConnection {
    $pingResult = Test-Connection -ComputerName github.com -Count 1 -Quiet
    if ($pingResult) {
        Write-Host "GitHub: " -NoNewline
        Write-Host "✓" -ForegroundColor Green
    } else {
        Write-Host "GitHub: " -NoNewline
        Write-Host "✗" -ForegroundColor Red
    }
    return $pingResult
}

# Function to download and update the profile
function Update-Profile {
    try {
        Write-Host "Checking for profile updates..." -ForegroundColor Yellow
        $newProfile = Invoke-WebRequest -Uri $global:GITHUB_PROFILE_URL -UseBasicParsing | Select-Object -ExpandProperty Content
        $newVersionMatch = $newProfile -match '\$profileVersion\s*=\s*"([\d\.]+)"'
        if ($newVersionMatch) {
            $newVersion = $Matches[1]
            Write-Host "Remote version: $newVersion, Local version: $profileVersion" -ForegroundColor Yellow
            if ([System.Management.Automation.SemanticVersion]$newVersion -gt [System.Management.Automation.SemanticVersion]$profileVersion) {
                Write-Host "New profile version found: $newVersion" -ForegroundColor Yellow
                Set-Content -Path $PROFILE -Value $newProfile
                Write-Host "Profile updated successfully to version $newVersion." -ForegroundColor Green
                Write-Host "Reloading profile..." -ForegroundColor Yellow
                . $PROFILE
                return $true
            } else {
                Write-Host "Profile is up to date (version $profileVersion)." -ForegroundColor Green
                return $false
            }
        } else {
            Write-Host "Failed to parse new profile version." -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "Failed to update profile: $_" -ForegroundColor Red
        return $false
    }
}

# Function to check for PowerShell updates and install if available
function Update-PowerShell {
    try {
        $currentVersion = $PSVersionTable.PSVersion
        $metadataUri = "https://raw.githubusercontent.com/PowerShell/PowerShell/master/tools/metadata.json"
        $metadata = Invoke-RestMethod -Uri $metadataUri
        $latestVersion = [System.Management.Automation.SemanticVersion]$metadata.StableReleaseTag.Substring(1)

        if ($latestVersion -gt $currentVersion) {
            Write-Host "New PowerShell version available: $latestVersion" -ForegroundColor Yellow
            Write-Host "Updating PowerShell..." -ForegroundColor Yellow
            $installerUri = "https://github.com/PowerShell/PowerShell/releases/download/v$latestVersion/PowerShell-$latestVersion-win-x64.msi"
            $installerPath = Join-Path $env:TEMP "PowerShell-$latestVersion-win-x64.msi"
            Invoke-WebRequest -Uri $installerUri -OutFile $installerPath
            
            # Run installer with elevated privileges
            Start-Process msiexec.exe -ArgumentList "/i `"$installerPath`" /qn" -Verb RunAs -Wait
            
            Remove-Item $installerPath
            Write-Host "PowerShell updated to version $latestVersion. Please restart your terminal." -ForegroundColor Green
            return $true
        } else {
            Write-Host "PowerShell is up to date (version $currentVersion)." -ForegroundColor Green
            return $false
        }
    } catch {
        Write-Host "Failed to update PowerShell: $_" -ForegroundColor Red
        return $false
    }
}

# Main update process
$global:GitHubConnected = Test-GitHubConnection

if ($global:GitHubConnected -and -not $global:ProfileUpdated) {
    $profileUpdated = Update-Profile
    if ($profileUpdated) {
        $global:ProfileUpdated = $true
        return
    }
}

if ($global:GitHubConnected) {
    # Update PowerShell itself
    $powershellUpdated = Update-PowerShell
    if ($powershellUpdated) {
        Write-Host "Please restart your terminal to use the updated PowerShell version." -ForegroundColor Yellow
    }
}

# Profile loaded message
Write-Host "Profile loaded successfully (version $profileVersion). Happy scripting!" -ForegroundColor Green

# Welcome message
Write-Host "Welcome to PowerShell!" -ForegroundColor Cyan