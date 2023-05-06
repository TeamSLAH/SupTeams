param (
    [Switch] $Force,
    [Switch] $NoLoad
)
if ($Force) {
    $Global:_Teams = $null
    $Global:_TeamsConnection = $null
    Disconnect-MicrosoftTeams
}
# Files
function LoadMSTeams {
    param(
        [Switch] $Force
    )
    $teams = $null
    if ($Force) {
        $Global:_Teams = $null
    }
    try {
        (Get-Team | Where-Object { $_.DisplayName -ne $null })
    }
    catch {
        Write-Host "Verbinde mit MS Teams." -ForegroundColor Red
        Write-Host "Account im Browser wählen, Browser/Tab schließen und dieses Fenster wieder aktivieren" -ForegroundColor White
        Write-Host "<Enter> zum fortfahren" -NoNewline
        Read-Host
        $connection = Connect-MicrosoftTeams
        $Global:_TeamsConnection = $connection
        (Get-Team | Where-Object { $_.DisplayName -ne $null })
    }
}

function testxx() {
    $teams = $null
    LoadMSTeams -Force
}




function GetTeam {
    param(
        $Name
    )
    LoadCfg
    [Team]::new($Name)
}

function LoadCfg {
    $Global:TeamsCfg = (ConvertFrom-Json (Get-Content $cfgjson -Raw))
}

function SaveCfg {
    param (
        $cfg
    )
    $s = (ConvertTo-Json $cfg -Depth 10)
    Set-Content $cfgjson $s
}

class Group {
    [String] $Name
    [User[]] $Users

    Group([String] $Name, [User[]] $Users) {
        $this.Name = $Name
        $this.Users = $Users
    }
    Group($obj) {
        $this.Name = $obj.Name
        $this.Users = @()
        foreach ($user in $obj.Users) {
            if ($user.StartsWith("*")) {
                $user = $user.SubString(1)
                $group = [Group]::new($user)
                foreach ($group_user in $group.Users) {
                    $this.Users += $group_user
                }
            }
            else {
                $this.Users += $user
            }
        }
    }
    Group([String] $Name) {
        $result = $Global:TeamsCfg.Groups | Where-Object { $_.Name -eq $Name }
        $this.Name = $Name
        $this.Users = @()
        foreach ($grp in $result) {
            $group = [Group]::new($grp)
            foreach ($group_user in $group.Users) {
                if (-not ($this.Users.ID -contains $group_user.ID)) {
                    $this.Users += $group_user
                }
            }
        }
    }

}

class User {
    [String] $ID

    User([String] $ID) {
        $this.ID = $ID
    }
}

class Team {
    [String] $Name
    [String] $ID
    [String] $Description
    [String] $Logo
    [User[]] $Users
    [Channel[]] $Channels

