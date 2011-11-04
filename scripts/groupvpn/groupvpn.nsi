; Builds the Windows installer with NSIS (v2.46).
; Also works with NSIS on WINE (GNU/Linux).

; Requires additional plugins (inside ./nsis).
!addincludedir nsis
!addplugindir nsis

!include "MUI2.nsh"
!include 'nsdialogs.nsh'
!include 'nsdialogs_createIPaddress.nsh'
!include 'XML.nsh'
!include "TextReplace.nsh"

SetPluginUnload alwaysoff



!define /file ACIS_VERSION acisp2p\version
Name "GroupVPN"
OutFile "groupvpn.${ACIS_VERSION}.exe"
SetCompressor /SOLID lzma
BrandingText "GroupVPN | ACIS P2P v0.${ACIS_VERSION}"

RequestExecutionLevel admin

;!define MUI_ABORTWARNING

!insertmacro MUI_DEFAULT MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\orange-install.ico"
!insertmacro MUI_DEFAULT MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\orange-uninstall.ico"

!insertmacro MUI_PAGE_LICENSE "acisp2p\LICENSE"
Page custom GroupConfig GroupConfigLeave
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES

ShowInstDetails Show

Var GroupConfig_Ctrl_Hostname
Var GroupConfig_Ctrl_Group
Var GroupConfig_Ctrl_Network
Var GroupConfig_Ctrl_Subnet
Var GroupConfig_Ctrl_File
Var GroupConfig_Ctrl_Browse
Var GroupConfig_Hostname
Var GroupConfig_Group
Var GroupConfig_Network
Var GroupConfig_Subnet
Var GroupConfig_File

!define AdapterKey "SYSTEM\CurrentControlSet\Control\Network\{4D36E972-E325-11CE-BFC1-08002BE10318}"
!define NetworkKey "SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}"
!define UninstallKey "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"

Var Adapter_PnpInstanceID

Function GroupConfig
	!insertmacro MUI_HEADER_TEXT "GroupVPN Settings" "Define your GroupVPN configuration."
	
	nsDialogs::Create 1018
	
	${NSD_CreateLabel} 0 0 100% 12u "Please set the configuration of your VPN group:"
	
	IntOp $0 0 + 0
	IntOp $1 0 + 13
	IntOp $2 0 + 18
	
	IntOp $0 $0 + $2
	${NSD_CreateLabel} 0 $0u 25% $1u "Group Config File"
	${NSD_CreateFileRequest} 25% $0u 50% $1u "$EXEDIR\config.zip"
	Pop $GroupConfig_Ctrl_File
	GetFunctionAddress $3 GroupConfig_File_Change
	nsDialogs::OnChange $GroupConfig_Ctrl_File $3
	${NSD_CreateBrowseButton} -22% $0u 22% $1u "Browse"
	Pop $GroupConfig_Ctrl_Browse
	GetFunctionAddress $3 GroupConfig_File_Browse
	nsDialogs::OnClick $GroupConfig_Ctrl_Browse $3
	
	IntOp $0 $0 + $2
	${NSD_CreateLabel} 0 $0u 100% $1u "Create your own group or join an existing one from www.grid-appliance.org"

	IntOp $0 $0 + $2
	${NSD_CreateLabel} 0 $0u 25% $1u "Host Name"
	${NSD_CreateLabel} 55% $0u 25% $1u "e.g. MyComputer"
	${NSD_CreateText} 25% $0u 25% $1u ""
	Pop $GroupConfig_Ctrl_Hostname
	
	IntOp $0 $0 + $2
	${NSD_CreateLabel} 0 $0u 25% $1u "Group Name"
	${NSD_CreateLabel} 55% $0u 25% $1u "e.g. MyGroup"
	${NSD_CreateText} 25% $0u 25% $1u ""
	Pop $GroupConfig_Ctrl_Group
	
	IntOp $0 $0 + $2
	${NSD_CreateLabel} 0 $0u 20% $1u "Network Address"
	${NSD_CreateLabel} 55% $0u 25% $1u "e.g. 192.168.1.0"
	${NSD_CreateIPaddress} 25% $0u 25% $1u ""
	Pop $GroupConfig_Ctrl_Network
	
	IntOp $0 $0 + $2
	${NSD_CreateLabel} 0 $0u 25% $1u "Subnet Mask"
	${NSD_CreateLabel} 55% $0u 25% $1u "e.g. 255.255.255.0"
	${NSD_CreateIPaddress} 25% $0u 25% $1u ""
	Pop $GroupConfig_Ctrl_Subnet
	
	Call GroupConfig_File_Change
	
	nsDialogs::Show
