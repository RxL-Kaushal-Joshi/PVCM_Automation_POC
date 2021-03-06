 On Error Resume Next

Dim App, sWorkspace, sFileName, blnBuildStatus

' ----------------------------------------------variables-------------------------------------

Dim TestName,TestDescription,TestPath, Status, FailureReason, ExecutionTime, StartTime_Global, EndTime_Global
'-------------------------------------------------------------------------------------------------------------------------------------

Private sWorkspacePath, sAutomationCommonPath

' workspace declared 

sWorkspacePath = "C:\TestJenkins"

'File name for reading the input data

sFileName = "C:\TestJenkins\Test.txt"

WScript.Echo "Reading the input file:" & sFileName

'Get the UFT Tests into an array

Set objFSO = CreateObject("scripting.FileSystemObject")

Set objTextFile = objFSO.OpenTextFile (sFileName, 1, True)   

sList = objTextFile.ReadAll()

objTextFile.Close

If Err.Number <> 0 OR sList = "" Then

    WScript.Echo "Error while reading the file:" & sFileName

    blnBuildStatus = 99

End If

sTempList = Split(sList,vbcrlf)

' WScript.Echo "-----------------------------------------------------"

' WScript.Echo "Listing all tests to be executed..."

' WScript.Echo "-----------------------------------------------------"

For i=0 to ubound(sTempList)

     'Test Cases

    sTempTCData = sTempTCData & sTempList(i) & ";"

Next 

iF sTempTCData <> "" THEN

    sTempTCData = mid(sTempTCData,1,Len(sTempTCData)-1)

End If   

Dim sArrList       

sArrList = Split(sTempTCData,";")

'Create object for UFT and launch 
Set App = CreateObject("QuickTest.Application")

App.Launch

App.Visible=True

blnBuildStatus = 0

'Set UFT options

App.Options.Run.ImageCaptureForTestResults = "OnError"

App.Options.Run.RunMode = "Fast"

App.Options.Run.ViewResults = False

'get the test case path and name
Dim QTP_Tests(1)
QTP_Tests(1)=sWorkspacePath & Replace(Trim(sArrList(0)),vbTab,"")
sTemp = QTP_Tests(1)
 
'Choosing the required addins for each test

' Create an array containing the list of addins associated with this test

arrTestAddins = App.GetAssociatedAddinsForTest(QTP_Tests(1))

If Err.Number <> 0 Then

                WScript.Echo "Error while finding addins for test: " & sTemp & ". Check the test case name and path is correct"

                blnBuildStatus = 99

Else

                ' Check if all required add-ins are all already loaded

                blnNeedChangeAddins = False

                ' Assume no change is necessary              

                For Each testAddin In arrTestAddins ' Iterate over the test's associated add-ins list             

                    If App.Addins(testAddin).Status <> "Active" Then

                        ' If an associated add-in is not loaded

						blnNeedChangeAddins = True

                        ' Indicate that a change in the loaded add-ins is necessary

                        Exit For

                        ' Exit the loop

                    End If

                Next

                If App.Launched And blnNeedChangeAddins Then

                    App.Quit ' If a change is necessary, exit UFT to modify the loaded add-ins

                End If 

                If blnNeedChangeAddins Then

                    WScript.Echo "Adding required addins"

                    Dim blnActivateOK

                    blnActivateOK = App.SetActiveAddins(arrTestAddins, errorDescription)

					' Load the add-ins associated with the test and check whether they load successfully.

                    If Not blnActivateOK Then ' If a problem occurs while loading the add-ins

                        WScript.Echo "Error while loading addins"

                        blnBuildStatus = 99

                    End If

                End If

                If Not App.Launched Then ' If UFT is not yet open

                    App.Launch ' Start UFT (with the correct add-ins loaded)

                End If

                App.Visible = True ' Make the UFT application visible

                nTot = UBound(sArrList)+1

                WScript.Echo "Total Tests to be Executed: " & nTot

                For i=1 to nTot

' -------------------initialize variables to null/empty string

                                TestName = ""
                           
                                TestDescription = ""

                                ExecutedOnMachine = ""

                                TestPath = ""

                                UFTResultPath = ""

                                Status = ""

                                FailureReason = ""

                                ExecutionTime = ""

                                StartTime_Global = ""

                                EndTime_Global = ""

