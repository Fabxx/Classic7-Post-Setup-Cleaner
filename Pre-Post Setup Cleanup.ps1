# Cleanup script to re-run Post-Setup executable - Fabxx

# Check if executing as admin, if not obtain admin permissions
$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Start-Process powershell.exe `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
        -Verb RunAs

    exit
}

$script:State = @{
	isBrowserInstalled = 0
    BrowserUninstalled = 0
    AuthUxUninstalled  = 0
    SetupDone          = 0
    Aborted            = 0
}

function selector()
{
	while ($true) {
		Clear-Host
		Write-Host "Select Browser to uninstall:"
		Write-Host "0) Exit"
		Write-Host "1) Uninstall Current Browser"
		
		[int]$selection = Read-Host "Enter a number"

		if ($selection -eq 0) {
			$script:state.Aborted = 1
			export_choices
			return [int]$selection
		} 

		elseif ($selection -eq 1) {
			return [int]$selection
		}

		else {
			Write-Host "Invalid selection!"
			Start-Sleep -Seconds 3
			continue
		}

		break
	}
}

function uninstall_browser()
{
	Write-Host "Checking Browser installation..."
	Get-Process nocturne -ErrorAction SilentlyContinue | Stop-Process -Force
	Get-Process firefox  -ErrorAction SilentlyContinue | Stop-Process -Force

	$uninstallers = @(
		"C:\Program Files\Nocturne\uninstall\helper.exe",
		"C:\Program Files (x86)\Nocturne\uninstall\helper.exe",
		"C:\Program Files\Mozilla Firefox\uninstall\helper.exe",
		"C:\Program Files (x86)\Mozilla Firefox\uninstall\helper.exe"
	)

	$uninstaller = 0

	foreach ($uninstaller in $uninstallers) {
		if (Test-Path $uninstaller) {
			$script:State.isBrowserInstalled = 1
			Write-Host "Running uninstaller..."
			Start-Process $uninstaller -ArgumentList "/S" -Wait -ErrorAction SilentlyContinue
		}
	}

	if ($script:State.isBrowserInstalled -eq 0) {
		Write-Host "No browser is installed, skipping this step..."
		Start-Sleep -Seconds 3
		export_choices
		return 
	}

	$folders = @(
		"C:\Program Files\Nocturne",
		"C:\Program Files (x86)\Nocturne",
		"C:\Program Files\Mozilla Firefox",
		"C:\Program Files (x86)\Mozilla Firefox",

		"$env:ProgramData\Nocturne",
		"$env:ProgramData\Mozilla",
		"$env:APPDATA\Nocturne",
		"$env:APPDATA\Mozilla",
		"$env:APPDATA\Mozilla\Firefox",
		"$env:LOCALAPPDATA\Nocturne",
		"$env:LOCALAPPDATA\Mozilla",
		"$env:LOCALAPPDATA\Mozilla\Firefox",
		"$env:LOCALAPPDATA\Temp\Mozilla*",
		"$env:LOCALAPPDATA\Temp\Firefox*"
	)

	foreach ($folder in $folders) {
		if (Test-Path $folder) {
			Write-Host "Removing $folder"
			Remove-Item $folder -Force -Recurse -ErrorAction SilentlyContinue
		}
	}

	$shortcutPaths = @(
		"$env:PUBLIC\Desktop\Mozilla Firefox.lnk",
		"$env:PUBLIC\Desktop\Firefox.lnk",
		"$env:PUBLIC\Desktop\Nocturne.lnk",
		"$env:PUBLIC\Desktop\Google Chrome.lnk",
		"$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Mozilla Firefox.lnk",
		"$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Mozilla Firefox.lnk",
		"$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Nocturne.lnk",
		"$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Google Chrome\Google Chrome.lnk"
	)

	foreach ($shortcut in $shortcutPaths) {
		if (Test-Path $shortcut) {
			Write-Host "Removing $shortcut"
			Remove-Item $shortcut -Force -ErrorAction SilentlyContinue
		}
	}

    # Uninstall successfull, reset installation state
	$script:State.isBrowserInstalled = 0
	$script:State.BrowserUninstalled = 1
	export_choices
}

function uninstall_authUx()
{
	$authUxPath = "C:\Program Files\AuthUX"

	if (Test-Path $authUxPath) {
		Write-Host "Removing $authUxPath"
		Remove-Item $authUxPath -Recurse -Force -ErrorAction SilentlyContinue
	}

	$script:State.AuthUxUninstalled = 1
	export_choices
}


function setup()
{
	$userProfile = $env:USERPROFILE
	$taskbarFolder = Join-Path $userProfile "AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
	$postSetupFolder = "C:\Classic Files\PostSetup"

	New-Item -ItemType Directory -Force -Path $taskbarFolder | Out-Null
	New-Item -ItemType Directory -Force -Path $postSetupFolder | Out-Null
	
	$ieExe = "C:\Program Files\Internet Explorer\iexplore.exe"
	$shell = New-Object -ComObject WScript.Shell

	if (Test-Path $ieExe) {
		# Internet Explorer.lnk (Taskbar)
		Write-Host "Creating Internet Explorer.lnk"
		$shortcut1 = $shell.CreateShortcut((Join-Path $taskbarFolder "Internet Explorer.lnk"))
		$shortcut1.TargetPath = $ieExe
		$shortcut1.WorkingDirectory = Split-Path $ieExe
		$shortcut1.IconLocation = "$ieExe,0"
		$shortcut1.Save()

		# Internet Explorer FF.lnk (PostSetup)
		Write-Host "Creating Internet Explorer FF.lnk"
		$shortcut2 = $shell.CreateShortcut((Join-Path $postSetupFolder "Internet Explorer FF.lnk"))
		$shortcut2.TargetPath = $ieExe
		$shortcut2.WorkingDirectory = Split-Path $ieExe
		$shortcut2.IconLocation = "$ieExe,0"
		$shortcut2.Save()
	}
	else {
		Write-Host "Internet Explorer executable not found."
	}
	
	# explorer7 folder placeholder, ask for admin permission to add folder under Windows
	$explorer7Path = "C:\Windows\explorer7"

	if (!(Test-Path $explorer7Path)) {
		Write-Host "Creating $explorer7Path (UAC prompt will appear)"
		Start-Process powershell `
		-ArgumentList '-Command "New-Item -ItemType Directory -Path C:\Windows\explorer7 -Force"' `
		-Verb RunAs
	}

	$script:state.SetupDone = 1
	export_choices
}

function run_post_setup()
{
	$setup = "C:\Classic Files\PostSetup\Files\Classic-PostSetup.exe"

	if (!(Test-Path $setup)) {
		Write-Host "Warning: post setup not found, the script cannot run it for you."
		return
	}

	while ($true) {
		Write-Host "Would you like the script to run the post setup for you?"
		Write-Host "1) Yes"
		Write-Host "2) No"

		[int]$val = Read-Host "Enter a number"

		if ($val -eq 1) {
			export_choices
			Write-Host "Running $setup..."
			Start-Process $setup -Wait
		} elseif ($val -eq 2) {
			break
		} else {
			Write-Host "Invalid selection!"
			Start-Sleep -Seconds 3
			continue
		}

		break
	}
}


function export_choices() {

    $iniFile = Join-Path $PSScriptRoot "config.ini"
@"
[Uninstaller]
IS_BROWSER_INSTALLED=$($script:State.isBrowserInstalled)
WAS_BROWSER_UNINSTALLED=$($script:State.BrowserUninstalled)
WAS_AUTHUX_UNINSTALLED=$($script:State.AuthUxUninstalled)
WAS_UNINSTALL_ABORTED=$($script:State.Aborted)
WAS_SETUP_DONE=$($script:State.SetupDone)
"@ | Set-Content $iniFile
}

function import_choices() {
    param(
        [string]$Path
    )

    $ini = @{}
    $section = ""

    foreach ($line in Get-Content $Path) {

        $line = $line.Trim()

        if ($line -match '^\[(.+)\]$') {
            $section = $matches[1]
            $ini[$section] = @{}
        }
        elseif ($line -match '^(.+?)=(.*)$') {
            $ini[$section][$matches[1]] = $matches[2]
        }
    }

    return $ini
}

function check_previous_run()
{
	$ini_path = Join-Path $PSScriptRoot "config.ini"
	$recovery = 0

	if (!(Test-Path $ini_path)) {
		Write-Host "First boot, creating config on exit."
		Start-Sleep 3
		return $recovery
	}

	$cfg = import_choices (Join-Path $PSScriptRoot "config.ini")
	
	$script:State.isBrowserInstalled = [int]$cfg["Uninstaller"]["IS_BROWSER_INSTALLED"]
	$script:State.BrowserUninstalled = [int]$cfg["Uninstaller"]["WAS_BROWSER_UNINSTALLED"]
	$script:State.AuthUxUninstalled  = [int]$cfg["Uninstaller"]["WAS_AUTHUX_UNINSTALLED"]
	$script:State.Aborted            = [int]$cfg["Uninstaller"]["WAS_UNINSTALL_ABORTED"]
	$script:State.SetupDone          = [int]$cfg["Uninstaller"]["WAS_SETUP_DONE"]

	if ($script:state.Aborted -eq 1) {
		Write-Host "Previous cleanup was aborted, no state to recover."
		Start-Sleep -Seconds 3
		return [int]$recovery
	}

	if ($script:state.AuthUxUninstalled -eq 0) {
		Write-Host "AuthUx was not removed, removing authUx..."
		Start-Sleep -Seconds 3
		uninstall_authUx
		$recovery = 1
	}

	if ($script:state.BrowserUninstalled -eq 0) {
		Write-Host "Browser was not removed, removing browser..."
		Start-Sleep -Seconds 3
		uninstall_browser
		$recovery = 1
	}

	if ($script:state.SetupDone -eq 0) {
		Write-Host "Shortcuts were not created, creating shortcuts..."
		Start-Sleep -Seconds 3
		setup
		$recovery = 1
	}

	return [int]$recovery
}


function main()
{
	$is_recovery_necessary = check_previous_run

	if ($is_recovery_necessary -eq 1) {
		run_post_setup
		return
	}

	$selection = selector

	if ($selection -eq 0) {
		return
	}

	$script:State.Aborted = 0

	uninstall_browser
	uninstall_authUx
	setup

	run_post_setup
	Write-Host "Operation complete, you can now re-run Post-Setup."
}

main