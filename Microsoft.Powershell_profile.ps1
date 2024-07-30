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
}

# Run the GitHub connection test when PowerShell starts
Test-GitHubConnection

# Welcome message
Write-Host "Welcome to PowerShell!" -ForegroundColor Cyan
Write-Host "Profile loaded successfully. Happy scripting!" -ForegroundColor Green
