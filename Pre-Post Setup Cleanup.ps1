# Cleanup script to re-run Post-Setup executable - Fabxx

function selector()
{
	Write-Host "Select Browser to uninstall:"
	Write-Host "1) Firefox"
	Write-Host "2) Nocturne"
	
	[int]$number = Read-Host "Enter a number"
	
	return $number;
}

function uninstall_nocturne()
{
	$uninstallerFound = 0
	
	Write-Host "Checking Nocturne installation..."
	Get-Process nocturne -ErrorAction SilentlyContinue | Stop-Process -Force

	$uninstallers = @(
		"C:\Program Files\Nocturne\uninstall\helper.exe",
		"C:\Program Files (x86)\Nocturne\uninstall\helper.exe"
	)

	foreach ($uninstaller in $uninstallers) {
		if (Test-Path $uninstaller) {
			$uninstallerFound = 1
			Write-Host "Running Nocturne uninstaller..."
			Start-Process $uninstaller -ArgumentList "/S" -Wait -ErrorAction SilentlyContinue
		}
	}
	
	if ($uninstallerFound -eq 0) {
		return 0
	}

	$folders = @(
		"C:\Program Files\Nocturne",
		"C:\Program Files (x86)\Nocturne",
		
		"$env:ProgramData\Nocturne",
		"$env:APPDATA\Nocturne",
		"$env:LOCALAPPDATA\Nocturne"
	)

	foreach ($folder in $folders) {
		if (Test-Path $folder) {
			Write-Host "Removing $folder"
			 Get-Item $folder -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
		}
	}


	$shortcutPaths = @(
		"$env:PUBLIC\Desktop\Mozilla Firefox.lnk",
		"$env:USERPROFILE\Desktop\Mozilla Firefox.lnk",
		"$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Mozilla Firefox.lnk",
		"$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Mozilla Firefox.lnk"
	)

	foreach ($shortcut in $shortcutPaths) {
		if (Test-Path $shortcut) {
			Write-Host "Removing $shortcut"
			Remove-Item $shortcut -Force -ErrorAction SilentlyContinue
		}
	}
	
	return 1
}

function uninstall_firefox()
{
	$uninstallerFound = 0
	
	Write-Host "Checking firefox installation..."
	Get-Process firefox -ErrorAction SilentlyContinue | Stop-Process -Force

	$uninstallers = @(
		"C:\Program Files\Mozilla Firefox\uninstall\helper.exe",
		"C:\Program Files (x86)\Mozilla Firefox\uninstall\helper.exe"
	)

	foreach ($uninstaller in $uninstallers) {
		if (Test-Path $uninstaller) {
			$uninstallerFound = 1
			Write-Host "Running firefox uninstaller..."
			Start-Process $uninstaller -ArgumentList "/S" -Wait -ErrorAction SilentlyContinue
		}
	}
	
	if ($uninstallerFound -eq 0) {
		return 0
	}

	$folders = @(
		"C:\Program Files\Mozilla Firefox",
		"C:\Program Files (x86)\Mozilla Firefox",
		"$env:ProgramData\Mozilla",

		"$env:APPDATA\Mozilla",
		"$env:APPDATA\Mozilla\Firefox",

		"$env:LOCALAPPDATA\Mozilla",
		"$env:LOCALAPPDATA\Mozilla\Firefox",

		"$env:LOCALAPPDATA\Temp\Mozilla*",
		"$env:LOCALAPPDATA\Temp\Firefox*"
	)

	foreach ($folder in $folders) {
		if (Test-Path $folder) {
			Write-Host "Removing $folder"
			 Get-Item $folder -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
		}
	}


	$shortcutPaths = @(
		"$env:PUBLIC\Desktop\Firefox.lnk",
		"$env:USERPROFILE\Desktop\Firefox.lnk",
		"$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Mozilla Firefox.lnk",
		"$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Mozilla Firefox.lnk"
	)

	foreach ($shortcut in $shortcutPaths) {
		if (Test-Path $shortcut) {
			Write-Host "Removing $shortcut"
			Remove-Item $shortcut -Force -ErrorAction SilentlyContinue
		}
	}
	
	return 1;
}

function uninstall_authUx()
{
	$authUxPath = "C:\Program Files\AuthUX"

	if (Test-Path $authUxPath) {
		Write-Host "Removing $authUxPath"
		Remove-Item $authUxPath -Recurse -Force -ErrorAction SilentlyContinue
	}
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
		Write-Host "Creating $explorer7Path"
		Start-Process powershell `
		-ArgumentList '-Command "New-Item -ItemType Directory -Path C:\Windows\explorer7 -Force"' `
		-Verb RunAs
	}
}

function main()
{	
	while ($true) {
		Clear-Host
		$selection = selector
		$result = 0

		if ($selection -eq 1) {
			$result = uninstall_firefox
		}
		elseif ($selection -eq 2) {
			$result = uninstall_nocturne
		}
		else {
			Write-Host "Invalid selection!"
			Start-Sleep -Seconds 3
			continue
		}

		if ($result -eq 0) {
			Write-Host "This browser is not installed!"
			Start-Sleep -Seconds 3
			continue
		}

		break
	}
	
	uninstall_authUx
	setup
	
	Write-Host "Operation complete, you can now re-run Post-Setup."
}


main