FunctionEnd

Function GroupConfig_File_Browse
	nsDialogs::SelectFileDialog open "$EXEDIR\config.zip" "Zip Files|*.zip|All Files|*.*"
	Pop $0
	${NSD_SetText} $GroupConfig_Ctrl_File $0
FunctionEnd

Function GroupConfig_File_Change
	${NSD_GetText} $GroupConfig_Ctrl_File $GroupConfig_File
	Delete "$TEMP\dhcp.config"
	ZipDLL::extractfile $GroupConfig_File $TEMP "dhcp.config"
	${xml::LoadFile} "$TEMP\dhcp.config" $R0
	${xml::GotoPath} "/DHCPConfig/Namespace" $R1
	${xml::GetText} $GroupConfig_Group $R1
	${xml::GotoPath} "/DHCPConfig/IPBase" $R2
	${xml::GetText} $GroupConfig_Network $R2
	${xml::GotoPath} "/DHCPConfig/Netmask" $R3
	${xml::GetText} $GroupConfig_Subnet $R3
	Delete "$TEMP\dhcp.config"
	
	${NSD_SetText} $GroupConfig_Ctrl_Group $GroupConfig_Group
	${NSD_SetText} $GroupConfig_Ctrl_Network $GroupConfig_Network
	${NSD_SetText} $GroupConfig_Ctrl_Subnet $GroupConfig_Subnet
	
	ReadRegStr $0 HKLM "System\CurrentControlSet\Control\ComputerName\ActiveComputerName" "ComputerName"
	System::Call "User32::CharLower(t r0 r1)i"
	${NSD_SetText} $GroupConfig_Ctrl_Hostname $1
FunctionEnd

Function GroupConfigLeave
	${NSD_GetText} $GroupConfig_Ctrl_File $GroupConfig_File
	${NSD_GetText} $GroupConfig_Ctrl_Hostname $GroupConfig_Hostname
	${NSD_GetText} $GroupConfig_Ctrl_Group $GroupConfig_Group
	${NSD_GetText} $GroupConfig_Ctrl_Network $GroupConfig_Network
	${NSD_GetText} $GroupConfig_Ctrl_Subnet $GroupConfig_Subnet
	StrCpy $INSTDIR "$PROGRAMFILES\GroupVPN\$GroupConfig_Group"
	${If} $GroupConfig_File != ""
	${AndIf} $GroupConfig_Hostname != ""
	${AndIf} $GroupConfig_Group != ""
	${AndIf} $GroupConfig_Network != ""
	${AndIf} $GroupConfig_Subnet != ""
		Goto settings_ok
	${Else}
		MessageBox MB_YESNO|MB_ICONQUESTION "Do you want to proceed without a complete group configuration? You will have to manually setup these later for GroupVPN to function." IDYES settings_skip
		ShowWindow $HWNDPARENT "${SW_RESTORE}"
	${EndIf}
	Abort
	settings_ok: settings_skip:
FunctionEnd

!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_FUNCTION StartService
!define MUI_FINISHPAGE_RUN_TEXT "Start GroupVPN Service Now"
!define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
!define MUI_FINISHPAGE_SHOWREADME "$INSTDIR\readme.txt"
!insertmacro MUI_PAGE_FINISH

