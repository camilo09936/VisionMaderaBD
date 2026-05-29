--PROCEDIMIENTO #1 (Registrar Pago de Cita):
--EJEMPLO DE USO-- Debe existir una cita, la cita debe estar asociada a un usuario. Se calcula el iva (19%), Calcula el valor total, Registra el pago en la tabla PAGO
--Cambia estado de cita a confirmada: Muestra pago registrado, Cita confirmada, Mensaje con el total pagado.
CREATE PROCEDURE sp_RegistrarPagoCita
	@id_cita INT,
	@monto_base DECIMAL (10,2),
	@id_metodo_pago INT
AS
BEGIN
	DECLARE @monto_total DECIMAL (10,2);
	DECLARE @iva DECIMAL (10,2);
	DECLARE @id_estado_confirmada INT = (SELECT id_estado_cita FROM ESTADO_CITA WHERE nombre = 'Confirmada');
	DECLARE @id_pago_aprobado INT = (SELECT id_estado_pago FROM ESTADO_PAGO WHERE nombre = 'Aprobado');
	BEGIN TRY
		BEGIN TRANSACTION
			SET @iva = @monto_base * 0.19;
			SET @monto_total = @monto_base + @iva;
			IF NOT EXISTS (SELECT 1 FROM CITA WHERE id_cita = @id_cita)  
			BEGIN  
				PRINT 'La cita no existe.';
				ROLLBACK TRANSACTION;
				RETURN;
			END
			IF EXISTS (SELECT 1 FROM PAGO WHERE id_cita = @id_cita)
			BEGIN
				PRINT 'Esta cita ya cuenta con pago registrado.'
				ROLLBACK TRANSACTION;
				RETURN;
			END
			INSERT INTO PAGO (monto, id_metodo_pago, id_estado_pago, fecha_pago, id_cita) 
			VALUES (@monto_total, @id_metodo_pago, @id_pago_aprobado, GETDATE(), @id_cita);
			UPDATE CITA SET id_estado_cita = @id_estado_confirmada WHERE id_cita = @id_cita; 
			PRINT 'Pago registrado por un total de: $' + CAST(@monto_total AS VARCHAR);
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		PRINT 'Error: ' + ERROR_MESSAGE();
	END CATCH
END;
GO

--PROCEDIMIENTO #2 (Calcular Comision Diseñadores segun citas realizadas)
--EJEMPLO DE USO--Deben existir diseñadores, no importa si tuvieron citas o no. Recorre todos los diseñadores con un cursor cuenta cuantas citas tienen con estado realizada
--Calcula comision de $5.000 por cada cita y muestra resultado en consola.
CREATE PROCEDURE sp_CalcularComisionDisenadores 
AS
BEGIN
	DECLARE @nombre VARCHAR(100);
	DECLARE @apellido VARCHAR(100);
	DECLARE @cantidad_citas INT;
	DECLARE @comision_total DECIMAL(18,2);

	DECLARE @id_realizada INT = (SELECT id_estado_cita FROM ESTADO_CITA WHERE nombre = 'Realizada');

	DECLARE CursorComision CURSOR FOR
	SELECT D.nombre, D.apellido, COUNT(C.id_cita) AS CitasRealizadas
	FROM DISENADOR D 
	LEFT JOIN CITA C ON D.id_disenador = C.id_disenador 
		AND C.id_estado_cita = @id_realizada 
	GROUP BY D.nombre, D.apellido;
	OPEN CursorComision;
	FETCH NEXT FROM CursorComision 
	INTO @nombre, @apellido, @cantidad_citas;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @comision_total = @cantidad_citas * 5000; 
		PRINT 'Diseñador: ' + ISNULL(@nombre, '') + ' ' + ISNULL(@apellido, '') + 
			  ' --> Citas Realizadas: ' + CAST(@cantidad_citas AS VARCHAR) + 
			  ' --> Comisión Total: $' + CAST(@comision_total AS VARCHAR);
		FETCH NEXT FROM CursorComision INTO @nombre, @apellido, @cantidad_citas;
	END
	CLOSE CursorComision;
	DEALLOCATE CursorComision;
END;
GO

--PROCEDIMIENTO #3 (Registrar Calificacion de Una Cita): Se usa cuando un usuario califica una cita despues de haber sido realizada.
--EJEMPLO DE USO--La cita debe existir, debe estar en estado realizada, no debe tener calificacion previa. Valida las condiciones, inserta calificacion, calcula el promedio. Muestra "calificacion registrada" 
--Muestra el promedio general por consola.
CREATE PROCEDURE sp_RegistrarCalificacionCita
	@id_cita INT,
	@puntaje INT,
	@comentario VARCHAR(500)
