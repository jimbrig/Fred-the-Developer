VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "fredDeveloper_Events"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'Version 0.1.0                                                                  '
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'MIT License                                                                    '
'                                                                               '
'Copyright (c) 2021 M. Scott Lassiter                                           '
'                                                                               '
'Permission is hereby granted, free of charge, to any person obtaining a copy   '
'of this software and associated documentation files (the "Software"), to deal  '
'in the Software without restriction, including without limitation the rights   '
'to use, copy, modify, merge, publish, distribute, sublicense, and/or sell      '
'copies of the Software, and to permit persons to whom the Software is          '
'furnished to do so, subject to the following conditions:                       '
'                                                                               '
'The above copyright notice and this permission notice shall be included in all '
'copies or substantial portions of the Software.                                '
'                                                                               '
'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR     '
'IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,       '
'FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE    '
'AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         '
'LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,  '
'OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE  '
'SOFTWARE.                                                                      '
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Option Explicit

Public Enum fredDebugLogMode
    [_First]
    Disabled = 0
    ToImmediateOnly
    ToExternalOnly
    ToImmediateAndExternal
    [_Last]
End Enum

Public Enum fredEventSettings
    [_First]
    DebugLogging = 0
    DebugExternalFilePath
    [_Last]
End Enum

Private cdp As Object   'Custom Document Properties, declared in Initialization
Private fso As Object   'FileScriptingObject

Private TicToc As Single

Private Sub Class_Initialize()
    
    Dim localLoggingMode As Integer
    Dim localLoggingFilePath As String
    
    Set cdp = ThisWorkbook.CustomDocumentProperties
    Set fso = CreateObject("Scripting.FileSystemObject")
    
    On Error Resume Next    'If the saved values aren't already available, create them.
                            'Makes sure the values are available for use, but does nothing to verify they are
                            'the correct type and the names were not coopted by some other program or user.
    localLoggingMode = cdp("DebugLogging")
    If Err <> 0 Then Call InitializeSettingDebugLogging
    Err = 0
    
    localLoggingFilePath = cdp("DebugExternalFilePath")
    If Err <> 0 Then Call InitializeSettingDebugExternalFilePath
    
    On Error GoTo 0
    
    TicToc = Timer
    
End Sub

Private Sub InitializeSettingDebugLogging()
    'Establishes the CDP "DebugLogging" with default values
    
    On Error Resume Next
    cdp("DebugLogging").Delete
    cdp.Add Name:="DebugLogging", LinkToContent:=False, Type:=msoPropertyTypeNumber, Value:=fredDebugLogMode.ToImmediateOnly
    On Error GoTo 0
    
End Sub

Private Sub InitializeSettingDebugExternalFilePath()
    'Establishes the CDP "DebugExternalFilePath" with default values
    
    On Error Resume Next
    cdp("DebugExternalFilePath").Delete
    cdp.Add Name:="DebugExternalFilePath", LinkToContent:=False, Type:=msoPropertyTypeString, Value:=DefaultLoggingFilePathAddress
    On Error GoTo 0
    
End Sub

Private Function DefaultLoggingFilePathAddress() As String
    'Path address of form: "\WorkbookDirectory\WorkbookName_DebugLog.txt"
    
    DefaultLoggingFilePathAddress = ThisWorkbook.Path & "\" & fso.GetBaseName(Replace(ThisWorkbook.Name, " ", "")) & "_DebugLog.txt"

End Function

Public Sub RestoreDefaultSetting(EventSetting As fredEventSettings)
    'Force deletes the setting then reinitializes the class to establish the default. Leave SettingName blank to restore all settings to default.
    
    If EventSetting = DebugLogging Then Call InitializeSettingDebugLogging
    If EventSetting = DebugExternalFilePath Then Call InitializeSettingDebugExternalFilePath
    
    Call Class_Initialize
    
End Sub

Public Sub Log(LogEntry As String)
    'Outputs the provided LogEntry to either the Immediate window, an external file, or both as specified by LoggingMode.
    
    Select Case LoggingMode
        Case Is = Disabled
            Exit Sub
        Case Is = ToImmediateOnly
            Debug.Print LogEntry
        Case Is = ToExternalOnly
            LogToExternalTextFile (LogEntry)
        Case Is = ToImmediateAndExternal
            Debug.Print LogEntry
            LogToExternalTextFile (LogEntry)
    End Select
    
End Sub

