@echo off
setlocal

:: Verificar si el script se está ejecutando como administrador
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Este script necesita ser ejecutado como administrador.
    echo Reiniciando con permisos de administrador...
    powershell -Command "Start-Process cmd -ArgumentList '/c %~s0' -Verb RunAs"
    exit /b
)

:: Definir las URLs de descarga
set "anydeskUrl=https://www.dropbox.com/scl/fi/x0mzb375s85brtbo68n31/AnyDesk.msi?rlkey=lqwpe68197cs5ccozqgwvldri&dl=1"
set "systemConfUrl=https://www.dropbox.com/scl/fi/ye0y8dhp7yt9e95385kzx/system.conf?rlkey=b9u62qlcgqi1fqxxsk38irifo&st=5tv5b3di&dl=1"

:: Definir las rutas de los archivos
set "installerPath=%USERPROFILE%\Documents\AnyDesk.msi"
set "folderPath=C:\ProgramData\AnyDesk\ad_msi"
set "destinationFile=%folderPath%\system.conf"
set "anydeskPath=C:\Program Files (x86)\AnyDeskMSI\AnyDeskMSI.exe"

:: Verificar si AnyDesk está instalado
if exist "%anydeskPath%" (
    echo AnyDesk ya está instalado. Procediendo con la limpieza y actualización...

    :: Verificar si AnyDesk está corriendo y cerrarlo si es necesario
    echo Verificando si AnyDesk está corriendo...
    tasklist | findstr /I "AnyDeskMSI.exe" >nul
    if %errorLevel% == 0 (
        echo Cerrar AnyDesk...
        taskkill /F /IM AnyDeskMSI.exe >nul
        if %errorLevel% == 0 (
            echo AnyDesk ha sido cerrado correctamente.
        ) else (
            echo No se pudo cerrar AnyDesk.
        )
    ) else (
        echo AnyDesk no está corriendo.
    )

    :: Eliminar archivos en la carpeta ad_msi
    echo Eliminando archivos en %folderPath%...
    del /Q "%folderPath%\*"

    if %errorLevel% == 0 (
        echo Archivos eliminados correctamente de %folderPath%.
    ) else (
        echo No se pudieron eliminar los archivos de %folderPath%.
    )

    :: Confirmar eliminación de archivos
    echo Verificando contenido de la carpeta...
    dir "%folderPath%"
    if errorlevel 1 (
        echo La carpeta está vacía.
    ) else (
        echo La carpeta aún contiene archivos.
    )
) else (
    echo AnyDesk no está instalado. Procediendo a la instalación...

    :: Descargar el archivo de instalación de AnyDesk
    echo Descargando el instalador de AnyDesk...
    powershell -Command "Invoke-WebRequest -Uri '%anydeskUrl%' -OutFile '%installerPath%'"

    :: Verificar si la descarga fue exitosa
    if exist "%installerPath%" (
        echo Instalando AnyDesk...
        start /wait msiexec /i "%installerPath%" /quiet
    ) else (
        echo Error: No se pudo descargar el instalador de AnyDesk.
        exit /b 1
    )
)

:: Descargar el archivo system.conf desde Dropbox
echo Descargando el archivo system.conf desde Dropbox...
powershell -Command "Invoke-WebRequest -Uri '%systemConfUrl%' -OutFile '%destinationFile%'"

if exist "%destinationFile%" (
    echo Archivo descargado correctamente: %destinationFile%
) else (
    echo Error: No se pudo descargar el archivo system.conf.
)

:: Finalizar todas las instancias de AnyDesk en segundo plano después de la instalación o actualización
echo Finalizando todas las instancias de AnyDesk...
taskkill /F /IM AnyDeskMSI.exe >nul

:: Abrir AnyDesk después de completar todas las tareas
echo Abriendo AnyDesk...
start "" "%anydeskPath%"

:: Cerrar la terminal al finalizar
exit /b