Function StartService
	SimpleSC::StartService "GroupVPN$GroupConfig_Group"
FunctionEnd

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

Section -pre SecPre
	ReadINIStr $R0 "$INSTDIR\Uninstall.ini" GroupConfig Group
	${If} $R0 != ""
		DetailPrint "Removing existing driver [Tap$R0]..."
		nsExec::ExecToLog '"$INSTDIR\drivers\driverhelper.exe" remove Tap$R0'
	${EndIf}
SectionEnd

Section "Virtual Network Interface" SecTap
	SetOutPath "$INSTDIR\drivers"
	
	; Check if we are running on a 64 bit system.
	System::Call "kernel32::GetCurrentProcess() i .s"
	System::Call "kernel32::IsWow64Process(i s, *i .r0)"
	IntCmp $0 0 tap-32bit

	; tap-64bit:
	DetailPrint "64-bit system detected."
	File acisp2p\drivers\windows_tap\Windows_64\*.*
	goto tapend

	tap-32bit:
	DetailPrint "32-bit system detected."
	File acisp2p\drivers\windows_tap\Windows_32\*.*

	tapend:
	
	;nsExec::ExecToLog '"$INSTDIR\drivers\driverhelper.exe" remove IpopTap'
	nsExec::ExecToLog '"$INSTDIR\drivers\driverhelper.exe" install "$INSTDIR\drivers\IpopTap.inf" IpopTap'
	
	; get PnpInstanceID necessary to lookup Guid for registry
	nsExec::ExecToStack '"$INSTDIR\drivers\driverhelper.exe" status IpopTap'
	Pop $R0
	Pop $R1
	StrCpy $R0 $R1 13
	;DetailPrint "PnpInstanceID for tap driver : $R0"
	
	StrCpy $Adapter_PnpInstanceID $R0
	
	nsExec::ExecToLog '"$INSTDIR\drivers\driverhelper.exe" sethwid @$Adapter_PnpInstanceID := =Tap$GroupConfig_Group'
	
	; loop through guids until we find matching with PnpInstanceID then rename
	StrCpy $0 0
	loop_rename_tap:
		EnumRegKey $1 HKLM "${AdapterKey}" $0
		StrCmp $1 "" done_rename_tap
		IntOp $0 $0 + 1
		ReadRegStr $2 HKLM "${AdapterKey}\$1\Connection" "PnpInstanceID"
		StrCmp $2 $R0 rename_tap loop_rename_tap
	rename_tap:
		DetailPrint "Renaming Tap interface: $1"
		WriteRegStr HKLM "${AdapterKey}\$1\Connection" "Name" "$GroupConfig_Group"
		Goto loop_rename_tap
	done_rename_tap:

	StrCpy $0 0
	loop_fix_endpoint:
		EnumRegKey $1 HKLM "${NetworkKey}" $0
		StrCmp $1 "" done_fix_endpoint
		IntOp $0 $0 + 1
		ReadRegStr $2 HKLM "${NetworkKey}\$1" "DeviceInstanceID"
		StrCmp $2 $R0 fix_endpoint loop_fix_endpoint
	fix_endpoint:
		DetailPrint "Fixing NdisDeviceType for Tap interface: $1"
		WriteRegDWORD HKLM "${NetworkKey}\$1" "*NdisDeviceType" 0x00000001
		nsExec::ExecToLog '"$INSTDIR\drivers\driverhelper.exe" restart @$R0'
		Goto loop_fix_endpoint
	done_fix_endpoint:
SectionEnd