AS
BEGIN
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
			PRINT 'Calificación Registrada Correctamente.'
			PRINT 'Promedio Actual de Todas las Calificaciones: ' + CAST(@promedio AS VARCHAR);
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		PRINT 'Error al registrar la calificación: ' + ERROR_MESSAGE();
	END CATCH
END;
GO

--PROCEDIMIENTO #4 (Visualizar o Listar PQRS registradas por los usuarios)
--EJEMPLO DE USO--Deben existir registros de PQRS. Recorre cada PQRS con el cursor, lo une con el usuario y muestra Nombre, Tipo y Estado.
CREATE PROCEDURE sp_ListarPQRSUsuarios
AS
BEGIN
	DECLARE @nombre_u VARCHAR(100);
	DECLARE @apellido_u VARCHAR(100);
	DECLARE @tipo VARCHAR(50);
	DECLARE @estado VARCHAR(50);
	DECLARE CursorPQRS CURSOR FOR
	SELECT U.nombre1, U.apellido1, T.nombre, E.nombre
	FROM PQRS P 
	JOIN USUARIO U ON P.documento = U.documento
	JOIN TIPO_PQRS T ON P.id_tipo_pqrs = T.id_tipo_pqrs
	JOIN ESTADO_PQRS E ON P.id_estado_pqrs = E.id_estado_pqrs;
	OPEN CursorPQRS;
	FETCH NEXT FROM CursorPQRS INTO @nombre_u, @apellido_u, @tipo, @estado;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		PRINT 'Usuario: ' + @nombre_u + ' ' + @apellido_u +
			  ' | Tipo: ' + @tipo +
			  ' | Estado: ' + @estado;
		FETCH NEXT FROM CursorPQRS INTO @nombre_u, @apellido_u, @tipo, @estado;
	END
	CLOSE CursorPQRS;
	DEALLOCATE CursorPQRS;
END;
GO

--PROCEDIMIENTO #5 (Registrar PQRS)
--EJEMPLO DE USO-- El usuario debe existir y el tipo de PQRS debe ser valido. Al final registra la PQRS con el estado abierto.
CREATE PROCEDURE sp_RegistrarPQRS
	@documento VARCHAR(20),
	@tipo_nombre VARCHAR(50),
	@descripcion VARCHAR(1000)
AS
BEGIN
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
			PRINT 'PQRS registrada exitosamente bajo el estado: Abierto.'
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		PRINT 'Error al registrar PQRS: ' + ERROR_MESSAGE();
	END CATCH
END;
GO

--PROCEDIMIENTO #6 (Reagendar Cita): Cambiar fecha y hora de una cita (aún no realizada)
--EJEMPLO DE USO-- La cita debe existir y no debe estar en estado 'Realizada o Cancelada'. Por ultimo actualiza los campos hora y fecha.
CREATE PROCEDURE sp_ReagendarCita
	@id_cita INT,
	@nueva_fecha DATE,
	@nuevo_id_bloque INT 
AS
BEGIN
	DECLARE @id_estado_actual INT;
	DECLARE @id_realizada INT = (SELECT id_estado_cita FROM ESTADO_CITA WHERE nombre = 'Realizada');
	DECLARE @id_cancelada INT = (SELECT id_estado_cita FROM ESTADO_CITA WHERE nombre = 'Cancelada');
	BEGIN TRY
		BEGIN TRANSACTION
			SELECT @id_estado_actual = C.id_estado_cita FROM CITA C WHERE id_cita = @id_cita; 
			IF @id_estado_actual IS NULL
			BEGIN
				PRINT 'La cita con ID ' + CAST(@id_cita AS VARCHAR) + ' no existe.';
				ROLLBACK TRANSACTION;
				RETURN;
			END
			IF @id_estado_actual = @id_realizada OR @id_estado_actual = @id_cancelada 
			BEGIN
				PRINT 'No se puede reagendar la cita ya que fue realizada o cancelada.';
				ROLLBACK TRANSACTION;
				RETURN;
			END
			IF NOT EXISTS (SELECT 1 FROM BLOQUE_HORARIO WHERE id_bloque = @nuevo_id_bloque)
			BEGIN
				PRINT 'El bloque de horario especificado no existe.';
				ROLLBACK TRANSACTION;
				RETURN;
			END
			UPDATE CITA
			SET fecha = @nueva_fecha,
				id_bloque = @nuevo_id_bloque -- Modificado para encajar con el nuevo esquema relacional
			WHERE id_cita = @id_cita;
			PRINT 'Cita ' + CAST(@id_cita AS VARCHAR) + ' reagendada exitosamente para el ' + CAST(@nueva_fecha AS VARCHAR) + ' en el bloque ' + CAST(@nuevo_id_bloque AS VARCHAR) + '.';
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		PRINT 'Error al intentar reagendar: ' + ERROR_MESSAGE();
	END CATCH
