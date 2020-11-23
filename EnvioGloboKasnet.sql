--4:30
DECLARE
	PIFECHA DATE := '20/11/2020';
	PIMONEDA NUMBER := 1;
	vCodSer  VARCHAR2(2) := '33';
	vCodEmp  VARCHAR2(2) := '33';

	CURSOR detalle IS
    SELECT 1 AS COD1,
           2 AS COD2,
           '02' AS TIP_REGISTRO,
           RPAD(TRIM(SUBSTR(pkg_persona.f_obt_nombrecompletobancos(pre.Codigopersona ),1,23)),23,' ')
           ||(SELECT LPAD(TO_CHAR(MAX(numerocuota)),3,0)
                FROM TABLE( cre08070.deudacuotassip(pre.periodosolicitud, pre.numerosolicitud, hoy))
               WHERE fechavencimiento <= HOY)
           ||TO_CHAR(HOY,'MMDD') AS NOM_CLIENTE,
           (SELECT LPAD(TO_CHAR(MAX(numerocuota)),3,0)
                FROM TABLE( CRE08070.DEUDACUOTASSIP(PRE.PeriodoSolicitud, PRE.NumeroSolicitud, HOY))
               WHERE FECHAVENCIMIENTO <= HOY)||TO_CHAR(HOY,'MMDD')AS IDENTIFICADORCUOTA,
           PKG_PERSONA.F_OBT_CIP(SP.CODIGOPERSONA) AS CODIGOSOCIO,
           DECODE(substr(pkg_syst902.f_obt_tbldescri(pd.tiposolicitud,pd.tipoprestamo) ,1,3),
                  'PTP',
                  PKG_PERSONA.F_OBT_CIP(SP.CODIGOPERSONA)||'-'||
                  SUBSTR(GEN05010(SP.TIPOSOLICITUD,SP.TIPOPRESTAMO),1,3)||'-'|| LPAD(SP.PERIODOSOLICITUD,4,0)||'-'||
                 SUBSTR(LPAD(SP.NUMEROSOLICITUD,7,0),1,2)||'-'||SUBSTR(LPAD(SP.NUMEROSOLICITUD,7,0),3)||'ATR',
           --per.cip ||''||
           TO_CHAR(HOY,'YYMMDD') ||  
           SUBSTR(pkg_syst902.f_obt_tbldescri(sp.tiposolicitud,sp.tipoprestamo) ,1,3) ||''|| 
            SUBSTR(pkg_syst900.f_obt_tbldescri(22, pre.moneda),1,1)  ||''||
            LPAD(pre.PeriodoSolicitud,4,0)||''||
            LPAD(pre.NumeroSolicitud,7,0)||
            --pre.NumeroSolicitud||
           'ATR')PAGO_ID,
           DECODE(SUBSTR(pkg_syst902.f_obt_tbldescri(pd.tiposolicitud,pd.tipoprestamo) ,1,3),'PTP',
           (SELECT LPAD(TO_CHAR(MAX(numerocuota)),3,0)
                FROM TABLE( CRE08070.DEUDACUOTASSIP(PRE.PeriodoSolicitud, PRE.NumeroSolicitud, HOY))
               WHERE FECHAVENCIMIENTO <= HOY)||TO_CHAR(HOY,'MMDD')           
           ||'-'||
           SUBSTR(GEN05010(SP.TIPOSOLICITUD,SP.TIPOPRESTAMO),1,3)||'-'|| LPAD(SP.PERIODOSOLICITUD,4,0) ||'-'||
           SUBSTR(LPAD(SP.NUMEROSOLICITUD,7,0),1,2)||'-'||SUBSTR(LPAD(SP.NUMEROSOLICITUD,7,0),3)||'ATR',
           --per.cip||''||
           TO_CHAR(HOY,'YYMMDD') || 
           SUBSTR(pkg_syst902.f_obt_tbldescri(sp.tiposolicitud,sp.tipoprestamo) ,1,3) ||''||  
           SUBSTR(pkg_syst900.f_obt_tbldescri(22, pre.moneda),1,1)  ||''|| 
           LPAD(pre.PeriodoSolicitud,4,0)||''||
           LPAD(pre.NumeroSolicitud,7,0)||
           'ATR'  
           /*|| NVL((SELECT LPAD(TO_CHAR(MAX(numerocuota)),3,0)
                FROM TABLE( CRE08070.DEUDACUOTASSIP(PRE.PeriodoSolicitud, PRE.NumeroSolicitud, HOY))
               WHERE FECHAVENCIMIENTO <= HOY),'001')*/
           ) PAGO_ID_2,
           DECODE(substr(pkg_syst902.f_obt_tbldescri(pd.tiposolicitud,pd.tipoprestamo) ,1,3),
                  'PTP',
                  PKG_PERSONA.F_OBT_CIP(SP.CODIGOPERSONA)||'-'||
                  SUBSTR(GEN05010(SP.TIPOSOLICITUD,SP.TIPOPRESTAMO),1,3)||'-'|| LPAD(SP.PERIODOSOLICITUD,4,0)||'-'||
                 SUBSTR(LPAD(SP.NUMEROSOLICITUD,7,0),1,2)||'-'||SUBSTR(LPAD(SP.NUMEROSOLICITUD,7,0),3)||'ATR',
           LPAD(per.cip,7,0) ||''||             
           SUBSTR(pkg_syst902.f_obt_tbldescri(sp.tiposolicitud,sp.tipoprestamo) ,1,3) ||''|| 
            SUBSTR(pkg_syst900.f_obt_tbldescri(22, pre.moneda),1,1)  ||''||
            LPAD(pre.PeriodoSolicitud,4,0)||''||
            LPAD(pre.NumeroSolicitud,7,0)||           
           'ATR' ||
           TO_CHAR(HOY,'YYMMDD'))PAGO_ID_CONTINENTAL,
           PKG_RECAUDACIONENVIO.F_GET_MONTOADEUDADO (pre.PeriodoSolicitud , pre.NumeroSolicitud, 1 ) AS Monto_Minimo,
           PKG_RECAUDACIONENVIO.F_GET_MONTOADEUDADO (pre.PeriodoSolicitud , pre.NumeroSolicitud, 2 ) AS SALDOCAPITAL,
           CASE WHEN SUBSTR(pkg_syst902.f_obt_tbldescri(pd.tiposolicitud,pd.tipoprestamo) ,1,3)='PTP'
                 AND PKG_RECAUDACIONENVIO.F_GET_MONTOADEUDADO (pre.PeriodoSolicitud , pre.NumeroSolicitud, 2 )=0  THEN
                 PKG_RECAUDACIONENVIO.F_OBT_INTERESATRASADO (pre.PeriodoSolicitud,pre.NumeroSolicitud,hoy)
           ELSE
               PKG_RECAUDACIONENVIO.F_GET_MONTOADEUDADO (pre.PeriodoSolicitud , pre.NumeroSolicitud, 3 )
           END AS SALDOINTERES,
           PKG_RECAUDACIONENVIO.F_GET_MONTOADEUDADO (pre.PeriodoSolicitud , pre.NumeroSolicitud, 4 ) AS SALDOMORA,
           PKG_RECAUDACIONENVIO.F_GET_MONTOADEUDADO (pre.PeriodoSolicitud , pre.NumeroSolicitud, 5 ) AS SEGUROINTERES,
           PKG_RECAUDACIONENVIO.F_GET_MONTOADEUDADO (pre.PeriodoSolicitud , pre.NumeroSolicitud, 6 ) AS APORTES,
           PKG_RECAUDACIONENVIO.F_GET_MONTOADEUDADO (pre.PeriodoSolicitud , pre.NumeroSolicitud, 7 ) AS REAJUSTE,
           NVL(PKG_RECAUDACIONENVIO.F_OBT_FECVENCADEUDADO (pre.PeriodoSolicitud , pre.NumeroSolicitud ), trunc(HOY) ) AS FECHAVENCIMIENTO,
           pkg_cartera.DIAS_ATRASO_CARTERA(PIFECHA ,pre.PeriodoSolicitud , pre.NumeroSolicitud ) DIASATRASO,
           pre.codigopersona,
           (SELECT LPAD(TO_CHAR(MAX(numerocuota)),3,0)
              FROM TABLE( CRE08070.DEUDACUOTASSIP(PRE.PeriodoSolicitud, PRE.NumeroSolicitud, HOY))
             WHERE FECHAVENCIMIENTO <= HOY) AS NUMEROCUOTA,
           SUBSTR(pkg_syst902.f_obt_tbldescri(pd.tiposolicitud,pd.tipoprestamo) ,1,3)TipoProducto,
           pre.PeriodoSolicitud , LPAD(pre.NumeroSolicitud,7,'0')NumeroSolicitud
      FROM prestamo pre
    INNER JOIN (SELECT periodosolicitud, numerosolicitud, MAX(numeroampliacion) nroampl
                  FROM prestamodetalle GROUP BY periodosolicitud, numerosolicitud) presdet
    ON presdet.periodosolicitud = pre.periodosolicitud AND presdet.numerosolicitud = pre.numerosolicitud
    INNER JOIN prestamodetalle pd
            ON pd.periodosolicitud = presdet.periodosolicitud
           AND pd.numerosolicitud = presdet.numerosolicitud AND pd.numeroampliacion = presdet.nroampl
    INNER JOIN solicitudprestamo sp ON PRE.PERIODOSOLICITUD= sp.PERIODOSOLICITUD AND PRE.NUMEROSOLICITUD = sp.NUMEROSOLICITUD
    INNER JOIN persona per ON per.codigopersona = pre.codigopersona
    INNER JOIN ( SELECT p.codigopersona, TO_CHAR(p.numeroruc) AS nrodoc FROM persona p INNER JOIN datossocio ds ON p.codigopersona =ds.codigopersona WHERE p.tipopersona = 2
                        UNION ALL SELECT pn.codigopersona, pn.numerodocumentoid AS nrodoc FROM personanatural pn
                  INNER JOIN datossocio ds ON pn.codigopersona =ds.codigopersona) soc ON  soc.codigopersona = pre.codigopersona

     WHERE pre.moneda = PIMONEDA
       AND LENGTH(TRIM(soc.nrodoc))>=8
       AND pre.SALDOPRESTAMO > 0 -- prestamos con monto adeudado pendiente
       AND substr(pkg_syst902.f_obt_tbldescri(pd.tiposolicitud,pd.tipoprestamo) ,1,3) NOT  IN ('PCC','PCY','PCM','PFI',-- CARTERA
                                                                                            'PDP', 'PDD','PLR','PLC', 'TAN'-- Descuento por Planilla
                                                                                              )
       AND PRE.PERIODOSOLICITUD<>1        
       AND pre.periodosolicitudconcesional IS NULL
       AND pre.numerosolicitudconcesional IS NULL
       AND (pre.periodosolicitud, pre.numerosolicitud) NOT IN (SELECT periodosolicitud, numerosolicitud
                                                                  FROM solicitudprestamo
                                                                  WHERE periodosolicitudconcesional IS NOT NULL
                                                                     AND numerosolicitudconcesional IS NOT NULL)
       AND NVL(DECODE(SUBSTR(pkg_syst902.f_obt_tbldescri(pd.tiposolicitud,pd.tipoprestamo) ,1,3),'PTP',
              ( SELECT MAX(numerocuota)
                  FROM TABLE( CRE08070.DEUDACUOTASSIP(pre.periodosolicitud, pre.numerosolicitud, HOY))
                 WHERE fechavencimiento <= HOY ),pkg_cartera.DIAS_ATRASO_CARTERA(PIFECHA ,pre.PeriodoSolicitud , pre.NumeroSolicitud )),0)>0
       AND pre.periodosolicitudconcesional IS NULL AND pre.numerosolicitudconcesional IS NULL
       AND (pre.periodosolicitud, pre.numerosolicitud) NOT IN(SELECT periodosolicitud, numerosolicitud
                                                                 FROM solicitudprestamo
                                                                 WHERE periodosolicitudconcesional IS NOT NULL
                                                                 AND numerosolicitudconcesional IS NOT NULL )
     UNION ALL
    SELECT 1 AS cod1,
           2 AS cod2,
           '02' TIP_REGISTRO,
           RPAD(TRIM(SUBSTR( PKG_PERSONA.F_OBT_NOMBRECOMPLETOBANCOS(pre.codigopersona ),1,23)),23,' ')
           ||LPAD(TRIM(TO_CHAR(PC.NUMEROCUOTA,'999')),3,'0')
           ||TO_CHAR(HOY,'MMDD') AS NOM_CLIENTE,
           LPAD(TRIM(TO_CHAR(PC.NUMEROCUOTA,'999')),3,'0')||
           TO_CHAR(HOY,'MMDD') AS IDENTIFICADORCUOTA,
           PKG_PERSONA.F_OBT_CIP(SP.CODIGOPERSONA) AS CODIGOSOCIO,
           DECODE(SUBSTR(pkg_syst902.f_obt_tbldescri(pd.tiposolicitud,pd.tipoprestamo) ,1,3),
                  'PTP',PKG_PERSONA.F_OBT_CIP(SP.CODIGOPERSONA)||'-'||
                        SUBSTR(GEN05010(SP.TIPOSOLICITUD,SP.TIPOPRESTAMO),1,3)||'-'||
                        LPAD(SP.PERIODOSOLICITUD,4,0)||'-'||
                        SUBSTR(LPAD(SP.NUMEROSOLICITUD,7,0),1,2)||'-'||
                        SUBSTR(LPAD(SP.NUMEROSOLICITUD,7,0),3)||
                        'ACT',
           --per.cip ||''||
           TO_CHAR(HOY,'YYMMDD') || 
           SUBSTR(pkg_syst902.f_obt_tbldescri(sp.tiposolicitud,sp.tipoprestamo) ,1,3) ||''||  
           SUBSTR(pkg_syst900.f_obt_tbldescri(22, pre.moneda),1,1)  ||''||
           LPAD(pre.PeriodoSolicitud,4,0)||''||
           LPAD(pre.NumeroSolicitud,7,0)||
           --pre.NumeroSolicitud||-- PAGO_ID,
           'ACT') PAGO_ID ,
           DECODE(SUBSTR(pkg_syst902.f_obt_tbldescri(pd.tiposolicitud,pd.tipoprestamo) ,1,3),
                  'PTP',( SELECT LPAD(TO_CHAR(MAX(numerocuota)),3,0)
                            FROM TABLE( CRE08070.DEUDACUOTASSIP(PRE.PeriodoSolicitud, 
                                                                PRE.NumeroSolicitud, HOY)
                                      )
                           WHERE FECHAVENCIMIENTO <= HOY )||
                        TO_CHAR(HOY,'MMDD')||'-'||
                        SUBSTR(GEN05010(SP.TIPOSOLICITUD,SP.TIPOPRESTAMO),1,3)||'-'||
                        LPAD(SP.PERIODOSOLICITUD,4,0)||'-'||
                        SUBSTR(LPAD(SP.NUMEROSOLICITUD,7,0),1,2)||'-'||
                        SUBSTR(LPAD(SP.NUMEROSOLICITUD,7,0),3)||
                        'ACT',
                  --per.cip ||''||
                  TO_CHAR(HOY,'YYMMDD') ||
                  SUBSTR(pkg_syst902.f_obt_tbldescri(sp.tiposolicitud,sp.tipoprestamo) ,1,3) ||''||  
                  SUBSTR(pkg_syst900.f_obt_tbldescri(22, pre.moneda),1,1)  ||''|| 
                  LPAD(pre.PeriodoSolicitud,4,0)||''||
                  LPAD(pre.NumeroSolicitud,7,0)||
                  'ACT'
                  /*|| 
                  NVL(( SELECT LPAD(TO_CHAR(MAX(numerocuota)),3,0)
                      FROM TABLE( CRE08070.DEUDACUOTASSIP( PRE.PeriodoSolicitud, 
                                                           PRE.NumeroSolicitud, 
                                                           HOY 
                                                         )
                  )
                     WHERE FECHAVENCIMIENTO <= HOY),'001')*/           
            )PAGO_ID_2,    
            DECODE(SUBSTR(pkg_syst902.f_obt_tbldescri(pd.tiposolicitud,pd.tipoprestamo) ,1,3),
                  'PTP',PKG_PERSONA.F_OBT_CIP(SP.CODIGOPERSONA)||'-'||
                        SUBSTR(GEN05010(SP.TIPOSOLICITUD,SP.TIPOPRESTAMO),1,3)||'-'||
                        LPAD(SP.PERIODOSOLICITUD,4,0)||'-'||
                        SUBSTR(LPAD(SP.NUMEROSOLICITUD,7,0),1,2)||'-'||
                        SUBSTR(LPAD(SP.NUMEROSOLICITUD,7,0),3)||
                        'ACT',
           LPAD(per.cip,7,0) ||''||                       
           SUBSTR(pkg_syst902.f_obt_tbldescri(sp.tiposolicitud,sp.tipoprestamo) ,1,3) ||''||  
           SUBSTR(pkg_syst900.f_obt_tbldescri(22, pre.moneda),1,1)  ||''||
           LPAD(pre.PeriodoSolicitud,4,0)||''||
           LPAD(pre.NumeroSolicitud,7,0)||            
           'ACT' ||
           TO_CHAR(HOY,'YYMMDD')) PAGO_ID_CONTINENTAL,                 
           pc.AMORTIZACION + pc.INTERES as Monto_MINIMO,
           pc.AMORTIZACION AS SALDOCAPITAL,
           pc.INTERES AS SALDOINTERES,
           0 AS SALDOMORA,
           NVL(pc.segurointeres,0) AS SEGUROINTERES,
           NVL(pc.portes,0) AS APORTES,
           NVL(pc.reajuste,0) AS REAJUSTE,
           NVL(pc.fechavencimiento,TRUNC(HOY)) AS FECHAVENCIMIENTO,
           0 DIASATRASO,
           pre.codigopersona,
           LPAD(TRIM(TO_CHAR(PC.NUMEROCUOTA,'999')),3,'0') AS numerocuota,
           SUBSTR(pkg_syst902.f_obt_tbldescri(pd.tiposolicitud,pd.tipoprestamo) ,1,3)TipoProducto,
           pre.PeriodoSolicitud , LPAD(pre.NumeroSolicitud,7,'0')NumeroSolicitud
      FROM prestamo pre
    INNER JOIN (SELECT periodosolicitud, numerosolicitud, MAX(numeroampliacion) nroampl
                  FROM prestamodetalle GROUP BY periodosolicitud, numerosolicitud) presdet
    ON presdet.periodosolicitud = pre.periodosolicitud AND presdet.numerosolicitud = pre.numerosolicitud
    INNER JOIN prestamodetalle pd ON pd.periodosolicitud = presdet.periodosolicitud AND pd.numerosolicitud = presdet.numerosolicitud AND pd.numeroampliacion = presdet.nroampl
    INNER JOIN solicitudprestamo sp ON PRE.PERIODOSOLICITUD= sp.PERIODOSOLICITUD AND PRE.NUMEROSOLICITUD = sp.NUMEROSOLICITUD
    INNER JOIN persona per ON per.codigopersona = pre.codigopersona
    INNER JOIN prestamocuotas pc ON pre.periodosolicitud = pc.periodosolicitud AND pre.numerosolicitud  = pc.numerosolicitud
    INNER JOIN  ( SELECT p.codigopersona, TO_CHAR(p.numeroruc) AS nrodoc from persona p INNER JOIN datossocio ds ON p.codigopersona =ds.codigopersona WHERE p.tipopersona = 2
                        UNION ALL SELECT pn.codigopersona, pn.numerodocumentoid AS nrodoc FROM personanatural pn INNER JOIN datossocio ds ON pn.codigopersona =ds.codigopersona) soc ON soc.codigopersona = pre.codigopersona

     WHERE pc.estado = 2
       AND LENGTH(TRIM(soc.nrodoc))>=8
       AND pre.moneda =PIMONEDA
       AND pre.SALDOPRESTAMO > 0 -- prestamos con monto adeudado pendiente
       AND SUBSTR(pkg_syst902.f_obt_tbldescri(pd.tiposolicitud,pd.tipoprestamo) ,1,3)   NOT  IN ('PCC','PCY','PCM','PFI',-- CARTERA
                                                                                                    'PDP', 'PDD','PLR','PLC', 'TAN'-- Descuento por Planilla
                                                                                                   )
       AND PRE.PERIODOSOLICITUD <> 1       
       AND pre.periodosolicitudconcesional IS NULL
       AND pre.numerosolicitudconcesional IS NULL
       AND (pre.periodosolicitud, pre.numerosolicitud) NOT IN (SELECT periodosolicitud, numerosolicitud
                                                                  FROM solicitudprestamo
                                                                  WHERE periodosolicitudconcesional IS NOT NULL
                                                                    AND numerosolicitudconcesional IS NOT NULL)
       AND TRUNC(pc.fechavencimiento) IN (SELECT MIN(fechavencimiento ) FROM prestamocuotas
                                             WHERE periodosolicitud = pre.periodosolicitud
                                               AND numerosolicitud = pre.numerosolicitud
                                               AND estado =2
                                               AND fechavencimiento>= HOY
                                            )
     ---Pago de Inscripcion en Cuotas
       UNION ALL                                     
       SELECT 1 AS cod1,
           2 AS cod2,
           '02' TIP_REGISTRO,
           RPAD(TRIM(SUBSTR( PKG_PERSONA.F_OBT_NOMBRECOMPLETOBANCOS(pre.codigopersona ),1,23)),23,' ')
           ||LPAD(TRIM(TO_CHAR(PC.NUMEROCUOTA,'999')),3,'0')
           ||TO_CHAR(HOY,'MMDD') AS NOM_CLIENTE,
           LPAD(TRIM(TO_CHAR(PC.NUMEROCUOTA,'999')),3,'0')||
           TO_CHAR(HOY,'MMDD') AS IDENTIFICADORCUOTA,
           PKG_PERSONA.F_OBT_CIP(SP.CODIGOPERSONA) AS CODIGOSOCIO,
           DECODE(SUBSTR(pkg_syst902.f_obt_tbldescri(pd.tiposolicitud,pd.tipoprestamo) ,1,3),
                  'PTP',PKG_PERSONA.F_OBT_CIP(SP.CODIGOPERSONA)||'-'||
                        SUBSTR(GEN05010(SP.TIPOSOLICITUD,SP.TIPOPRESTAMO),1,3)||'-'||
                        LPAD(SP.PERIODOSOLICITUD,4,0)||'-'||
                        SUBSTR(LPAD(SP.NUMEROSOLICITUD,7,0),1,2)||'-'||
                        SUBSTR(LPAD(SP.NUMEROSOLICITUD,7,0),3)||
                        'ACT',
           --per.cip ||''||
           TO_CHAR(HOY,'YYMMDD') || 
           SUBSTR(pkg_syst902.f_obt_tbldescri(sp.tiposolicitud,sp.tipoprestamo) ,1,3) ||''||  
           SUBSTR(pkg_syst900.f_obt_tbldescri(22, pre.moneda),1,1)  ||''||
           LPAD(pre.PeriodoSolicitud,4,0)||''||
           --pre.NumeroSolicitud||-- PAGO_ID,
           LPAD(pre.NumeroSolicitud,7,0) ||
           'ACT') PAGO_ID ,
           DECODE(SUBSTR(pkg_syst902.f_obt_tbldescri(pd.tiposolicitud,pd.tipoprestamo) ,1,3),
                  'PTP',( SELECT LPAD(TO_CHAR(MAX(numerocuota)),3,0)
                            FROM TABLE( CRE08070.DEUDACUOTASSIP(PRE.PeriodoSolicitud, 
                                                                PRE.NumeroSolicitud, HOY)
                                      )
                           WHERE FECHAVENCIMIENTO <= HOY )||
                        TO_CHAR(HOY,'MMDD')||'-'||
                        SUBSTR(GEN05010(SP.TIPOSOLICITUD,SP.TIPOPRESTAMO),1,3)||'-'||
                        LPAD(SP.PERIODOSOLICITUD,4,0)||'-'||
                        SUBSTR(LPAD(SP.NUMEROSOLICITUD,7,0),1,2)||'-'||
                        SUBSTR(LPAD(SP.NUMEROSOLICITUD,7,0),3)||
                        'ACT',
                  --per.cip ||''||
                  TO_CHAR(HOY,'YYMMDD') || 
                  SUBSTR(pkg_syst902.f_obt_tbldescri(sp.tiposolicitud,sp.tipoprestamo) ,1,3) ||''||  
                  SUBSTR(pkg_syst900.f_obt_tbldescri(22, pre.moneda),1,1)  ||''|| 
                  LPAD(pre.PeriodoSolicitud,4,0)||''||
                  LPAD(pre.NumeroSolicitud,7,0)||
                  'ACT'
                  /*|| 
                  NVL(( SELECT LPAD(TO_CHAR(MAX(numerocuota)),3,0)
                      FROM TABLE( CRE08070.DEUDACUOTASSIP( PRE.PeriodoSolicitud, 
                                                           PRE.NumeroSolicitud, 
                                                           HOY 
                                                         )
                  )
                     WHERE FECHAVENCIMIENTO <= HOY),'001')*/           
            )PAGO_ID_2,    
           DECODE(SUBSTR(pkg_syst902.f_obt_tbldescri(pd.tiposolicitud,pd.tipoprestamo) ,1,3),
                  'PTP',PKG_PERSONA.F_OBT_CIP(SP.CODIGOPERSONA)||'-'||
                        SUBSTR(GEN05010(SP.TIPOSOLICITUD,SP.TIPOPRESTAMO),1,3)||'-'||
                        LPAD(SP.PERIODOSOLICITUD,4,0)||'-'||
                        SUBSTR(LPAD(SP.NUMEROSOLICITUD,7,0),1,2)||'-'||
                        SUBSTR(LPAD(SP.NUMEROSOLICITUD,7,0),3)||
                        'ACT',
           LPAD(per.cip,7,0) ||''||            
           SUBSTR(pkg_syst902.f_obt_tbldescri(sp.tiposolicitud,sp.tipoprestamo) ,1,3) ||''||  
           SUBSTR(pkg_syst900.f_obt_tbldescri(22, pre.moneda),1,1)  ||''||
           LPAD(pre.PeriodoSolicitud,4,0)||''||           
           LPAD(pre.NumeroSolicitud,7,0) ||
           'ACT'||
           TO_CHAR(HOY,'YYMMDD')
           ) PAGO_ID_CONTINENTAL ,                 
           pc.AMORTIZACION + pc.INTERES as Monto_MINIMO,
           pc.AMORTIZACION AS SALDOCAPITAL,
           pc.INTERES AS SALDOINTERES,
           0 AS SALDOMORA,
           NVL(pc.segurointeres,0) AS SEGUROINTERES,
           NVL(pc.portes,0) AS APORTES,
           NVL(pc.reajuste,0) AS REAJUSTE,
           NVL(pc.fechavencimiento,TRUNC(HOY)) AS FECHAVENCIMIENTO,
           0 DIASATRASO,
           pre.codigopersona,
           LPAD(TRIM(TO_CHAR(PC.NUMEROCUOTA,'999')),3,'0') AS numerocuota,
           SUBSTR(pkg_syst902.f_obt_tbldescri(pd.tiposolicitud,pd.tipoprestamo) ,1,3)TipoProducto,
           pre.PeriodoSolicitud , LPAD(pre.NumeroSolicitud,7,'0')NumeroSolicitud
      FROM prestamo pre
    INNER JOIN (SELECT periodosolicitud, numerosolicitud, MAX(numeroampliacion) nroampl
                  FROM prestamodetalle GROUP BY periodosolicitud, numerosolicitud) presdet
    ON presdet.periodosolicitud = pre.periodosolicitud AND presdet.numerosolicitud = pre.numerosolicitud
    INNER JOIN prestamodetalle pd ON pd.periodosolicitud = presdet.periodosolicitud AND pd.numerosolicitud = presdet.numerosolicitud AND pd.numeroampliacion = presdet.nroampl
    INNER JOIN solicitudprestamo sp ON PRE.PERIODOSOLICITUD= sp.PERIODOSOLICITUD AND PRE.NUMEROSOLICITUD = sp.NUMEROSOLICITUD
    INNER JOIN persona per ON per.codigopersona = pre.codigopersona
    INNER JOIN prestamocuotas pc ON pre.periodosolicitud = pc.periodosolicitud AND pre.numerosolicitud  = pc.numerosolicitud
    INNER JOIN  ( SELECT p.codigopersona, TO_CHAR(p.numeroruc) AS nrodoc from persona p INNER JOIN datossocio ds ON p.codigopersona =ds.codigopersona WHERE p.tipopersona = 2
                        UNION ALL SELECT pn.codigopersona, pn.numerodocumentoid AS nrodoc FROM personanatural pn INNER JOIN datossocio ds ON pn.codigopersona =ds.codigopersona) soc ON soc.codigopersona = pre.codigopersona

     WHERE pc.estado = 2      
       AND LENGTH(TRIM(soc.nrodoc))>=8
       AND pre.moneda =PIMONEDA
       AND pre.SALDOPRESTAMO > 0 -- prestamos con monto adeudado pendiente
       AND PRE.PERIODOSOLICITUD = 1
       AND pre.periodosolicitudconcesional IS NULL
       AND pre.numerosolicitudconcesional IS NULL
       AND (pre.periodosolicitud, pre.numerosolicitud) NOT IN (SELECT periodosolicitud, numerosolicitud
                                                                  FROM solicitudprestamo
                                                                  WHERE periodosolicitudconcesional IS NOT NULL
                                                                    AND numerosolicitudconcesional IS NOT NULL)
      --<04.03.2020-Richard Rodriguez -Para que traiga la primera cuota en estado vigente-Techo propio>                                                              
       /*AND TRUNC(pc.fechavencimiento) IN (SELECT fechavencimiento  FROM prestamocuotas
                                             WHERE periodosolicitud = pre.periodosolicitud
                                               AND numerosolicitud = pre.numerosolicitud
                                               AND estado =2
                                               AND fechavencimiento<= HOY
                                         )*/
        AND pc.numerocuota=1
        AND pc.estado=2
        --<F.04.03.2020-Richard Rodriguez -Para que traiga la primera cuota en estado vigente--Techo propio>   
        AND EXISTS (SELECT *
              FROM viviendaptp
              WHERE codigopersona = pre.codigopersona )
        AND EXISTS (    SELECT *
             FROM CuentaCorriente
            WHERE TipoTransaccion =2
              And Moneda = PIMoneda
              AND estado = 1
              AND CodigoPersona = pre.codigopersona
              AND tablaservicio=101
              AND argumentoservicio IN (13,14));

	vNumerocuota		prestamocuotas.numerocuota%TYPE;

	vTotalAmortizacion NUMBER(15,2):=0;
	vMontoadeudado   NUMBER(15,2):=0;
	vConteoTotal     NUMBER(9):=0;
	vTipoPersona     NUMBER(1);
	vNumeroDocumento VARCHAR2(15);
	vTipodocumento   VARCHAR2(1);
	vTipodocumentofin  VARCHAR2(1);
	--
	vSumaCREDITO       NUMBER(15,2):=0;
	--
	v01  VARCHAR2(2);
	v02  VARCHAR2(2);
	v03  VARCHAR2(2);
	v04  VARCHAR2(2);
	v05  VARCHAR2(2);
	v06  VARCHAR2(2);
	vMinimo NUMBER(15,2) :=0;
	
	vfechabloqueo date;
	vSumaTotalGlobokas NUMBER(15,2):=0; --GLOBOKAS --Redondeado

	vMonedaGlobokas       VARCHAR2(2); --GLOBOKAS
	vDetalleGlobokas      VARCHAR2(400):= ' '; --GLOBOKAS
	vCabeceraGlobokas      VARCHAR2(400):= ' '; --GLOBOKAS

