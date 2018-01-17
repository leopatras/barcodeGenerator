IMPORT util
IMPORT os
IMPORT FGL fgldialog
MAIN
  DEFINE result STRING
  MENU "Test"
    COMMAND "Generate Hello"
      CALL ui.Interface.frontCall("cordova","call",
            ["BarcodeGenerator","barcodeGenerator","Hello",300,300,
              "#000","#fff"],[result])
      IF result.getLength()>0 THEN
        TRY
          LET result=removeCRLF(result)
          CALL util.Strings.base64Decode(result,"result.png")
        CATCH
          CALL fgldialog.fgl_winMessage("Error",err_get(status),"info")
          CONTINUE MENU
        END TRY
        OPEN WINDOW w WITH FORM "result"
        DISPLAY "result.png" TO img
        MENU 
          ON ACTION cancel
            EXIT MENU
        END MENU
      END IF
    COMMAND "Exit"
      EXIT MENU
  END MENU
END MAIN

FUNCTION removeCRLF(s) --the base64 string is polluted with newlines (Apple)
  DEFINE s STRING
  DEFINE tok base.StringTokenizer 
  DEFINE sb base.StringBuffer
  LET sb=base.StringBuffer.create()
  LET tok=base.StringTokenizer.create(s,"\r\n")
  WHILE tok.hasMoreTokens()
    CALL sb.append(tok.nextToken())
  END WHILE
  RETURN sb.toString()
END FUNCTION