Section "GroupVPN Application" SecGroupVPN
	SetOutPath $INSTDIR

	File acisp2p\release_notes.txt
	File /oname=readme.txt acisp2p\README
	File /oname=license.txt acisp2p\LICENSE
	
	File /x *.py /x *.sh acisp2p\bin\*.*

	ZipDLL::extractall $GroupConfig_File $INSTDIR
	
	CreateDirectory "$INSTDIR\certificates"
	Rename "$INSTDIR\webcert" "$INSTDIR\certificates\webcert"
	Rename "$INSTDIR\cacert" "$INSTDIR\certificates\cacert"
	
	${xml::LoadFile} "$INSTDIR\dhcp.config" $R0
		${xml::GotoPath} "/DHCPConfig/Namespace" $R1
		${xml::SetText} $GroupConfig_Group $R2
		${xml::GotoPath} "/DHCPConfig/IPBase" $R1
		${xml::SetText} $GroupConfig_Network $R2
		${xml::GotoPath} "/DHCPConfig/Netmask" $R1
		${xml::SetText} $GroupConfig_Subnet $R2
		${xml::GotoPath} "/DHCPConfig/LeaseTime" $R1
		${xml::SetText} "3600" $R2
		${xml::SaveFile} "" $R3
	
	${xml::LoadFile} "$INSTDIR\ipop.config" $R0
		${xml::GotoPath} "/IpopConfig" $R1
		${xml::CreateNode} "<AddressData><Hostname>$GroupConfig_Hostname</Hostname></AddressData>" $R2
		${xml::InsertEndChild} $R2 $R3
		
		${xml::GotoPath} "/IpopConfig" $R1
		${xml::CreateNode} "<Dns><Type>DhtDns</Type></Dns>" $R2
		${xml::InsertEndChild} $R2 $R3
		
		${xml::GotoPath} "/IpopConfig/VirtualNetworkDevice" $R1
		${xml::SetText} $GroupConfig_Group $R2
		${xml::GotoPath} "/IpopConfig/IpopNamespace" $R1
		${xml::SetText} $GroupConfig_Group $R2
		${xml::SaveFile} "" $R3
	
	${xml::LoadFile} "$INSTDIR\node.config" $R0
		${xml::GotoPath} "/NodeConfig/XmlRpcManager/Enabled" $R1
		${xml::SetText} "false" $R2
		${xml::SaveFile} "" $R3
	
	DetailPrint "Adding firewall exceptions..."
	SimpleFC::AddApplication "GroupVPN$GroupConfig_Group" "$INSTDIR\GroupVPNService.exe" 0 2 "" "1"
	SimpleFC::AddApplication "IPOP$GroupConfig_Group" "$INSTDIR\DhtIpopNode.exe" 0 2 "" "1"
	SimpleFC::AddApplication "P2P$GroupConfig_Group" "$INSTDIR\P2PNode.exe" 0 2 "" "1"

	DetailPrint "Setting up service GroupVPN$GroupConfig_Group..."
	SimpleSC::InstallService "GroupVPN$GroupConfig_Group" "GroupVPN $GroupConfig_Group" "16" "2" "$INSTDIR\GroupVPNService.exe" "" "" ""
	SimpleSC::SetServiceFailure "GroupVPN$GroupConfig_Group" 0 "" "" 1 10000 1 60000 1 600000
SectionEnd

