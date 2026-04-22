;- ############### ImageConverter Info
;
Global Version.s="v0.1e"
;
; © 2026 Paul Vince (MrV2k)
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
; Added webp support.
; Added iff support.
; Added pdf output.
; Added 320x128 resolution.
;
;============================================
; VERSION INFO v0.1b
;============================================
;
; Fixed name spelling (D'oh!).
; Added version number to window title.
;
;============================================
; VERSION INFO v0.1c
;============================================
;
; Added workaround for non compatable IFF files.
;
;============================================
; VERSION INFO v0.1d
;============================================
;
; Added paste image from clipboard.
; Fixed batch procedure error if no folder selected.
; Changed 'Command Line' procedures to macros.
; Added console output to image conversion to speed up operation.
; Changed gadget positions
; Added zoomable preview window
; Added more scaling types
; Fixed preview image size
;
;============================================
; VERSION INFO v0.1e
;============================================
;
; Added the ability to keep the original image's aspect ratio when processing it.
; Added the ability to change the image background colour on aspect ratio corrected images.
; Removed the buggy IFF loading procedure and fixed the preview for IFF images.
;
;- ############### Enumerations

Enumeration
  #MAIN_WINDOW
  #PREVIEW_WINDOW
  #OPEN_BUTTON
  #IMAGE_CANVAS
  #CLOSE_BUTTON
  #START_BUTTON
  #OUTPUT_STRING
  #OUTPUT_BUTTON
  #INPUT_STRING
  #INPUT_BUTTON
  #APPEND_STRING
  #PREVIEW_BUTTON
  #PREVIEW_IMAGE
  #PREVIEW_IMAGE_CANVAS
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
  #CLIP_BUTTON
  #TEMP_IMAGE
  #KEEP_ASPECT_CHECKBOX
  #BACKGROUND_COLOUR_BUTTON
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
Global keep_aspect.b=#False
Global back_colour.l
Global resize=0
Global resize_name.s=""
Global colours=256
Global colour_num=7
Global itype=0
Global itype_ext.s="iff"
Global count.i
Global overwrite.b=#True
Global append.s=""
Global zoom=1
Global preview_w, preview_h

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

Macro Center_Frame(value)
  
  SetWindowLongPtr_(GadgetID(value), #GWL_STYLE, GetWindowLongPtr_(GadgetID(value), #GWL_STYLE) | #BS_CENTER)
  
EndMacro

Macro Window_Update() ; <---------------------------------------------> Waits For Window Update
  While WindowEvent() : Wend
EndMacro

Macro Make_Command_line()
  
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
        Case 1 : full_commandline+" -rtype quick"
        Case 2 : full_commandline+" -rtype linear"
        Case 3 : full_commandline+" -rtype hermite"
        Case 4 : full_commandline+" -rtype gaussian"
        Case 5 : full_commandline+" -rtype bell"
        Case 6 : full_commandline+" -rtype bspline"
        Case 7 : full_commandline+" -rtype mitchell"
        Case 8 : full_commandline+" -rtype hanning"
        Case 9 : full_commandline+" -rtype lanczos"
        Case 10 : full_commandline+" -rtype lanczos2"
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
  
EndMacro

Procedure Make_Full_Command_line(preview.b)
  
  Protected n_ext.s, n_path.s
  
  full_commandline=""
  
  If overwrite
    full_commandline+" -overwrite "
  EndIf
  
  If preview
    n_ext="png"
    n_path=Home_Path+"preview"
  Else
    n_ext=itype_ext
    n_path=output_path+output_name
  EndIf
  
  full_commandline+" -out "+n_ext
  full_commandline+" -o "+#DOUBLEQUOTE$+n_path+"."+n_ext+#DOUBLEQUOTE$
  
  If itype=0
    full_commandline+" -c 1"
  EndIf
  
  If itype<>2
    If vert_res<>0 And horiz_res<>0
      full_commandline+" -resize "+horiz_res+" "+vert_res
      Select resize
        Case 1 : full_commandline+" -rtype quick"
        Case 2 : full_commandline+" -rtype linear"
        Case 3 : full_commandline+" -rtype hermite"
        Case 4 : full_commandline+" -rtype gaussian"
        Case 5 : full_commandline+" -rtype bell"
        Case 6 : full_commandline+" -rtype bspline"
        Case 7 : full_commandline+" -rtype mitchell"
        Case 8 : full_commandline+" -rtype hanning"
        Case 9 : full_commandline+" -rtype lanczos"
        Case 10 : full_commandline+" -rtype lanczos2"
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

Macro Draw_Preview()
  
  StartDrawing(CanvasOutput(#PREVIEW_IMAGE_CANVAS))
  DrawImage(ImageID(#PREVIEW_IMAGE),0,0)
  StopDrawing()
  
EndMacro

Procedure Batch_Convert()
   
  Protected NewList Batch_list.s()
  Protected Hwnd
  
  input_path=PathRequester("Select A Folder",Home_Path)
  If input_path<>""
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
        Make_Full_Command_line(#False)
        RunProgram(GetFilePart(NConvert_Path),full_commandline,GetPathPart(NConvert_Path),#PB_Program_Wait)
      Next
      RunProgram(output_path,"","")
    EndIf
    
    CloseConsole()
    
  Else
    
    MessageRequester("Error","No folder selected!",#PB_MessageRequester_Error|#PB_MessageRequester_Ok)
    
  EndIf   
  
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
      Make_Full_Command_line(#False)
      RunProgram(GetFilePart(NConvert_Path),full_commandline,GetPathPart(NConvert_Path),#PB_Program_Wait)
    Next
    RunProgram(output_path,"","")
  EndIf
  
  CloseConsole()
    
  FreeList(Batch_list())
  
EndProcedure

Procedure Preview_Window()
  
  OpenConsole("Processing...")
  Center_Console()
  
  Make_Full_Command_line(#True)
  RunProgram(GetFilePart(NConvert_Path),full_commandline,GetPathPart(NConvert_Path),#PB_Program_Wait)
  
  CloseConsole()
  
  LoadImage(#PREVIEW_IMAGE,Home_Path+"preview.png")
  
  DisableWindow(#MAIN_WINDOW,#True)
  
  OpenWindow(#PREVIEW_WINDOW, 0, 0, DesktopUnscaledX(ImageWidth(#PREVIEW_IMAGE)), DesktopUnscaledY(ImageHeight(#PREVIEW_IMAGE)), "Preview Window (F1 to zoom)", #PB_Window_SystemMenu | #PB_Window_WindowCentered, WindowID(#MAIN_WINDOW))
  CanvasGadget(#PREVIEW_IMAGE_CANVAS,0,0,WindowWidth(#PREVIEW_WINDOW),WindowHeight(#PREVIEW_WINDOW))
  
  SetActiveWindow(#PREVIEW_WINDOW)
  
  Draw_Preview()
EndProcedure

Procedure Create_Window()
  
  Protected fgadget
  
  If OpenWindow(#MAIN_WINDOW,0,0,740,235,"Image Converter "+Version,#PB_Window_SystemMenu|#PB_Window_ScreenCentered)
    
    Pause_Window(#MAIN_WINDOW)
    
    fgadget=FrameGadget(#PB_Any,5,0,425,50,"Command Line")
    Center_Frame(fgadget)
    StringGadget(#COMMAND_STRING,10,20,350,20,"",#PB_String_ReadOnly)
    SetGadgetColor(#COMMAND_STRING,#PB_Gadget_FrontColor,#White)
    SetGadgetColor(#COMMAND_STRING,#PB_Gadget_BackColor,#Black)
    TextGadget(#PB_Any,365,0,55,20," Append ")
    StringGadget(#APPEND_STRING,365,20,60,20,append)
    SetGadgetColor(#APPEND_STRING,#PB_Gadget_FrontColor,#White)
    SetGadgetColor(#APPEND_STRING,#PB_Gadget_BackColor,#Black)
            
    fgadget=FrameGadget(#PB_Any,5,50,210,70,"Images")
    Center_Frame(fgadget)
    StringGadget(#INPUT_STRING,10,70,95,22,"",#PB_String_ReadOnly)
    StringGadget(#OUTPUT_STRING,110,70,100,22,output_name)
    ButtonGadget(#INPUT_BUTTON,10,94,95,22,"Input Image")
    ButtonGadget(#OUTPUT_BUTTON,110,94,100,22,"Output Image")
    EnableGadgetDrop(#INPUT_STRING,#PB_Drop_Files,#PB_Drag_Copy)
    
    fgadget=FrameGadget(#PB_Any,220,50,100,70,"Resize")
    Center_Frame(fgadget)
    StringGadget(#HORIZ_RES_STRING,225,70,37,22,Str(vert_res),#PB_String_Numeric)
    TextGadget(#PB_Any,268,71,10,22,"x")
    StringGadget(#VERT_RES_STRING,280,70,37,22,Str(horiz_res),#PB_String_Numeric)  
    ComboBoxGadget(#QUICK_RES_COMBO,225,94,90,22)
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
    
    fgadget=FrameGadget(#PB_Any,5,120,210,110,"Resize Options",#PB_Frame_Container)
    Center_Frame(fgadget)
    TextGadget(#PB_Any,5,15,95,20,"Type",#PB_Text_Center)
    ComboBoxGadget(#RESIZE_METHOD,5,35,95,20)
    AddGadgetItem(#RESIZE_METHOD,-1,"None")
    AddGadgetItem(#RESIZE_METHOD,-1,"Quick")
    AddGadgetItem(#RESIZE_METHOD,-1,"Bilinear") 
    AddGadgetItem(#RESIZE_METHOD,-1,"Hermite")
    AddGadgetItem(#RESIZE_METHOD,-1,"Gaussian")
    AddGadgetItem(#RESIZE_METHOD,-1,"Bell")
    AddGadgetItem(#RESIZE_METHOD,-1,"BSpline")
    AddGadgetItem(#RESIZE_METHOD,-1,"Mitchell")
    AddGadgetItem(#RESIZE_METHOD,-1,"Hanning")
    AddGadgetItem(#RESIZE_METHOD,-1,"Lanczos")
    AddGadgetItem(#RESIZE_METHOD,-1,"Lanczos2")
    
    SetGadgetState(#RESIZE_METHOD,resize)
    TextGadget(#PB_Any,105,15,100,20,"Dither",#PB_Text_Center)
    ComboBoxGadget(#DITHER,105,35,100,20)
    AddGadgetItem(#DITHER,-1,"None")
    AddGadgetItem(#DITHER,-1,"Floyd")
    AddGadgetItem(#DITHER,-1,"Bayer")
    SetGadgetState(#DITHER,dither)
    
    CheckBoxGadget(#KEEP_ASPECT_CHECKBOX,40,60,150,20,"Keep Image Aspect",#PB_CheckBox_Center)
    
    ButtonGadget(#BACKGROUND_COLOUR_BUTTON,5,85,50,20,"Select")
    TextGadget(#PB_Any,60,86,140,21,"Image Background Colour")
    DisableGadget(#BACKGROUND_COLOUR_BUTTON,#True)   
    
    CloseGadgetList()
    
    fgadget=FrameGadget(#PB_Any,220,185,210,45,"Output",#PB_Frame_Container)
    Center_Frame(fgadget)
    TextGadget(#PB_Any,10,22,80,20,"Image Format",#PB_Text_Center)
    ComboBoxGadget(#OUTPUT_ITYPE_COMBO,110,20,90,20)
    AddGadgetItem(#OUTPUT_ITYPE_COMBO,-1,"IFF/ILBM")
    AddGadgetItem(#OUTPUT_ITYPE_COMBO,-1,"PNG")
    AddGadgetItem(#OUTPUT_ITYPE_COMBO,-1,"PDF")
    SetGadgetState(#OUTPUT_ITYPE_COMBO,itype)
    CloseGadgetList()
    
    fgadget=FrameGadget(#PB_Any,220,120,100,65,"Colour")
    Center_Frame(fgadget)
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
    
    CanvasGadget(#IMAGE_CANVAS,435,5,300,225,#PB_Canvas_Border)   
    EnableGadgetDrop(#IMAGE_CANVAS,#PB_Drop_Files,#PB_Drag_Copy)
    
    Resume_Window(#MAIN_WINDOW)
    
    Protected hComboEdit = FindWindowEx_(GadgetID(#COLOUR_COMBO), #Null, "Edit", #Null) 
    SetWindowLong_(hComboEdit, #GWL_STYLE, GetWindowLong_(hComboEdit, #GWL_STYLE) | #ES_NUMBER)
    
    FrameGadget(#PB_Any,325,50,105,130,"")
    ButtonGadget(#PREVIEW_BUTTON,327,65,50,22,"Preview")
    DisableGadget(#PREVIEW_BUTTON,1)
    ButtonGadget(#CLIP_BUTTON,377,65,50,22,"Paste")
    ButtonGadget(#BATCH_BUTTON,327,92,50,22,"Batch")
    ButtonGadget(#RESET_BUTTON,377,92,50,22,"Reset")
    ButtonGadget(#START_BUTTON,333,120,90,30,"Start")
    DisableGadget(#START_BUTTON,1)
    CheckBoxGadget(#OVERWRITE_TOGGLE,340,155,75,22,"Overwrite?",#PB_CheckBox_Center)
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
  keep_aspect=#False
  back_colour=#Black
  
  If FileSize(Home_Path+"Clip_Image.png")>-1
    DeleteFile(Home_Path+"Clip_Image.png")
  EndIf
    
  If IsImage(0) : FreeImage(0) : EndIf
  
  StartDrawing(CanvasOutput(#IMAGE_CANVAS))
  Box(0,0,DpiX(GadgetWidth(#IMAGE_CANVAS)),DpiY(GadgetHeight(#IMAGE_CANVAS)),#White)
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
  SetGadgetState(#KEEP_ASPECT_CHECKBOX,keep_aspect)
  DisableGadget(#BACKGROUND_COLOUR_BUTTON,#True)
  DisableGadget(#PREVIEW_BUTTON,#True)
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

Macro Draw_Image()
  
  If Not keep_aspect
    
    ResizeImage(0,DesktopScaledX(imagex),DesktopScaledY(imagey),#PB_Image_Smooth)
    
  Else
       
    imagex=DesktopScaledX(imagex)
    imagey=DesktopScaledY(imagey)
    
    cline="-quiet -out png -o "+Home_Path+"temp.png"+" -c 1 -rtype lanczos2 -ratio -resize "+imagex+" "+imagey+" -bgcolor "+Str(cr)+" "+Str(cg)+" "+Str(cb)+" "+" -canvas "+imagex+" "+imagey+" center -resize "+imagex+" "+imagey+" "+#DOUBLEQUOTE$+i_path+#DOUBLEQUOTE$
    
    RunProgram(GetFilePart(NConvert_Path),cline,GetPathPart(NConvert_Path),#PB_Program_Wait|#PB_Program_Hide)    
    LoadImage(0,Home_Path+"temp.png")       
    DeleteFile(Home_Path+"temp.png")
    
  EndIf
  
  StartDrawing(CanvasOutput(#IMAGE_CANVAS))
  DrawImage(ImageID(0),0,0)
  StopDrawing()
  
EndMacro

Procedure Update_Image(i_path.s)
  
  Protected cline.s, imagex, imagey, cr, cg, cb
  
  imagex=GadgetWidth(#IMAGE_CANVAS)
  imagey=GadgetHeight(#IMAGE_CANVAS)
  cr=Red(back_colour)
  cg=Green(back_colour)
  cb=Blue(back_colour)
  
  StartDrawing(CanvasOutput(#IMAGE_CANVAS))
  Box(0,0,DpiX(GadgetWidth(#IMAGE_CANVAS)),DpiY(GadgetHeight(#IMAGE_CANVAS)),#White)
  StopDrawing()
  
  If GetExtensionPart(i_path)="png" Or GetExtensionPart(i_path)="jpg"
    If LoadImage(0,i_path)
      Draw_Image()
    Else
      MessageRequester("Error","Error in image file",#PB_MessageRequester_Ok|#PB_MessageRequester_Error)
    EndIf
  EndIf
  
  If GetExtensionPart(i_path)="webp" Or GetExtensionPart(i_path)="iff"
    cline="-out png -o "+GetTemporaryDirectory()+GetFilePart(i_path,#PB_FileSystem_NoExtension)+".png "+i_path
    RunProgram(GetFilePart(NConvert_Path),cline,GetPathPart(NConvert_Path),#PB_Program_Wait|#PB_Program_Hide)
    If LoadImage(0,GetTemporaryDirectory()+GetFilePart(i_path,#PB_FileSystem_NoExtension)+".png")
      DeleteFile(GetTemporaryDirectory()+GetFilePart(i_path,#PB_FileSystem_NoExtension)+".png")
      Draw_Image()
    Else
      MessageRequester("Error","Error in image file",#PB_MessageRequester_Ok|#PB_MessageRequester_Error)
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
      
    Case #WM_KEYDOWN
      
      If EventwParam() = #VK_F1
        If IsWindow(#PREVIEW_WINDOW)
          CloseWindow(#PREVIEW_WINDOW)
          If zoom=1 
            ResizeImage(#PREVIEW_IMAGE,ImageWidth(#PREVIEW_IMAGE)*2,ImageHeight(#PREVIEW_IMAGE)*2,#PB_Image_Raw) 
            zoom=2
          Else
            ResizeImage(#PREVIEW_IMAGE,ImageWidth(#PREVIEW_IMAGE)/2,ImageHeight(#PREVIEW_IMAGE)/2,#PB_Image_Raw)
            zoom=1
          EndIf
          OpenWindow(#PREVIEW_WINDOW, 0, 0, DesktopUnscaledX(ImageWidth(#PREVIEW_IMAGE)), DesktopUnscaledY(ImageHeight(#PREVIEW_IMAGE)), "Preview Window (F1 to Zoom)", #PB_Window_SystemMenu | #PB_Window_WindowCentered, WindowID(#MAIN_WINDOW))
          CanvasGadget(#PREVIEW_IMAGE_CANVAS,0,0,WindowWidth(#PREVIEW_WINDOW),WindowHeight(#PREVIEW_WINDOW))
          Draw_Preview()
        EndIf
        Window_Update()
      EndIf
      
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
            DisableGadget(#PREVIEW_BUTTON,0)
            Update_Image(path)
            Update_Commandline()
          Else
            MessageRequester("Error","Invalid file type!",#PB_MessageRequester_Error|#PB_MessageRequester_Ok)
          EndIf
        EndIf
      EndIf
      
    Case #PB_Event_CloseWindow 
      If IsWindow(#PREVIEW_WINDOW)
        CloseWindow(#PREVIEW_WINDOW)
        zoom=1
        Window_Update()
        DeleteFile(Home_Path+"preview.png")
        DisableWindow(#MAIN_WINDOW,#False)
      Else
        Break
      EndIf
 
      
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
          
        Case #BACKGROUND_COLOUR_BUTTON
          back_colour=ColorRequester()
          Update_Image(path)
          
        Case #KEEP_ASPECT_CHECKBOX
          keep_aspect=GetGadgetState(#KEEP_ASPECT_CHECKBOX)
          If GetGadgetState(#KEEP_ASPECT_CHECKBOX) = 0
            DisableGadget(#BACKGROUND_COLOUR_BUTTON,#True)
          Else
            DisableGadget(#BACKGROUND_COLOUR_BUTTON,#False)
          EndIf
          Update_Image(path)
          
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
          Make_Full_Command_line(#False)
          If MessageRequester("Warning","Create new file?",#PB_MessageRequester_Warning|#PB_MessageRequester_YesNo)=#PB_MessageRequester_Yes 
            OpenConsole()
            Center_Console()
            PrintN("Processing Image...")
            RunProgram(GetFilePart(NConvert_Path),full_commandline,GetPathPart(NConvert_Path),#PB_Program_Wait)
            CloseConsole()
            RunProgram(output_path,"","")
          EndIf
          
        Case #RESET_BUTTON
          Reset_Gadgets()
          
        Case #BATCH_BUTTON
          Batch_Convert()
          
        Case #APPEND_STRING
          append=GetGadgetText(#APPEND_STRING)
          Update_Commandline()
          
        Case #CLIP_BUTTON
          If GetClipboardImage(#TEMP_IMAGE)
            path=Home_Path+"Clip_Image.png"
            DeleteFile(path)
            SaveImage(#TEMP_IMAGE,path)
            input_name=GetFilePart(path)
            input_path=GetPathPart(path) 
            output_name=GetFilePart(path,#PB_FileSystem_NoExtension)
            output_path=GetPathPart(path)
            SetGadgetText(#INPUT_STRING,input_name) 
            SetGadgetText(#OUTPUT_STRING,output_name+"."+itype_ext)
            DisableGadget(#START_BUTTON,0)
            DisableGadget(#PREVIEW_BUTTON,0)
            Update_Image(path)
            Update_Commandline()
          Else
            MessageRequester("Error","No image in clipboard!",#PB_MessageRequester_Ok|#PB_MessageRequester_Error)
          EndIf
          
        Case #PREVIEW_BUTTON
          Preview_Window()
          
      EndSelect
  EndSelect
ForEver

End    
; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 506
; FirstLine = 211
; Folding = AAI+
; Optimizer
; EnableThread
; EnableXP
; DPIAware
; UseIcon = icon.ico
; Executable = E:\ImageConvert\ImageConverter.exe
; Compiler = PureBasic 6.21 (Windows - x64)
; Debugger = Standalone