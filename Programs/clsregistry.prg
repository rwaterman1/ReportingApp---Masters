
*************************************************************
DEFINE CLASS Registry AS Custom
*************************************************************
***    Author: Rick Strahl
***            (c) West Wind Technologies, 1995
***   Contact: (503) 386-2087  / 76427,2363@compuserve.com
***  Modified: 02/24/95
***
***  Function: Provides read and write access to the
***            System Registry under Windows 95 and
***            NT. The functionality provided is
***            greatly abstracted resulting in using
***            a single method call to set and
***            retrieve values from the registry.
***            The functionality  closely matches
***            the way GetPrivateProfileString
***            works, including the ability to
***            automatically delete key nodes.
***
*** Wish List: Key Enumeration and enumerated deletion         
***            Allow Binary Registry values
***
*** *** *** *** *** *** SAMPLE TEXT *** *** *** *** *** ***
***
*** This example will set the pdf driver outfile to the value
*** supplied in the sFilename and set flag to display the 
*** "Save As" to the value in sValue.
***
*** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
***
*** oRegistry=CREATE("Registry")
***
*** oRegistry.WriteRegistryString(HKEY_CURRENT_USER,;
***                               "Software\Custom PDF Printer",;
***                               "OutputFile",sFileName,.T.)
***
*** oRegistry.WriteRegistryString(HKEY_CURRENT_USER,;
***                               "Software\Custom PDF Printer",;
***                               "BypassSaveAs ",sValue,.T.)
*** (0 = show Save as dialog box after spooling,1 = do not show Save as dialog box.) 
***
*************************************************************

*** Custom Properties

*** Stock Properties

************************************************************************
* Registry :: Init
*********************************
***  Function: Loads required DLLs. Note Read and Write DLLs are
***            not loaded here since they need to be reloaded each
***            time depending on whether String or Integer values
***            are required
************************************************************************
FUNCTION Init

*** Open Registry Key
DECLARE INTEGER RegOpenKey ;
        IN Win32API ;
        INTEGER nHKey,;
        STRING cSubKey,;
        INTEGER @nHandle

*** Create a new Key
DECLARE Integer RegCreateKey ;
        IN Win32API ;
        INTEGER nHKey,;
        STRING cSubKey,;
        INTEGER @nHandle

*** Close an open Key
DECLARE Integer RegCloseKey ;
        IN Win32API ;
        INTEGER nHKey

*** Delete a key (path)
DECLARE INTEGER RegDeleteKey ;
        IN Win32API ;
        INTEGER nHKEY,;
        STRING cSubkey

*** Delete a value from a key
DECLARE INTEGER RegDeleteValue ;
        IN Win32API ;
        INTEGER nHKEY,;
        STRING cEntry
                
ENDPROC

************************************************************************
* Registry :: ReadRegistryString
*********************************
***  Function: Reads a string value from the registry.
***      Pass: tnHKEY    -  HKEY value (in CGIServ.h)
***            tcSubkey  -  The Registry subkey value
***            tcEntry   -  The actual Key to retrieve
***    Return: Registry String or .NULL. on error
************************************************************************
FUNCTION ReadRegistryString
LPARAMETERS tnHKey, tcSubkey, tcEntry
LOCAL lnRegHandle, lnResult, lnSize, lcDataBuffer, tnType

tnHKey=IIF(type("tnHKey")="N",tnHKey,HKEY_LOCAL_MACHINE)

lnRegHandle=0

*** Open the registry key
lnResult=RegOpenKey(tnHKey,tcSubKey,@lnRegHandle)
IF lnResult#ERROR_SUCCESS
   RETURN .NULL.
ENDIF   

*** Need to define here specifically for Return Type
*** for lpdData parameter or VFP will choke.
*** Here it's STRING.
DECLARE INTEGER RegQueryValueEx ;
        IN Win32API AS RegQueryString;
        INTEGER nHKey,;
        STRING lpszValueName,;
        INTEGER dwReserved,;
        INTEGER @lpdwType,;
        STRING @lpbData,;
        INTEGER @lpcbData

*** Return buffer to receive value
lcDataBuffer=space(MAX_INI_BUFFERSIZE)
lnSize=LEN(lcDataBuffer)
lnType=0

lnResult=RegQueryString(lnRegHandle,tcEntry,0,@lnType,;
                         @lcDataBuffer,@lnSize)