Section "Uninstall"
	ReadINIStr $GroupConfig_Group "$INSTDIR\Uninstall.ini" GroupConfig Group
	ReadINIStr $Adapter_PnpInstanceID "$INSTDIR\Uninstall.ini" Adapter PnpInstanceID
	
	${If} $GroupConfig_Group == ""
		MessageBox MB_OK|MB_ICONSTOP "Installation information has been corrupted. Please go ahead for a manual uninstallation."
		Abort
	${EndIF}
	
	DetailPrint "Removing driver [Tap$GroupConfig_Group]..."
	nsExec::ExecToLog '"$INSTDIR\drivers\driverhelper.exe" remove Tap$GroupConfig_Group'
	
	; cleanup orphan connection entries from registry
	StrCpy $0 0
	loop_remove_conn:
		EnumRegKey $1 HKLM "${AdapterKey}" $0
		StrCmp $1 "" done_remove_conn
		IntOp $0 $0 + 1
		ReadRegStr $2 HKLM "${AdapterKey}\$1\Connection" "PnpInstanceID"
		StrCmp $2 $Adapter_PnpInstanceID remove_conn loop_remove_conn
	remove_conn:
		DetailPrint "Cleaning up connection: $1"
		DeleteRegKey HKLM "${AdapterKey}\$1"
		Goto loop_remove_conn
	done_remove_conn:
	
	SimpleSC::ExistsService "GroupVPN$GroupConfig_Group"
	Pop $R0
	${If} $R0 == 0
		DetailPrint "Removing service [GroupVPN$GroupConfig_Group]..."
		SimpleSC::StopService "GroupVPN$GroupConfig_Group" 1
		SimpleSC::RemoveService "GroupVPN$GroupConfig_Group"
		Sleep 3000 ; wait for a few more seconds, just in case
	${EndIf}
	
	DetailPrint "Removing service..."
	SimpleSC::StopService "GroupVPN$GroupConfig_Group"
	SimpleSC::RemoveService "GroupVPN$GroupConfig_Group"

	RMDir /r /REBOOTOK "$INSTDIR\drivers"

	DetailPrint "Removing firewall exceptions..."
	SimpleFC::RemoveApplication "$INSTDIR\GroupVPNService.exe"
	SimpleFC::RemoveApplication "$INSTDIR\DhtIpopNode.exe"
	SimpleFC::RemoveApplication "$INSTDIR\P2PNode.exe"

	RMDir /r "$SMPROGRAMS\GroupVPN\$GroupConfig_Group"
	RMDir "$SMPROGRAMS\GroupVPN"
	RMDir /r "$INSTDIR"

	DeleteRegKey HKLM "${UninstallKey}\GroupVPN$GroupConfig_Group"
SectionEnd

Section -post SecPost
	SetOutPath "$SMPROGRAMS"
	CreateDirectory "$SMPROGRAMS\GroupVPN\$GroupConfig_Group"
	CreateShortCut "$SMPROGRAMS\GroupVPN\$GroupConfig_Group\Start Service.lnk" "net" "start GroupVPN$GroupConfig_Group"
	CreateShortCut "$SMPROGRAMS\GroupVPN\$GroupConfig_Group\Stop Stop.lnk" "net" "stop GroupVPN$GroupConfig_Group"
	CreateShortCut "$SMPROGRAMS\GroupVPN\$GroupConfig_Group\Restart Service.lnk" "net" "restart GroupVPN$GroupConfig_Group"
	CreateShortCut "$SMPROGRAMS\GroupVPN\$GroupConfig_Group\Uninstall.lnk" "$INSTDIR\Uninstall.exe"

	WriteRegStr HKLM "${UninstallKey}\GroupVPN$GroupConfig_Group" DisplayName "GroupVPN for $GroupConfig_Group"
	WriteRegStr HKLM "${UninstallKey}\GroupVPN$GroupConfig_Group" DisplayVersion "0.${ACIS_VERSION}"
	WriteRegStr HKLM "${UninstallKey}\GroupVPN$GroupConfig_Group" UninstallString "$INSTDIR\Uninstall.exe"
	WriteRegDWORD HKLM "${UninstallKey}\GroupVPN$GroupConfig_Group" NoModify 1
	WriteRegDWORD HKLM "${UninstallKey}\GroupVPN$GroupConfig_Group" NoRepair 1
	
	WriteUninstaller "$INSTDIR\Uninstall.exe"
	WriteINIStr "$INSTDIR\Uninstall.ini" GroupConfig Group $GroupConfig_Group
	WriteINIStr "$INSTDIR\Uninstall.ini" GroupConfig Network $GroupConfig_Network
	WriteINIStr "$INSTDIR\Uninstall.ini" GroupConfig Subnet $GroupConfig_Subnet
	WriteINIStr "$INSTDIR\Uninstall.ini" Adapter PnpInstanceID $Adapter_PnpInstanceID
	
SectionEnd
