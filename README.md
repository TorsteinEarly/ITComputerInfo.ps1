# ITComputerInfo.ps1
Everything the Help Desk needs over the phone. 


The project: Create a simple tool that a Help Desk Technician can open to review computer information. Make the tool available for the clients to ease service over the phone. 

Use a computer management system like Configuration Manager or Group Policy to copy the files to the computers. Run the Install.bat file to copy the files to C:\Program files\SVC Tools\IT Computer info\ and to copy a shortcut to the start menu. 

The ITComputerInfo.EXE is simply a PS1toEXE that runs the form.ps1 in Functions static, which is the real form/program.

Features:
* Copy all info to the clipboard for sending an email or creating a ticket.
* Network Test
* Test and fix Windows Active Directory Trust
* Links to SVC Web Resources
* Run check disk, clean up temp files, clean out download files. 
* Checks for certain pain points such as out-of-date operating system or long system uptime.
* Display computer information, network, storage, memory, and recent Stop Errors (BSOD). etc.

  
  <img src="/ITComputerInfo.jpg" alt="IT Computer Info Screenshot" title="IT Computer Info Screenshot">
  
  
  Problems and Opportunities:
* The script is quite slow to load information when first started due to the nature of working with Windows Forms in PowerShell.
  * Converting to a C## program should help with this, or
  * The script should initially run and save the information to an XML or JSON file during installation. This would allow it to start and load from the file to quickly display information to the client. This method may produce outdated information, so a background process should run on form load to update the information. The script could run in Task Scheduler to update the data in the XML or JSON file to keep it up to date. 
* The Network Test has some faulty logic when run off campus. 
  * Review off-campus and confirm logic/messages. 
* This project involved experimentation to learn functions, and object and script block manipulation. 
  * The next release should simplify the code. 