=RegCloseKey(lnRegHandle)

IF lnResult#ERROR_SUCCESS 
   RETURN .NULL.
ENDIF   

IF lnSize<2
   RETURN ""
ENDIF
   
*** Return string based on length returned
RETURN SUBSTR(lcDataBuffer,1,lnSize-1)
ENDPROC
* ReadRegistryString


************************************************************************
* Registry :: ReadRegistryInt
*********************************
***  Function: Reads an integer (DWORD) or short (4 byte or less) binary
***            value from the registry.
***      Pass: tnHKEY    -  HKEY value (in CGIServ.h)
***            tcSubkey  -  The Registry subkey value
***            tcEntry   -  The actual Key to retrieve
***    Return: Registry String or .NULL. on error
************************************************************************
FUNCTION ReadRegistryInt
LPARAMETERS tnHKey, tcSubkey, tcEntry
LOCAL lnRegHandle, lnResult, lnSize, lcDataBuffer, tnType

tnHKey=IIF(type("tnHKey")="N",tnHKey,HKEY_LOCAL_MACHINE)

lnRegHandle=0

lnResult=RegOpenKey(tnHKey,tcSubKey,@lnRegHandle)
IF lnResult#ERROR_SUCCESS
   RETURN .NULL.
ENDIF   

*** Need to define here specifically for Return Type
*** for lpdData parameter or VFP will choke. 
*** Here's it's an INTEGER
DECLARE INTEGER RegQueryValueEx ;
        IN Win32API AS RegQueryInt;
        INTEGER nHKey,;
        STRING lpszValueName,;
        INTEGER dwReserved,;
        Integer @lpdwType,;
        INTEGER @lpbData,;
        INTEGER @lpcbData

       lnDataBuffer=0
       lnSize=4
       lnResult=RegQueryInt(lnRegHandle,tcEntry,0,@tnType,;
                            @lnDataBuffer,@lnSize)
=RegCloseKey(lnRegHandle)

IF lnResult#ERROR_SUCCESS
   RETURN .NULL.
ENDIF   

RETURN lnDataBuffer
* EOP RegQueryInt


************************************************************************
* Registry :: WriteRegistryString
*********************************
***  Function: Reads a string value from the registry.
***      Pass: tnHKEY    -  HKEY value (in CGIServ.h)
***            tcSubkey  -  The Registry subkey value
***            tcEntry   -  The actual Key to write to
***            tcValue   -  Value to write or .NULL. to delete key
***            tlCreate  -  Create if it doesn't exist
***    Assume: Use with extreme caution!!! Blowing your registry can
***            hose your system!
***    Return: .T. or .NULL. on error
************************************************************************
FUNCTION WriteRegistryString
LPARAMETERS tnHKey, tcSubkey, tcEntry, tcValue,tlCreate
LOCAL lnRegHandle, lnResult, lnSize, lcDataBuffer, tnType

tnHKey=IIF(type("tnHKey")="N",tnHKey,HKEY_LOCAL_MACHINE)

lnRegHandle=0

lnResult=RegOpenKey(tnHKey,tcSubKey,@lnRegHandle)
IF lnResult#ERROR_SUCCESS
   IF !tlCreate
      RETURN .NULL.
   ELSE
      lnResult=RegCreateKey(tnHKey,tcSubKey,@lnRegHandle)
      IF lnResult#ERROR_SUCCESS
         RETURN .NULL.
      ENDIF  
   ENDIF
ENDIF   

*** Need to define here specifically for Return Type!
*** Here lpbData is STRING.
DECLARE INTEGER RegSetValueEx ;
        IN Win32API ;
        INTEGER nHKey,;
        STRING lpszEntry,;
        INTEGER dwReserved,;
        INTEGER fdwType,;
        STRING lpbData,;
        INTEGER cbData

*** Check for .NULL. which means delete key
IF !ISNULL(tcValue)
  *** Nope - write new value
  lnSize=LEN(tcValue)
  lnResult=RegSetValueEx(lnRegHandle,tcEntry,0,REG_SZ,;
                         tcValue,lnSize)
ELSE
  *** DELETE THE KEY
  lnResult=RegDeleteValue(lnRegHandle,tcEntry)
ENDIF                         

=RegCloseKey(lnRegHandle)
                        