' ----------------------------------------------------------------------

                                startTime = Timer()

                                testStartTime = Now()

                                sTest = Replace(Trim(sArrList(i-1)),vbTab,"")

                                'WScript.Echo "Opening the Test: " & sWorkspacePath & sTest

                                App.Open sWorkspacePath & sTest, False

                                If err.Number <> 0 Then

                                                WScript.Echo "Test not found: " & sWorkspacePath & sTest

                                                err.clear

                                                endTime = Timer()

                                                ' wscript.echo("End time - " + FormatDateTime(Now()))

                                Else

                                                dateStamp = Day(Date)&"_"&Month(Date)&"_"&Year(Date)

                                                timeStamp = Hour(Now)&"_"&Minute(Now)&"_"&Second(Now)

                                               ' ExecutedOnMachine for reporting

                                                strComputerName = CreateObject( "WScript.Network" ).ComputerName

                                                ExecutedOnMachine = strComputerName

                                                Set QTP_Test=App.Test

                                                ' extract current test name from sTest

                                                arrCurrentTestName = Split(sTest, "\")

                                                strCurrentTestName = arrCurrentTestName(ubound(arrCurrentTestName))

											' TestName reporting

                                                TestName = strCurrentTestName                                             

                                                WScript.Echo "Running Test: " & i & "/" & nTot & " - " & sWorkspacePath & sTest

                                                wscript.echo("Start time - " + FormatDateTime(testStartTime))

                                                QTP_Test.Run                                                                                               

                                                While QTP_Test.isrunning

                                                    Wait(1)

                                                Wend

                                                sStatus = QTP_Test.LastRunResults.Status

                                                'Failing the build in case a test case fails.

                                                IF sStatus = "Failed" Then blnBuildStatus = 99
                                               
                                                WScript.Echo " " & i & " | " & sTest & sSpace & "|" & sStatus                   

                                                IF sStatus = "Failed" Then

                                                                WScript.Echo "Error Details----"
                                              

                                                End IF

                                                QTP_Test.Close

                                                'WScript.Echo "Test Completed: " & sWorkspacePath & sTest

                                                strComputerName = CreateObject( "WScript.Network" ).ComputerName
                                             
                                                Status = sStatus

                                                endTime = Timer()

                                                wscript.echo("End time - " + FormatDateTime(Now()))

                                End If

 

' ExecutionTime for reporting

                                strExecutionTime = cStr(Round(endTime - startTime , 0))

                                ExecutionTime = cStr(strExecutionTime)

                                StartTime_Global = testStartTime

                                EndTime_Global = now()

                                wscript.echo("Elapsed time - " + cStr(strExecutionTime) + "(" + cStr(Round(endTime - startTime , 0)) + " seconds)")

                                ' WScript.Echo "---------------------------Test Details End--------------------------------------"

                                WScript.Echo ""

                                If err.Number <> 0 Then

                                                err.clear

                                End If

                Next

                WScript.Echo "-------------------------------------------------------------------------------------"

End If

' close UFT
App.Quit

Set QTP_Test=nothing

Set App=nothing

WScript.Echo "EXECUTION COMPLETED"

'msgbox "Clear this message box from code after testing"

WScript.Quit(blnBuildStatus)

 
Private Function GetElapsedTime(dtmStartTime, dtmEndTime)

    Const SECONDS_IN_DAY = 86400

    Const SECONDS_IN_HOUR = 3600

    Const SECONDS_IN_MINUTE = 60

    Const SECONDS_IN_WEEK = 604800


    seconds = Round(dtmEndTime - dtmStartTime, 2)

    If seconds < SECONDS_IN_MINUTE Then

        GetElapsedTime = seconds & " seconds "

        Exit Function

    End If

    If seconds < SECONDS_IN_HOUR Then

        minutes = seconds / SECONDS_IN_MINUTE

        seconds = seconds MOD SECONDS_IN_MINUTE

                If Int(minutes) <= 1 Then

                                GetElapsedTime = Int(minutes) & " minute " & seconds & " seconds "

                Else

                                GetElapsedTime = Int(minutes) & " minutes " & seconds & " seconds "

                End If

       

        Exit Function

    End If

    If seconds < SECONDS_IN_DAY Then

        hours = seconds / SECONDS_IN_HOUR

        minutes = (seconds MOD SECONDS_IN_HOUR) / SECONDS_IN_MINUTE

        seconds = (seconds MOD SECONDS_IN_HOUR) MOD SECONDS_IN_MINUTE

        GetElapsedTime = Int(hours) & " hour(s) " & Int(minutes) & " minutes " & seconds & " seconds "

        Exit Function

    End If

    If seconds < SECONDS_IN_WEEK Then

        days = seconds / SECONDS_IN_DAY

        hours = (seconds MOD SECONDS_IN_DAY) / SECONDS_IN_HOUR

        minutes = ((seconds MOD SECONDS_IN_DAY) MOD SECONDS_IN_HOUR) / SECONDS_IN_MINUTE

        seconds = ((seconds MOD SECONDS_IN_DAY) MOD SECONDS_IN_HOUR) MOD SECONDS_IN_MINUTE

        GetElapsedTime = Int(days) & " day(s) " & Int(hours) & " hour(s) " & Int(minutes) & " minutes " & seconds & " seconds "

        Exit Function

    End If

End Function