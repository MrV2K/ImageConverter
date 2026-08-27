;- ############### ImageConverter Info
;
Global Version.s="v0.1f"
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
;============================================
; VERSION INFO v0.1f
;============================================
;
; Added multiple image format support.
; Fixed file append not being added to output file.
; Changed all gadget panels to containers.
; Simplified image loading.
; Added GIF frame capture.
; Cleaned up redundant code.
; Offloaded most image processing to NConvert.
; Added JPEG file output.
; Updated drag and drop to all file types.
; Fixed crash bug in aspect ratio button if no image loaded.
; Fixed single image drag and drop not clearing multi drop lists.
;
;- ############### Enumerations

EnableExplicit

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
  #FRAME_NEXT_BUTTON
  #FRAME_PREV_BUTTON
  #FRAME_FIRST_BUTTON
  #FRAME_LAST_BUTTON
  #FRAME_INFO_TEXT
  
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
Global cr,cb,cg, hWnd
Global is_gif.b
Global gif_frame.i
Global gif_length.i
Global imagex.i, imagey.i
Global cline.s
Global i_path.s

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
  
  cr=Red(back_colour)
  cg=Green(back_colour)
  cb=Blue(back_colour)  
  
  commandline=""
  commandline+GetFilePart(NConvert_Path) 
  
  If overwrite
    commandline+" -overwrite "
  EndIf
  
  commandline+"-out "+itype_ext+" "
  
  If is_gif
    commandline+"-page "+Str(gif_frame)+" "
  EndIf
      
  If output_name<>""
    commandline+"-o "+output_name+append+"."+itype_ext+" "
  Else
    commandline+"-o <NONE> "
  EndIf
  
  If itype_ext="jpeg"
    commandline+"-32bits "
  EndIf
  
  If itype=0
    commandline+"-c 1 "
  EndIf
  
  If keep_aspect
    commandline+"-ratio "
  EndIf  
      
  If itype<>3
    
    If vert_res<>0 And horiz_res<>0

      commandline+" -resize "+horiz_res+" "+vert_res
        Select resize
        Case 1 : full_commandline+"-rtype quick "
        Case 2 : full_commandline+"-rtype linear "
        Case 3 : full_commandline+"-rtype hermite "
        Case 4 : full_commandline+"-rtype gaussian "
        Case 5 : full_commandline+"-rtype bell "
        Case 6 : full_commandline+"-rtype bspline "
        Case 7 : full_commandline+"-rtype mitchell "
        Case 8 : full_commandline+"-rtype hanning "
        Case 9 : full_commandline+"-rtype lanczos "
        Case 10 : full_commandline+"-rtype lanczos2 "
        EndSelect
    EndIf
  EndIf
  
  If keep_aspect
    commandline+"-bgcolor "+Str(cr)+" "+Str(cg)+" "+Str(cb)+" "+" -canvas "+horiz_res+" "+vert_res+" center -resize "+horiz_res+" "+vert_res+" "
  EndIf
  
  If itype=0
    If colours<>0
      commandline+"-colors "+Str(colours)+" "
      If dither=1
        commandline+"-floyd "
      EndIf
      If dither=2
        commandline+"-dither "
      EndIf
    EndIf
  EndIf

  If input_name<>""
    commandline+input_name
  EndIf
  
EndMacro

