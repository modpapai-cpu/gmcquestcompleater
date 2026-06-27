Set-ExecutionPolicy Bypass -Scope Process -Force
Clear-Host

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "      GMC Vencord Auto Installer" -ForegroundColor White
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# ADMIN CHECK
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()

$principal = New-Object Security.Principal.WindowsPrincipal($identity)

$admin = $principal.IsInRole(
[Security.Principal.WindowsBuiltInRole]::Administrator
)


if(!$admin){
Write-Host "Please Run As Administrator"
pause
exit
}


function RefreshPath {

$env:Path =
[System.Environment]::GetEnvironmentVariable("Path","Machine")+
";"+
[System.Environment]::GetEnvironmentVariable("Path","User")

}



# =========================
# WINGET CHECK (NO FORCE INSTALL)
# =========================

if(Get-Command winget -ErrorAction SilentlyContinue){

Write-Host "[✓] Winget Installed" -ForegroundColor Green

}else{

Write-Host "[WARN] Winget Not Found"
Write-Host "Skipping Winget..."

}


# =========================
# GIT CHECK
# =========================

if(Get-Command git -ErrorAction SilentlyContinue){

Write-Host "[✓] Git Installed" -ForegroundColor Green

}else{

Write-Host "Installing Git..."

$git="$env:TEMP\git.exe"

Invoke-WebRequest `
"https://github.com/git-for-windows/git/releases/download/v2.52.0.windows.1/Git-2.52.0-64-bit.exe" `
-OutFile $git


Start-Process `
$git `
-ArgumentList "/VERYSILENT" `
-Wait


RefreshPath
if(!(Get-Command git -ErrorAction SilentlyContinue)){

Write-Host "Git Install Failed!"
pause
exit

}
}



# =========================
# NODE CHECK
# =========================

if(Get-Command node -ErrorAction SilentlyContinue){

Write-Host "[✓] Node Installed" -ForegroundColor Green

}else{


Write-Host "Installing Node LTS..."


$node="$env:TEMP\node.msi"


Invoke-WebRequest `
"https://nodejs.org/dist/v24.12.0/node-v24.12.0-x64.msi" `
-OutFile $node


Start-Process msiexec.exe `
-ArgumentList "/i `"$node`" /qn" `
-Wait


RefreshPath
if(!(Get-Command npm -ErrorAction SilentlyContinue)){

Write-Host "Node/NPM Install Failed!"
pause
exit

}
}


# =========================
# PNPM 9.15.9 CHECK FIX
# =========================

$needPnpm="9.15.9"

RefreshPath

$pnpmCmd = Get-Command pnpm -ErrorAction SilentlyContinue

if($pnpmCmd){

$currentPnpm = pnpm --version

}else{

$currentPnpm=$null

}


if($currentPnpm -eq $needPnpm){
Write-Host "[✓] PNPM 9.15.9 Installed" -ForegroundColor Green


}else{


if($currentPnpm){

Write-Host "Removing PNPM $currentPnpm"
npm uninstall -g pnpm

}


Write-Host "Installing PNPM 9.15.9..."

npm install -g pnpm@9.15.9

if($LASTEXITCODE -ne 0){

Write-Host "PNPM Download Failed!"
pause
exit

}

RefreshPath


}


$pnpmCmd = Get-Command pnpm -ErrorAction SilentlyContinue


if(!$pnpmCmd){

Write-Host "PNPM install failed!"
pause
exit

}


Write-Host "[OK] PNPM Ready:"
pnpm --version


# =========================
# VENCORD FIX
# =========================

cd C:\


if(!(Test-Path "C:\Vencord\package.json")){

Write-Host "Bad Vencord folder detected, reinstalling..."

if(Test-Path "C:\Vencord"){
Remove-Item "C:\Vencord" -Recurse -Force
}


git clone https://github.com/Vendicated/Vencord.git C:\Vencord

if($LASTEXITCODE -ne 0){

Write-Host "Vencord Download Failed!"
pause
exit

}
}


cd C:\Vencord


Write-Host "[✓] Vencord Ready" -ForegroundColor Green



# =========================
# REMOTE PLUGIN INSTALLER
# =========================

$configUrl="https://pastebin.com/raw/uLhCY0dv"

try{

$config=(Invoke-WebRequest $configUrl -UseBasicParsing).Content

}
catch{

Write-Host "Remote Config Failed!"
$config=""

}
function InstallPlugin($name,$fileId){


if($name -eq "GMCQUESTCOMPLEATER"){
    $path="src\plugins\$name"
}
else{
    $path="src\userplugins\$name"
}


if($config -match "$name=ON"){


Write-Host "$name Enabled - Updating"


$url="https://drive.google.com/uc?export=download&id=$fileId"


$zip="$env:TEMP\$name.zip"

$tmp="$env:TEMP\$name"


$ProgressPreference = 'SilentlyContinue'

try{

(New-Object Net.WebClient).DownloadFile(
$url,
$zip
)

}
catch{

Write-Host "Download Failed!"
pause
exit

}


if(Test-Path $tmp){

Remove-Item $tmp -Recurse -Force

}


try{

Expand-Archive `
$zip `
$tmp `
-Force `
-ErrorAction Stop

}
catch{

Write-Host "ZIP Extract Failed!"
pause
exit

}



if(Test-Path $path){

Remove-Item `
$path `
-Recurse `
-Force

}


mkdir $path


Copy-Item `
"$tmp\*" `
$path `
-Recurse `
-Force


Write-Host "[OK] $name Updated"


}

else{


Write-Host "$name OFF - Skipped (Not Removed)"


}


}


# =========================
# PLUGIN LIST
# =========================
InstallPlugin `
"GMCQUESTCOMPLEATER" `
"1S012lWbNcwhmkRRRLt1tcF4o3e_5dUP8"

InstallPlugin `
"FakeDeafen" `
"1U3MCO7rWoB-zCFw_p-VPqPtTc-kGnwrA"


InstallPlugin `
"voiceChatUtilities" `
"1oqe3nYA85-213T720DHDUJnKnw40rdDl"


InstallPlugin `
"followUser" `
"1mYKd4HSNoz67ZUgKJbycgkxCQx6VVxzP"




# =========================
# BUILD
# =========================


Write-Host ""
Write-Host "Installing Packages..." -ForegroundColor Cyan

pnpm install --no-frozen-lockfile

if($LASTEXITCODE -ne 0){
Write-Host "Package Install Failed!"
pause
exit
}


Write-Host ""
Write-Host "Building Vencord..." -ForegroundColor Blue

pnpm build

if($LASTEXITCODE -ne 0){
Write-Host "Build Failed!"
pause
exit
}


Write-Host "Injecting..."

pnpm inject

if($LASTEXITCODE -ne 0){
Write-Host "Inject Failed!"
pause
exit
}



# =========================
# DISCORD RESTART
# =========================


Write-Host "Restarting Discord..."


$discord="$env:LOCALAPPDATA\Discord\Update.exe"


if(Test-Path $discord){
taskkill /F /IM Discord.exe 2>$null
Start-Sleep -Seconds 2
Start-Process `
$discord `
-ArgumentList "--processStart Discord.exe"

}

Write-Host ""
Write-Host "#############################################" -ForegroundColor Green
Write-Host "#                                           #" -ForegroundColor Green
Write-Host "#      GMC INSTALL COMPLETED SUCCESSFULLY   #" -ForegroundColor White -BackgroundColor DarkGreen
Write-Host "#                                           #" -ForegroundColor Green
Write-Host "#############################################" -ForegroundColor Green
Write-Host ""


pause
