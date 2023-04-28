$teams = $null
try {
    $teams = (Get-Team | Where-Object { $_ -isnot [String] })
}
catch {
    Write-Host "Verbinde mit MS Teams." -ForegroundColor Red
    Write-Host "Account im Browser wählen, Browser/Tab schließen und dieses Fenster wieder aktivieren" -ForegroundColor White
    Write-Host "<Enter> zum fortfahren" -NoNewline
    Read-Host
    $connection = Connect-MicrosoftTeams
    $teams = (Get-Team | Where-Object { $_ -isnot [String] })
}

$testt = $teams | Where-Object { $_.DisplayName -eq "Test" }
$tid = $testt.GroupID
$testc = (Get-TeamChannel -GroupId $testt.GroupId | Where-Object { $_.DisplayName -eq "General" })


# Install-Module -Name MicrosoftTeams -AllowPrerelease -Force


# $nt = New-Team -DisplayName Test -Description "Test via PS" -Owner "carsten.schlegel@suportis.com"
# Set-TeamPicture -GroupId $nt.GroupID -ImagePath (Resolve-Path ./logo.png)
# $nc = (New-TeamChannel -GroupId $nt.GroupID -DisplayName "Ankündigungen 📢" -Description "Verwenden Sie diesen Kanal, um wichtige Team- und Ereignisankündigungen zu veröffentlichen." -MembershipType Standard)
