--Optimizacion SP #1 (Registrar Pago de Cita)
CREATE PROCEDURE sp_RegistrarPagoCita
	@id_cita INT,
	@monto_base DECIMAL (10,2),
	@id_metodo_pago INT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @monto_total DECIMAL (10,2) = @monto_base * 1.19;
	DECLARE @id_estado_confirmada INT;
	DECLARE @id_pago_aprobado INT;
	SELECT @id_estado_confirmada = id_estado_cita FROM ESTADO_CITA WHERE nombre = 'Confirmada';
	SELECT @id_pago_aprobado = id_estado_pago FROM ESTADO_PAGO WHERE nombre = 'Aprobado';
	BEGIN TRY
		BEGIN TRANSACTION
			IF NOT EXISTS (SELECT 1 FROM CITA WHERE id_cita = @id_cita)  
			BEGIN  
				PRINT 'La cita no existe.';
				ROLLBACK TRANSACTION;
				RETURN;
			END
			IF EXISTS (SELECT 1 FROM PAGO WHERE id_cita = @id_cita)
			BEGIN
				PRINT 'Esta cita ya cuenta con pago registrado.';
				ROLLBACK TRANSACTION;
				RETURN;
			END
			INSERT INTO PAGO (monto, id_metodo_pago, id_estado_pago, fecha_pago, id_cita) 
			VALUES (@monto_total, @id_metodo_pago, @id_pago_aprobado, GETDATE(), @id_cita);
			UPDATE CITA 
			SET id_estado_cita = @id_estado_confirmada 
			WHERE id_cita = @id_cita; 
			PRINT 'Pago registrado por un total de: $' + CAST(@monto_total AS VARCHAR);
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		PRINT 'Error: ' + ERROR_MESSAGE();
	END CATCH
END;
GO

----------------------------------------------------------------------------------------------------
CREATE NONCLUSTERED INDEX IX_CITA_id_disenador_id_estado ON CITA (id_disenador, id_estado_cita);
GO

--Optimizacion SP #2 (Calcular Comision Dise�adores segun citas realizadas)
CREATE PROCEDURE sp_CalcularComisionDisenadores 
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @id_realizada INT = (SELECT id_estado_cita FROM ESTADO_CITA WHERE nombre = 'Realizada'); 
	SELECT 
		CONCAT('Dise�ador: ', ISNULL(D.nombre, ''), ' ', ISNULL(D.apellido, ''), 
		       ' --> Citas Realizadas: ', COUNT(C.id_cita), 
		       ' --> Comisi�n Total: $', CAST(COUNT(C.id_cita) * 5000 AS VARCHAR)) AS ReporteComision
	FROM DISENADOR D 
	LEFT JOIN CITA C ON D.id_disenador = C.id_disenador AND C.id_estado_cita = @id_realizada 
	GROUP BY D.nombre, D.apellido, D.id_disenador;
END;
GO

--------------------------------------------------------------------------------------------------------
--Optimizacion SP #3 (Registrar Calificacion de Una Cita)
CREATE PROCEDURE sp_RegistrarCalificacionCita
	@id_cita INT,
	@puntaje INT,
	@comentario VARCHAR(500)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @promedio DECIMAL(5,2);
	DECLARE @id_realizada INT = (SELECT id_estado_cita FROM ESTADO_CITA WHERE nombre = 'Realizada');
	BEGIN TRY
		BEGIN TRANSACTION
			IF NOT EXISTS(SELECT 1 FROM CITA WHERE id_cita = @id_cita AND id_estado_cita = @id_realizada) 
			BEGIN
				PRINT 'La cita no existe o no se ha marcado como realizada.';
				ROLLBACK TRANSACTION;
				RETURN;
			END
			IF EXISTS(SELECT 1 FROM CALIFICACION WHERE id_cita = @id_cita) 
			BEGIN
				PRINT 'La cita ya tiene calificaci�n registrada.';
				ROLLBACK TRANSACTION;
				RETURN;
			END
			INSERT INTO CALIFICACION (puntaje, comentario, fecha, id_cita)
			VALUES (@puntaje, @comentario, GETDATE(), @id_cita);
			SELECT @promedio = AVG(CAST(puntaje AS DECIMAL(5,2))) FROM CALIFICACION;
			PRINT 'Calificaci�n Registrada Correctamente.';
			PRINT 'Promedio Actual de Todas las Calificaciones: ' + CAST(@promedio AS VARCHAR);
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		PRINT 'Error al registrar la calificaci�n: ' + ERROR_MESSAGE();
	END CATCH
END;
GO

-----------------------------------------------------------------------------------------------------------------------
--Optimizacion SP #4 (Visualizar o Listar PQRS registradas por los usuarios)
CREATE PROCEDURE sp_ListarPQRSUsuarios
AS
BEGIN
	SET NOCOUNT ON; 
	SELECT 
		CONCAT('Usuario: ', U.nombre1, ' ', ISNULL(U.apellido1, ''),
		       ' | Tipo: ', T.nombre, 
		       ' | Estado: ', E.nombre) AS ReportePQRS
	FROM PQRS P 
	INNER JOIN USUARIO U ON P.documento = U.documento
	INNER JOIN TIPO_PQRS T ON P.id_tipo_pqrs = T.id_tipo_pqrs
	INNER JOIN ESTADO_PQRS E ON P.id_estado_pqrs = E.id_estado_pqrs;
