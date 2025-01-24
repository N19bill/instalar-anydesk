# Verificar si el script se está ejecutando como administrador
$IsAdmin = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
$IsAdmin = $IsAdmin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Write-Host "Este script necesita ser ejecutado como administrador."
    Write-Host "Reiniciando con permisos de administrador..."
    Start-Process powershell -ArgumentList "-Command & {Start-Process -FilePath '$PSCommandPath' -Verb RunAs}" -Wait
    exit
}

# Definir las URLs de descarga
$anydeskUrl = "https://www.dropbox.com/scl/fi/x0mzb375s85brtbo68n31/AnyDesk.msi?rlkey=lqwpe68197cs5ccozqgwvldri&dl=1"
$systemConfUrl = "https://www.dropbox.com/scl/fi/ye0y8dhp7yt9e95385kzx/system.conf?rlkey=b9u62qlcgqi1fqxxsk38irifo&st=5tv5b3di&dl=1"

# Definir las rutas de los archivos
$installerPath = [System.IO.Path]::Combine($env:USERPROFILE, "Documents\AnyDesk.msi")
$folderPath = "C:\ProgramData\AnyDesk\ad_msi"
$destinationFile = [System.IO.Path]::Combine($folderPath, "system.conf")
$anydeskPath = "C:\Program Files (x86)\AnyDeskMSI\AnyDeskMSI.exe"

# Verificar si AnyDesk está instalado
if (Test-Path $anydeskPath) {
    Write-Host "AnyDesk ya está instalado. Procediendo con la limpieza y actualización..."

    # Verificar si AnyDesk está corriendo y cerrarlo si es necesario
    Write-Host "Verificando si AnyDesk está corriendo..."
    $anydeskProcess = Get-Process -Name "AnyDeskMSI" -ErrorAction SilentlyContinue
    if ($anydeskProcess) {
        Write-Host "Cerrando AnyDesk..."
        Stop-Process -Name "AnyDeskMSI" -Force
        Write-Host "AnyDesk ha sido cerrado correctamente."
    } else {
        Write-Host "AnyDesk no está corriendo."
    }

    # Eliminar archivos en la carpeta ad_msi
    Write-Host "Eliminando archivos en $folderPath..."
    Remove-Item -Path "$folderPath\*" -Force -ErrorAction SilentlyContinue
    Write-Host "Archivos eliminados correctamente de $folderPath."

    # Confirmar eliminación de archivos
    Write-Host "Verificando contenido de la carpeta..."
    if (-not (Get-ChildItem -Path $folderPath)) {
        Write-Host "La carpeta está vacía."
    } else {
        Write-Host "La carpeta aún contiene archivos."
    }
} else {
    Write-Host "AnyDesk no está instalado. Procediendo a la instalación..."

    # Descargar el archivo de instalación de AnyDesk
    Write-Host "Descargando el instalador de AnyDesk..."
    Invoke-WebRequest -Uri $anydeskUrl -OutFile $installerPath

    # Verificar si la descarga fue exitosa
    if (Test-Path $installerPath) {
        Write-Host "Instalando AnyDesk..."
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", $installerPath, "/quiet" -Wait
    } else {
        Write-Host "Error: No se pudo descargar el instalador de AnyDesk."
        exit
    }
}

# Descargar el archivo system.conf desde Dropbox
Write-Host "Descargando el archivo system.conf desde Dropbox..."
Invoke-WebRequest -Uri $systemConfUrl -OutFile $destinationFile

if (Test-Path $destinationFile) {
    Write-Host "Archivo descargado correctamente: $destinationFile"
} else {
    Write-Host "Error: No se pudo descargar el archivo system.conf."
}

# Finalizar todas las instancias de AnyDesk en segundo plano después de la instalación o actualización
Write-Host "Finalizando todas las instancias de AnyDesk..."
$anydeskProcess = Get-Process -Name "AnyDeskMSI" -ErrorAction SilentlyContinue
if ($anydeskProcess) {
    Stop-Process -Name "AnyDeskMSI" -Force
}

# Abrir AnyDesk después de completar todas las tareas
Write-Host "Abriendo AnyDesk..."
Start-Process -FilePath $anydeskPath

# Cerrar la terminal al finalizar
exit