BEGIN

	EXECUTE IMMEDIATE 'TRUNCATE TABLE recaudaglobokas'; --GLOBOKAS
	COMMIT;  --GLOBOKAS

	EXECUTE IMMEDIATE 'ALTER SESSION set NLS_LANGUAGE = "SPANISH" ';
	EXECUTE IMMEDIATE 'ALTER SESSION set NLS_TERRITORY = "SPAIN" ';

	IF PIMONEDA = 1 THEN
		vMonedaGlobokas := '1';             --GLOBOKAS
	ELSE
		vMonedaGlobokas := NULL;             --GLOBOKAS
	END IF;

	FOR x IN detalle LOOP
             vTipoPersona := pkg_persona.f_obt_tipopersona( x.codigopersona );
             IF vTipoPersona = 1 THEN
                vNumerodocumento := pkg_personanatural.F_OBT_NUMERODOCUMENTOID( x.codigopersona );
                vTipodocumento   := 'L';
                vTipodocumentofin := 'C';
             ELSE
                 vNumerodocumento := pkg_persona.F_OBT_NUMERORUC( x.codigopersona );
                 vTipodocumento   := 'R';
                 vTipodocumentofin := 'R';
             END IF;
             --
             vTotalAmortizacion  := x.SALDOCAPITAL + x.SEGUROINTERES + x.APORTES + x.REAJUSTE;
             vMontoadeudado := vTotalAmortizacion + x.SALDOINTERES + x.SALDOMORA;
             
             vMinimo := vMontoadeudado;
              
             --
             IF x.fechavencimiento > TRUNC(HOY) THEN
                vfechabloqueo := x.fechavencimiento;
             ELSE
                vfechabloqueo := TRUNC(HOY);
             END IF;
             --
             IF LENGTH(TRIM(x.numerocuota)) >= 3  THEN
                vNumerocuota := SUBSTR (TRIM(x.numerocuota),2,2);
             ELSE
                vNumerocuota := x.numerocuota;
             END IF;
                  vDetalleGlobokas := vCodSer|| --SER Codigo del Servicio SVC
                                      '00'|| --SECCION fijo
                                      TRIM(LPAD(x.PeriodoSolicitud ||x.NumeroSolicitud || '-' || SUBSTR(x.pago_id, -3, 3), 15, '0'))|| --RECIBO Numero Recibo
                                      TRIM(TO_CHAR(x.fechavencimiento,'YYYYMMDD'))|| --FechaVigencia
                                      vMonedaGlobokas|| --TipoMoneda
                                      --TRIM(LPAD(x.CODIGOSOCIO, 15, '0'))|| --NUMSER campo de busqueda
                                      CASE PKG_PERSONA.F_OBT_TIPOPERSONA(x.codigopersona)
                                          WHEN 1 THEN
                                             LPAD(PKG_PERSONANATURAL.F_OBT_NUMERODOCUMENTOID(x.codigopersona), 15, ' ') --NUMSER campo de busqueda
                                          WHEN 2 THEN
                                             LPAD(PKG_PERSONA.F_OBT_NUMERORUC(x.codigopersona), 15, ' ') --NUMSER campo de busqueda
                                       END ||
                                       RPAD(SUBSTR(PKG_PERSONA.F_OBT_NOMBRECOMPLETOBANCOS(x.codigopersona), 1, 30), 30, ' ') || --NUMABO Nombre Cliente
                                      '000'|| --NROCEN fijo
                                      TRIM(LPAD(vNumerocuota||TO_CHAR(x.fechavencimiento,'YYMMDD')||TO_CHAR(HOY,'YYMMDD'), 15, '0'))|| --NUMCLI
                                      TRIM(TO_CHAR(CEIL(vMontoadeudado)*100, '0000000000'))|| --TOTAL Importe Facturado a Cobrar
                                      vCodEmp|| --CODEMP Codigo de la empresa SVC
                                      'R'; --GLOBOKAS
             --
             IF NVL (vTotalAmortizacion, 0) > 0 THEN
                IF NVL (x.Monto_Minimo, 0) >= 0
                   AND NVL (x.SALDOCAPITAL, 0) >= 0
                   AND NVL (x.SALDOINTERES, 0) >= 0
                   AND NVL (x.SALDOMORA, 0) >= 0
                   AND NVL (x.SEGUROINTERES, 0) >= 0
                   AND NVL (x.APORTES, 0) >= 0
                   AND NVL (x.REAJUSTE, 0) >= 0
                THEN
             		vSumaTotalGlobokas := vSumaTotalGlobokas + CEIL(vMontoadeudado); --GLOBOKAS --Al inicio
                	vConteoTotal := vConteoTotal + 1;
                	IF vMonedaGlobokas IS NOT NULL THEN
                    	INSERT INTO recaudaglobokas (orden, campo) VALUES (vConteoTotal, vDetalleGlobokas);  --GLOBOKAS
                    END IF;
                END IF;
             END IF;
         END LOOP;
          
          vCabeceraGlobokas := '99999999'||
                  TRIM(TO_CHAR(vConteoTotal,'0000000'))||
                  TRIM(TO_CHAR((CASE WHEN (PIMONEDA) = 1 THEN vSumaTotalGlobokas * 100 ELSE 0 END), '000000000000000000'))||
                  TRIM(TO_CHAR((CASE WHEN (PIMONEDA) = 2 THEN vSumaTotalGlobokas * 100 ELSE 0 END), '000000000000'))||
                  TRIM(TO_CHAR(vfechabloqueo, 'YYYYMMDD'))||
                  vCodSer|| --Codigo de la empresa SVC
                  '00000000'|| --Fecha Vencimiento
                  '00000000000000000000000000000000000000000';  --GLOBOKAS
         --
         
         IF vMonedaGlobokas IS NOT NULL THEN
         	INSERT INTO recaudaglobokas (orden, campo ) VALUES (0, vCabeceraGlobokas );  --GLOBOKAS
         END IF;
         COMMIT;  --GLOBOKAS
END;

SELECT CAMPO FROM RECAUDAGLOBOKAS ORDER BY ORDEN ASC;