    Team([String] $Name, [String] $ID, [String] $Description, [String] $Logo, [User[]] $Users, [Channel[]] $Channels) {
        $this.Name = $Name
        $this.ID = $ID
        $this.Description = $Description
        $this.Logo = $Logo
        $this.Users = $Users
        $this.Channels = $Channels
    }
    Team($obj) {
        $this.Name = $obj.Name
        $this.ID = $obj.ID
        $this.Description = $obj.Description
        $this.Logo = $obj.Logo
        $this.Users = @()
        foreach ($user in $obj.Users) {
            if ($user.StartsWith("*")) {
                $user = $user.SubString(1)
                $group = [Group]::new($user)
                foreach ($group_user in $group.Users) {
                    $this.Users += $group_user
                }
            }
            else {
                $this.Users += $user
            }
        }
        $this.Channels = @()
        foreach ($chn in $obj.Channels) {
            if ($chn -is [String]) {
                if ($chn.StartsWith("*")) {
                    $chn = $chn.SubString(1)
                }

                $template = [ChannelTemplate]::new($chn)
                foreach ($tmp_channel in $template.Channels) {
                    $this.Channels += $tmp_channel
                }
            }
            else {
                $this.Channels += [Channel]::new($chn.Name, $chn.Description, $chn.Settings)
            }
        }
    }
    Team([String] $Name) {
        $result = $Global:TeamsCfg.Teams | Where-Object { $_.Name -eq $Name }
        $this.Name = $Name
        $this.Users = @()
        $this.Channels = @()
        foreach ($team in $result) {
            $this.ID = $team.ID
            $this.Description = $team.Description
            $this.Logo = $team.Logo
            foreach ($user in $team.Users) {
                if ($user.StartsWith("*")) {
                    $user = $user.Substring(1)
                    $group = [Group]::new($user)
                    foreach ($group_user in $group.Users) {
                        if (-not ($this.Users.ID -Contains $group_user.ID)) {
                            $this.Users += $group_user
                        }
                    }
                }
                else {
                    if (-not ($this.Users.ID -Contains $user)) {
                        $this.Users += $user
                    }
                }
            }
            foreach ($chn in $team.Channels) {
                if ($chn -is [String]) {
                    if ($chn.StartsWith("*")) {
                        $chn = $chn.SubString(1)
                    }

                    $template = [ChannelTemplate]::new($chn)
                    foreach ($tmp_channel in $template.Channels) {
                        if (-not ($this.Channels.Name -Contains $tmp_channel.Name)) {
                            $this.Channels += $tmp_channel
                        }
                    }
                }
                else {
                    if (-not ($this.Channels.Name -Contains $chn)) {
                        $this.Channels += [Channel]::new($chn.Name, $chn.Description, $chn.Settings)
                    }
                }
            }
        }
    }
}

class Channel {
    [String] $Name
    [String] $Description
    [Object[]] $Settings
    Channel([String] $Name, [String] $Description, [Object[]] $Settings) {
        $this.Name = $Name
        $this.Description = $Description
        $this.Settings = $Settings
    }
}

class ChannelTemplate {
    [String] $Name
    [Channel[]] $Channels

    ChannelTemplate([String] $Name, [Channel[]] $Channels) {
        $this.Name = $Name
        $this.Channels = $Channels
    }
    ChannelTemplate($obj) {
        $this.Name = $obj.Name
        $this.Channels = @()
        foreach ($chn in $obj.Channels) {
            if ($chn -is [String]) {
                if ($chn.StartsWith("*")) {
                    $chn = $chn.SubString(1)
                }

                $template = [ChannelTemplate]::new($chn)
                foreach ($tmp_channel in $template.Channels) {
                    $this.Channels += $tmp_channel
                }
            }
            else {
                $this.Channels += [Channel]::new($chn.Name, $chn.Description, $chn.Settings)
            }
        }
    }
    ChannelTemplate([String] $Name) {
        $result = $Global:TeamsCfg.ChannelTemplates | Where-Object { $_.Name -eq $Name }
        $this.Name = $Name
        $this.Channels = @()
        foreach ($tmp in $result) {
            $chn = [ChannelTemplate]::new($tmp)
            foreach ($tmp_channel in $chn.Channels) {
                if (-not ($this.Channels.Name -Contains $tmp_channel.Name)) {
                    $this.Channels += $tmp_channel
                }
            }
        }
    }
}


# Install-Module -Name MicrosoftTeams -AllowPrerelease -Force
# Install-Module Microsoft.Graph -Scope CurrentUser

# $nt = New-Team -DisplayName Test -Description "Test via PS" -Owner "carsten.schlegel@suportis.com"
# Set-TeamPicture -GroupId $nt.GroupID -ImagePath (Resolve-Path ./logo.png)
# $nc = (New-TeamChannel -GroupId $nt.GroupID -DisplayName "Ankündigungen 📢" -Description "Verwenden Sie diesen Kanal, um wichtige Team- und Ereignisankündigungen zu veröffentlichen." -MembershipType Standard)

