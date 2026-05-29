CREATE PROCEDURE sp_generar_datos_masivos_optimizado
    @cantidad_usuarios INT = 100000,
    @cantidad_citas INT = 400000,
    @cantidad_sedes INT = 100,
    @cantidad_disenadores INT = 1000,
    @cantidad_agendas INT = 5000
AS
BEGIN
    SET NOCOUNT ON;

    PRINT '==================================================';
    PRINT '  INICIANDO GENERACIÓN DE DATOS MASIVOS COMPLETA ';
    PRINT '==================================================';

    -- Base de generación numérica rápida mediante CTEs multiplicadas por filas cruzadas
    WITH L0 AS (SELECT 1 AS c UNION ALL SELECT 1), -- 2
         L1 AS (SELECT 1 AS c FROM L0 AS a CROSS JOIN L0 AS b), -- 4
         L2 AS (SELECT 1 AS c FROM L1 AS a CROSS JOIN L1 AS b), -- 16
         L3 AS (SELECT 1 AS c FROM L2 AS a CROSS JOIN L2 AS b), -- 256
         L4 AS (SELECT 1 AS c FROM L3 AS a CROSS JOIN L3 AS b), -- 65,536
         L5 AS (SELECT 1 AS c FROM L4 AS a CROSS JOIN L4 AS b), -- 4,294,967,296
         Nums AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS N FROM L5)
    SELECT N INTO #NumerosBase FROM Nums WHERE N <= 500000; -- Guardamos una matriz rápida indexada en TempDB

    ---------------------------------------------------------
    -- 1. GENERACIÓN MASIVA DE SEDES
    ---------------------------------------------------------
    PRINT 'Insertando sedes masivas...';
    INSERT INTO SEDE (nombre, direccion, telefono)
    SELECT TOP (@cantidad_sedes)
        CONCAT('Sede Industrial ', N) AS nombre,
        CONCAT('Avenida Metropolitana # ', (N % 150) + 1, ' - ', (N % 90) + 1) AS direccion,
        CONCAT('604', RIGHT('0000000' + CAST(N AS VARCHAR), 7)) AS telefono
    FROM #NumerosBase;

    -- Capturamos rango de Sedes reales creadas
    DECLARE @min_s INT = (SELECT MIN(id_sede) FROM SEDE);
    DECLARE @max_s INT = (SELECT MAX(id_sede) FROM SEDE);
    DECLARE @total_sedes INT = (@max_s - @min_s + 1);

    ---------------------------------------------------------
    -- 2. GENERACIÓN MASIVA DE DISEÑADORES
    ---------------------------------------------------------
    PRINT 'Insertando diseñadores masivos...';
    INSERT INTO DISENADOR (nombre, apellido, correo, id_sede)
    SELECT TOP (@cantidad_disenadores)
        CONCAT('DisenadorNombre_', N) AS nombre,
        CONCAT('Apellido_', N) AS apellido,
        CONCAT('disenador_corp_', N, '@visionmadera.com') AS correo,
        ISNULL((N % @total_sedes) + @min_s, @min_s) AS id_sede
    FROM #NumerosBase;

    -- Capturamos rango de Diseñadores reales creadas
    DECLARE @min_d INT = (SELECT MIN(id_disenador) FROM DISENADOR);
    DECLARE @max_d INT = (SELECT MAX(id_disenador) FROM DISENADOR);
    DECLARE @total_disenadores INT = (@max_d - @min_d + 1);

    ---------------------------------------------------------
    -- 3. GENERACIÓN MASIVA DE AGENDAS DE DISEÑADOR
    ---------------------------------------------------------
    PRINT 'Insertando agendas de diseñadores masivas...';
    DECLARE @min_b INT = (SELECT MIN(id_bloque) FROM BLOQUE_HORARIO);
    DECLARE @max_b INT = (SELECT MAX(id_bloque) FROM BLOQUE_HORARIO);
    DECLARE @total_bloques INT = (@max_b - @min_b + 1);

    -- Tabla temporal en línea para mapear días de la semana de forma cíclica y matemática
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
    -- 4. GENERACIÓN MASIVA DE USUARIOS
    ---------------------------------------------------------
    PRINT 'Insertando usuarios masivos...';
    DECLARE @ultimo_id INT = (SELECT ISNULL(MAX(TRY_CAST(documento AS INT)), 0) FROM USUARIO);

    INSERT INTO USUARIO (documento, nombre1, nombre2, apellido1, apellido2, correo, contrasena, direccion, telefono, fecha_nacimiento)
    SELECT TOP (@cantidad_usuarios)
        CAST(N + @ultimo_id AS VARCHAR(20)) AS documento,
        CONCAT('Nombre1_', N + @ultimo_id) AS nombre1,
        CASE WHEN N % 3 = 0 THEN CONCAT('Nombre2_', N + @ultimo_id) ELSE NULL END AS nombre2,
        CONCAT('Apellido1_', N + @ultimo_id) AS apellido1,
        CASE WHEN N % 3 = 0 THEN CONCAT('Apellido2_', N + @ultimo_id) ELSE NULL END AS apellido2,
        CONCAT('user_opt_', N + @ultimo_id, '@visionmadera.com') AS correo,
        'hash_password_seguro_999' AS contrasena,
        CONCAT('Calle ', (N % 100) + 1, ' Carrera ', (N % 80) + 1, ' # ', (N % 50) + 1) AS direccion,
        CONCAT('315', RIGHT('0000000' + CAST(N AS VARCHAR), 7)) AS telefono,
        DATEADD(DAY, -(N % 12000) - 6570, GETDATE()) AS fecha_nacimiento
    FROM #NumerosBase
    WHERE NOT EXISTS (SELECT 1 FROM USUARIO WHERE documento = CAST(#NumerosBase.N + @ultimo_id AS VARCHAR(20)));

    -- Estructura de mapeo secuencial de usuarios existentes para evitar fallas FK_Cita
    CREATE TABLE #UsuariosExistentes (IdSecuencial INT PRIMARY KEY, documento VARCHAR(20));
    INSERT INTO #UsuariosExistentes (IdSecuencial, documento) SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)), documento FROM USUARIO;
    DECLARE @total_usuarios_reales INT = (SELECT COUNT(*) FROM #UsuariosExistentes);

    ---------------------------------------------------------
    -- 5. GENERACIÓN MASIVA DE CITAS
    ---------------------------------------------------------
    PRINT 'Insertando citas masivas...';
    DECLARE @min_e INT = (SELECT MIN(id_estado_cita) FROM ESTADO_CITA);
    DECLARE @max_e INT = (SELECT MAX(id_estado_cita) FROM ESTADO_CITA);
    DECLARE @total_estados INT = (@max_e - @min_e + 1);

    INSERT INTO CITA (fecha, id_bloque, id_estado_cita, documento, id_sede, id_disenador)
    SELECT TOP (@cantidad_citas)
        DATEADD(DAY, (N % 120) - 60, GETDATE()) AS fecha, 
        ISNULL((N % @total_bloques) + @min_b, @min_b) AS id_bloque,
        ISNULL((N % @total_estados) + @min_e, @min_e) AS id_estado_cita,
        U.documento AS documento, 
        ISNULL((N % @total_sedes) + @min_s, @min_s) AS id_sede,
        ISNULL((N % @total_disenadores) + @min_d, @min_d) AS id_disenador
    FROM #NumerosBase
    INNER JOIN #UsuariosExistentes U ON U.IdSecuencial = ((N % @total_usuarios_reales) + 1);

    ---------------------------------------------------------
    -- 6. GENERACIÓN MASIVA DE PAGOS (Relación 1 a 1 con Citas)
    ---------------------------------------------------------
    PRINT 'Insertando pagos masivos...';
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
    WHERE C.id_estado_cita IN (2, 3) 
      AND NOT EXISTS (SELECT 1 FROM PAGO P WHERE P.id_cita = C.id_cita);

    ---------------------------------------------------------
    -- 7. GENERACIÓN MASIVA DE CALIFICACIONES
    ---------------------------------------------------------
    PRINT 'Insertando calificaciones masivas...';
    INSERT INTO CALIFICACION (puntaje, comentario, fecha, id_cita)
    SELECT 
        (C.id_cita % 5) + 1 AS puntaje,
        CONCAT('Calificación automática optimizada. Cita ID: ', C.id_cita),
        GETDATE() AS fecha,
        C.id_cita
    FROM CITA C
    WHERE C.id_estado_cita = 3 
      AND NOT EXISTS (SELECT 1 FROM CALIFICACION CAL WHERE CAL.id_cita = C.id_cita);

    ---------------------------------------------------------
    -- 8. GENERACIÓN MASIVA DE PQRS
    ---------------------------------------------------------
    PRINT 'Insertando PQRS masivas...';
    DECLARE @min_tp INT = (SELECT MIN(id_tipo_pqrs) FROM TIPO_PQRS);
    DECLARE @max_tp INT = (SELECT MAX(id_tipo_pqrs) FROM TIPO_PQRS);
    DECLARE @min_estp INT = (SELECT MIN(id_estado_pqrs) FROM ESTADO_PQRS);
    DECLARE @max_estp INT = (SELECT MAX(id_estado_pqrs) FROM ESTADO_PQRS);
    DECLARE @total_pqrs INT = @cantidad_citas / 10; 

    INSERT INTO PQRS (id_tipo_pqrs, descripcion, fecha, id_estado_pqrs, documento)
    SELECT TOP (@total_pqrs)
        ISNULL((N % (@max_tp - @min_tp + 1)) + @min_tp, @min_tp) AS id_tipo_pqrs,
        CONCAT('Sugerencia/Reclamo analítico del sistema masivo número: ', N),
        GETDATE() AS fecha,
        ISNULL((N % (@max_estp - @min_estp + 1)) + @min_estp, @min_estp) AS id_estado_pqrs,
        U.documento
    FROM #NumerosBase
    INNER JOIN #UsuariosExistentes U ON U.IdSecuencial = ((N % @total_usuarios_reales) + 1);

    -- Limpieza estructural final
    DROP TABLE #NumerosBase;
    DROP TABLE #UsuariosExistentes;

    PRINT '==================================================';
    PRINT '  PROCESO DE CARGA MASIVA FINALIZADO CON ÉXITO    ';
    PRINT '==================================================';
END;
GO

EXEC sp_generar_datos_masivos_optimizado 
    @cantidad_usuarios = 100000, 
    @cantidad_citas = 400000,
    @cantidad_sedes = 150,       
    @cantidad_disenadores = 1500,
    @cantidad_agendas = 8000;