END;
GO

--PROCEDIMIENTO #7 (Reporte Citas Por Sede)--
--EJEMPLO DE USO-- Recorre todas las sedes mediante un cursor, cuenta sus citas asociadas
--por cada sede incluso si no tiene y muestra el total en consola.
CREATE PROCEDURE sp_ReporteCitasSedes
AS
BEGIN
	DECLARE @sede_nombre VARCHAR(100);
	DECLARE @total_citas INT;
	DECLARE CursorSedes CURSOR FOR 
	SELECT S.nombre, COUNT(C.id_cita)
	FROM SEDE S
	LEFT JOIN CITA C ON S.id_sede = C.id_sede
	GROUP BY S.nombre;
	OPEN CursorSedes;
	FETCH NEXT FROM CursorSedes INTO @sede_nombre, @total_citas;
	PRINT '---Reporte de Citas Por Sede---';
	WHILE @@FETCH_STATUS = 0
	BEGIN
		PRINT 'Sede: ' + @sede_nombre + ' | Total de Citas Registradas: ' + CAST(@total_citas AS VARCHAR);
		FETCH NEXT FROM CursorSedes INTO @sede_nombre, @total_citas;
	END
	CLOSE CursorSedes;
	DEALLOCATE CursorSedes;
END;
GO

--PROCEDIMIENTO #8 (Actualizar Datos de Contacto)--
--EJEMPLO DE USO--El usuario debe existir, valida que exista y actualiza.
CREATE PROCEDURE sp_ActualizarContactoUsuario
	@documento VARCHAR(20),
	@nuevo_telefono VARCHAR(20),
	@nuevo_correo VARCHAR(100)
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			IF NOT EXISTS (SELECT 1 FROM USUARIO WHERE documento = @documento) 
			BEGIN
				PRINT 'El usuario con Documento ' + @documento + ' no existe.';
				ROLLBACK TRANSACTION;
				RETURN;
			END
			UPDATE USUARIO 
			SET telefono = @nuevo_telefono,
				correo = @nuevo_correo
			WHERE documento = @documento;
			PRINT 'Datos de contacto actualizados para el usuario con documento: ' + @documento + '.';
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		PRINT 'Error en la actualización: ' + ERROR_MESSAGE();
	END CATCH
END;
GO

--PROCEDIMIENTO #9 (Agendar Cita)--
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
    -- 1. VALIDACIÓN: El cliente ya tiene una cita en ese mismo bloque y fecha?
    IF EXISTS (SELECT 1 FROM CITA WHERE fecha = @fecha AND id_bloque = @id_bloque AND documento = @documento)
    BEGIN
        RAISERROR ('Error: Ya tienes otra cita agendada en este mismo día y bloque horario.', 16, 1);
        RETURN;
    END
    -- 2. VALIDACIÓN CRÍTICA: El diseñador ya está ocupado en ese bloque y fecha?
    IF EXISTS (SELECT 1 FROM CITA WHERE fecha = @fecha AND id_bloque = @id_bloque AND id_disenador = @id_disenador)
    BEGIN
        -- El estado de severidad 16 fuerza a Node.js / Sequelize a capturarlo en el catch
        RAISERROR ('Error: El diseñador seleccionado ya se encuentra asignado a otra cita en este bloque horario.', 16, 1);
        RETURN;
    END
    -- 3. INSERCIÓN: Si pasa las validaciones anteriores, se registra la cita con éxito
    BEGIN TRY
        INSERT INTO CITA (fecha, id_bloque, id_estado_cita, documento, id_sede, id_disenador)
        VALUES (@fecha, @id_bloque, @id_estado_cita, @documento, @id_sede, @id_disenador);
        PRINT 'Cita agendada exitosamente en el sistema.';
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO