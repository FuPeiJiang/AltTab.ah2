#SingleInstance force
ListLines 0
KeyHistory 0
SendMode "Input" ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir ; Ensures a consistent starting directory.

SetWinDelay -1

isValidWindow(hWnd) {
    returnValue := false
    breakToReturnFalse:
    loop 1 {
        title := WinGetTitle("ahk_id " hwnd)
        if (!title) {
            break breakToReturnFalse
        }
        dwExStyle := WinGetExStyle("ahk_id " hWnd)
        if (!(dwExStyle & 0x00040000)) {
            if (dwExStyle & 0x00000080 || dwExStyle & 0x08000000) {
                break breakToReturnFalse
            }
            owner_hWnd := DllCall("GetWindow", "Ptr", hWnd, "Uint", 4)
            if (owner_hWnd) {
                break breakToReturnFalse
            }
        }
        returnValue := true
    }
    return returnValue
}
CoordMode "Mouse", "Screen"

winTitleArr:=[]
winIdArr:=[]
backgroundHexArr:=[]
yPos:=-1

refresh_list() {
    global winTitleArr, winIdArr, backgroundHexArr

    winTitleArr:=[]
    winIdArr:=[]
    backgroundHexArr:=[]

    hBitmapMap:=Map()
    for thisHwnd in WinGetList() {
        if (isValidWindow(thisHwnd)) {
            winTitle:=WinGetTitle(thisHwnd)
            if (thisHwnd == hWnd) {
                continue
            }
            if (InStr(winTitle," - ahk_explorer")) {
                continue
            }
            className:=WinGetClass(thisHwnd)
            processName:=WinGetProcessName(thisHwnd)
            backgroundHex:=0x202020
            if (className=="#32770" && InStr(processName,"AutoHotkey")) {
                try {
                    text:=ControlGetText("Static1", thisHwnd)
                } catch {
                    text:=ControlGetText("RichEdit20W1", thisHwnd)
                }
                winTitle.=" <" SubStr(text,1,100)
                backgroundHex:=0xF0F0F0
            }
            switch processName {
                case "Code.exe":
                    backgroundHex:=0xEFD966
                    ; for those who use:
                    ; "window.title": "${rootPath} <${activeEditorLong}> - VS Code",
                    loop 1 {
                        pos_lessThan:=InStr(winTitle,"<",true)
                        if (!pos_lessThan) {
                            break
                        }
                        pos_slash:=InStr(winTitle,"\",true,pos_lessThan,-1)
                        if (!pos_slash) {
                            break
                        }
                        pos_greaterThan:=InStr(winTitle,">",true,pos_lessThan)
                        if (!pos_greaterThan) {
                            break
                        }
                        pos_slash2:=InStr(winTitle,"\",true,pos_greaterThan,-1)
                        if (!pos_slash2) {
                            break
                        }
                        winTitle:=SubStr(winTitle,pos_slash+1,pos_lessThan-pos_slash-2) " <" SubStr(winTitle,pos_slash2+1,pos_greaterThan-pos_slash2-1)
                    }
                case "chrome.exe":
                    backgroundHex:=rgb_to_bgr(0xE43D30)

            }
            backgroundHexArr.Push(backgroundHex)
            winTitleArr.Push(winTitle)
            winIdArr.Push(thisHwnd)
        }
    }
}

hBrush_black:=DllCall("CreateSolidBrush","Uint",0x0,"Ptr")

hFont_Consolas := DllCall("CreateFontA",
    "Int",24,  ; font height
    "Int",0,   ; font width (0 = default)
    "Int",0,   ; escapement (0 = default)
    "Int",0,   ; orientation (0 = default)
    "Int",400,  ; font weight
    "Uint",0,     ; italic
    "Uint",0,     ; underline
    "Uint",0,     ; strikeout
    "Uint",1,  ; character set
    "Uint",0, ;iOutPrecision
    "Uint",0, ;iClipPrecision
    "Uint",6, ;iQuality
    "Uint",0,
    "Str","Consolas") ; font family name

; hFont_Consolas_Bold := DllCall("CreateFontA",
;     "Int",24,  ; font height
;     "Int",0,   ; font width (0 = default)
;     "Int",0,   ; escapement (0 = default)
;     "Int",0,   ; orientation (0 = default)
;     "Int",400,  ; font weight
;     "Uint",0,     ; italic
;     "Uint",0,     ; underline
;     "Uint",0,     ; strikeout
;     "Uint",1,  ; character set
;     "Uint",0, ;iOutPrecision
;     "Uint",0, ;iClipPrecision
;     "Uint",6, ;iQuality
;     "Uint",0,
;     "Str","Consolas") ; font family name

WNDCLASSEXW := Buffer(0x50)
NumPut("Uint", 0x50, WNDCLASSEXW, 0x0) ;cbSize
NumPut("Uint", 3, WNDCLASSEXW, 0x4) ;Style
NumPut("Ptr", CallbackCreate(MyWndProc), WNDCLASSEXW, 0x8) ;lpfnWndProc
NumPut("Int", 0, WNDCLASSEXW, 0x10) ;cbClsExtra
NumPut("Int", 0, WNDCLASSEXW, 0x1C) ;cbWndExtra
NumPut("Ptr", 0, WNDCLASSEXW, 0x18) ;hInstance
NumPut("Ptr", 0, WNDCLASSEXW, 0x20) ;hIcon
NumPut("Ptr", DllCall("LoadCursorA","Ptr",0,"Ptr",32512,"Ptr"), WNDCLASSEXW, 0x28) ;hCursor
NumPut("Ptr", DllCall("CreateSolidBrush", "Uint", 0x000000, "Ptr"), WNDCLASSEXW, 0x30) ;hbrBackground
NumPut("Ptr", 0, WNDCLASSEXW, 0x38) ;lpszMenuName
class_name := Buffer(StrPut("ResizableWindow", "UTF-16"))
StrPut("ResizableWindow", class_name.Ptr, "UTF-16")
NumPut("Ptr", class_name.Ptr, WNDCLASSEXW, 0x40)
NumPut("Ptr", 0, WNDCLASSEXW, 0x48)
ret:=DllCall("RegisterClassExW", "Ptr", WNDCLASSEXW, "Ptr")
selectedIdx:=2
idxMoved:=false
hWnd:=DllCall("CreateWindowExW","Uint",0,"Str","ResizableWindow","Str","My Resizable Window","Uint",0x80000000,"Int",0,"Int",0,"Int",800,"Int",800,"Ptr",0,"Ptr",0,"Ptr",0,"Ptr",0,"Ptr")
; hWnd:=DllCall("CreateWindowExW","Uint",8,"Str","ResizableWindow","Str","My Resizable Window","Uint",0x80000000,"Int",0,"Int",0,"Int",800,"Int",800,"Ptr",0,"Ptr",0,"Ptr",0,"Ptr",0,"Ptr")

refresh_list()
WinMove 100,100,,winTitleArr.Length*100,hWnd
paint(hWnd)

rgb_to_bgr(rbgHex) {
    return ((rbgHex & 0x0000FF) << 16) | ((rbgHex & 0xFF0000) >> 16) | (rbgHex & 0x00FF00)
}

paint(hWnd) {
    global selectedIdx, winTitleArr, backgroundHexArr, hFont_Consolas, hBrush_black
    hdc:=DllCall("GetDC","Ptr",hWnd,"Ptr")
    hdcMem:=DllCall("CreateCompatibleDC","Ptr",hdc,"Ptr")
    hdcMem2:=DllCall("CreateCompatibleDC","Ptr",hdc,"Ptr")
    hbm:=DllCall("CreateCompatibleBitmap","Ptr",hdc,"Int",800,"Int",100*winTitleArr.Length,"Ptr")
    DllCall("SelectObject","Ptr",hdcMem,"Ptr",hbm)

    for k, v in winTitleArr {
        rect:=Buffer(0x10)
        NumPut("Int",0,rect,0x0)
        NumPut("Int",800,rect,0x8)
        NumPut("Int",((k-1)*100),rect,0x4)
        NumPut("Int",((k-1)*100)+100,rect,0xC)
        ; colorHex:=0x0

        ; colorHex:=Random(0x0,0xFFFFFF)
        ; if (A_Index==selectedIdx) {
        if (false) {
            colorHex:=0x0000FF
            ; colorHex:=0xFFFFFF
            ; colorHex:=rgb_to_bgr(0xE9D838)
            ; colorHex:=0x000000
            ; colorHex:=0xEFD966
            ; colorHex:=rgb_to_bgr(0x4A7856)
            ; colorHex:=rgb_to_bgr(0xF79A32)
            ; colorHex:=0x329AF7
            ; colorHex:=0xFFFFFF
            backgroundHex:=0x0
            ; backgroundHex:=0xFFFFFF
            lettersBackgroundHex:=0xEFD966
            ; colorHex:=0x202020
            ; R:66
            ; G:D9
            ; B:EF
            DllCall("SelectObject","Ptr",hdcMem,"Ptr",hFont_Consolas)

            ; BGR
        } else {
            colorHex:=0xF0F0F0
            ; backgroundHex:=0x202020
            ; backgroundHex:=0xEFD966
            backgroundHex:=backgroundHexArr[k]
            ; backgroundHex:=rgb_to_bgr(0x0087D1)
            ; backgroundHex:=rgb_to_bgr(0x25AEF3)
            lettersBackgroundHex:=0x202020
            DllCall("SelectObject","Ptr",hdcMem,"Ptr",hFont_Consolas)

        }
        hBrush:=DllCall("CreateSolidBrush","Uint",backgroundHex,"Ptr")
        DllCall("FillRect","Ptr",hdcMem,"Ptr",rect,"Ptr",hBrush)
        DllCall("DeleteObject","Ptr",hBrush)
        DllCall("SetBkColor","Ptr",hdcMem,"Uint",lettersBackgroundHex)
        DllCall("SetTextColor","Ptr",hdcMem,"Uint",colorHex)
        NumPut("Int",100,rect,0x0)

        if (k==selectedIdx) {
            rect2:=Buffer(0x10)
            NumPut("Int",0,rect2,0x0)
            NumPut("Int",85,rect2,0x8)
            NumPut("Int",((k-1)*100) + 25,rect2,0x4)
            NumPut("Int",((k-1)*100)+100 - 25,rect2,0xC)
            DllCall("FillRect","Ptr",hdcMem,"Ptr",rect2,"Ptr",hBrush_black)
            NumPut("Int",715,rect2,0x0)
            NumPut("Int",800,rect2,0x8)
            DllCall("FillRect","Ptr",hdcMem,"Ptr",rect2,"Ptr",hBrush_black)
        }


        ; DllCall("BitBlt","Ptr",hdcMem,"Int",0,"Int",((A_Index-1)*100),"Int",800,"Int",100,"Ptr",hdcMem2,"Int",0,"Int",0,"Uint",0x00CC0020)
        ; DllCall("SelectObject","Ptr",hdcMem2,"Ptr",ok)
        DllCall("DrawTextW","Ptr",hdcMem,"Str",v,"Int",StrLen(v),"Ptr",rect,"Uint",0x00000024)
    }

    DllCall("BitBlt","Ptr",hdc,"Int",0,"Int",0,"Int",800,"Int",100*winTitleArr.Length,"Ptr",hdcMem,"Int",0,"Int",0,"Uint",0x00CC0020)
    DllCall("DeleteDC","Ptr",hdcMem)
    DllCall("DeleteObject","Ptr",hbm)
    DllCall("ReleaseDC","Ptr",0,"Ptr",hdc)
}

MyWndProc(hWnd, uMsg, wParam, lParam) {
    global selectedIdx, yPos, idxMoved
    Critical
    ; FileAppend uMsg "`n", "*"
    switch (uMsg) {
        case 0x0008: ;WM_KILLFOCUS
            WinHide hWnd
        case 0x0201: ;WM_LBUTTONDOWN
            y:=(lParam >> 16) & 0xFFFF
            idx:=(y // 100) + 1
            WinHide hWnd
            WinActivate winIdArr[idx]
        case 0x0204: ;WM_RBUTTONDOWN
            WinHide hWnd
            ; ExitApp
        case 0x0200: ;WM_MOUSEMOVE
            x:=lParam & 0xFFFF
            y:=(lParam >> 16) & 0xFFFF
            DllCall("ClientToScreen","Ptr",hWnd,"Uint64*",&idkParam:=(x | y<<32))
            yScreen:=(idkParam >> 32) & 0xFFFFFFFF
            idx:=(y // 100) + 1
                ; FileAppend x " " y "`n", "*"
            if (yScreen!=yPos) {
                ; ToolTip yScreen " " yPos
                yPos:=yScreen
                if (idx!=selectedIdx) {
                    selectedIdx:=idx
                    ; idxMoved:=true
                    ; DllCall("RedrawWindow","Ptr",hWnd,"Ptr",0,"Ptr",0,"Uint",0x101) ;0x1=RDW_INVALIDATE, 0x100=RDW_UPDATENOW
                    ; FileAppend selectedIdx "`n", "*"
                }
            }
            paint(hWnd)
            return 0
        case 0x0002:
            DllCall("DestroyWindow","Ptr",hWnd)
    }
    return DllCall("DefWindowProc","Ptr",hWnd,"Uint",uMsg,"UInt64",wParam,"Int64",lParam)
}

okSure() {
    global hWnd, idxMoved
    idxMoved:=false
    refresh_list()

    ; WinMove 100,100,,winTitleArr.Length*100,hWnd
    DllCall("SetWindowPos","Ptr",hWnd,"Ptr",-1,"Int",100,"Int",100,"Int",800,"Int",winTitleArr.Length*100,"Uint",0x0000)
    ; WinActivate hWnd
    ; DllCall("SetWindowLongPtrW","Ptr",hWnd,"Int",-16,"Ptr",DllCall("GetWindowLongPtrW","Ptr",hWnd,"Int",-16,"Ptr") ^ 0x10000000)


    ; sure:=DllCall("SetActiveWindow","Ptr",hWnd,"Ptr")
    ; sure:=DllCall("SetForegroundWindow","Ptr",hWnd,"Ptr")
    ; paint(hWnd)
    DllCall("ShowWindow","Ptr",hWnd,"Uint",1)
    ; DllCall("QueryPerformanceCounter","Uint64*",&sure1:=0)
    ; DllCall("ShowWindow","Ptr",hWnd,"Uint",9)
    ; DllCall("QueryPerformanceCounter","Uint64*",&sure2:=0)
    ; MsgBox (sure2 - sure1) / 10000 " ms"
    ; DllCall("ShowWindow","Ptr",hWnd,"Uint",4)
    ; sure:=DllCall("BringWindowToTop","Ptr",hWnd,"Ptr")
    ; sure:=DllCall("SetFocus","Ptr",hWnd,"Ptr")
    ; WinRestore hWnd
    paint(hWnd)
    WinActivate hWnd

    ; paint(hWnd)
    ; paint(hWnd)
    ; DllCall("ShowWindow","Ptr",hWnd,"Uint",1)
}

!Tab::{
    global yPos, selectedIdx

    MouseGetPos ,&OutputVarY
    yPos:=OutputVarY
    selectedIdx:=2
    okSure()
}
!+Tab::
!^+Tab::{
    global yPos, selectedIdx, winTitleArr

    MouseGetPos ,&OutputVarY
    yPos:=OutputVarY
    selectedIdx:=winTitleArr.Length
    okSure()
}

#HotIf WinActive(hWnd)
!Tab::{
    global idxMoved, selectedIdx, hWnd, winTitleArr

    if (idxMoved) {
        idxMoved:=false
        selectedIdx:=1
    } else {
        ++selectedIdx
        if (selectedIdx > winTitleArr.Length) {
            selectedIdx:=1
        }
    }
    paint(hWnd)
    WinActivate hWnd
}
!+Tab::
!^+Tab::{
    global idxMoved, selectedIdx, hWnd, winTitleArr

    if (idxMoved) {
        idxMoved:=false
        selectedIdx:=winTitleArr.Length
    } else {
        --selectedIdx
        if (selectedIdx < 1) {
            selectedIdx:=winTitleArr.Length
        }
    }
    paint(hWnd)
    WinActivate hWnd
}
~Alt Up::{
    global idxMoved, hWnd
    if (!idxMoved) {
        WinHide hWnd
        WinActivate winIdArr[selectedIdx]
    } else {
        WinActivate hWnd
    }
}
*up::{
    global selectedIdx, hWnd, idxMoved, winTitleArr
    --selectedIdx
    if (selectedIdx < 1) {
        selectedIdx:=winTitleArr.Length
    }
    idxMoved:=true
    paint(hWnd)
    WinActivate hWnd
}
*down::{
    global selectedIdx, hWnd, idxMoved, winTitleArr
    ++selectedIdx
    if (selectedIdx > winTitleArr.Length) {
        selectedIdx:=1
    }
    idxMoved:=true
    paint(hWnd)
    WinActivate hWnd
}
*left::{
    global selectedIdx, winTitleArr, hWnd
    WinHide hWnd
    WinActivate winIdArr[selectedIdx]
}
*right::{
    global selectedIdx, winTitleArr, hWnd
    WinClose winIdArr[selectedIdx]
    winTitleArr.RemoveAt(selectedIdx)
    winIdArr.RemoveAt(selectedIdx)
    backgroundHexArr.RemoveAt(selectedIdx)
    ; needsActivate:=false
    if (selectedIdx > winTitleArr.Length) {
        selectedIdx:=winTitleArr.Length
        ; needsActivate:=true
    }
    DllCall("SetWindowPos","Ptr",hWnd,"Ptr",-1,"Int",100,"Int",100,"Int",800,"Int",winTitleArr.Length*100,"Uint",0x0000)
    paint(hWnd)
    ; if (needsActivate) {
    ; }
    WinActivate hWnd
}
#HotIf

return

; f3::Exitapp