IF lnResult#ERROR_SUCCESS
   RETURN .NULL.
ENDIF   

RETURN .T.
ENDPROC
* WriteRegistryString

************************************************************************
* Registry :: WriteRegistryInt
*********************************
***  Function: Writes a numeric value to the registry.
***      Pass: tnHKEY    -  HKEY value (in CGIServ.h)
***            tcSubkey  -  The Registry subkey value
***            tcEntry   -  The actual Key to write to
***            tcValue   -  Value to write or .NULL. to delete key
***            tlCreate  -  Create if it doesn't exist
***    Assume: Use with extreme caution!!! Blowing your registry can
***            hose your system!
***    Return: .T. or .NULL. on error
************************************************************************
FUNCTION WriteRegistryInt
LPARAMETERS tnHKey, tcSubkey, tcEntry, tnValue,tlCreate
LOCAL lnRegHandle, lnResult, lnSize, lcDataBuffer, tnType

tnHKey=IIF(type("tnHKey")="N",tnHKey,HKEY_LOCAL_MACHINE)

lnRegHandle=0

lnResult=RegOpenKey(tnHKey,tcSubKey,@lnRegHandle)
IF lnResult#ERROR_SUCCESS
   IF !tlCreate
      RETURN .NULL.
   ELSE
      lnResult=RegCreateKey(tnHKey,tcSubKey,@lnRegHandle)
      IF lnResult#ERROR_SUCCESS
         RETURN .NULL.
      ENDIF  
   ENDIF
ENDIF   

*** Need to define here specifically for Return Type!
*** Here lpbData is STRING.
DECLARE INTEGER RegSetValueEx ;
        IN Win32API ;
        INTEGER nHKey,;
        STRING lpszEntry,;
        INTEGER dwReserved,;
        INTEGER fdwType,;
        INTEGER @lpbData,;
        INTEGER cbData

*** Check for .NULL. which means delete key
IF !ISNULL(tnValue)
  *** Nope - write new value
  lnSize=4
  lnResult=RegSetValueEx(lnRegHandle,tcEntry,0,REG_DWORD,;
                         @tnValue,lnSize)
ELSE
  *** DELETE THE KEY
  lnResult=RegDeleteValue(lnRegHandle,tcEntry)
ENDIF                         

=RegCloseKey(lnRegHandle)
                        
IF lnResult#ERROR_SUCCESS
   RETURN .NULL.
ENDIF   

RETURN .T.
ENDPROC
* WriteRegistryInt

************************************************************************
* Registry :: WriteRegistryBinary
*********************************
***  Function: Writes a binary value to the registry.
***            Binary must be written as character values:
***            chr(80)+chr(13)  will result in "50 1D"
***            for example.
***      Pass: tnHKEY    -  HKEY value (in CGIServ.h)
***            tcSubkey  -  The Registry subkey value
***            tcEntry   -  The actual Key to write to
***            tcValue   -  Value to write or .NULL. to delete key
***            tnLength  -  you have to supply the length
***            tlCreate  -  Create if it doesn't exist
***    Assume: Use with extreme caution!!! Blowing your registry can
***            hose your system!
***    Return: .T. or .NULL. on error
************************************************************************
FUNCTION WriteRegistryBinary
LPARAMETERS tnHKey, tcSubkey, tcEntry, tcValue,tnLength,tlCreate
LOCAL lnRegHandle, lnResult, lnSize, lcDataBuffer, tnType

tnHKey=IIF(type("tnHKey")="N",tnHKey,HKEY_LOCAL_MACHINE)
tnLength=IIF(type("tnLength")="N",tnLength,LEN(tcValue))

lnRegHandle=0

lnResult=RegOpenKey(tnHKey,tcSubKey,@lnRegHandle)
IF lnResult#ERROR_SUCCESS
   IF !tlCreate
      RETURN .NULL.
   ELSE
      lnResult=RegCreateKey(tnHKey,tcSubKey,@lnRegHandle)
      IF lnResult#ERROR_SUCCESS
         RETURN .NULL.
      ENDIF  
   ENDIF
ENDIF   

*** Need to define here specifically for Return Type!
*** Here lpbData is STRING.
DECLARE INTEGER RegSetValueEx ;
        IN Win32API ;
        INTEGER nHKey,;
        STRING lpszEntry,;
        INTEGER dwReserved,;
        INTEGER fdwType,;
        STRING @lpbData,;
        INTEGER cbData

