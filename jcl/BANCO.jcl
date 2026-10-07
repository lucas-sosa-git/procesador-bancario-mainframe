//BANCO JOB (CONTAB),'PROCESADOR',CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID
//STEP01   EXEC PGM=BANCO
//STEPLIB  DD  DSN=TU.PREFIJO.CARGA,DISP=SHR
//CUENTAS DD PATH='/u/tuusuario/BANCO/cuentas.txt',
//             PATHOPTS=(ORDONLY)
//MOVIM DD PATH='/u/tuusuario/BANCO/movimientos.txt',
//              PATHOPTS=(ORDONLY)
//CUENACT DD PATH='/u/tuusuario/BANCO/cuentas-actualizadas.txt',
//              PATHOPTS=(OWRONLY,OCREAT,OTRUNC),
//              PATHMODE=(SIRUSR,SIWUSR,SIRGRP)
//CIERRE DD PATH='/u/tuusuario/BANCO/reporte-cierre.txt',
//            PATHOPTS=(OWRONLY,OCREAT,OTRUNC),
//            PATHMODE=(SIRUSR,SIWUSR,SIRGRP)
//RECHAZOS  DD PATH='/u/tuusuario/BANCO/rechazados.txt',
//           PATHOPTS=(OWRONLY,OCREAT,OTRUNC),
//           PATHMODE=(SIRUSR,SIWUSR,SIRGRP)
