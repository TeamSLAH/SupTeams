
try {
    ms = (Get-Team -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue | Where-Object { -isnot [String] })
}
catch {
    Write-Host "Login"
}
