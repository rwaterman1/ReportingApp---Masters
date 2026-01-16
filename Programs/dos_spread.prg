DONE=.F.
DO WHILE !Done AND LASTKEY()#27
	IF FILE('tmpsprd.DBF')
		lDataPathOK=.T.
	    DONE=.T.
	    *cDataLoc=GetDIR("Z:\ZZZ","Select Region's Data Path")
	    *IF LEN(ALLTRIM(cDataLoc))=0
	     *  QUIT
	    *ENDIF
		*SET DEFAULT TO &cDataLoc
	ELSE
	    lDataPathOK=.F.
	  	DONE=.F.
	ENDIF
	IF !lDataPathOK
		* Dummy path causes default folder to be folder
		* that jkcity.exe is located in
		cDataLoc=GetDIR("Z:\ZZZ","Select Region's Data Path")
	    IF LEN(ALLTRIM(cDataLoc))=0
	       QUIT
	    ENDIF
		SET DEFAULT TO &cDataLoc
	ENDIF
ENDDO
IF LASTKEY()=27 
	QUIT
ENDIF

do form print_spreadsheet