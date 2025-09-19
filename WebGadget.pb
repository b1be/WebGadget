progname.s=ProgramFilename()
configfilename.s = progname.s+".conf"
lockfile.s = progname.s+".lock"
systrayiconpng.s = progname.s+".png"
addr.s = Space(0)
ExamineDesktops()
x = DesktopWidth(0)/2 - 400
y = DesktopHeight(0)/2 - 300
w = 800
h = 600
m = #PB_Window_Normal
tmpweb = #Null
systrayicon = #Null
systraymenu = #Null
tmpwin = #Null
Quit = #False
showwindow = 0
logoimg = #Null
logoimgwin = #Null

Procedure SingleInstance()
  Shared lockfile.s
  Protected result = #False
  Protected cf = #Null
  result = RenameFile(lockfile,lockfile)
  cf = CreateFile(#PB_Any,lockfile,#PB_Ascii)
  ProcedureReturn result
EndProcedure

Procedure Config(rewrite = #False)
  Shared configfilename
  Shared addr.s
  Shared x,y,w,h,m
  
  Select rewrite
      Case #False
  
  If FileSize(configfilename) <= 0    
    cf = CreateFile(#PB_Any,configfilename,#PB_File_SharedRead|#PB_File_SharedWrite|#PB_Ascii)
    WriteStringN(cf,"server = https://demo.home-assistant.io")
    WriteStringN(cf,"window = "+Str(x)+","+Str(y)+","+Str(w)+","+Str(h)+","+Str(m))
    CloseFile(cf)
    cf = #Null
  EndIf
  
  If FileSize(configfilename) > 0
    cf = ReadFile(#PB_Any,configfilename,#PB_File_SharedRead|#PB_Ascii)
    While Not Eof(cf)
      rs.s=ReadString(cf)
       Select UCase(LTrim(RTrim(StringField(rs.s,1,"="))))
        Case "SERVER"
          addr.s=LTrim(RTrim(StringField(rs.s,2,"=")))
        Case "WINDOW"
          x = Val(StringField(StringField(rs.s,2,"="),1,","))
          y = Val(StringField(StringField(rs.s,2,"="),2,","))
          w = Val(StringField(StringField(rs.s,2,"="),3,","))
          h = Val(StringField(StringField(rs.s,2,"="),4,","))
          m = Val(StringField(StringField(rs.s,2,"="),5,","))
      EndSelect
    Wend
    CloseFile(cf)
    cf = #Null
  EndIf
     Case #True      
        cf = CreateFile(#PB_Any,configfilename,#PB_File_SharedRead|#PB_File_SharedWrite|#PB_Ascii)
        WriteStringN(cf,"server = "+addr.s)
        WriteStringN(cf,"window = "+Str(x)+","+Str(y)+","+Str(w)+","+Str(h)+","+Str(m))
        CloseFile(cf)
        cf = #Null      
  
  EndSelect
EndProcedure

Procedure SizeWindowHandler()    
 Shared tmpweb
 Shared addr.s
 Shared x,y,w,h,m
 m = GetWindowState(EventWindow())
 Select m
     Case 0
 w = WindowWidth(EventWindow())
 h = WindowHeight(EventWindow())
 x = WindowX(EventWindow())
 y = WindowY(EventWindow())
     Default
        :
 EndSelect
 ResizeGadget(tmpweb, #PB_Ignore, #PB_Ignore,WindowWidth(EventWindow()) , WindowHeight(EventWindow()))
 Config(#True)
EndProcedure

Procedure WindowHandler()    
 Shared tmpweb
 Shared addr.s 
 Shared x,y,w,h,m
 m = GetWindowState(EventWindow())
 Select m
     Case 0
 w = WindowWidth(EventWindow())
 h = WindowHeight(EventWindow())
 x = WindowX(EventWindow())
 y = WindowY(EventWindow())
    Default
      :
 EndSelect
 Config(#True)
EndProcedure

UsePNGImageDecoder()
Config()

If Not SingleInstance()
  MessageRequester("Error","Already Running",#PB_MessageRequester_Ok|#PB_MessageRequester_Error)
  End
EndIf

tmpwin = OpenWindow(#PB_Any,x,y,w,h,GetFilePart(progname.s,#PB_FileSystem_NoExtension)+"-Web",#PB_Window_SystemMenu|#PB_Window_SizeGadget|#PB_Window_MaximizeGadget|#PB_Window_MinimizeGadget|m)
CompilerSelect #PB_Compiler_OS
 CompilerCase #PB_OS_Windows
   tmpweb = WebGadget(#PB_Any,0,0,WindowWidth(tmpwin),WindowHeight(tmpwin),addr.s,#PB_Web_Edge) 
 CompilerDefault
  tmpweb = WebGadget(#PB_Any,0,0,WindowWidth(tmpwin),WindowHeight(tmpwin),addr.s)
CompilerEndSelect


If FileSize(systrayiconpng) <= 0
    logoimg = CatchImage(#PB_Any,?browser)
  Else    
    logoimg = LoadImage(#PB_Any,systrayiconpng)
EndIf
logoimgwin1 = CatchImage(#PB_Any,?show)
logoimgwin2 = CatchImage(#PB_Any,?hide)
logoimgwin3 = CatchImage(#PB_Any,?onoff)

; Load Systray Icon
systrayicon = AddSysTrayIcon(#PB_Any, WindowID(tmpwin), ImageID(logoimg))

systraymenu1 = CreatePopupImageMenu(#PB_Any, #PB_Menu_SysTrayLook)
MenuItem(1, "Show &Window"+Chr(9)+"S",ImageID(logoimgwin1))
MenuBar()
MenuItem(2, "E&xit"+Chr(9)+"X",ImageID(logoimgwin3))

systraymenu2 = CreatePopupImageMenu(#PB_Any, #PB_Menu_SysTrayLook)
MenuItem(1, "Hide &Window"+Chr(9)+"H",ImageID(logoimgwin2))
MenuBar()
MenuItem(2, "E&xit"+Chr(9)+"X",ImageID(logoimgwin3))


; Associate the menu to the systray
SysTrayIconMenu(systrayicon, MenuID(systraymenu2))

; Save Configuration of Window Size and State
BindEvent(#PB_Event_SizeWindow, @SizeWindowHandler())
BindEvent(#PB_Event_MoveWindow, @WindowHandler())
BindEvent(#PB_Event_MaximizeWindow, @WindowHandler())
BindEvent(#PB_Event_MinimizeWindow, @WindowHandler())

Repeat
  Delay(1)
  ev = WaitWindowEvent(1)
  Select ev
    Case #PB_Event_CloseWindow
      showwindow = 1
      HideWindow(tmpwin,showwindow)
      SysTrayIconMenu(systrayicon, MenuID(systraymenu1))
    Case #PB_Event_Menu
      Select EventMenu()
        Case 0
          :          
        Case 1          
          showwindow = 1 - showwindow
          HideWindow(tmpwin,showwindow)
          Select showwindow
            Case 1              
              SysTrayIconMenu(systrayicon, MenuID(systraymenu1))
            Case 0              
              SysTrayIconMenu(systrayicon, MenuID(systraymenu2))
          EndSelect
        Case 2
          Quit = #True
      EndSelect
    Case #PB_Event_SysTray
      Select EventType()
        Case #PB_EventType_LeftClick
          DisplayPopupMenu(systraymenu,WindowID(tmpwin))
        Case #PB_EventType_LeftDoubleClick
          HideWindow(tmpwin,#False)
      EndSelect    
  EndSelect
Until Quit = #True

End

DataSection
  browser:
  IncludeBinary "browser.png"
  onoff:
  IncludeBinary "onoff.png"
  hide:
  IncludeBinary "1.png"
  show:
  IncludeBinary "2.png"
EndDataSection
