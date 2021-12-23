#################################################################################################################
#  Script Name:  Remote_Memory_Capture
#  Programmer:   https://github.com/elnao/Remote_Memory_Capture
#  Purpose:      Pull memory capture from a remote windows machine on the internal network.
#  Prerequisite: Run script as account that is admin on remote machine;
#                  Run from C:\stage\Memory_Capture folder; Winpmem.exe and 7za.exe must be in this folder;
#################################################################################################################

# Speed up Copy-Item operations
$ProgressPreference = "SilentlyContinue"
 
# Create Timestamp and remote powershell session.
$MemoryCaptureStartDate = (Get-Date -Format FileDateTimeUniversal)

# Ask for name of the computer to have its memory captured.
$input_computer = Read-Host -Prompt "Enter computer to capture memory from"
write-host -ForegroundColor Magenta -BackgroundColor Yellow "Memory will be captured from" $input_computer

# Start logging script output.
Start-Transcript -path .\$input_computer"_"$MemoryCaptureStartDate"_Memory_Capture.log"

# Create remote powershell session.
write-host -ForegroundColor Magenta $MemoryCaptureStartDate "Start Time"
$RemoteSession = new-pssession -computername $input_computer
$RemotePath = "C:\Program Files\Elnao-Files"

# Copy Files to Remote Machine.
write-host -ForegroundColor Magenta "- Winpmem.exe and 7za.exe are being copied to" $input_computer
copy-item -ToSession $RemoteSession -path .\winpmem.exe -Destination $RemotePath
copy-item -ToSession $RemoteSession -path .\7za.exe -Destination $RemotePath

# Perform Memory Capture on Remote Machine.
write-host -ForegroundColor Magenta "- Memory Capture and Compress being performed on" $input_computer
Invoke-Command -session $RemoteSession  -Scriptblock { CD "$using:RemotePath";
                                                       .\winpmem.exe .\"$using:input_computer"_"$using:MemoryCaptureStartDate"_physmem.raw;
                                                       write-host -ForegroundColor Magenta "- Memory capture operation complete";
                                                       .\7za.exe h -scrcSHA256 .\"$using:input_computer"_"$using:MemoryCaptureStartDate"_physmem.raw;
                                                       .\7za.exe a -mx1 -sdel .\"$using:input_computer"_"$using:MemoryCaptureStartDate"_physmem.zip .\"$using:input_computer"_"$using:MemoryCaptureStartDate"_physmem.raw;
                                                       write-host -ForegroundColor Magenta "- Memory capture file compression operation complete";
                                                       rm .\winpmem.exe;
                                                       rm .\7za.exe;
                                                       write-host -ForegroundColor Magenta "- Associated files deleted on remote machine.";  }

$MemoryCaptureCompressedDate = (Get-Date -Format FileDateTimeUniversal)
write-host -ForegroundColor Magenta $MemoryCaptureCompressedDate "Memory Capture Complete and File Compressed"

# Copy compressed memory capture to requesting workstation.
write-host -ForegroundColor Magenta "- Compressed Memory Capture Being Sent to Requesting Workstation."
copy-item -FromSession $RemoteSession -path $RemotePath"\"$input_computer"_"$MemoryCaptureStartDate"_physmem.zip"


$MemoryCaptureCompleteDate = (Get-Date -Format FileDateTimeUniversal)
write-host -ForegroundColor Magenta -BackgroundColor Yellow $MemoryCaptureCompleteDate "Compressed Memory Capture Send Complete"

# Hash expanded memory file and hash to compare to original hash.
# .\7za.exe e .\"$input_computer"_"$MemoryCaptureStartDate"_physmem.raw .\"input_computer"_"$MemoryCaptureStartDate"_physmem.zip 
# .\7za.exe h -scrcSHA256 .\"$using:input_computer"_"$using:MemoryCaptureStartDate"_physmem.raw

Stop-Transcript
