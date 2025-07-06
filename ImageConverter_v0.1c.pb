;- ############### ImageConverter Info
;
Global Version.s="0.1c"
;
; © 2024 Paul Vince (MrV2k)
;
; https://easyemu.mameworld.info
;
; [ PB V5.7x/V6.x / 32Bit / 64Bit / Windows / DPI ]
;
; A bodged together image convertor for AGS images
;
;- ############### Version Info
;
;============================================
; VERSION INFO v0.1
;============================================
;
; Private release.
;
;============================================
; VERSION INFO v0.1a
;============================================
;
; Added webp support
; Added iff support
; Added pdf output
; Added 320x128 resolution
;
;============================================
; VERSION INFO v0.1b
;============================================
;
; Fixed name spelling (D'oh!)
; Added version number to window title.
;
;============================================
; VERSION INFO v0.1c
;======================================
;
; Added workaround for non compatable IFF files.
;
;- ############### Enumerations

XIncludeFile "TinyIFF.pbi"

Enumeration
  #MAIN_WINDOW
  #OPEN_BUTTON
  #IMAGE_GADGET
  #CLOSE_BUTTON
  #START_BUTTON
  #OUTPUT_STRING
  #OUTPUT_BUTTON
  #INPUT_STRING
  #INPUT_BUTTON
  #APPEND_STRING
  #HORIZ_RES_STRING
  #VERT_RES_STRING
  #QUICK_RES_COMBO
  #OUTPUT_ITYPE_COMBO
  #RESIZE_METHOD
  #DITHER
  #COMMAND_STRING
  #RESET_BUTTON
  #COLOUR_COMBO
  #BATCH_BUTTON
  #OVERWRITE_TOGGLE
  #BLANK_IMAGE
EndEnumeration

;- ############### Global Variables

Global event,gadget,type,option

Global Home_Path.s=GetCurrentDirectory()
Global NConvert_Path.s=Home_Path+"NConvert.exe"
Global commandline.s=""
Global full_commandline.s=""
Global input_name.s=""
Global input_path.s=Home_Path
Global output_name.s=""
Global output_path.s=Home_Path
Global path.s=""
Global vert_res=0
Global horiz_res=0
Global q_res=0
Global dither=0
Global dither_name.s=""
Global resize=0
Global resize_name.s=""
Global colours=256
Global colour_num=7
Global itype=0
Global itype_ext.s="iff"
Global count.i
Global overwrite.b=#True
Global append.s=""

;- ############### Procedures

Import ""
  GetConsoleWindow(Void)
EndImport

Macro Center_Console()
  hWnd = GetConsoleWindow(0)
  MoveWindow_(hWnd, DpiX(WindowX(#MAIN_WINDOW))+(WindowWidth(#MAIN_WINDOW)/8), DpiY(WindowY(#MAIN_WINDOW))+(WindowHeight(#MAIN_WINDOW)/8), DpiX(WindowWidth(#MAIN_WINDOW)/1.25), DpiY(WindowHeight(#MAIN_WINDOW)*2), 1)
EndMacro

Macro DpiX(value) ; <--------------------------------------------------> DPI X Scaling
  DesktopScaledX(value)
EndMacro

Macro DpiY(value) ; <--------------------------------------------------> DPI Y Scaling
  DesktopScaledY(value)
EndMacro

Procedure.b Load_IFF(path.s,imagenum.l)
    
  Protected my_image.l, outcome.b
  
  outcome=#False
  
  If IsImage(my_image) : FreeImage(my_image) : EndIf
  
  my_image=TinyIFF::Load(#PB_Any ,path)
  
  If IsImage(my_image)
    outcome=#True
    CopyImage(my_image,imagenum)    
    FreeImage(my_image)
  EndIf 
  
  ProcedureReturn outcome
  
EndProcedure

Procedure Make_Command_line()
  
  commandline=""
  commandline+GetFilePart(NConvert_Path) 
  If overwrite
    commandline+" -overwrite "
  EndIf
  commandline+" -out "+itype_ext
  
  If output_name<>""
    commandline+" -o "+output_name+append+"."+itype_ext
  Else
    commandline+" -o <NONE>"
  EndIf
  
  If itype=0
    commandline+" -c 1"
  EndIf
  
  If itype<>2
    If vert_res<>0 And horiz_res<>0
      commandline+" -resize "+horiz_res+" "+vert_res
        Select resize
          Case 1 : commandline+" -rtype lanczos"
          Case 2 : commandline+" -rtype quick"
          Case 3 : commandline+" -rtype mitchell"
        EndSelect
    EndIf
  EndIf
  
  If itype=0
    If colours<>0
      commandline+" -colors "+Str(colours)
      If dither=1
        commandline+" -floyd"
      EndIf
      If dither=2
        commandline+" -dither"
      EndIf
    EndIf
  EndIf

  If input_name<>""
    commandline+" "+input_name
  EndIf
  
EndProcedure

Procedure Make_Full_Command_line()
  
  full_commandline=""
  If overwrite
    full_commandline+" -overwrite "
  EndIf
  full_commandline+" -out "+itype_ext
  full_commandline+" -o "+#DOUBLEQUOTE$+output_path+output_name+append+"."+itype_ext+#DOUBLEQUOTE$
  
  If itype=0
    full_commandline+" -c 1"
  EndIf
  
  If itype<>2
    If vert_res<>0 And horiz_res<>0
      full_commandline+" -resize "+horiz_res+" "+vert_res
      Select resize
        Case 1 : full_commandline+" -rtype lanczos"
        Case 2 : full_commandline+" -rtype quick"
        Case 3 : full_commandline+" -rtype mitchell"
      EndSelect
    EndIf
  EndIf
  
  If itype=0
    If colours<>0
      full_commandline+" -colors "+Str(colours)
      Select Dither
        Case 1 : full_commandline+" -floyd"
        Case 2 : full_commandline+" -dither"
      EndSelect
    EndIf
  EndIf
   
  If input_name<>""
    full_commandline+" "+#DOUBLEQUOTE$+input_path+input_name+#DOUBLEQUOTE$
  EndIf
  
EndProcedure

Macro Update_Commandline()
  Make_Command_line()
  SetGadgetText(#COMMAND_STRING,commandline)
EndMacro

Macro Pause_Console()
  PrintN("Press A Key To Continue...")
  Repeat : Until Inkey()<>""
EndMacro

Macro Pause_Window(window)
  SendMessage_(WindowID(window),#WM_SETREDRAW,#False,0)
EndMacro

Macro Resume_Window(window)
  SendMessage_(WindowID(window),#WM_SETREDRAW,#True,0)
  RedrawWindow_(WindowID(window),#Null,#Null,#RDW_INVALIDATE)
EndMacro

Procedure Batch_Convert()
   
  Protected NewList Batch_list.s()
  Protected Hwnd
  
  input_path=PathRequester("Select A Folder",Home_Path)
  output_path=input_path
  
  ExamineDirectory(0,input_path,"*.png")
  While NextDirectoryEntry(0)
    AddElement(Batch_list())
    Batch_list()=DirectoryEntryName(0)
  Wend
  
  FinishDirectory(0)
  
  ExamineDirectory(0,input_path,"*.jpg")
  While NextDirectoryEntry(0)
    AddElement(Batch_list())
    Batch_list()=DirectoryEntryName(0)
  Wend
  
  FinishDirectory(0)
  
  ExamineDirectory(0,input_path,"*.iff")
  While NextDirectoryEntry(0)
    AddElement(Batch_list())
    Batch_list()=DirectoryEntryName(0)
  Wend
  
  FinishDirectory(0)
  
  OpenConsole()
  Center_Console()
  
  PrintN("Files Added...")
  PrintN("")
  
  ForEach Batch_list()
    PrintN(GetFilePart(Batch_list()))
  Next
  
  If MessageRequester("Warning","Create batch files?",#PB_MessageRequester_Warning|#PB_MessageRequester_YesNo)=#PB_MessageRequester_Yes  
    ForEach Batch_list()
      PrintN("Converting: "+Batch_list())
      input_name=GetFilePart(Batch_list())
      output_name=GetFilePart(Batch_list(),#PB_FileSystem_NoExtension)
      Make_Full_Command_line()
      RunProgram(GetFilePart(NConvert_Path),full_commandline,GetPathPart(NConvert_Path),#PB_Program_Wait)
    Next
    RunProgram(output_path,"","")
  EndIf
  
  CloseConsole()
    
  FreeList(Batch_list())
  
EndProcedure

Procedure Batch_Convert_Drop(filelist.s)
   
  Protected NewList Batch_list.s()
  Protected Hwnd
  
  count=CountString(filelist,#LF$)

  For i=1 To count+1
    AddElement(Batch_list())
    Batch_list()=StringField(filelist,i,#LF$)
  Next
  
  OpenConsole()
  Center_Console()
  
  PrintN("Files Added...")
  PrintN("")
  
  ForEach Batch_list()
    If GetExtensionPart(Batch_list())<>"iff" And GetExtensionPart(Batch_list())<>"jpg" And GetExtensionPart(Batch_list())<>"png"
      DeleteElement(Batch_list())
      Continue
    EndIf
    output_path=GetPathPart(Batch_list())
    input_path=output_path
    PrintN(GetFilePart(Batch_list()))
  Next
  
  If MessageRequester("Warning","Create batch files?",#PB_MessageRequester_Warning|#PB_MessageRequester_YesNo)=#PB_MessageRequester_Yes  
    ForEach Batch_list()
      PrintN("Converting: "+Batch_list())
      input_name=GetFilePart(Batch_list())
      output_name=GetFilePart(Batch_list(),#PB_FileSystem_NoExtension)
      Make_Full_Command_line()
      RunProgram(GetFilePart(NConvert_Path),full_commandline,GetPathPart(NConvert_Path),#PB_Program_Wait)
    Next
    RunProgram(output_path,"","")
  EndIf
  
  CloseConsole()
    
  FreeList(Batch_list())
  
EndProcedure

Procedure Create_Window()
  
  If OpenWindow(#MAIN_WINDOW,0,0,670,195,"Image Converter v"+Version,#PB_Window_SystemMenu|#PB_Window_ScreenCentered)
    
    Pause_Window(#MAIN_WINDOW)
    
    FrameGadget(#PB_Any,5,0,425,50,"Command Line")
    StringGadget(#COMMAND_STRING,10,20,350,20,"",#PB_String_ReadOnly)
    SetGadgetColor(#COMMAND_STRING,#PB_Gadget_FrontColor,#White)
    SetGadgetColor(#COMMAND_STRING,#PB_Gadget_BackColor,#Black)
    
    
    TextGadget(#PB_Any,365,0,55,20," Append ")
    StringGadget(#APPEND_STRING,365,20,60,20,append)
    SetGadgetColor(#APPEND_STRING,#PB_Gadget_FrontColor,#White)
    SetGadgetColor(#APPEND_STRING,#PB_Gadget_BackColor,#Black)
            
    FrameGadget(#PB_Any,5,50,210,70,"Images")
    StringGadget(#INPUT_STRING,10,70,95,22,"",#PB_String_ReadOnly)
    
    StringGadget(#OUTPUT_STRING,110,70,100,22,output_name)
    ButtonGadget(#INPUT_BUTTON,10,94,95,22,"Input Image")
    ButtonGadget(#OUTPUT_BUTTON,110,94,100,22,"Output Image")
    
    EnableGadgetDrop(#INPUT_STRING,#PB_Drop_Files,#PB_Drag_Copy)
    
    FrameGadget(#PB_Any,220,50,210,70,"Resolution")
    TextGadget(#PB_Any,235,70,70,22,"Output Res.")
    StringGadget(#HORIZ_RES_STRING,225,90,40,22,Str(vert_res),#PB_String_Numeric)
    TextGadget(#PB_Any,268,91,10,22,"x")
    StringGadget(#VERT_RES_STRING,275,90,40,22,Str(horiz_res),#PB_String_Numeric)
    
    TextGadget(#PB_Any,330,70,70,20,"Quick Res.")
    ComboBoxGadget(#QUICK_RES_COMBO,320,90,105,22)
    AddGadgetItem(#QUICK_RES_COMBO,-1,"No Resize") 
    AddGadgetItem(#QUICK_RES_COMBO,-1,"320 x 128")
    AddGadgetItem(#QUICK_RES_COMBO,-1,"320 x 256")
    AddGadgetItem(#QUICK_RES_COMBO,-1,"320 x 512")
    AddGadgetItem(#QUICK_RES_COMBO,-1,"640 x 256")
    AddGadgetItem(#QUICK_RES_COMBO,-1,"640 x 512")
    AddGadgetItem(#QUICK_RES_COMBO,-1,"640 x 824")
    AddGadgetItem(#QUICK_RES_COMBO,-1,"800 x 600")
    AddGadgetItem(#QUICK_RES_COMBO,-1,"1024 x 768")
    AddGadgetItem(#QUICK_RES_COMBO,-1,"1280 x 720")
    AddGadgetItem(#QUICK_RES_COMBO,-1,"1920 x 1080")
    AddGadgetItem(#QUICK_RES_COMBO,-1,"Custom")

    SetGadgetState(#QUICK_RES_COMBO,q_res)
    
    FrameGadget(#PB_Any,5,120,140,70,"Resize")
    TextGadget(#PB_Any,25,140,60,20,"Type")
    ComboBoxGadget(#RESIZE_METHOD,10,160,60,20)
    AddGadgetItem(#RESIZE_METHOD,-1,"None")
    AddGadgetItem(#RESIZE_METHOD,-1,"Lanczos")
    AddGadgetItem(#RESIZE_METHOD,-1,"Quick") 
    AddGadgetItem(#RESIZE_METHOD,-1,"Mitchell")
    SetGadgetState(#RESIZE_METHOD,resize)
    
    TextGadget(#PB_Any,90,140,70,20,"Dither")
    ComboBoxGadget(#DITHER,75,160,65,20)
    AddGadgetItem(#DITHER,-1,"None")
    AddGadgetItem(#DITHER,-1,"Floyd")
    AddGadgetItem(#DITHER,-1,"Bayer")

    SetGadgetState(#DITHER,dither)
    
    FrameGadget(#PB_Any,150,120,65,70,"Output")
    TextGadget(#PB_Any,155,140,55,20,"Format",#PB_Text_Center)
    ComboBoxGadget(#OUTPUT_ITYPE_COMBO,155,160,55,20)
    AddGadgetItem(#OUTPUT_ITYPE_COMBO,-1,"IFF")
    AddGadgetItem(#OUTPUT_ITYPE_COMBO,-1,"PNG")
    AddGadgetItem(#OUTPUT_ITYPE_COMBO,-1,"PDF")
    SetGadgetState(#OUTPUT_ITYPE_COMBO,itype)
    
    FrameGadget(#PB_Any,220,120,100,70,"Colour")
    TextGadget(#PB_Any,240,140,70,20,"Set Colours")
    ComboBoxGadget(#COLOUR_COMBO,225,160,90,20,#PB_ComboBox_Editable)
    AddGadgetItem(#COLOUR_COMBO,-1,"8")
    AddGadgetItem(#COLOUR_COMBO,-1,"16")
    AddGadgetItem(#COLOUR_COMBO,-1,"32")
    AddGadgetItem(#COLOUR_COMBO,-1,"64")
    AddGadgetItem(#COLOUR_COMBO,-1,"128")
    AddGadgetItem(#COLOUR_COMBO,-1,"192")
    AddGadgetItem(#COLOUR_COMBO,-1,"216")
    AddGadgetItem(#COLOUR_COMBO,-1,"256")
    AddGadgetItem(#COLOUR_COMBO,-1,"32Bit")
    SetGadgetState(#COLOUR_COMBO,colour_num)
    
    CanvasGadget(#IMAGE_GADGET,435,5,230,185,#PB_Canvas_Border)
    
    EnableGadgetDrop(#IMAGE_GADGET,#PB_Drop_Files,#PB_Drag_Copy)
    
    Resume_Window(#MAIN_WINDOW)
    
    Protected hComboEdit = FindWindowEx_(GadgetID(#COLOUR_COMBO), #Null, "Edit", #Null) 
    SetWindowLong_(hComboEdit, #GWL_STYLE, GetWindowLong_(hComboEdit, #GWL_STYLE) | #ES_NUMBER)
    
    ButtonGadget(#START_BUTTON,325,122,105,22,"Start")
    DisableGadget(#START_BUTTON,1)
    ButtonGadget(#BATCH_BUTTON,325,149,50,22,"Batch")
    ButtonGadget(#RESET_BUTTON,380,149,50,22,"Reset")
    CheckBoxGadget(#OVERWRITE_TOGGLE,325,171,105,22,"Overwrite Files?",#PB_CheckBox_Center)
    Make_Command_line()
    SetGadgetText(#COMMAND_STRING,commandline)
    SetGadgetState(#OVERWRITE_TOGGLE,overwrite)
    DisableGadget(#VERT_RES_STRING,#True)
    DisableGadget(#HORIZ_RES_STRING,#True)
  EndIf
EndProcedure

Procedure Reset_Gadgets()
  
  commandline.s=""
  full_commandline.s=""
  input_name.s=""
  input_path.s=""
  output_name.s=""
  output_path.s=Home_Path
  vert_res=0
  horiz_res=0
  q_res=0
  dither=0
  dither_name.s=""
  resize=0
  resize_name.s=""
  colours=256
  colour_num=7
  itype=0
  itype_ext.s="iff"
  overwrite=#True
  append=""
  
  If IsImage(0) : FreeImage(0) : EndIf
  StartDrawing(CanvasOutput(#IMAGE_GADGET))
  Box(0,0,DpiX(GadgetWidth(#IMAGE_GADGET)),DpiY(GadgetHeight(#IMAGE_GADGET)),#White)
  StopDrawing()
  
  SetGadgetText(#INPUT_STRING,input_name)
  SetGadgetText(#OUTPUT_STRING,output_name)
  SetGadgetText(#APPEND_STRING,append)
  SetGadgetText(#VERT_RES_STRING,Str(vert_res))
  SetGadgetText(#HORIZ_RES_STRING,Str(horiz_res))
  SetGadgetState(#RESIZE_METHOD,resize)
  SetGadgetState(#DITHER,dither)
  SetGadgetState(#COLOUR_COMBO,colour_num)
  SetGadgetState(#QUICK_RES_COMBO,q_res)
  SetGadgetState(#OUTPUT_ITYPE_COMBO,itype)
  DisableGadget(#START_BUTTON,#True )
  DisableGadget(#DITHER,#False)
  DisableGadget(#RESIZE_METHOD,#False)
  DisableGadget(#QUICK_RES_COMBO,#False)
  DisableGadget(#VERT_RES_STRING,#False)
  DisableGadget(#HORIZ_RES_STRING,#False)
  DisableGadget(#COLOUR_COMBO,#False)
  SetGadgetState(#OVERWRITE_TOGGLE,overwrite)
  
  Update_Commandline()
  
EndProcedure

Procedure Update_Image(i_path.s)
  
  Protected cline.s
  
  If GetExtensionPart(i_path)="png" Or GetExtensionPart(i_path)="jpg"
    If LoadImage(0,i_path)
      ResizeImage(0,DesktopScaledX(230),DesktopScaledY(185),#PB_Image_Smooth)
      StartDrawing(CanvasOutput(#IMAGE_GADGET))
      DrawImage(ImageID(0),0,0)
      StopDrawing()
    Else
      MessageRequester("Error","Error in image file",#PB_MessageRequester_Ok|#PB_MessageRequester_Error)
    EndIf
  EndIf
  
  If GetExtensionPart(i_path)="webp"
    cline="-out png -o "+GetTemporaryDirectory()+GetFilePart(i_path,#PB_FileSystem_NoExtension)+".png "+i_path
    RunProgram(GetFilePart(NConvert_Path),cline,GetPathPart(NConvert_Path),#PB_Program_Wait|#PB_Program_Hide)
    If LoadImage(0,GetTemporaryDirectory()+GetFilePart(i_path,#PB_FileSystem_NoExtension)+".png")
      DeleteFile(GetTemporaryDirectory()+GetFilePart(i_path,#PB_FileSystem_NoExtension)+".png")
      ResizeImage(0,DesktopScaledX(230),DesktopScaledY(185),#PB_Image_Smooth)
      StartDrawing(CanvasOutput(#IMAGE_GADGET))
      DrawImage(ImageID(0),0,0)
      StopDrawing()
    Else
      MessageRequester("Error","Error in image file",#PB_MessageRequester_Ok|#PB_MessageRequester_Error)
    EndIf
  EndIf
  
  If GetExtensionPart(i_path)="iff"
    If Load_IFF(i_path,0)
      ResizeImage(0,DesktopScaledX(230),DesktopScaledY(185),#PB_Image_Smooth)
      StartDrawing(CanvasOutput(#IMAGE_GADGET))
      DrawImage(ImageID(0),0,0)
      StopDrawing()
    Else
      MessageRequester("Error","Error in image file",#PB_MessageRequester_Ok|#PB_MessageRequester_Error)
      CreateImage(0,230,185,32,#Black)
    EndIf
  EndIf

EndProcedure

;- Program Startup

UseJPEGImageDecoder()
UsePNGImageDecoder()

Create_Window()

;- Main Loop

Repeat
  event=WaitWindowEvent()
  gadget=EventGadget()
  type=EventType()
  Select event
    Case #PB_Event_GadgetDrop
      path=EventDropFiles()
      count=CountString(path,#LF$)
      If count>=1
         Batch_Convert_Drop(path)
      Else 
        If path<>""
          If GetExtensionPart(path)="png" Or GetExtensionPart(path)="jpg" Or GetExtensionPart(path)="gif" Or GetExtensionPart(path)="iff"  Or GetExtensionPart(path)="webp"
            input_name=GetFilePart(path)
            input_path=GetPathPart(path) 
            output_name=GetFilePart(path,#PB_FileSystem_NoExtension)
            output_path=GetPathPart(path)
            SetGadgetText(#INPUT_STRING,input_name) 
            SetGadgetText(#OUTPUT_STRING,output_name+"."+itype_ext)
            DisableGadget(#START_BUTTON,0)
            Update_Image(path)
            Update_Commandline()
          Else
            MessageRequester("Error","Invalid file type!",#PB_MessageRequester_Error|#PB_MessageRequester_Ok)
          EndIf
        EndIf
      EndIf
    Case #PB_Event_CloseWindow : Break
    Case #PB_Event_Gadget
      Select gadget
        Case #OUTPUT_ITYPE_COMBO
          If type=#PB_EventType_Change
            itype=GetGadgetState(#OUTPUT_ITYPE_COMBO)
            itype_ext=LCase(GetGadgetText(#OUTPUT_ITYPE_COMBO))
            Update_Commandline()
            If output_name<>""
              SetGadgetText(#OUTPUT_STRING,output_name+"."+itype_ext)
            EndIf
            If itype=0
              DisableGadget(#DITHER,#False)
              DisableGadget(#RESIZE_METHOD,#False)
              DisableGadget(#QUICK_RES_COMBO,#False)
              DisableGadget(#VERT_RES_STRING,#False)
              DisableGadget(#HORIZ_RES_STRING,#False)
              DisableGadget(#COLOUR_COMBO,#False)
            EndIf
            If itype=1
              DisableGadget(#DITHER,#False)
              DisableGadget(#RESIZE_METHOD,#False)
              DisableGadget(#QUICK_RES_COMBO,#False)
              DisableGadget(#VERT_RES_STRING,#False)
              DisableGadget(#HORIZ_RES_STRING,#False)
              DisableGadget(#COLOUR_COMBO,#True)
            EndIf
            If itype=2
              DisableGadget(#DITHER,#True)
              DisableGadget(#RESIZE_METHOD,#True)
              DisableGadget(#QUICK_RES_COMBO,#True)
              DisableGadget(#VERT_RES_STRING,#True)
              DisableGadget(#HORIZ_RES_STRING,#True)
              DisableGadget(#COLOUR_COMBO,#True)
            EndIf
          EndIf  
        Case #VERT_RES_STRING
          If EventType()=#PB_EventType_Change
            vert_res=Val(GetGadgetText(#VERT_RES_STRING))
            Update_Commandline()
          EndIf
         Case #HORIZ_RES_STRING
          If EventType()=#PB_EventType_Change
            horiz_res=Val(GetGadgetText(#HORIZ_RES_STRING))
            Update_Commandline()
          EndIf         
        Case #QUICK_RES_COMBO
          option=GetGadgetState(#QUICK_RES_COMBO)
          Select option 
            Case 0
              horiz_res=0 : vert_res=0
              DisableGadget(#VERT_RES_STRING,#True)
              DisableGadget(#HORIZ_RES_STRING,#True)
            Case 1
              horiz_res=320 : vert_res=128
              DisableGadget(#VERT_RES_STRING,#True)
              DisableGadget(#HORIZ_RES_STRING,#True)
            Case 2
              horiz_res=320 : vert_res=256
              DisableGadget(#VERT_RES_STRING,#True)
              DisableGadget(#HORIZ_RES_STRING,#True)
            Case 3
              horiz_res=320 : vert_res=512
              DisableGadget(#VERT_RES_STRING,#True)
              DisableGadget(#HORIZ_RES_STRING,#True)
            Case 4
              horiz_res=640 : vert_res=256
              DisableGadget(#VERT_RES_STRING,#True)
              DisableGadget(#HORIZ_RES_STRING,#True)
            Case 5
              horiz_res=640 : vert_res=512
              DisableGadget(#VERT_RES_STRING,#True)
              DisableGadget(#HORIZ_RES_STRING,#True)
            Case 6
              horiz_res=640 : vert_res=824
              DisableGadget(#VERT_RES_STRING,#True)
              DisableGadget(#HORIZ_RES_STRING,#True)
            Case 7
              horiz_res=800 : vert_res=600
              DisableGadget(#VERT_RES_STRING,#True)
              DisableGadget(#HORIZ_RES_STRING,#True)
            Case 8
              horiz_res=1024 : vert_res=768
              DisableGadget(#VERT_RES_STRING,#True)
              DisableGadget(#HORIZ_RES_STRING,#True)
            Case 9
              horiz_res=1280 : vert_res=720
              DisableGadget(#VERT_RES_STRING,#True)
              DisableGadget(#HORIZ_RES_STRING,#True)
            Case 10
              horiz_res=1920 : vert_res=1080
              DisableGadget(#VERT_RES_STRING,#True)
              DisableGadget(#HORIZ_RES_STRING,#True)
            Case 11
              DisableGadget(#VERT_RES_STRING,#False)
              DisableGadget(#HORIZ_RES_STRING,#False)
          EndSelect
          SetGadgetText(#HORIZ_RES_STRING,Str(horiz_res))
          SetGadgetText(#VERT_RES_STRING,Str(vert_res))
          Update_Commandline()
        Case #RESIZE_METHOD
          resize=GetGadgetState(#RESIZE_METHOD)
          Update_Commandline()
        Case #OUTPUT_STRING
          output_name=GetGadgetText(#OUTPUT_STRING)
          output_name=RemoveString(output_name,".iff")
          Update_Commandline()
        Case #DITHER
          dither=GetGadgetState(#DITHER)
          Update_Commandline()
        Case #OVERWRITE_TOGGLE
          overwrite=GetGadgetState(#OVERWRITE_TOGGLE)
          Update_Commandline()
        Case #COLOUR_COMBO
          If type=#PB_EventType_Change
            If GetGadgetText(#COLOUR_COMBO) <> "32Bit"
              colours=Val(GetGadgetText(#COLOUR_COMBO))
            Else
              colours=0
            EndIf
            Update_Commandline()
          EndIf
        Case #INPUT_BUTTON
          path=OpenFileRequester("Select Input Image",input_path,"Image (*.png,*.jpg,*.iff,*.webp)|*.png;*.jpg;*.iff;*.webp",0)
          If path<>""
            If GetExtensionPart(path)="png" Or GetExtensionPart(path)="jpg" Or GetExtensionPart(path)="gif" Or GetExtensionPart(path)="webp"
              input_name=GetFilePart(path)
              input_path=GetPathPart(path) 
              output_name=GetFilePart(path,#PB_FileSystem_NoExtension)
              output_path=GetPathPart(path)
              SetGadgetText(#INPUT_STRING,input_name) 
              SetGadgetText(#OUTPUT_STRING,output_name+"."+itype_ext)
              DisableGadget(#START_BUTTON,0)
              Update_Image(path)
              Update_Commandline()
            Else
              MessageRequester("Error","Invalid file type!",#PB_MessageRequester_Error|#PB_MessageRequester_Ok)
            EndIf
          EndIf
        Case #OUTPUT_BUTTON
          path=InputRequester("Select Output Image Name","Enter A Filename","")
          If path<>""
            output_name=path
            output_path=input_path
            SetGadgetText(#OUTPUT_STRING,output_name+"."+itype_ext)
            Update_Commandline()
          EndIf
        Case #START_BUTTON
          Make_Full_Command_line()
          If MessageRequester("Warning","Create new file?",#PB_MessageRequester_Warning|#PB_MessageRequester_YesNo)=#PB_MessageRequester_Yes
          RunProgram(GetFilePart(NConvert_Path),full_commandline,GetPathPart(NConvert_Path),#PB_Program_Wait)
          RunProgram(output_path,"","")
          EndIf
        Case #RESET_BUTTON
          Reset_Gadgets()
        Case #BATCH_BUTTON
          Batch_Convert()
        Case #APPEND_STRING
          append=GetGadgetText(#APPEND_STRING)
          Update_Commandline()
          
      EndSelect
  EndSelect
ForEver

End    
; IDE Options = PureBasic 6.21 (Windows - x64)
; CursorPosition = 16
; Folding = AA9
; Optimizer
; EnableXP
; DPIAware
; UseIcon = icon.ico
; Executable = E:\ImageConvert\ImageConverter.exe
; Compiler = PureBasic 6.21 - C Backend (Windows - x64)
; Debugger = Standalone