--Corregir 3 tramas mal parseadas por PKG_RECAUDACIONBANCO.P_GEN_CARGAGLOBOKAS
DECLARE
    TYPE array_linebuf_type IS varray(3) OF VARCHAR2(1000);
    array_linebuf array_linebuf_type := array_linebuf_type( '330020202118384-ATR202103061000000044885150005210210210305000000000069700R CT0089700201L27ADMIN   2021030610343733V 000000000000000',
                                                            '330020202118385-ACT202103051000000073467928006210310210304000000000062500R CT0089175641L27ADMIN   2021030509392133V 000000000000000',
                                                            '330020210823191-ACT202103021000000040667119001210312210301000000000010100R CT0089645201L27ADMIN   2021030215504733V 000000000000000');
    linebuf             VARCHAR2(1000);
    cRecauda            recaudacionbanco%ROWTYPE;
    
    vNumerocuota        prestamocuotas.numerocuota%TYPE;
    vCodSVC             VARCHAR(4) := '3300'; --Codigo del Servicio SVC. Identificador de trama kasnet
    
BEGIN
    FOR i IN 1..array_linebuf.count LOOP
        linebuf := array_linebuf(i);

        IF linebuf IS NOT NULL AND SUBSTR(linebuf, 1, 4) = vCodSVC THEN
            
            cRecauda.trama                  := linebuf;
            cRecauda.codigobanco            := 5;  -- Codigo Banco en Datosbanco -- ScotiaBank

            BEGIN
                --CODSER Siempre 33
                --SUBSTR(linebuf, 1, 2)

                --CODSEC Siempre 00
                --SUBSTR(linebuf, 3, 2)

                --NROFAC (PERIODO+SOLICITUD-ACT/ATR)
                --SUBSTR(linebuf, 5, 15)
                cRecauda.periodosolicitud   := SUBSTR(linebuf, 5, 4);
                cRecauda.numerosolicitud    := SUBSTR(linebuf, 9, 7);
                --guion
                cRecauda.tipopago           := SUBSTR(linebuf, 17, 3);

                SELECT b.CIP, b.nombrecompleto INTO cRecauda.codigosocio, cRecauda.nombrecliente
                FROM PRESTAMO a, PERSONA b
                WHERE a.PERIODOSOLICITUD = cRecauda.periodosolicitud
                    AND a.NUMEROSOLICITUD = cRecauda.numerosolicitud
                    AND b.CODIGOPERSONA = a.CODIGOPERSONA
                    AND ROWNUM = 1;

                --FECFAC (YYYYMMDD)
                --SUBSTR(linebuf, 20, 8)

                --MONFAC (Soles = 1)
                --SUBSTR(linebuf, 28, 1)
                cRecauda.moneda             := SUBSTR(linebuf, 28, 1);

                --NROSER (Cod. Socio) 
                --SUBSTR(linebuf, 29, 15)

                --NROCLI (NroCuota, FechaVencimiento, FechaEnvio) 
                --SUBSTR(linebuf, 44, 15)
                cRecauda.numerocuota        := SUBSTR(linebuf, 44, 3);
                cRecauda.fechavencimiento   := TO_DATE  (
                                                        SUBSTR(linebuf, 47, 2)||'-'||
                                                        SUBSTR(linebuf, 49, 2)||'-'||
                                                        SUBSTR(linebuf, 51, 2),
                                                        'YY-MM-DD'
                                                        );
                cRecauda.fechaenvio         := TO_DATE  (
                                                        SUBSTR(linebuf, 53, 2)||'-'||
                                                        SUBSTR(linebuf, 55, 2)||'-'||
                                                        SUBSTR(linebuf, 57, 2),
                                                        'YY-MM-DD'
                                                        );

                cRecauda.nromovimiento      := SUBSTR(linebuf, 44, 15);

                --NROCEN Siempre 000
                --SUBSTR(linebuf, 59, 3)

                --IMPTOT
                --SUBSTR(linebuf, 62, 12)
                cRecauda.importedepositado  := TO_NUMBER(SUBSTR(linebuf, 62, 12)) / 100;
                
                --TIPODOC1 Siempre R
                --SUBSTR(linebuf, 74, 2)
                
                --TIPOENT Siempre CT
                --SUBSTR(linebuf, 76, 2)
                
                --CODENT
                --SUBSTR(linebuf, 78, 4)
                
                --CODSUC
                --SUBSTR(linebuf, 82, 6)
                
                --CODAGE
                --SUBSTR(linebuf, 88, 3)
                
                --USUARIO
                --SUBSTR(linebuf, 91, 8)
                cRecauda.referencias        := SUBSTR(linebuf, 74, 25);
                
                --FECCAN (YYYYMMDD)
                --SUBSTR(linebuf, 99, 8)
                cRecauda.fechapago          := TO_DATE  (
                                                        SUBSTR(linebuf, 99, 4)||'-'||
                                                        SUBSTR(linebuf, 103, 2)||'-'||
                                                        SUBSTR(linebuf, 105, 2),
                                                        'YYYY-MM-DD'
                                                        );
                
                --HORPAG (HHMMSS)
                --SUBSTR(linebuf, 107, 6)
                
                --CODNEG
                --SUBSTR(linebuf, 113, 2)
                
                --VIAPAG
                --SUBSTR(linebuf, 115, 2)
                
                --FILLER
                --SUBSTR(linebuf, 117, 15)

                cRecauda.numerocuentabanco  := pkg_datosbanco.f_obt_cuentabancorecauda(cRecauda.codigobanco, cRecauda.moneda);

                cRecauda.importemora        := 0;

                cRecauda.oficinapago        := 0;

                BEGIN
                    SELECT MIN(numerocuota)
                    INTO vNumerocuota
                    FROM prestamocuotas 
                    WHERE periodosolicitud = cRecauda.periodosolicitud 
                    AND numerosolicitud = cRecauda.numerosolicitud 
                    AND estado = 2;
                EXCEPTION WHEN OTHERS THEN
                    vNumerocuota := NULL;
                END; 

                BEGIN
                    PKG_RECAUDACIONBANCO.P_OBT_VERIFICARDEBITOAUTO(cRecauda.periodosolicitud, cRecauda.numerosolicitud, cRecauda.debitoautomatico);
                    cRecauda.estado := '1';
                EXCEPTION WHEN OTHERS THEN
                    RAISE_APPLICATION_ERROR(-20120,'  cRecauda.estado  ' || cRecauda.estado  );
                END;

                cRecauda.cuotacronograma    := vNumerocuota;

                cRecauda.amortizacion       := pkg_prestamocuotas.F_OBT_AMORTIZACION (  cRecauda.numerosolicitud, 
                                                                                        cRecauda.periodosolicitud, 
                                                                                        vNumerocuota);

                cRecauda.interes            := pkg_prestamocuotas.F_OBT_INTERES (       cRecauda.numerosolicitud,
                                                                                        cRecauda.periodosolicitud, 
                                                                                        vNumerocuota );

                cRecauda.mora               := 0;

                cRecauda.reajuste           := pkg_prestamocuotas.F_OBT_REAJUSTE (      cRecauda.numerosolicitud, 
                                                                                        cRecauda.periodosolicitud, 
                                                                                        vNumerocuota);

                cRecauda.portes             := pkg_prestamocuotas.F_OBT_PORTES (        cRecauda.numerosolicitud, 
                                                                                        cRecauda.periodosolicitud, 
                                                                                        vNumerocuota);

                cRecauda.segurointeres      := pkg_prestamocuotas.F_OBT_SEGUROINTERES(  cRecauda.numerosolicitud, 
                                                                                        cRecauda.periodosolicitud, 
                                                                                        vNumerocuota); 
                cRecauda.totalcuota         :=  NVL(cRecauda.amortizacion, 0) +
                                                NVL(cRecauda.interes, 0) +
                                                NVL(cRecauda.mora, 0) +
                                                NVL(cRecauda.reajuste, 0) +
                                                NVL(cRecauda.portes, 0) +
                                                NVL(cRecauda.segurointeres, 0);

                cRecauda.importeorigen      :=  NVL(cRecauda.amortizacion, 0) +
                                                NVL(cRecauda.interes, 0) +
                                                NVL(cRecauda.mora, 0) +
                                                NVL(cRecauda.reajuste, 0) +
                                                NVL(cRecauda.portes, 0) +
                                                NVL(cRecauda.segurointeres, 0);
                --
                IF cRecauda.numerocuota <> cRecauda.cuotacronograma THEN 
                    cRecauda.observaciones  := cRecauda.observaciones || ' CUOTAS DIFERENTES ' || CHR(9);
                END IF;

                IF cRecauda.importeorigen <> cRecauda.totalcuota THEN
                    cRecauda.observaciones  := cRecauda.observaciones || ' IMPORTES DIFERENTES ' || CHR(9);
                END IF;

                BEGIN
                    UPDATE recaudacionbanco 
                    SET codigosocio = cRecauda.codigosocio,
                        nombrecliente = cRecauda.nombrecliente,
                        referencias = cRecauda.referencias,
                        importeorigen = cRecauda.importeorigen,
                        importedepositado = cRecauda.importedepositado,
                        importemora = cRecauda.importemora,
                        oficinapago = cRecauda.oficinapago,
                        nromovimiento = cRecauda.nromovimiento,
                        fechapago = cRecauda.fechapago,
                        tipopago = cRecauda.tipopago,
                        estado = cRecauda.estado,
                        codigobanco = cRecauda.codigobanco,
                        numerocuentabanco = cRecauda.numerocuentabanco,
                        periodosolicitud = cRecauda.periodosolicitud,
                        numerosolicitud = cRecauda.numerosolicitud,
                        moneda = cRecauda.moneda,
                        numerocuota = cRecauda.numerocuota,
                        fechavencimiento = cRecauda.fechavencimiento,
                        amortizacion = cRecauda.amortizacion,
                        interes = cRecauda.interes,
                        mora = cRecauda.mora,
                        reajuste = cRecauda.reajuste,
                        portes = cRecauda.portes,
                        segurointeres = cRecauda.segurointeres,
                        fechaenvio = cRecauda.fechaenvio,
                        debitoautomatico = cRecauda.debitoautomatico,
                        cuotacronograma = cRecauda.cuotacronograma,
                        totalcuota = cRecauda.totalcuota,
                        observaciones = cRecauda.observaciones
                    WHERE REPLACE(TRIM(TRAMA), ' ', '') = REPLACE(TRIM(linebuf), ' ', '');
                    COMMIT; 
                END;
            END;
        END IF;
    END LOOP;
END;