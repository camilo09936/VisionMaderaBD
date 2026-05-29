CREATE PROCEDURE sp_generar_datos_masivos_optimizado
    @cantidad_usuarios INT = 200000,     -- Escalado a 200 mil usuarios
    @cantidad_citas INT = 3000000,       -- ¡Por defecto 3 Millones de Citas!
    @cantidad_sedes INT = 200,           
    @cantidad_disenadores INT = 2000,     -- Escalado a 2.000 diseñadores
    @cantidad_agendas INT = 15000
AS
BEGIN
    SET NOCOUNT ON;

    PRINT '==================================================';
    PRINT '  INICIANDO GENERACIÓN MULTIMILLONARIA DE DATOS   ';
    PRINT '==================================================';

    -- Matriz numérica base en TempDB (Bloque optimizado de 500k filas max por vuelta)
    IF OBJECT_ID('tempdb..#NumerosBase') IS NOT NULL DROP TABLE #NumerosBase;
    
    WITH L0 AS (SELECT 1 AS c UNION ALL SELECT 1), 
         L1 AS (SELECT 1 AS c FROM L0 AS a CROSS JOIN L0 AS b), 
         L2 AS (SELECT 1 AS c FROM L1 AS a CROSS JOIN L1 AS b), 
         L3 AS (SELECT 1 AS c FROM L2 AS a CROSS JOIN L2 AS b), 
         L4 AS (SELECT 1 AS c FROM L3 AS a CROSS JOIN L3 AS b), 
         L5 AS (SELECT 1 AS c FROM L4 AS a CROSS JOIN L4 AS b), 
         Nums AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS N FROM L5)
    SELECT N INTO #NumerosBase FROM Nums WHERE N <= 500000;

    ---------------------------------------------------------
    -- 1. GENERACIÓN MASIVA DE SEDES
    ---------------------------------------------------------
    PRINT '-> Insertando sedes masivas...';
    INSERT INTO SEDE (nombre, direccion, telefono)
    SELECT TOP (@cantidad_sedes)
        CONCAT('Sede Industrial ', N) AS nombre,
        CONCAT('Avenida Metropolitana # ', (N % 150) + 1, ' - ', (N % 90) + 1) AS direccion,
        CONCAT('604', RIGHT('0000000' + CAST(N AS VARCHAR), 7)) AS telefono
    FROM #NumerosBase;

    DECLARE @min_s INT = (SELECT MIN(id_sede) FROM SEDE);
    DECLARE @max_s INT = (SELECT MAX(id_sede) FROM SEDE);
    DECLARE @total_sedes INT = (@max_s - @min_s + 1);

    ---------------------------------------------------------
    -- 2. GENERACIÓN MASIVA DE DISEÑADORES
    ---------------------------------------------------------
    PRINT '-> Insertando diseñadores masivos...';
    INSERT INTO DISENADOR (nombre, apellido, correo, id_sede)
    SELECT TOP (@cantidad_disenadores)
        CONCAT('DisenadorNombre_', N) AS nombre,
        CONCAT('Apellido_', N) AS apellido,
        CONCAT('disenador_corp_', N, '@visionmadera.com') AS correo,
        ISNULL((N % @total_sedes) + @min_s, @min_s) AS id_sede
    FROM #NumerosBase;

    DECLARE @min_d INT = (SELECT MIN(id_disenador) FROM DISENADOR);
    DECLARE @max_d INT = (SELECT MAX(id_disenador) FROM DISENADOR);
    DECLARE @total_disenadores INT = (@max_d - @min_d + 1);

    ---------------------------------------------------------
    -- 3. GENERACIÓN MASIVA DE AGENDAS DE DISEÑADOR
    ---------------------------------------------------------
    PRINT '-> Insertando agendas masivas...';
    DECLARE @min_b INT = (SELECT MIN(id_bloque) FROM BLOQUE_HORARIO);
    DECLARE @max_b INT = (SELECT MAX(id_bloque) FROM BLOQUE_HORARIO);
    DECLARE @total_bloques INT = (@max_b - @min_b + 1);

    CREATE TABLE #DiasSemana (id INT, dia VARCHAR(20));
    INSERT INTO #DiasSemana VALUES (0,'Lunes'),(1,'Martes'),(2,'Miercoles'),(3,'Jueves'),(4,'Viernes'),(5,'Sabado');

    INSERT INTO AGENDA_DISENADOR (id_disenador, dia_semana, id_bloque)
    SELECT TOP (@cantidad_agendas)
        ISNULL((N % @total_disenadores) + @min_d, @min_d) AS id_disenador,
        D.dia AS dia_semana,
        ISNULL((N % @total_bloques) + @min_b, @min_b) AS id_bloque
    FROM #NumerosBase
    INNER JOIN #DiasSemana D ON D.id = (N % 6);
    
    DROP TABLE #DiasSemana;

    ---------------------------------------------------------
    -- 4. GENERACIÓN MASIVA DE USUARIOS (Soporta Cientos de Miles)
    ---------------------------------------------------------
    PRINT '-> Insertando usuarios masivos...';
    DECLARE @usuarios_insertados INT = 0;
    DECLARE @ultimo_id INT = (SELECT ISNULL(MAX(TRY_CAST(documento AS INT)), 0) FROM USUARIO);

    WHILE @usuarios_insertados < @cantidad_usuarios
    BEGIN
        DECLARE @lote_u INT = CASE WHEN (@cantidad_usuarios - @usuarios_insertados) > 500000 THEN 500000 ELSE (@cantidad_usuarios - @usuarios_insertados) END;

        INSERT INTO USUARIO (documento, nombre1, nombre2, apellido1, apellido2, correo, contrasena, direccion, telefono, fecha_nacimiento)
        SELECT TOP (@lote_u)
            CAST(N + @usuarios_insertados + @ultimo_id AS VARCHAR(20)) AS documento,
            CONCAT('Nombre1_', N + @usuarios_insertados) AS nombre1,
            CASE WHEN N % 3 = 0 THEN CONCAT('Nombre2_', N + @usuarios_insertados) ELSE NULL END AS nombre2,
            CONCAT('Apellido1_', N + @usuarios_insertados) AS apellido1,
            CASE WHEN N % 3 = 0 THEN CONCAT('Apellido2_', N + @usuarios_insertados) ELSE NULL END AS apellido2,
            CONCAT('user_', N + @usuarios_insertados + @ultimo_id, '@visionmadera.com') AS correo,
            'hash_password_seguro_999' AS contrasena,
            CONCAT('Calle ', (N % 100) + 1, ' Carrera ', (N % 80) + 1, ' # ', (N % 50) + 1) AS direccion,
            CONCAT('315', RIGHT('0000000' + CAST(N AS VARCHAR), 7)) AS telefono,
            DATEADD(DAY, -(N % 12000) - 6570, GETDATE()) AS fecha_nacimiento
        FROM #NumerosBase;

        SET @usuarios_insertados += @lote_u;
    END

    -- Estructura de mapeo secuencial estricto de usuarios existentes
    CREATE TABLE #UsuariosExistentes (IdSecuencial INT PRIMARY KEY, documento VARCHAR(20));
    INSERT INTO #UsuariosExistentes (IdSecuencial, documento) SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)), documento FROM USUARIO;
    DECLARE @total_usuarios_reales INT = (SELECT COUNT(*) FROM #UsuariosExistentes);

    ---------------------------------------------------------
    -- 5. GENERACIÓN POR LOTES DE CITAS (Soporta MILLONES)
    ---------------------------------------------------------
    PRINT '-> Insertando CITAS por lotes (Operación Multimillonaria)...';
    DECLARE @citas_insertadas INT = 0;
    DECLARE @min_e INT = (SELECT MIN(id_estado_cita) FROM ESTADO_CITA);
    DECLARE @max_e INT = (SELECT MAX(id_estado_cita) FROM ESTADO_CITA);
    DECLARE @total_estados INT = (@max_e - @min_e + 1);

    WHILE @citas_insertadas < @cantidad_citas
    BEGIN
        -- Evaluamos el tamaño del fragmento actual (máximo 500.000 por vuelta)
        DECLARE @lote_c INT = CASE WHEN (@cantidad_citas - @citas_insertadas) > 500000 THEN 500000 ELSE (@cantidad_citas - @citas_insertadas) END;

        INSERT INTO CITA (fecha, id_bloque, id_estado_cita, documento, id_sede, id_disenador)
        SELECT TOP (@lote_c)
            DATEADD(DAY, ((N + @citas_insertadas) % 180) - 90, GETDATE()) AS fecha, 
            ISNULL(((N + @citas_insertadas) % @total_bloques) + @min_b, @min_b) AS id_bloque,
            ISNULL(((N + @citas_insertadas) % @total_estados) + @min_e, @min_e) AS id_estado_cita,
            U.documento AS documento, 
            ISNULL(((N + @citas_insertadas) % @total_sedes) + @min_s, @min_s) AS id_sede,
            ISNULL(((N + @citas_insertadas) % @total_disenadores) + @min_d, @min_d) AS id_disenador
        FROM #NumerosBase
        INNER JOIN #UsuariosExistentes U ON U.IdSecuencial = (((N + @citas_insertadas) % @total_usuarios_reales) + 1);

        SET @citas_insertadas += @lote_c;
        PRINT CONCAT('   ... ', @citas_insertadas, ' citas procesadas.');
    END

    ---------------------------------------------------------
    -- 6. GENERACIÓN MASIVA DE PAGOS (Relación 1 a 1 con Citas)
    ---------------------------------------------------------
    PRINT '-> Insertando pagos masivos...';
    DECLARE @min_mp INT = (SELECT MIN(id_metodo_pago) FROM METODO_PAGO);
    DECLARE @max_mp INT = (SELECT MAX(id_metodo_pago) FROM METODO_PAGO);
    DECLARE @min_ep INT = (SELECT MIN(id_estado_pago) FROM ESTADO_PAGO);
    DECLARE @max_ep INT = (SELECT MAX(id_estado_pago) FROM ESTADO_PAGO);
    
    DECLARE @total_mp INT = (@max_mp - @min_mp + 1);
    DECLARE @total_ep INT = (@max_ep - @min_ep + 1);

    INSERT INTO PAGO (monto, id_metodo_pago, id_estado_pago, fecha_pago, id_cita)
    SELECT 
        CAST(((C.id_cita % 500) * 1000) + 45000 AS DECIMAL(10,2)) AS monto,
        ISNULL((C.id_cita % @total_mp) + @min_mp, @min_mp) AS id_metodo_pago,
        ISNULL((C.id_cita % @total_ep) + @min_ep, @min_ep) AS id_estado_pago,
        GETDATE() AS fecha_pago,
        C.id_cita
    FROM CITA C
    WHERE C.id_estado_cita IN (2, 3);

    ---------------------------------------------------------
    -- 7. GENERACIÓN MASIVA DE CALIFICACIONES
    ---------------------------------------------------------
    PRINT '-> Insertando calificaciones masivas...';
    INSERT INTO CALIFICACION (puntaje, comentario, fecha, id_cita)
    SELECT 
        (C.id_cita % 5) + 1 AS puntaje,
        CONCAT('Comentario automático optimizado millonario. Cita ID: ', C.id_cita),
        GETDATE() AS fecha,
        C.id_cita
    FROM CITA C
    WHERE C.id_estado_cita = 3;

    ---------------------------------------------------------
    -- 8. GENERACIÓN MASIVA DE PQRS
    ---------------------------------------------------------
    PRINT '-> Insertando PQRS masivas...';
    DECLARE @min_tp INT = (SELECT MIN(id_tipo_pqrs) FROM TIPO_PQRS);
    DECLARE @max_tp INT = (SELECT MAX(id_tipo_pqrs) FROM TIPO_PQRS);
    DECLARE @min_estp INT = (SELECT MIN(id_estado_pqrs) FROM ESTADO_PQRS);
    DECLARE @max_estp INT = (SELECT MAX(id_estado_pqrs) FROM ESTADO_PQRS);
    DECLARE @total_pqrs INT = @cantidad_citas / 12; 

    INSERT INTO PQRS (id_tipo_pqrs, descripcion, fecha, id_estado_pqrs, documento)
    SELECT TOP (@total_pqrs)
        ISNULL((N % (@max_tp - @min_tp + 1)) + @min_tp, @min_tp) AS id_tipo_pqrs,
        CONCAT('PQRS masiva analítica del sistema número: ', N),
        GETDATE() AS fecha,
        ISNULL((N % (@max_estp - @min_estp + 1)) + @min_estp, @min_estp) AS id_estado_pqrs,
        U.documento
    FROM #NumerosBase
    INNER JOIN #UsuariosExistentes U ON U.IdSecuencial = ((N % @total_usuarios_reales) + 1);

    -- Limpieza estructural final
    DROP TABLE #NumerosBase;
    DROP TABLE #UsuariosExistentes;

    PRINT '==================================================';
    PRINT '  PROCESO CARGA MULTIMILLONARIA COMPLETADO EXITOSO';
    PRINT '==================================================';
END;
GO

EXEC sp_generar_datos_masivos_optimizado 
    @cantidad_usuarios = 3000000, 
    @cantidad_citas = 4000000,    
    @cantidad_sedes = 200,        
    @cantidad_disenadores = 2000, 
    @cantidad_agendas = 15000;