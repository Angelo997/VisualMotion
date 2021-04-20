@ECHO OFF
::...............................
::MOTION for ASMETA batch script
::...............................
:: %1 inputFileName
:: %2 outputFileName
java -jar asmeta\AsmetaS.jar -n 1 -shuffle %1 >> %2