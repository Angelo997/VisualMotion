::...............................
::Sample batch script
::...............................

del asmeta\sample\debug.txt
start cmd.exe /k "java -jar asmeta\sample\AsmetaS.jar -ne -shuffle asmeta\sample\sample.asm >> asmeta/sample/debug.txt"
::PAUSE