function Import-UserExportArgumentCompleter {
    param(
        $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters
    )
 
    try {
        $wordToComplete = $wordToComplete.ToUpper()
        $dlDir = (Resolve-Path "~/downloads")
        $csvFiles = (Get-ChildItem (Join-Path $dlDir "*.csv")).Name
        foreach ($file in $csvFiles) {
            if ($file.ToUpper().StartsWith($wordToComplete)) {
                $rv = New-Object System.Management.Automation.CompletionResult (
                    $file,
                    $file,
                    "ParameterValue",
                    $file
                )
                $rv
            }
        }
    }
    catch {
        return
    }
}
    
<#
.SYNOPSIS
Importieren von User Exports vom Microsoft Intune Admin Center

.DESCRIPTION
Mit Parameter -OpenAdminCenter öffnet sich das Mircosoft Intune Admin Center mit der Userliste. Dort über der Tabelle 'Benutzer herunterladen' klicken und die Schritte folgen.
Die Export-CSV Datei in den Download Ordner speichern.
Anschließend diesen Befehl erneut ausführen und den Dateinamen des Downloads angeben (Tab/Strg+Space zur Vervollständigung)

.PARAMETER CsvExportFile
Dateiname (Download-Ordner) oder kompletter Pfad zur heruntergeladenen Benutzer-Liste (csv Datei)

.PARAMETER OpenAdminCenter
Microsoft Intune Admin Center im Browser öffnen

.EXAMPLE
Import-UserExport exportUsers_2023-4-28.csv

.EXAMPLE
Import-UserExport -OpenAdminCenter

.NOTES
Importiere User werden automatisch zu anderen Nutzern der Suportis Teams Verwaltung Synchronisiert (Sync-SuportisTeams nzw. stsync)
#>
function Import-UserExport {
    [CmdletBinding()]
    [Alias("iue", "tsi", "sti")]
    param(
        [ArgumentCompleter({ Import-UserExportArgumentCompleter @args })]
        [string] $CsvExportFile,
        [Switch] $OpenAdminCenter
    )
    if ($OpenAdminCenter) {
        OpenWebBrowser "https://devicemanagement.portal.azure.com/#view/Microsoft_AAD_UsersAndTenants/UserManagementMenuBlade/~/AllUsers"
        return
    }
    
    $dest = $null
    if (Test-Path $CsvExportFile) {
        $dest = $CsvExportFile
    }
    else {
        $dlDir = (Resolve-Path "~/downloads")
        $CsvExportFile = (Join-Path $dlDir $CsvExportFile)
        if (Test-Path $CsvExportFile) {
            $dest = $CsvExportFile
        }
    }
    if ($dest -eq $null) {
        Write-Host "Keine oder keine gültige User-Liste (" -ForegroundColor Red -NoNewline
        Write-Host "z.B. exportUser_2023-4-28.csv" -ForegroundColor Cyan -NoNewline
        Write-Host ") angegeben/gefunden" -ForegroundColor Red
        Write-Host "Abbruch" -ForegroundColor Red
        return
    }
    $obj = (ConvertFrom-Csv (Get-Content $dest -Raw))
    $json = (ConvertTo-Json $obj -Depth 10)
    Set-Content -PassThru $userjson -Value $json
}
function  Edit-Team {
    [CmdletBinding()]
    [Alias("tst", "stt", "Team")]
    param(
        [ArgumentCompleter({ TeamListArgumentCompleter @args })]
        [string] $Team
    )
    LoadCfg
    $grpJS = $Global:TeamsCfg.Teams | Where-Object { $_.Name -eq $Team }
    $grpObj = [Team]::new($Team)

    EditUserListObject -grpJS $grpJS -allUsers $grpObj.Users.ID -title "Team"
}