*** Check for .NULL. which means delete key
IF !ISNULL(tcValue)
  *** Nope - write new value
  lnResult=RegSetValueEx(lnRegHandle,tcEntry,0,REG_BINARY,;
                         @tcValue,tnLength)
ELSE
  *** DELETE THE KEY
  lnResult=RegDeleteValue(lnRegHandle,tcEntry)
ENDIF                         

=RegCloseKey(lnRegHandle)
                        
IF lnResult#ERROR_SUCCESS
   RETURN .NULL.
ENDIF   

RETURN .T.
ENDPROC
* WriteRegistryBinary

************************************************************************
* Registry :: DeleteRegistryKey
*********************************
***  Function: Deletes a registry key. Note this does not delete
***            an entry but the key (ie. a path node). 
***            Use WriteRegistryString/Int with a .NULL. to 
***            Delete an entry.
***      Pass: tnHKey    -   Registry Root node key
***            tcSubkey  -   Path to clip
***    Return: .T. or .NULL.
************************************************************************
FUNCTION DeleteRegistryKey
LPARAMETERS tnHKEY,tcSubKey
LOCAL lnResult, lnRegHandle

tnHKey=IIF(type("tnHKey")="N",tnHKey,HKEY_LOCAL_MACHINE)

lnRegHandle=0

lnResult=RegOpenKey(tnHKey,tcSubKey,@lnRegHandle)
IF lnResult#ERROR_SUCCESS
   *** Key doesn't exist or can't be opened
   RETURN .NULL.
ENDIF   

lnResult=RegDeleteKey(tnHKey,tcSubKey)

=RegCloseKey(lnRegHandle)

IF lnResult#ERROR_SUCCESS
   RETURN .NULL.
ENDIF

RETURN .T.
ENDPROC
* DeleteRegistryKey

************************************************************************
* wwAPI :: EnumRegistryKey
*********************************
***  Function: Returns a registry key name based on an index
***            Allows enumeration of keys in a FOR loop. If key
***            is empty end of list is reached or the key doesn't
***            exist or is empty.
***      Pass: tnHKey    -   HKEY_ root key
***            tcSubkey  -   Subkey string
***            tnIndex   -   Index of key name to get (0 based)
***    Return: "" on error - Key name otherwise
************************************************************************
PROTECTED PROCEDURE EnumKey
LPARAMETERS tnHKey, tcSubKey, tnIndex 
LOCAL lcSubKey, lcReturn, lnResult, lcDataBuffer

lnRegHandle=0

*** Open the registry key
lnResult=RegOpenKey(tnHKey,tcSubKey,@lnRegHandle)
IF lnResult#ERROR_SUCCESS
   *** Not Found
   RETURN .NULL.
ENDIF   

DECLARE Integer RegEnumKey ;
  IN WIN32API ;
  INTEGER nHKey, ;
  INTEGER nIndex, ;
  STRING @cSubkey, ;  
  INTEGER nSize

lcDataBuffer=SPACE(MAX_INI_BUFFERSIZE)
lnSize=MAX_INI_BUFFERSIZE
lnReturn=RegENumKey(lnRegHandle, tnIndex, @lcDataBuffer, lnSize)

=RegCloseKey(lnRegHandle)

IF lnResult#ERROR_SUCCESS 
   *** Not Found
   RETURN .NULL.
ENDIF   

RETURN TRIM(CHRTRAN(lcDataBuffer,CHR(0),""))
ENDFUNC
* EnumRegistryKey

************************************************************************
* Registry :: EnumValue
*********************************
***  Function: Returns the name of a registry Value key. Note the actual
***            Value is not returned but just the key. This is done
***            so you can check the type first and use the appropriate
***            ReadRegistryX method. The type is returned by ref in the
***            last parameter.
***    Assume: 
***      Pass: tnHKey   -   HKEY value
***            tcSubkey -   The key to enumerate valuekeys for
***            tnIndex  -   Index of key to work on
***            @tnType  -   Used to pass back the type of the value
***    Return: String of ValueKey or .NULL.
************************************************************************
PROTECTED FUNCTION EnumValue
LPARAMETERS tnHKey, tcSubKey, tnIndex, tnType
LOCAL lcSubKey, lcReturn, lnResult, lcDataBuffer

