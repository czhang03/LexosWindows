######################################################################

# define variable
!define APP_NAME "Lexos"
!define COMP_NAME "WheatonCS"
!define WEB_SITE "http://lexos.wheatoncollege.edu/"
!define VERSION "{{Version}}"
!define COPYRIGHT "WheatonCS � 2016"
!define DESCRIPTION "Python/Flask-based website for text analysis workflow."
!define LICENSE_TXT "..\Lexos\LICENSE"
!define INSTALLER_NAME "LexosInstaller_${VERSION}_{{PlatformName}}.exe"
!define MAIN_APP_EXE "LexosWindows.exe"
!define ANACONDA_FILE "Anaconda3-{{anacondaVersion}}-Windows-{{PlatformName}}.exe"
!define INSTALL_TYPE "SetShellVarContext all"
!define REG_ROOT "HKCU"
!define REG_APP_PATH "Software\Microsoft\Windows\CurrentVersion\App Paths\${MAIN_APP_EXE}"
!define UNINSTALL_PATH "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"
!define APP_INFO_PATH "Software\Lexos\"

!define REG_START_MENU "Start Menu Folder"

var SM_Folder

######################################################################

# regeister information on windows
VIProductVersion  "${VERSION}"
VIAddVersionKey "ProductName"  "${APP_NAME}"
VIAddVersionKey "CompanyName"  "${COMP_NAME}"
VIAddVersionKey "LegalCopyright"  "${COPYRIGHT}"
VIAddVersionKey "FileDescription"  "${DESCRIPTION}"
VIAddVersionKey "FileVersion"  "${VERSION}"

######################################################################

# set package information
SetCompressor ZLIB
Name "${APP_NAME}"
Caption "${APP_NAME}"
OutFile "${INSTALLER_NAME}"
BrandingText "${APP_NAME}"
ManifestDPIAware true
InstallDirRegKey "${REG_ROOT}" "${REG_APP_PATH}" ""
InstallDir "$LOCALAPPDATA\${APP_NAME}"

######################################################################

!include "MUI2.nsh"

!define MUI_ABORTWARNING
!define MUI_UNABORTWARNING

# cutomize the images
!define MUI_ICON "..\Lexos\install\assets\Lexos.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP LexosTree.bmp

# welcome page
!insertmacro MUI_PAGE_WELCOME

# licnese page
!ifdef LICENSE_TXT
!insertmacro MUI_PAGE_LICENSE "${LICENSE_TXT}"
!endif

# choose what to install page
!insertmacro MUI_PAGE_COMPONENTS 

# directory page
!insertmacro MUI_DEFAULT MUI_DIRECTORYPAGE_VARIABLE $INSTDIR
!insertmacro MUI_PAGE_DIRECTORY

# start menu page
!ifdef REG_START_MENU
!define MUI_STARTMENUPAGE_DEFAULTFOLDER "${APP_NAME}"
!define MUI_STARTMENUPAGE_REGISTRY_ROOT "${REG_ROOT}"
!define MUI_STARTMENUPAGE_REGISTRY_KEY "${UNINSTALL_PATH}"
!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "${REG_START_MENU}"
!insertmacro MUI_PAGE_STARTMENU Application $SM_Folder
!endif

# install page
!insertmacro MUI_PAGE_INSTFILES

# finish and run
!define MUI_FINISHPAGE_RUN "$INSTDIR\${MAIN_APP_EXE}"
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM

!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_UNPAGE_FINISH

!insertmacro MUI_LANGUAGE "English"

######################################################################
# anaconda install section
Section "Install Anaconda" AnacondaSec

    # check the commandline parameter
    !include "FileFunc.nsh"
    ${GetParameters} $R0  # get the command line variable and then pass it in R1
    ${GetOptions} $R0 "/noAnaconda" $R1  # check if '/noAnaconda' is in R0, if not raise an error. R1 is a trash variable
    IfErrors 0 SkipAnaconda  # if previous command raise error, then jump 0 line, else go to SkipAnaconda label

    SetOutPath "$TEMP\LexosInstaller\${ANACONDA_FILE}"
    File "${ANACONDA_FILE}"
    DetailPrint "Installing Anaconda, this can take 5-30 minutes depends on your machine"
    SetDetailsPrint none
    ExecWait "${ANACONDA_FILE} /S /D=$\"C:\tools\Anaconda3$\""
    SetDetailsPrint both

    SkipAnaconda:  # SkipAnaconda label
SectionEnd



# description of the section
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${AnacondaSec} "This option will let you to install Anaconda with Lexos. Anaconda is a python distribution required by lexos. $\nIf you uncheck this option, you will need to install python by yourself."
!insertmacro MUI_FUNCTION_DESCRIPTION_END

######################################################################

# main install page
Section -MainProgram
${INSTALL_TYPE}
SetOverwrite ifnewer

# extracting files
SetOutPath "$INSTDIR\scr"
File /nonfatal /r "..\..\Lexos\"

SetOutPath "$INSTDIR"
File /nonfatal /r "..\..\Executable\LexosWindows\bin\{{PlatformName}}\Release\"