function Edit-Group {
    [CmdletBinding()]
    [Alias("tsg", "stg", "Gruppe")]
    param(
        [ArgumentCompleter({ GroupListArgumentCompleter @args })]
        [string] $Gruppe
    )
    LoadCfg
    $grpJS = $Global:TeamsCfg.Groups | Where-Object { $_.Name -eq $Gruppe }
    $grpObj = [Group]::new($Gruppe)

    EditUserListObject -grpJS $grpJS -allUsers $grpObj.Users.ID -title "Gruppe"
}
function EditUserListObject {
    param(
        $grpJS,
        $allUsers,
        $title
    )

    $changes = $false
    while ($true) {
        Clear-Host
        Write-Host "$($title): $($grpJS.Name)"
        Write-Host "----------------------------------------------------------------------------------------------------"
        $nr = 1
        foreach ($user in $grpJS.Users) {
            $nrs = ($nr.ToString())
            $nrs = (" " * (3 - ($nrs.Length))) + $nrs
            Write-Host "$nrs. " -ForegroundColor Yellow -NoNewline
            if ($user.StartsWith("*")) {
                Write-Host "Gruppe: $($user.SubString(1))"
            }
            else {
                Write-Host $user
            }
            $nr++
        }
        Write-Host
        Write-Host "Nr. Eingabe für Benutzer löschen/Gruppe löschen oder Gruppe bearbeiten"
        Write-Host "Namenseingabe (Vorname, Nachname oder /<RegEx>) um Benutzer oder Gruppe hinzuzufügen."

        $e = Read-Host "Nr/Name/q für Ende"
        if ($e -eq "q") {
            if ($changes) {
                $e = Read-Host "Änderungen speichern? (j/N)"
                if ($e -eq "J") {
                    SaveCfg $Global:TeamsCfg
                }
            }
            break;
        }
        $nr = -1
        if ([int]::TryParse($e, [ref]$nr)) {
            if ($nr -gt 0 -and $nr -le $grpJS.Users.Length) {
                $nr--
            }
            else {
                $nr = -1
            }
        }
        else {
            $nr = -1
        }
        if ($nr -gt -1) {
            # Nummerneingabe
            $name = $grpJS.Users[$nr]
            if ($name.StartsWith("*")) {
                $e = Read-Host "Gruppe $($name.SubString(1)) löschen? (j/N)"
                if ($e -eq "J") {
                    $arrayList = [System.Collections.ArrayList]::new($grpJS.Users)
                    $arrayList.RemoveAt($nr)
                    $grpJS.Users = $arrayList.ToArray()
                    $changes = $true
                }
            }
            else {
                $e = Read-Host "Benutzer $($name) löschen? (j/N)"
                if ($e -eq "J") {
                    $arrayList = [System.Collections.ArrayList]::new($grpJS.Users)
                    $arrayList.RemoveAt($nr)
                    $grpJS.Users = $arrayList.ToArray()
                    $changes = $true
                }
            }
        }
        else {
            # Namenseingabe
            $names = (SelectUser $e)
            foreach ($newUser in $names) {
                if ($newUser.StartsWith("*")) {
                    if ($newUser.SubString(1) -ne $grpJS.Name) {
                        # ALT - Benutzer der Gruppe hinzufügen
                        # $group = [Group]::new($newUser.SubString(1))
                        # foreach ($newUser2 in $group.Users) {
                        #     if (-not ($allUsers -Contains $newUser2.ID)) {
                        #         $grpJS.Users += $newUser2.ID
                        #     }
                        # }
                    
                        # Neu: Gruppe selbst hinzufügen
                        if (-not ($grpJS.Users -Contains $newUser)) {
                            $changes = $true
                            $grpJS.Users += $newUser
                        }
                    }
                }
                else {
                    if (-not ($allUsers -Contains $newUser)) {
                        $grpJS.Users += $newUser
                        $changes = $true
                    }
                }
            }
        }
    }
}
function FindUser {
    param(
        $name
    )
    $userlist = (ConvertFrom-Json (Get-Content $userjson -Raw))
    $possible = @()
    if (-not ($name.StartsWith("/"))) {
        $userlist | Where-Object { ($_.givenName -eq $name) -or ($_.surname -eq $name) -or ($_.displayName -eq $name) } | ForEach-Object { $possible += $_.userPrincipalName }
        $Global:TeamsCfg.Groups | Where-Object { $_.Name -eq $name } | ForEach-Object { $possible += "*$($_.Name)" }
        if ($possible.Count -eq 0) {
            $name = "/$name"
        }
    }
    if ($name.StartsWith("/")) {
        $name = $name.SubString(1)
        $name = $name.Replace(".*", "*").Replace("*", ".*")
        $userlist | Where-Object { ($_.userPrincipalName -match $name) -or ($_.displayName -match $name) } | ForEach-Object { $possible += $_.userPrincipalName }
        $Global:TeamsCfg.Groups | Where-Object { $_.Name -match $name } | ForEach-Object { $possible += "*$($_.Name)" }
    }
    $possible
}
function SelectUser {
    param(
        $name
    )
    $possible = (FindUser $name)
    if ($possible -is [String]) {
        $possible = @($possible)
    }
    $nr = 1
    foreach ($user in $possible) {
        $nrs = ($nr.ToString())
        $nrs = (" " * (3 - ($nrs.Length))) + $nrs
        Write-Host "$nrs. " -ForegroundColor Yellow -NoNewline
        if ($user.StartsWith("*")) {
            Write-Host "Gruppe:   $($user.SubString(1))" -ForegroundColor Green
        }
        else {
            Write-Host "Benutzer: $user" -ForegroundColor Cyan
        }
        $nr++
    }
    Write-Host
    $e = (Read-Host "Nr. oder Nr,Nr,Nr... für Auswahl/keine Eingabe=Ende")

    if ($e -eq "") {
        return
    }
    $rv = @()
    $nrs = $e.Split(",").Trim()
    foreach ($e in $nrs) {
        if ([int]::TryParse($e, [ref] $nr)) {
            if ($nr -gt 0 -and $nr -le $possible.Length) {
                $rv += $possible[$nr - 1]
            }
        }
    }
    $rv
}