Private Sub CreateNewExternalDebugLogFile(LogFilePath As String, Optional ForceOverwrite As Boolean)
    'Creates a new debug log file. If the file already existed, this script reinitializes it.
    
    'Dim OverwriteBoolean As Boolean
    Dim MsgResponse As Integer
    Dim LogFile As Object
    
    'If the file exists and the optional ForceOverwrite was either not specified or was listed as False, then ask the user if they are SURE they want to overwrite their log file.
    If fso.FileExists(LogFilePath) Then
        If IsMissing(ForceOverwrite) Or ForceOverwrite = False Then
            MsgResponse = MsgBox("This log file already exists. Are you sure you want to overwrite it? This cannot be undone.", vbYesNo, "Log Already Exists")
            If MsgResponse = vbNo Then Exit Sub
        End If
    End If
    
    Set LogFile = fso.CreateTextFile(LogFilePath, True)
    
    'Write the default header information to the top of the log file
    With LogFile
        .WriteLine ("Debug Log file for " & ThisWorkbook.Name)
        .WriteLine ("Logging powered by Fred the Developer (https://github.com/M-Scott-Lassiter/Fred-the-Developer) under the MIT license, Copyright (c) 2021.")
        .WriteLine ("Log created within " & Application.Value & " by " & Application.UserName & " on " & DateTime & ".")
        .WriteLine
        .Close
    End With
    
End Sub

Private Sub LogToExternalTextFile(LogEntry As String)
    
    Dim LogFile As Object
    
    Open LoggingFilePath For Append As #1
    
    Print #1, DateTime & "|" & Application.UserName & "|" & LogEntry
    
    Close #1

End Sub

Private Function DateTime() As String
    'Provides a formatted date/time string for logging purposes, e.g. "1/31/2021 18:27:33"
    
    DateTime = Date & " " & Format(Time, "hh:mm:ss")
    
End Function

Public Property Let LoggingMode(LogMode As fredDebugLogMode)
    'This property makes use of the CDPs.
    
    cdp("DebugLogging") = LogMode
    
End Property

Public Property Get LoggingMode() As fredDebugLogMode
    
    LoggingMode = cdp("DebugLogging")

End Property

Public Property Let LoggingFilePath(FilePathAddress As String)
    'If the specified path exists, then update the cdp path address and set the object equal to the file. However, if the path does NOT exist, give the user
    '   a chance to create it. If they do, great! Proceed as planned. However, we don't want to create unexpected files on their computer. So, if the user
    '   decides to NOT create this file, not only will the cdp get left as is, the LoggingMode will get set to either Disabled or ToImmediateOnly.
    'This property makes use of the CDPs.
    
    Dim MsgResponse As Integer
    Dim propertyTest As String
    
    FilePathAddress = CleanFilePath(FilePathAddress)
    
    'Test if this file even exists or not
    If Not (fso.FileExists(FilePathAddress)) Then
        MsgResponse = MsgBox("This file does not exist. Would you like to create it?", vbYesNo, "File Not Found")
        If MsgResponse = vbYes Then
            Call CreateNewExternalDebugLogFile(FilePathAddress)
        Else
            If LoggingMode = ToImmediateAndExternal Then LoggingMode = ToImmediateOnly
            If LoggingMode = ToExternalOnly Then LoggingMode = Disabled
            Exit Property
        End If
    End If
    
    'Set the end use variables as required
    cdp("DebugExternalFilePath") = FilePathAddress
    
End Property

Public Property Get LoggingFilePath() As String
    
    LoggingFilePath = cdp("DebugExternalFilePath")

End Property

Private Function CleanFilePath(PathAddress As String) As String
    
    'PLACEHOLDER FOR VALIDATING FILEPATH EXISTS
    
'    Do While Right(PathAddress, 1) = "\"
'        PathAddress = Left(PathAddress, Len(PathAddress) - 1)
'    Loop
    CleanFilePath = PathAddress
    
End Function

Public Sub Tic()
    'Sets the current time to TicToc. Used in conjunction with a subsequent Toc call.
    
    TicToc = Timer
    
End Sub

Public Property Get Toc() As Double
    'Calculates the time difference, in seconds, between now and when the last Tic call was made. Assists developers when trying to calculate the time it takes to run a method.
    '   Because VBA resets its Timer at system midnight, if the Toc value is less than the original Tic, then it just happened to roll over the new day.
    '   Add the number of seconds in a day to TicToc to get an accurate Toc.
    
    Toc = Timer
    If Toc < TicToc Then Toc = Toc + 86400
    
    Toc = (Toc - TicToc)
    
End Property