Procedure Make_Full_Command_line(preview.b)
  
  Protected n_ext.s, n_path.s
  
  cr=Red(back_colour)
  cg=Green(back_colour)
  cb=Blue(back_colour)  
  
  full_commandline=""
  
  If overwrite
    full_commandline+" -overwrite "
  EndIf
  
  If preview
    n_ext="png"
    n_path=Home_Path+"Preview"
  Else
    n_ext=itype_ext
    n_path=output_path+output_name
  EndIf
  
  If is_gif
    full_commandline+"-page "+Str(gif_frame)+" "
  EndIf
  
  If itype_ext="jpeg"
    full_commandline+"-32bits "
  EndIf
  
  full_commandline+"-out "+n_ext+" "
  full_commandline+"-o "+#DOUBLEQUOTE$+n_path+append+"."+n_ext+#DOUBLEQUOTE$+" "
  
  If itype=0
    full_commandline+"-c 1 "
  EndIf
  
  If itype<>3
    
    If vert_res<>0 And horiz_res<>0
      If keep_aspect
        full_commandline+"-ratio "
      EndIf
      full_commandline+"-resize "+horiz_res+" "+vert_res+" "
      Select resize
        Case 1 : full_commandline+"-rtype quick "
        Case 2 : full_commandline+"-rtype linear "
        Case 3 : full_commandline+"-rtype hermite "
        Case 4 : full_commandline+"-rtype gaussian "
        Case 5 : full_commandline+"-rtype bell "
        Case 6 : full_commandline+"-rtype bspline "
        Case 7 : full_commandline+"-rtype mitchell "
        Case 8 : full_commandline+"-rtype hanning "
        Case 9 : full_commandline+"-rtype lanczos "
        Case 10 : full_commandline+"-rtype lanczos2 "
      EndSelect
    EndIf
  EndIf

  If keep_aspect
    full_commandline+"-bgcolor "+Str(cr)+" "+Str(cg)+" "+Str(cb)+" "+" -canvas "+horiz_res+" "+vert_res+" center -resize "+horiz_res+" "+vert_res+" "
  EndIf
  
  If itype=0
    If colours<>0
      full_commandline+"-colors "+Str(colours)+" "
      Select Dither
        Case 1 : full_commandline+"-floyd "
        Case 2 : full_commandline+"-dither "
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

