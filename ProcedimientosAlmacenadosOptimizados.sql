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

--Optimizacion SP #2 (Calcular Comision Diseñadores segun citas realizadas)
CREATE PROCEDURE sp_CalcularComisionDisenadores 
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @id_realizada INT = (SELECT id_estado_cita FROM ESTADO_CITA WHERE nombre = 'Realizada'); 
	SELECT 
		CONCAT('Diseñador: ', ISNULL(D.nombre, ''), ' ', ISNULL(D.apellido, ''), 
		       ' --> Citas Realizadas: ', COUNT(C.id_cita), 
		       ' --> Comisión Total: $', CAST(COUNT(C.id_cita) * 5000 AS VARCHAR)) AS ReporteComision
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
				PRINT 'La cita ya tiene calificación registrada.';
				ROLLBACK TRANSACTION;
				RETURN;
			END
			INSERT INTO CALIFICACION (puntaje, comentario, fecha, id_cita)
			VALUES (@puntaje, @comentario, GETDATE(), @id_cita);
			SELECT @promedio = AVG(CAST(puntaje AS DECIMAL(5,2))) FROM CALIFICACION;
			PRINT 'Calificación Registrada Correctamente.';
			PRINT 'Promedio Actual de Todas las Calificaciones: ' + CAST(@promedio AS VARCHAR);
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		PRINT 'Error al registrar la calificación: ' + ERROR_MESSAGE();
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
				PRINT 'El usuario con documento ' + @documento + ' no está registrado';
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