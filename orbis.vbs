Set shell = CreateObject("WScript.Shell")
shell.CurrentDirectory = "C:\users\matheus\desktop\projetos\orbis\build\web"
shell.Run "python -m http.server 8092", 0, False
WScript.Sleep 1500
shell.Run "chrome.exe --app=http://localhost:8092 --window-size=1600,1000"