Macro Pause_Window(window)
  SendMessage_(WindowID(window),#WM_SETREDRAW,#False,0)
EndMacro

Macro Resume_Window(window)
  SendMessage_(WindowID(window),#WM_SETREDRAW,#True,0)
  RedrawWindow_(WindowID(window),#Null,#Null,#RDW_INVALIDATE)
EndMacro

Procedure Batch_Convert()
   
  Protected NewList Batch_list.s()
  
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
  Protected i
  
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

Procedure Draw_Preview()
  
  StartDrawing(CanvasOutput(#PREVIEW_IMAGE_CANVAS))
  DrawImage(ImageID(#PREVIEW_IMAGE),0,0)
  StopDrawing()
  
EndProcedure

Procedure Preview_Window()
    
  OpenConsole("Processing...")
  Center_Console()
  
  If FileSize(Home_Path+"Preview.png")>-1
    DeleteFile(Home_Path+"Preview.png")
  EndIf
    
  Make_Full_Command_line(#True)
  
  RunProgram(GetFilePart(NConvert_Path),full_commandline,GetPathPart(NConvert_Path),#PB_Program_Wait)
  
  CloseConsole()
  
  LoadImage(#PREVIEW_IMAGE,Home_Path+"Preview.png")
  
  DisableWindow(#MAIN_WINDOW,#True)
  
  OpenWindow(#PREVIEW_WINDOW, 0, 0, DesktopUnscaledX(ImageWidth(#PREVIEW_IMAGE)), DesktopUnscaledY(ImageHeight(#PREVIEW_IMAGE)), "Preview Window (F1 to zoom)", #PB_Window_SystemMenu | #PB_Window_WindowCentered, WindowID(#MAIN_WINDOW))
  CanvasGadget(#PREVIEW_IMAGE_CANVAS,0,0,WindowWidth(#PREVIEW_WINDOW),WindowHeight(#PREVIEW_WINDOW))
  
  SetActiveWindow(#PREVIEW_WINDOW)
  
  Draw_Preview() 
  
EndProcedure

Procedure Create_Window()
  
  Protected fgadget
  
  If OpenWindow(#MAIN_WINDOW,0,0,765,265,"Image Converter "+Version,#PB_Window_SystemMenu|#PB_Window_ScreenCentered)
    
    Pause_Window(#MAIN_WINDOW)
    
    fgadget=FrameGadget(#PB_Any,5,0,430,50,"Command Line",#PB_Frame_Container)
    Center_Frame(fgadget)
    StringGadget(#COMMAND_STRING,10,20,350,20,"",#PB_String_ReadOnly)
    SetGadgetColor(#COMMAND_STRING,#PB_Gadget_FrontColor,#White)
    SetGadgetColor(#COMMAND_STRING,#PB_Gadget_BackColor,#Black)
    TextGadget(#PB_Any,365,0,55,20," Append ")
    StringGadget(#APPEND_STRING,365,20,60,20,append)
    SetGadgetColor(#APPEND_STRING,#PB_Gadget_FrontColor,#White)
    SetGadgetColor(#APPEND_STRING,#PB_Gadget_BackColor,#Black)
    CloseGadgetList()
    
    fgadget=FrameGadget(#PB_Any,5,50,210,75,"Images",#PB_Frame_Container)
    Center_Frame(fgadget)
    StringGadget(#INPUT_STRING,10,20,95,22,"",#PB_String_ReadOnly)
    StringGadget(#OUTPUT_STRING,110,20,100,22,output_name)
    ButtonGadget(#INPUT_BUTTON,10,44,95,25,"Input Image")
    ButtonGadget(#OUTPUT_BUTTON,110,44,100,25,"Output Image")
    EnableGadgetDrop(#INPUT_STRING,#PB_Drop_Files,#PB_Drag_Copy)
    CloseGadgetList()
    
    fgadget=FrameGadget(#PB_Any,220,50,100,75,"Resize",#PB_Frame_Container)
    Center_Frame(fgadget)
    StringGadget(#HORIZ_RES_STRING,5,20,37,22,Str(vert_res),#PB_String_Numeric)
    TextGadget(#PB_Any,48,21,10,22,"x")
    StringGadget(#VERT_RES_STRING,60,20,37,22,Str(horiz_res),#PB_String_Numeric)  
    ComboBoxGadget(#QUICK_RES_COMBO,5,45,90,22)
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
    CloseGadgetList()
    
    fgadget=FrameGadget(#PB_Any,5,125,210,65,"Resize Options",#PB_Frame_Container)
    Center_Frame(fgadget)
    TextGadget(#PB_Any,5,20,95,20,"Type",#PB_Text_Center)
    ComboBoxGadget(#RESIZE_METHOD,5,40,95,20)
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
    TextGadget(#PB_Any,105,20,100,20,"Dither",#PB_Text_Center)
    ComboBoxGadget(#DITHER,105,40,100,20)
    AddGadgetItem(#DITHER,-1,"None")
    AddGadgetItem(#DITHER,-1,"Floyd")
    AddGadgetItem(#DITHER,-1,"Bayer")
    SetGadgetState(#DITHER,dither)
    CloseGadgetList()
    
    fgadget=FrameGadget(#PB_Any,5,190,210,70,"Image Aspect",#PB_Frame_Container)
    Center_Frame(fgadget)
    CheckBoxGadget(#KEEP_ASPECT_CHECKBOX,35,20,150,20,"Keep Image Aspect",#PB_CheckBox_Center)
    ButtonGadget(#BACKGROUND_COLOUR_BUTTON,5,45,50,20,"Select")
    TextGadget(#PB_Any,60,46,140,21,"Image Background Colour")
    DisableGadget(#BACKGROUND_COLOUR_BUTTON,#True)   
    CloseGadgetList()
    
    fgadget=FrameGadget(#PB_Any,220,190,100,70,"Image Output",#PB_Frame_Container)
    Center_Frame(fgadget)
    TextGadget(#PB_Any,10,22,80,20,"Image Format",#PB_Text_Center)
    ComboBoxGadget(#OUTPUT_ITYPE_COMBO,5,45,90,20)
    AddGadgetItem(#OUTPUT_ITYPE_COMBO,-1,"IFF/ILBM")
    AddGadgetItem(#OUTPUT_ITYPE_COMBO,-1,"PNG") 
    AddGadgetItem(#OUTPUT_ITYPE_COMBO,-1,"JPEG")
    AddGadgetItem(#OUTPUT_ITYPE_COMBO,-1,"PDF")
    SetGadgetState(#OUTPUT_ITYPE_COMBO,itype)
    CloseGadgetList()
    
    fgadget=FrameGadget(#PB_Any,220,125,100,65,"Colour",#PB_Frame_Container)
    Center_Frame(fgadget)
    TextGadget(#PB_Any,5,20,90,20,"Set Colours",#PB_Text_Center)
    ComboBoxGadget(#COLOUR_COMBO,5,40,90,20,#PB_ComboBox_Editable)
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
    CloseGadgetList()
    
    fgadget=FrameGadget(#PB_Any,440,0,320,255,"Preview",#PB_Frame_Container)
    Center_Frame(fgadget)    
    CanvasGadget(#IMAGE_CANVAS,10,20,300,225,#PB_Canvas_Border)   
    EnableGadgetDrop(#IMAGE_CANVAS,#PB_Drop_Files,#PB_Drag_Copy)
    CloseGadgetList()

    fgadget=FrameGadget(#PB_Any,325,50,110,140,"Output",#PB_Frame_Container)
    Center_Frame(fgadget) 
    ButtonGadget(#PREVIEW_BUTTON,5,20,50,22,"Preview")
    DisableGadget(#PREVIEW_BUTTON,1)
    ButtonGadget(#CLIP_BUTTON,55,20,50,22,"Paste")
    ButtonGadget(#BATCH_BUTTON,5,45,50,22,"Batch")
    ButtonGadget(#RESET_BUTTON,55,45,50,22,"Reset")
    ButtonGadget(#START_BUTTON,10,75,90,30,"Start")
    DisableGadget(#START_BUTTON,1)
    CheckBoxGadget(#OVERWRITE_TOGGLE,15,110,75,22,"Overwrite?",#PB_CheckBox_Center)
    CloseGadgetList()
    
    fgadget=FrameGadget(#PB_Any,325,190,110,70,"GIF Control",#PB_Frame_Container)
    Center_Frame(fgadget) 
    TextGadget(#FRAME_INFO_TEXT,5,20,100,20,"No Image",#PB_Text_Center)
    ButtonGadget(#FRAME_FIRST_BUTTON,5,40,25,25,"|<")
    GadgetToolTip(#FRAME_FIRST_BUTTON,"First Frame")
    ButtonGadget(#FRAME_PREV_BUTTON,30,40,25,25,"<")
    GadgetToolTip(#FRAME_PREV_BUTTON,"Previous Frame")
    ButtonGadget(#FRAME_NEXT_BUTTON,55,40,25,25,">")
    GadgetToolTip(#FRAME_NEXT_BUTTON,"Next Frame")
    ButtonGadget(#FRAME_LAST_BUTTON,80,40,25,25,">|")
    GadgetToolTip(#FRAME_LAST_BUTTON,"Last Frame")
    DisableGadget(#FRAME_FIRST_BUTTON,1)
    DisableGadget(#FRAME_LAST_BUTTON,1)
    DisableGadget(#FRAME_NEXT_BUTTON,1)
    DisableGadget(#FRAME_PREV_BUTTON,1)
    CloseGadgetList()
    
    Make_Command_line()
    SetGadgetText(#COMMAND_STRING,commandline)
    SetGadgetState(#OVERWRITE_TOGGLE,overwrite)
    DisableGadget(#VERT_RES_STRING,#True)
    DisableGadget(#HORIZ_RES_STRING,#True)
    
    Resume_Window(#MAIN_WINDOW)
    
    Protected hComboEdit = FindWindowEx_(GadgetID(#COLOUR_COMBO), #Null, "Edit", #Null) 
    SetWindowLong_(hComboEdit, #GWL_STYLE, GetWindowLong_(hComboEdit, #GWL_STYLE) | #ES_NUMBER)  
    
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
  is_gif=#False
  gif_frame=0
  gif_length=0
  
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
  DisableGadget(#FRAME_FIRST_BUTTON,1)
  DisableGadget(#FRAME_LAST_BUTTON,1)
  DisableGadget(#FRAME_NEXT_BUTTON,1)
  DisableGadget(#FRAME_PREV_BUTTON,1)
  TextGadget(#FRAME_INFO_TEXT,5,20,100,20,"No Image",#PB_Text_Center)
  
  Update_Commandline()
  
EndProcedure

Procedure Update_GIF()

  If is_gif
    SetGadgetText(#FRAME_INFO_TEXT,"Frame "+Str(gif_frame+1)+" of "+Str(gif_length))
    DisableGadget(#FRAME_FIRST_BUTTON,0)
    DisableGadget(#FRAME_LAST_BUTTON,0)
    DisableGadget(#FRAME_NEXT_BUTTON,0)
    DisableGadget(#FRAME_PREV_BUTTON,0)
  Else
    SetGadgetText(#FRAME_INFO_TEXT,"No Image")
    DisableGadget(#FRAME_FIRST_BUTTON,1)
    DisableGadget(#FRAME_LAST_BUTTON,1)
    DisableGadget(#FRAME_NEXT_BUTTON,1)
    DisableGadget(#FRAME_PREV_BUTTON,1)
  EndIf
  
EndProcedure

Procedure Draw_Image(i_path.s)
  
  imagex=GadgetWidth(#IMAGE_CANVAS)
  imagey=GadgetHeight(#IMAGE_CANVAS)
  imagex=DesktopScaledX(imagex)
  imagey=DesktopScaledY(imagey)
  cr=Red(back_colour)
  cg=Green(back_colour)
  cb=Blue(back_colour)
  
  If FileSize(Home_Path+"temp.png")<>-1
    DeleteFile(Home_Path+"temp.png")
  EndIf
  
  If GetExtensionPart(i_path)="gif" 
    is_gif=#True 
    If LoadImage(0,i_path)
      gif_length=ImageFrameCount(0) 
    EndIf
    FreeImage(0) 
  Else 
    is_gif=#False
  EndIf
  
  Update_GIF()
  
  If Not keep_aspect
    
    cline="-quiet -out png -o "+Home_Path+"temp.png"
    If is_gif
      cline+" -page "+Str(gif_frame)
    EndIf    
    cline+" -c 1 -rtype lanczos2 -resize "+imagex+" "+imagey+" "+#DOUBLEQUOTE$+i_path+#DOUBLEQUOTE$
    
  Else

    cline="-quiet -out png -o "+Home_Path+"temp.png"
    If is_gif
      cline+" -page "+Str(gif_frame)
    EndIf
    cline+" -c 1 -rtype lanczos2 -ratio -resize "+imagex+" "+imagey+" -bgcolor "+Str(cr)+" "+Str(cg)+" "+Str(cb)+" "+" -canvas "+imagex+" "+imagey+" center -resize "+imagex+" "+imagey+" "+#DOUBLEQUOTE$+i_path+#DOUBLEQUOTE$
 
  EndIf

  RunProgram(GetFilePart(NConvert_Path),cline,GetPathPart(NConvert_Path),#PB_Program_Wait|#PB_Program_Hide)    
  LoadImage(0,Home_Path+"temp.png")       
  DeleteFile(Home_Path+"temp.png")
    
  StartDrawing(CanvasOutput(#IMAGE_CANVAS))
  DrawImage(ImageID(0),0,0)
  StopDrawing()
  
EndProcedure

;- Program Startup

UseJPEGImageDecoder()
UsePNGImageDecoder()
UseGIFImageDecoder()

DeleteFile(Home_Path+"Clip_Image.png")
DeleteFile(Home_Path+"Temp_Image.png")
DeleteFile(Home_Path+"Preview.png")

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
            input_name=GetFilePart(path)
            input_path=GetPathPart(path) 
            output_name=GetFilePart(path,#PB_FileSystem_NoExtension)
            output_path=GetPathPart(path)
            SetGadgetText(#INPUT_STRING,input_name) 
            SetGadgetText(#OUTPUT_STRING,output_name+"."+itype_ext)
            DisableGadget(#START_BUTTON,0)
            DisableGadget(#PREVIEW_BUTTON,0)
            Draw_Image(path)
            Update_Commandline()
        EndIf
      EndIf
      
    Case #PB_Event_CloseWindow 
      If IsWindow(#PREVIEW_WINDOW)
        CloseWindow(#PREVIEW_WINDOW)
        zoom=1
        Window_Update()
        DeleteFile(Home_Path+"Preview.png")
        DisableWindow(#MAIN_WINDOW,#False)
      Else
        Break
      EndIf
 
      
    Case #PB_Event_Gadget
      
      Select gadget
          
        Case #FRAME_NEXT_BUTTON
          If gif_frame<(gif_length-1)
            gif_frame+1 
            Update_GIF()
            Update_Commandline()
            Draw_Image(input_path+input_name)
          EndIf

        Case #FRAME_PREV_BUTTON
          If gif_frame>0
            gif_frame-1 
            Update_GIF()
            Update_Commandline()
            Draw_Image(input_path+input_name)
          EndIf
          
        Case #FRAME_FIRST_BUTTON
            gif_frame=0
            Update_GIF()
            Update_Commandline()
            Draw_Image(input_path+input_name)
          
        Case #FRAME_LAST_BUTTON
            gif_frame=gif_length-1
            Update_GIF()
            Update_Commandline()
            Draw_Image(input_path+input_name)
         
        Case #OUTPUT_ITYPE_COMBO
          If type=#PB_EventType_Change
            
            itype=GetGadgetState(#OUTPUT_ITYPE_COMBO)
            
            Select itype
              Case 0          
                itype_ext="iff"
              Case 1
                itype_ext="png"
              Case 2
                itype_ext="jpeg"
              Case 3
                itype_ext="pdf"
            EndSelect
            
            If output_name<>""
              SetGadgetText(#OUTPUT_STRING,output_name+"."+itype_ext)
            EndIf
            
            Select itype
              Case 0,1
                DisableGadget(#DITHER,#False)
                DisableGadget(#RESIZE_METHOD,#False)
                DisableGadget(#QUICK_RES_COMBO,#False)
                DisableGadget(#VERT_RES_STRING,#False)
                DisableGadget(#HORIZ_RES_STRING,#False)
                DisableGadget(#COLOUR_COMBO,#False)
              Case 2
                DisableGadget(#DITHER,#False)
                DisableGadget(#RESIZE_METHOD,#False)
                DisableGadget(#QUICK_RES_COMBO,#False)
                DisableGadget(#VERT_RES_STRING,#False)
                DisableGadget(#HORIZ_RES_STRING,#False)
                DisableGadget(#COLOUR_COMBO,#True)
              Case 3
                DisableGadget(#DITHER,#True)
                DisableGadget(#RESIZE_METHOD,#True)
                DisableGadget(#QUICK_RES_COMBO,#True)
                DisableGadget(#VERT_RES_STRING,#True)
                DisableGadget(#HORIZ_RES_STRING,#True)
                DisableGadget(#COLOUR_COMBO,#True)
            EndSelect
            
            Update_Commandline()
            
          EndIf
          
        Case #BACKGROUND_COLOUR_BUTTON
          back_colour=ColorRequester()
          Draw_Image(input_path+input_name)
          Update_Commandline()
          
        Case #KEEP_ASPECT_CHECKBOX
          keep_aspect=GetGadgetState(#KEEP_ASPECT_CHECKBOX)
          If GetGadgetState(#KEEP_ASPECT_CHECKBOX) = 0
            DisableGadget(#BACKGROUND_COLOUR_BUTTON,#True)
          Else
            DisableGadget(#BACKGROUND_COLOUR_BUTTON,#False)
          EndIf
          If input_name <>""
           Draw_Image(input_path+input_name)
           Update_Commandline()
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
          path=OpenFileRequester("Select Input Image",input_path,"*.*",0)
          If path<>""
              input_name=GetFilePart(path)
              input_path=GetPathPart(path) 
              output_name=GetFilePart(path,#PB_FileSystem_NoExtension)
              output_path=GetPathPart(path)
              SetGadgetText(#INPUT_STRING,input_name) 
              SetGadgetText(#OUTPUT_STRING,output_name+"."+itype_ext)
              DisableGadget(#START_BUTTON,0)
              Draw_Image(input_path+input_name)
              Update_Commandline()
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
            Draw_Image(input_path+input_name)
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
; IDE Options = PureBasic 6.41 (Windows - x64)
; CursorPosition = 69
; FirstLine = 33
; Folding = ghA-
; Optimizer
; EnableThread
; EnableXP
; DPIAware
; UseIcon = icon.ico
; Executable = E:\ImageConvert\ImageConverter.exe
; Compiler = PureBasic 6.40 - C Backend (Windows - x64)
; Debugger = Standalone