# Profile version (Semantic Versioning)
$profileVersion = "1.0.4"

# Constants
Set-Variable -Name GITHUB_PROFILE_URL -Value "https://raw.githubusercontent.com/rendegosling/powershell-profile/main/Microsoft.Powershell_profile.ps1" -Option Constant

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
        Write-Host "Downloading profile from $GITHUB_PROFILE_URL" -ForegroundColor Yellow
        $newProfile = Invoke-WebRequest -Uri $GITHUB_PROFILE_URL -UseBasicParsing | Select-Object -ExpandProperty Content
        Write-Host "Profile content downloaded successfully." -ForegroundColor Yellow
        
        Write-Host "Searching for version in new profile..." -ForegroundColor Yellow
        $newVersionMatch = $newProfile -match '\$profileVersion\s*=\s*"([\d\.]+)"'
        if ($newVersionMatch) {
            $newVersion = $Matches[1]
            Write-Host "New version found: $newVersion" -ForegroundColor Yellow
            
            if ([System.Management.Automation.SemanticVersion]$newVersion -gt [System.Management.Automation.SemanticVersion]$profileVersion) {
                Set-Content -Path $PROFILE -Value $newProfile
                Write-Host "Profile updated successfully to version $newVersion." -ForegroundColor Green
                return $true
            } else {
                Write-Host "Profile is already up to date (version $profileVersion)." -ForegroundColor Green
                return $false
            }
        } else {
            Write-Host "Failed to parse new profile version. Content of new profile:" -ForegroundColor Red
            Write-Host $newProfile
            return $false
        }
    } catch {
        Write-Host "Failed to update profile: $_" -ForegroundColor Red
        Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Red
        return $false
    }
}

# Run the GitHub connection test when PowerShell starts and store the result
$global:GitHubConnected = Test-GitHubConnection

# Update profile if GitHub is reachable and profile hasn't been updated yet
if ($global:GitHubConnected -and -not $global:ProfileUpdated) {
    $updated = Update-Profile
    if ($updated) {
        $global:ProfileUpdated = $true
        Write-Host "Profile has been updated. Please restart PowerShell for changes to take effect." -ForegroundColor Yellow
        return
    }
}

# Profile loaded message
Write-Host "Profile loaded successfully (version $profileVersion). Happy scripting!" -ForegroundColor Green

# Welcome message
Write-Host "Welcome to PowerShell!" -ForegroundColor Cyan