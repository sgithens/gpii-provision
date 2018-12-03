# gpii-provision.ps1
#
# This script will provision a set of USB drives with GPII UUID tokens/keys.
# Usage Example:
#
#   .\gpii-provision.ps1 -InputFile C:\Users\LGS-User\UUIDSshort.csv -DriveLetter 'D:\'
#
# Notes:
# - DriveLetter is the full drive (or path) of the USB sticks to be provisioned. It's assumed
#   to stay the same as you remove and plug in new ones.  It needs to have the colon and 
#   slash.
# - InputFile is a csv file with a header row UUIDS that contains the values. In may look 
#   something like this: (it only needs to have a UUIDS column)
# 
#         UUIDS,Description,JAVI'S CLUSTER,AWS PRODUCTION (Current installer), Comments
#         f3dfd83a-59b2-4ee9-94d5-d77d95e109a7,"Stuff - DO NOT CLICK ON ""SAVE""",X,X,
#         7b1a946d-0a7b-4a81-8394-01e62d5c3d58,"Random Notes - DO NOT CLICK ON ""SAVE""",X,X,
#         2b6e79cc-2ba2-4089-91fb-3783b15b7243,Empty pref set,Claimed for meeting,
#         a532d213-2cf7-457a-9258-dd5e948fa523,Empty pref set,Claimed for meeting,
#         4a6c458e-4199-4553-99cc-09f18112d7f9,Empty pref set,Claimed for meeting,
# - Output is written to the file `gpii-flash-out.txt` in the working directory. It's contents
#   are a series of UUIDS and the serial number of the USB drive it was written to.
# - You are prompted before each writing, letting you swap out the USB drive with the next
#   on. You can quit anytime with ctrl-c

param (
    $InputFile,
    $DriveLetter
)

Function getUSBDiskSerialNumber {
    $DATA = get-disk | where-object {$_.BusType -eq 'USB'} | Select-Object SerialNumber
    return $DATA[0].SerialNumber
}

Function createGPIItokenFile {
    Param($UUID)
    $tokenFilePath = "$DriveLetter.gpii-user-token.txt"
    Set-Content -Path $tokenFilePath -value $UUID -Force
    Get-Item -Path $tokenFilePath -Force | ForEach-Object { $_.Attributes = $_.Attributes -bor "Hidden" }
}

Function processGPIIcsv {
    $GPII_UUIDS = Import-Csv $InputFile | Select-Object UUIDS
    $GPII_UUIDS | ForEach-Object {
        $UUID = $_.UUIDS
        Read-Host "Hit Enter to flash next drive with UUID $UUID"
        $SERIAL_NUMBER = getUSBDiskSerialNumber
        $OUT_STRING = "$UUID,$SERIAL_NUMBER"
        createGPIItokenFile -UUID $UUID
        Add-Content -Path ./gpii-flash-out.txt -Value $OUT_STRING
    }
}

processGPIIcsv