SectionEnd

######################################################################

# finish up 
Section -Icons_Reg

# write uninstaller
SetOutPath "$INSTDIR"
WriteUninstaller "$INSTDIR\uninstall.exe"

# put link in start menu
!ifdef REG_START_MENU
!insertmacro MUI_STARTMENU_WRITE_BEGIN Application
CreateDirectory "$SMPROGRAMS\$SM_Folder"
CreateShortCut "$SMPROGRAMS\$SM_Folder\${APP_NAME}.lnk" "$INSTDIR\${MAIN_APP_EXE}"
CreateShortCut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${MAIN_APP_EXE}"
CreateShortCut "$SMPROGRAMS\$SM_Folder\Uninstall ${APP_NAME}.lnk" "$INSTDIR\uninstall.exe"

# create web site url
!ifdef WEB_SITE
WriteIniStr "$INSTDIR\${APP_NAME} website.url" "InternetShortcut" "URL" "${WEB_SITE}"
CreateShortCut "$SMPROGRAMS\$SM_Folder\${APP_NAME} Website.lnk" "$INSTDIR\${APP_NAME} website.url"
!endif
!insertmacro MUI_STARTMENU_WRITE_END
!endif

# This is auto generated, I don't know what this do...
!ifndef REG_START_MENU
CreateDirectory "$SMPROGRAMS\${APP_NAME}"
CreateShortCut "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk" "$INSTDIR\${MAIN_APP_EXE}"
CreateShortCut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${MAIN_APP_EXE}"
CreateShortCut "$SMPROGRAMS\${APP_NAME}\Uninstall ${APP_NAME}.lnk" "$INSTDIR\uninstall.exe"

!ifdef WEB_SITE
WriteIniStr "$INSTDIR\${APP_NAME} website.url" "InternetShortcut" "URL" "${WEB_SITE}"
CreateShortCut "$SMPROGRAMS\${APP_NAME}\${APP_NAME} Website.lnk" "$INSTDIR\${APP_NAME} website.url"
!endif
!endif

# write information to registry
WriteRegStr ${REG_ROOT} "${REG_APP_PATH}" "" "$INSTDIR\${MAIN_APP_EXE}"
WriteRegStr ${REG_ROOT} "${UNINSTALL_PATH}"  "DisplayName" "${APP_NAME}"
WriteRegStr ${REG_ROOT} "${UNINSTALL_PATH}"  "UninstallString" "$INSTDIR\uninstall.exe"
WriteRegStr ${REG_ROOT} "${UNINSTALL_PATH}"  "DisplayIcon" "$INSTDIR\${MAIN_APP_EXE}"
WriteRegStr ${REG_ROOT} "${UNINSTALL_PATH}"  "DisplayVersion" "${VERSION}"
WriteRegStr ${REG_ROOT} "${UNINSTALL_PATH}"  "Publisher" "${COMP_NAME}"
WriteRegStr ${REG_ROOT} "${APP_INFO_PATH}" "LexosPyLocation" "$INSTDIR\scr\lexos.py"
WriteRegStr ${REG_ROOT} "${APP_INFO_PATH}" "LexosReqLocation" "$INSTDIR\scr\Reqirement.txt"

!ifdef WEB_SITE
WriteRegStr ${REG_ROOT} "${UNINSTALL_PATH}"  "URLInfoAbout" "${WEB_SITE}"
!endif
SectionEnd

######################################################################

Section Uninstall
${INSTALL_TYPE}
RMDir /r /REBOOTOK "$INSTDIR"
 
Delete "$INSTDIR\uninstall.exe"
!ifdef WEB_SITE
Delete "$INSTDIR\${APP_NAME} website.url"
!endif

RmDir "$INSTDIR"

!ifdef REG_START_MENU
!insertmacro MUI_STARTMENU_GETFOLDER "Application" $SM_Folder
Delete "$SMPROGRAMS\$SM_Folder\${APP_NAME}.lnk"
Delete "$SMPROGRAMS\$SM_Folder\Uninstall ${APP_NAME}.lnk"
!ifdef WEB_SITE
Delete "$SMPROGRAMS\$SM_Folder\${APP_NAME} Website.lnk"
!endif
Delete "$DESKTOP\${APP_NAME}.lnk"

RmDir "$SMPROGRAMS\$SM_Folder"
!endif

!ifndef REG_START_MENU
Delete "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk"
Delete "$SMPROGRAMS\${APP_NAME}\Uninstall ${APP_NAME}.lnk"
!ifdef WEB_SITE
Delete "$SMPROGRAMS\${APP_NAME}\${APP_NAME} Website.lnk"
!endif
Delete "$DESKTOP\${APP_NAME}.lnk"

RmDir "$SMPROGRAMS\${APP_NAME}"
!endif

DeleteRegKey ${REG_ROOT} "${REG_APP_PATH}"
DeleteRegKey ${REG_ROOT} "${UNINSTALL_PATH}"
DeleteRegKey ${REG_ROOT} "${APP_INFO_PATH}"

SectionEnd

######################################################################