END;
GO

-----------------------------------------------------------------------------------------------------------------------
--Optimizacion SP #5 (Registrar PQRS)
ALTER PROCEDURE sp_RegistrarPQRS
	@documento VARCHAR(20),
	@tipo_nombre VARCHAR(50),
	@descripcion VARCHAR(1000)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @id_tipo INT;
	DECLARE @id_abierto INT = (SELECT id_estado_pqrs FROM ESTADO_PQRS WHERE nombre = 'Abierto'); 
	BEGIN TRY
		BEGIN TRANSACTION
			SELECT @id_tipo = T.id_tipo_pqrs FROM TIPO_PQRS T WHERE nombre = @tipo_nombre;
			IF @id_tipo IS NULL
			BEGIN
				PRINT 'El tipo de PQRS "' + @tipo_nombre + '" no existe.';
				ROLLBACK TRANSACTION;
				RETURN;
			END
			IF NOT EXISTS(SELECT 1 FROM USUARIO WHERE documento = @documento) 
			BEGIN
				PRINT 'El usuario con documento ' + @documento + ' no est� registrado';
				ROLLBACK TRANSACTION;
				RETURN;
			END
			INSERT INTO PQRS (id_tipo_pqrs, descripcion, documento, fecha, id_estado_pqrs)
			VALUES (@id_tipo, @descripcion, @documento, GETDATE(), @id_abierto);
			PRINT 'PQRS registrada exitosamente bajo el estado: Abierto.';
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		PRINT 'Error al registrar PQRS: ' + ERROR_MESSAGE();
	END CATCH
END;
GO

-----------------------------------------------------------------------------------------------------
--Optimizacion SP #6 (Agendar cita)
CREATE PROCEDURE sp_AgendarCita
    @fecha DATE,
    @id_bloque INT,
    @id_estado_cita INT,
    @documento VARCHAR(20),
    @id_sede INT,
    @id_disenador INT
AS
BEGIN

    SET NOCOUNT ON;
    -- VALIDAR CONFLICTOS DEL CLIENTE
    IF EXISTS (
        SELECT 1
        FROM CITA
        WHERE fecha = @fecha
        AND id_bloque = @id_bloque
        AND documento = @documento
    )
    BEGIN
        RAISERROR(
            'El usuario ya tiene una cita en este horario.',
            16,
            1
        );
        RETURN;
    END
    -- VALIDAR DISPONIBILIDAD DEL DISEÑADOR
    IF EXISTS (
        SELECT 1
        FROM CITA
        WHERE fecha = @fecha
        AND id_bloque = @id_bloque
        AND id_disenador = @id_disenador
    )
    BEGIN
        RAISERROR(
            'El diseñador ya está ocupado.',
            16,
            1
        );
        RETURN;
    END
    INSERT INTO CITA(
        fecha,
        id_bloque,
        id_estado_cita,
        documento,
        id_sede,
        id_disenador
    )
    VALUES(
        @fecha,
        @id_bloque,
        @id_estado_cita,
        @documento,
        @id_sede,
        @id_disenador
    );
END;
GO

-----------------------------------------------------------------------------------------------------
--Optimizacion SP #7 (Reagendar cita)

CREATE PROCEDURE sp_ReagendarCita
    @id_cita INT,
    @nueva_fecha DATE,
    @nuevo_id_bloque INT
AS
BEGIN

    SET NOCOUNT ON;

    -- Validar existencia rápida
    IF NOT EXISTS (
        SELECT 1
        FROM CITA
        WHERE id_cita = @id_cita
    )
    BEGIN
        RAISERROR('La cita no existe.',16,1);
        RETURN;
    END

    -- Actualización directa
    UPDATE CITA
    SET fecha = @nueva_fecha,
        id_bloque = @nuevo_id_bloque
    WHERE id_cita = @id_cita;

END;
GO

-----------------------------------------------------------------------------------------------------
--Optimizacion SP #8 (Actualizar Datos de Contacto)


CREATE PROCEDURE sp_ActualizarContactoUsuario
    @documento VARCHAR(20),
    @nuevo_telefono VARCHAR(20),
    @nuevo_correo VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE USUARIO
    SET telefono = @nuevo_telefono,
        correo = @nuevo_correo
    WHERE documento = @documento;

    IF @@ROWCOUNT = 0
    BEGIN
    THROW 50004, 'Usuario no encontrado.',1;
END

PRINT 'Contacto actualizado.';
END;
GO

-----------------------------------------------------------------------------------------------------
--Optimizacion SP #9 (Reporte Citas Por Sede )

CREATE PROCEDURE sp_ReporteCitasSedes
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        S.nombre AS sede,
        COUNT(C.id_cita) AS total_citas
    FROM SEDE S
        LEFT JOIN CITA C
        ON S.id_sede = C.id_sede
    GROUP BY S.nombre
    ORDER BY total_citas DESC;
END;
GO
