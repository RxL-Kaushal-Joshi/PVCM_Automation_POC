Dim App 'As Application
Set App = CreateObject("QuickTest.Application")
App.Launch
App.Visible = True
App.Open "C:\Test\POC", false
Set QTP_Test=App.Test
QTP_Test.Run
 