function GroupListArgumentCompleter {
    param(
        $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters
    )


    LoadCfg
    $wordToComplete = $wordToComplete.ToUpper()
    foreach ($group in $Global:TeamsCfg.Groups) {
        if ($group.Name.ToUpper().StartsWith($wordToComplete)) {
            New-Object System.Management.Automation.CompletionResult (
                $group.Name,
                $group.Name,
                "ParameterValue",
                $group.Name
            )
        }
    }
 
 
}
function TeamListArgumentCompleter {
    param(
        $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters
    )


    LoadCfg
    $wordToComplete = $wordToComplete.ToUpper()
    foreach ($team in $Global:TeamsCfg.Teams) {
        if ($team.Name.ToUpper().StartsWith($wordToComplete)) {
            New-Object System.Management.Automation.CompletionResult (
                $team.Name,
                $team.Name,
                "ParameterValue",
                $team.Name
            )
        }
    }
}


function GetApiTeam {
    param(
        $groupid
    )
    $try = 0
    while ($true) {
        $try++
        if ($try -gt 30) {
            return $null
        }
        try {
            $teams = (Get-Team -GroupID $groupid)
            if ($try -gt 1) {
                Write-Host
            }
            return $teams
        }
        catch {
            Write-Host "." -NoNewline
            Start-Sleep -Milliseconds 50
        }
    }
}
function Update-Teams {
    [CmdletBinding()]
    [Alias("tsu", "stu")]
    param(

    )
    
    LoadCfg
    $try = 0
    $change = $false
    while ($true) {
        $emptyID = ($Global:TeamsCfg.Teams | Where-Object { $_.ID -eq "" })
        if ($emptyID.Length -eq 0) {
            break   
        }
        $try++
        if ($try -gt 0) {
            Write-Host "Erneuter Versuch die Teams abzufragen..." -ForegroundColor Red
        }
        if ($try -gt 10) {
            Write-Host "Folgende Teams konnten nicht gefunden werden:" -ForegroundColor Red
            foreach ($team in $emptyID) {
                Write-Host "  - $($team.Name)" -ForegroundColor Red
            }
            Write-Host
            Write-Host "Bitte fehlende Teams anlegen, Einstellungen prüfen oder erneut probieren."
            return
        }
        $teams = (LoadMSTeams -Force)
        foreach ($team in $emptyID) {
            $groupid = (($teams | Where-Object { $_.DisplayName -eq $team.Name }).GroupID)
            if ($groupid -ne $null) {
                $team.ID = $groupid
                $change = $true
            }
        }
    }
    if ($change) {
        SaveCfg $Global:TeamsCfg
    }
    Clear-Host
    $errors = $false
    foreach ($t in $Global:TeamsCfg.Teams) {
        $teamObj = GetTeam($t.Name)
        Write-Debug "1:Get-Team" 
        $teamAPI = (GetApiTeam $t.ID)
        if ($teamAPI -eq $null) {
            Write-Host "Team $($teamObj.Name) existiert nicht oder Fehler bei der Datenübertragung!" -foregroundColor Red
            $errors = $true
            continue
        }

        Write-Host "Team " -ForegroundColor Magenta -NoNewline
        Write-Host "$($teamObj.Name)" -ForegroundColor Cyan -NoNewline
        Write-Host " wird upgedatet..." -ForegroundColor Magenta
        if ($teamAPI.DisplayName -ne $teamObj.Name) {
            # Neuer Name/DisplayName
            Write-Host "   Name wird geändert" -ForegroundColor Gray
            Write-Debug "2:Set-Team DisplayMessage" 
            Set-Team -GroupId $teamObj.ID -DisplayName $teamObj.Name 
        }
        if ($teamAPI.Description -ne $teamObj.Description) {
            # Neue Beschreibung
            Write-Host "   Beschreibung wird geändert" -ForegroundColor Gray
            Write-Debug "3:Set-Team Description"
            Set-Team -GroupId $teamObj.ID -Description $teamObj.Description
        }
        if ($teamObj.Logo -ne "" -and $teamObj.Logo -ne $null) {
            $logo = $teamObj.Logo
            if (-Not (Test-Path $logo)) {
                $logo = (ModPath $logo)
            }
            if (Test-Path $logo) {
                $try = 0
                Write-Host "   Logo wird festgelegt" -ForegroundColor Gray
                while ($try -lt 3) {
                    $try++
                    try {
                        Write-Debug "4:Set-TeamPicture"
                        Set-TeamPicture -GroupId $teamObj.ID -ImagePath (Resolve-Path $logo).Path
                        break
                    }
                    catch {
                        Write-Host "   INTERNER FEHLER" -foregroundColor Red
                        $try++
                        if ($try -lt 3) {
                            Write-Host "   Erneuter Versuch"
                        }
                    }
                }
            }
        }
        if ($false) {
            # Channes werden nicht upgedatet!
            Write-Debug "5:Get-TeamChannel" 
            $existsChannels = (Get-TeamChannel -GroupId $teamObj.ID)
            Write-Host "   Channels werden geupdated..."
            # 1. Nicht vorhanden hinzufügen

            foreach ($chn in $teamObj.Channels) {
                if ($existsChannels.DisplayName -notcontains $chn.Name) {
                    Write-Host "      + Kanal " -foregroundColor Green -NoNewline
                    Write-Host "$($chn.Name)" -foregroundColor Cyan -NoNewline
                    Write-Host " wird hinzugefügt..." -foregroundColor Green 
                    Write-Debug "6:New-TeamChannel"
                    try {
                        $nc = (New-TeamChannel -GroupId $teamObj.ID -DisplayName $chn.Name -Description $chn.Description -MembershipType Standard)
                    }
                    catch {
                        Write-Host "      ! Fehler beim anlegen des Kanals " -ForegroundColor Red -NoNewline
                        Write-Host "$($teamObj.Name)" -ForegroundColor Cyan -NoNewline
                        Write-Host ":" -ForegroundColor Red
                        $er = $_.Exception.Message
                        $er = ($er.split("`n") | Where-Object { $_.StartsWith("Message") }).Replace("Message: ", "")
                        Write-Host "        $er" -ForegroundColor Red
                    }
                }
            }
            # 2. Nicht mehr vorhandene löschen
            foreach ($chn in $existsChannels) {
                if ($chn.DisplayName -ne "General") {
                    if ($teamObj.Channels.Name -notcontains $chn.DisplayName) {
                        Write-Host "      - Kanal " -ForegroundColor Red -NoNewline
                        Write-Host "$($chn.DisplayName)" -ForegroundColor Cyan -NoNewline
                        Write-Host " wird entfernt..." -ForegroundColor Red
                        Write-Debug "7:Remove-TeamChannel"
                        Remove-TeamChannel -GroupId $teamObj.ID -DisplayName $chn.DisplayName
                    }
                }
            }
        }

        Write-Debug "8:Get-TeamUser" 
        $existsUser = (Get-TeamUser -GroupId $teamObj.ID)
        Write-Host "   Benutzer werden geupdated..."
        # 1. Neue User hinzufügen
        foreach ($user in $teamObj.Users) {
            if ($existsUser.User -notcontains $user.ID) {
                Write-Host "      + Benutzer " -ForegroundColor Yellow -NoNewline
                Write-Host "$($user.ID)" -ForegroundColor Cyan -NoNewline
                Write-Host " wird dem Team hinzugefügt" -ForegroundColor Yellow
                Write-Debug "9:Add-TeamUser" 
                $nu = (Add-TeamUser -GroupId $teamObj.ID -User $user.ID -Role Member)
            }
        }

        # 2. Nicht mehr vorhandene User entfernen
        foreach ($user in $existsUser) {
            if ($teamObj.Users.ID -notcontains $user.user) {
                Write-Host "      - Benutzer " -foregroundColor Red -NoNewline
                Write-Host "$($user.user)" -foregroundColor Cyan -NoNewline
                Write-Host " wird aus dem Team entfernt" -foregroundColor Red
                Write-Debug "10:Remove-TeamUser" 
                Remove-TeamUser -GroupId $teamObj.ID -User $user.user
            }
        }
        Write-Host "   Fertig"
    }
    if ($errors) {
        Write-Host "Ein oder mehrere Fehler sind aufgetreten." -ForegroundColor Red
        Write-Host "Bitte Teams kontrollieren und ggfs. Update-Teams erneut aufrufen" -ForegroundColor Red
    }
}

function ModPath {
    param (
        $add = $null
    )
    if ($add -eq $null) {
        return $PSScriptRoot
    }
    else {
        return (Join-Path $PSScriptRoot $add)
    }
}
function OpenWebBrowser {
    param(
        $url
    )
    if (Test-Path $url) {
        Invoke-Item $url
    }
    else {
        Start-Process $url -Wait
    }
}

$userjson = (ModPath "userlist.json")
$cfgjson = (ModPath "config.json")

if (-not ($NoLoad)) {
    $teams = LoadMSTeams
}

if (-not (Test-Path $userjson)) {
    Write-Host "Bitte zuerst mit Import-UserExport die Benutzer-Liste importieren" -ForegroundColor Red
    Write-Host "Hilfe mit 'Get-Help Import-UserExport -Detailed'" -ForegroundColor Cyan
}
