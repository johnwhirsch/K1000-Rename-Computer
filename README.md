# K1000-Rename-Computer

This script is still being finalized and is only intended as a starting point for people, please use at your own risk.

Workstation Requirements:
- Windows 7 or newer (Windows Management Framework 4.0 is required for Windows 7)
- MySQL Data Connector (installed via K1000 script)

Asset Settings:
- Go to Asset > Asset Types > Computer
- Add an asset field called "Desired Name" or something of that sort
- Use MySQL Workbench to lookup what name this new field is assigned
  - It should be located in something similar to ORG1.ASSET_DATA_5 (may be different for you)
  
Label to target computers with new names:
 - Create a smart label that targets computers as such:
 - "Desired Name" != "" (blank)
 
 Script Settings:
 - Type: Online KScript
 - Labels: the smart label you created above
 - Operating Systems: Win7+
 - Windows Run As: Local System
 - Dependencies: 
   - MySql Data Connector installer MSI
   - The powershell script created to rename the computer
 Task - Run Batch: powershell -executionpolicy bypass -file "set-name.ps1"
 
  What this should do:
  - Put any computer you add a "Desired Name" for in it's asset item to a smart label group
  - Run the set-name file and rename the computer and restart at midnight