tnType=IIF(type("tnType")="N",tnType,0)

lnRegHandle=0

*** Open the registry key
lnResult=RegOpenKey(tnHKey,tcSubKey,@lnRegHandle)
IF lnResult#ERROR_SUCCESS
   *** Not Found
   RETURN .NULL.
ENDIF   

*** Need to define here specifically for Return Type
*** for lpdData parameter or VFP will choke.
*** Here it's STRING.
DECLARE INTEGER RegEnumValue ;
        IN Win32API ;
        INTEGER nHKey,;
        INTEGER nIndex,;
        STRING @lpszValueName,;
        INTEGER @lpdwSize,;
        INTEGER dwReserved,;
        INTEGER @lpdwType,;
        STRING @lpbData,;
        INTEGER @lpcbData


tcSubkey=SPACE(MAX_INI_BUFFERSIZE)
tcValue=SPACE(MAX_INI_BUFFERSIZE)
lnSize=MAX_INI_BUFFERSIZE
lnValSize=MAX_INI_BUFFERSIZE

lnReturn=RegEnumValue(lnRegHandle, tnIndex, @tcSubkey,@lnValSize, 0, @tnType, @tcValue, @lnSize)

=RegCloseKey(lnRegHandle)

IF lnResult#ERROR_SUCCESS 
   *** Not Found
   RETURN .NULL.
ENDIF   

RETURN TRIM(CHRTRAN(tcSubKey,CHR(0),""))
ENDFUNC
* EnumRegValue

************************************************************************
* Registry :: GetEnumValues
*********************************
***  Function: Retrieves all Values off a key into an array. The
***            array is 2D and consists of: Key Name, Value
***    Assume: Not tested with non-string values
***      Pass: @taValues     -   Result Array: Pass by Reference
***            tnHKEY        -   ROOT KEY value
***            tcSubKey      -   SubKey to work on
***    Return: Count of Values retrieved
************************************************************************
FUNCTION GetEnumValues
LPARAMETERS taValues, tnHKey, tcSubKey
LOCAL x, lcKey

lcKey="x"
x=0
DO WHILE !EMPTY(lcKey) OR ISNULL(lcKey)
 lnType=0
 lcKey=THIS.EnumValue(tnHKey,tcSubKey,x,@lnType)

 IF ISNULL(lcKey) OR EMPTY(lcKey) 
    EXIT
 ENDIF

 x=x+1
 DIMENSION  taValues[x,2]

 DO CASE 
   CASE lnType=REG_SZ OR lnType=REG_BINARY OR lnType=REG_NONE
     lcValue=oRegistry.ReadRegistryString(tnHKey,tcSubKey,lcKey)
     taValues[x,1]=lcKey
     taValues[x,2]=lcValue
   CASE lnType=REG_DWORD
     lnValue=oRegistry.ReadRegistryInt(tnHKey,tcSubKey,lcKey)
     taValues[x,1]=lcKey
     taValues[x,2]=lnValue
   OTHERWISE
     taValues[x,1]=lcKey
     taValues[x,2]=""
   ENDCASE     
ENDDO

RETURN x
ENDFUNC
* GetEnumValues

************************************************************************
* Registry :: GetEnumKeys
*********************************
***  Function: Returns an array of all subkeys for a given key
***            NOTE: This function does not return Value Keys only
***                  Tree Keys!!!!
***      Pass: @taKeys  -   An array that gets filled with key names
***            tnHKEY   -   Root Key
***            tcSubkey -   Subkey to enumerate for
***    Return: Number of keys or 0
************************************************************************
FUNCTION GetEnumKeys
LPARAMETERS taKeys, tnHKey, tcSubKey
LOCAL x, lcKey

lcKey="x"
x=0
DO WHILE !EMPTY(lcKey) OR ISNULL(lcKey)
 lnType=0
 lcKey=THIS.EnumKey(tnHKey,tcSubKey,x)

 IF ISNULL(lcKey) OR EMPTY(lcKey) 
    EXIT
 ENDIF

 x=x+1
 DIMENSION  taKeys[x]
 taKeys[x]=lcKey
ENDDO 

RETURN x
ENDFUNC
* GetEnumKeys


ENDDEFINE
*EOC Registry
