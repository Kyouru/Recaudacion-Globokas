DECLARE
	linebuf				VARCHAR2 (1000);
	cRecauda			recaudacionbanco%ROWTYPE;
	vFechapago			VARCHAR2(8);
	vValidaTrama		NUMBER;
	vFechaProceso		DATE:= SYSDATE;
	vNumerocuota		prestamocuotas.numerocuota%TYPE;

	vNrocli				VARCHAR(15);
	vNroSer				VARCHAR(15);
	vCodSVC				VARCHAR(2) := '33'; --Codigo del Servicio SVC
BEGIN
	--linebuf := '@@-00-20191014675-ATR-20201027-1-000000000005431-010201105201026-000-000033332145- R-CT-1234-000002-420-99999999-20201027-181059-69- V-000000000000000';
	linebuf := '330020200181283-ACT202011191000000000012841004210105201103000000000002600R CT0089645201L27ADMIN   2020111915495733V 000000000000000';
	linebuf := '330020201318882-ACT202011191000000000012841005210105201115000000000003700R CT0089645201L27ADMIN   2020111915495733V 000000000000000';
	linebuf := '330020200181734-ACT202011201000000000012841001210105201115000000000008400R CT0089645201L27ADMIN   2020111915495733V 000000000000000';
	
	IF linebuf IS NOT NULL AND SUBSTR(linebuf, 1, 2) = vCodSVC THEN
		SELECT COUNT(*) 
		INTO vValidaTrama 
		FROM RECAUDACIONBANCO
		WHERE REPLACE(TRIM(TRAMA), ' ', '') = REPLACE(TRIM(linebuf), ' ', '');

		IF vValidaTrama = 0 THEN

			cRecauda.trama					:= linebuf;
			cRecauda.fechacarga				:= vFechaProceso;
			cRecauda.usuariocarga			:= USER;
			cRecauda.codigobanco			:= 5;		-- Codigo Banco en Datosbanco -- ScotiaBank

			BEGIN
				vNrocli						:= SUBSTR(linebuf, 44, 15);
				vNroSer						:= SUBSTR(linebuf, 5, 15);

				cRecauda.nombrecliente		:= PKG_PERSONA.F_OBT_NOMBRECOMPLETO(PKG_PERSONA.F_OBT_CODIGOPERSONA(LPAD(TRIM(SUBSTR(linebuf, 29, 15)), 7, 0)));

				cRecauda.numerocuota		:= SUBSTR(vNrocli, 0, 3);

				cRecauda.tipopago			:= SUBSTR(vNroSer, 13, 3);
	            
				cRecauda.referencias      	:= SUBSTR(linebuf, 78, 21);
				cRecauda.moneda           	:= SUBSTR(linebuf, 28, 1);

				cRecauda.numerocuentabanco 	:= pkg_datosbanco.f_obt_cuentabancorecauda(cRecauda.codigobanco, cRecauda.moneda);

				cRecauda.periodosolicitud  	:= SUBSTR(vNroSer, 1, 4);
				cRecauda.numerosolicitud   	:= SUBSTR(vNroSer, 5, 7);
	            
				SELECT b.CIP INTO cRecauda.codigosocio
				FROM PRESTAMO a,PERSONA b
				WHERE a.PERIODOSOLICITUD=cRecauda.periodosolicitud
					AND a.NUMEROSOLICITUD=cRecauda.numerosolicitud
					AND b.CODIGOPERSONA=a.CODIGOPERSONA
					AND ROWNUM = 1;

				cRecauda.importeorigen 		:= TO_NUMBER(LTRIM(SUBSTR(linebuf, 62, 10), '0') || '.' || SUBSTR(linebuf, 72, 2), '9999999.99');
				cRecauda.importedepositado 	:= cRecauda.importeorigen;

				cRecauda.importemora 		:= 0;
				--cRecauda.oficinapago 		:= SUBSTR(linebuf, 82, 9);
	            cRecauda.oficinapago 		:= 0;
				cRecauda.nromovimiento 		:= vNrocli;

				cRecauda.fechaenvio 		:= TO_DATE 	(
														SUBSTR(vNrocli, -2, 2)||'/'||
														SUBSTR(vNrocli, -4, 2)||'/'||
														SUBSTR(vNrocli, -6, 2),
														'DD/MM/RR'
														);

				cRecauda.fechavencimiento 	:= TO_DATE 	(
														SUBSTR(vNrocli, -8, 2)||'/'||
														SUBSTR(vNrocli, -10, 2)||'/'||
														SUBSTR(vNrocli, -12, 2),
														'DD/MM/RR'
														);

				cRecauda.fechapago 			:= TO_DATE(SUBSTR(linebuf, 26, 2) || '/' || SUBSTR(linebuf, 24, 2) || '/' || SUBSTR(linebuf, 20, 4), 'DD/MM/RRRR');

				cRecauda.fechaproceso 		:= SYSDATE;
				cRecauda.usuarioproceso 	:= USER;
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

				cRecauda.cuotacronograma 	:= vNumerocuota;

				cRecauda.amortizacion   	:= pkg_prestamocuotas.F_OBT_AMORTIZACION ( 	cRecauda.numerosolicitud, 
																						cRecauda.periodosolicitud, 
																						vNumerocuota);

				cRecauda.interes        	:= pkg_prestamocuotas.F_OBT_INTERES ( 		cRecauda.numerosolicitud,
																						cRecauda.periodosolicitud, 
																						vNumerocuota );

				cRecauda.mora           	:= 0;

				cRecauda.reajuste       	:= pkg_prestamocuotas.F_OBT_REAJUSTE (		cRecauda.numerosolicitud, 
																						cRecauda.periodosolicitud, 
																						vNumerocuota);

				cRecauda.portes         	:= pkg_prestamocuotas.F_OBT_PORTES (		cRecauda.numerosolicitud, 
																						cRecauda.periodosolicitud, 
																						vNumerocuota);

				cRecauda.segurointeres  	:= pkg_prestamocuotas.F_OBT_SEGUROINTERES( 	cRecauda.numerosolicitud, 
																						cRecauda.periodosolicitud, 
																						vNumerocuota); 
				cRecauda.totalcuota 		:= 	NVL(cRecauda.amortizacion, 0) +
												NVL(cRecauda.interes, 0) +
												NVL(cRecauda.mora, 0) +
												NVL(cRecauda.reajuste, 0) +
												NVL(cRecauda.portes, 0) +
												NVL(cRecauda.segurointeres, 0);

				cRecauda.importeorigen 		:= 	NVL(cRecauda.amortizacion, 0) +
												NVL(cRecauda.interes, 0) +
												NVL(cRecauda.mora, 0) +
												NVL(cRecauda.reajuste, 0) +
												NVL(cRecauda.portes, 0) +
												NVL(cRecauda.segurointeres, 0);
				--
				IF cRecauda.numerocuota <> cRecauda.cuotacronograma THEN 
					cRecauda.observaciones 	:= cRecauda.observaciones || ' CUOTAS DIFERENTES ' || CHR(9);
				END IF;

				IF cRecauda.importeorigen <> cRecauda.totalcuota THEN
					cRecauda.observaciones 	:= cRecauda.observaciones || ' IMPORTES DIFERENTES ' || CHR(9);
				END IF;

				BEGIN
					INSERT INTO recaudacionbanco( fechacarga,
					usuariocarga,
					codigosocio,
					nombrecliente,
					referencias,
					importeorigen,
					importedepositado,
					importemora,
					oficinapago,
					nromovimiento,
					fechapago,
					tipopago,
					estado,
					codigobanco,
					numerocuentabanco,
					periodosolicitud,
					numerosolicitud,
					moneda,
					numerocuota,
					fechavencimiento,
					amortizacion,
					interes,
					mora,
					reajuste,
					portes,
					segurointeres,
					fechaproceso,
					usuarioproceso,
					trama,
					fechaenvio,
					debitoautomatico,
					cuotacronograma,
					totalcuota,
					observaciones
					)
					VALUES ( cRecauda.fechacarga,
					cRecauda.usuariocarga,
					cRecauda.codigosocio,
					cRecauda.nombrecliente,
					cRecauda.referencias,
					cRecauda.importeorigen,
					cRecauda.importedepositado,
					cRecauda.importemora,
					cRecauda.oficinapago,
					cRecauda.nromovimiento,
					cRecauda.fechapago,
					cRecauda.tipopago,
					cRecauda.estado,
					cRecauda.codigobanco,
					cRecauda.numerocuentabanco,
					cRecauda.periodosolicitud,
					cRecauda.numerosolicitud,
					cRecauda.moneda,
					cRecauda.numerocuota,
					cRecauda.fechavencimiento,
					cRecauda.amortizacion,
					cRecauda.interes,
					cRecauda.mora,
					cRecauda.reajuste,
					cRecauda.portes,
					cRecauda.segurointeres,
					cRecauda.fechaproceso,
					cRecauda.usuarioproceso,
					cRecauda.trama,
					cRecauda.fechaenvio,
					cRecauda.debitoautomatico,
					cRecauda.cuotacronograma,
					cRecauda.totalcuota,
					cRecauda.observaciones
					) ;
					COMMIT;
				END;
			END;
		END IF;
	END IF;
END;

SELECT * FROM RECAUDACIONBANCO ORDER BY FECHACARGA DESC;

DELETE FROM RECAUDACIONBANCO WHERE TRAMA = '330020200181283-ACT202011191000000000012841004210105201103000000000002600R CT0089645201L27ADMIN   2020111915495733V 000000000000000';