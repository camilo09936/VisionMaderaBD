--PROCEDIMIENTO #1 (Registrar Pago de Cita): 
CREATE PROCEDURE RegistrarPagoCita
	@id_cita INT,
	@monto_base DECIMAL (10,2),
	@metodo_pago VARCHAR (20)
AS
BEGIN
	DECLARE @monto_total DECIMAL (10,2);
	DECLARE @iva DECIMAL (10,2);
	BEGIN TRY
		BEGIN TRANSACTION
			SET @iva = @monto_base*0.19;
			SET @monto_total= @monto_base + @iva;
			IF NOT EXISTS (SELECT 1 FROM CITA C JOIN USUARIO U ON C.id_usuario= U.id_usuario 
			WHERE id_cita=@id_cita) --Validacion para ver si la cita existe y quien es el usuario
			BEGIN
				PRINT 'La cita o el usuario no existen.';
				ROLLBACK TRANSACTION;
				RETURN;
			END
			INSERT INTO PAGO (monto,metodo_pago,estado_pago,id_cita) --Insertar en la tabla pago
			VALUES (@monto_total, @metodo_pago, 'aprobado', @id_cita);
			UPDATE CITA SET estado= 'confirmada' WHERE id_cita=@id_cita;
			PRINT 'Pago registrado por un total de: ' +CAST(@monto_total AS VARCHAR);
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		PRINT 'Error en la transacción del pago.';
	END CATCH
END

--EJEMPLO DE USO-- Debe existir una cita, la cita debe estar asociada a un usuario. Se calcula el iva (19%), Calcula el valor total, Registra el pago en la tabla PAGO
--Cambia estado de cita a confirmada: Muestra pago registrado, Cita confirmada, Mensaje con el total pagado.
EXEC RegistrarPagoCita 
    @id_cita = 3, 
    @monto_base = 100000, 
    @metodo_pago = 'tarjeta';

--PROCEDIMIENTO #2 (Calcular Comision Diseñadores segun citas realizadas)
CREATE PROCEDURE CalcularComisionDisenadores 
AS
BEGIN
	DECLARE @nombre VARCHAR(100);
	DECLARE @apellido VARCHAR(100);
	DECLARE @cantidad_citas INT;
	DECLARE @comision_total DECIMAL(18,2);

	DECLARE CursorComision CURSOR FOR
	SELECT D.nombre, D.apellido, COUNT(C.id_cita)
	FROM DISENADOR D 
	LEFT JOIN CITA C ON D.id_disenador=C.id_disenador --Muestra todos los diseñadore, incluso si no tienen citas, pero solo calcula comiison si las citas estan realizadas
	WHERE (C.estado= 'realizada' OR C.id_cita IS NULL)
	GROUP BY D.nombre, D.apellido;
	OPEN CursorComision;
	FETCH NEXT FROM CursorComision 
	INTO @nombre, @apellido, @cantidad_citas;
	WHILE @@FETCH_STATUS =0
	BEGIN
		SET @comision_total=@cantidad_citas*50000; --Comision de 50.000 por cada cita realizada
		PRINT 'Diseñador: ' + ISNULL(@nombre, '') + ' ' + ISNULL(@apellido, '') + 
			  ' --> Citas Realizadas: ' +CAST(@cantidad_citas AS VARCHAR) + 
			  ' --> Comisión Total: $' + CAST(@comision_total AS VARCHAR);
		FETCH NEXT FROM CursorComision INTO @nombre, @apellido, @cantidad_citas;
	END
	CLOSE CursorComision;
	DEALLOCATE CursorComision;
END;

--EJEMPLO DE USO--Deben existir diseñadores, no importa si tuvieron citas o no. Recorre todos los diseñadores con un cursor cuenta cuantas citas tienen con estado realizada
--Calcula comision de $50.000 por cada cita y muestra resultado en consola.
EXEC dbo.CalcularComisionDisenadores;

--PROCEDIMIENTO #3 (Registrar Calificacion de Una Cita): Se usa cuando un usuario califica una cita despues de haber sido realizada.
CREATE PROCEDURE RegistrarCalificacionCita
	@id_cita INT,
	@puntaje INT,
	@comentario VARCHAR(500)
AS
BEGIN
	DECLARE @promedio DECIMAL(5,2);
	BEGIN TRY
		BEGIN TRANSACTION
			IF NOT EXISTS(SELECT 1 FROM CITA WHERE id_cita=@id_cita AND estado = 'realizada') --Validar que la cita exista y esté realizada
			BEGIN
				PRINT 'La cita no existe o no se ha realizado.';
				ROLLBACK TRANSACTION;
				RETURN;
			END
			IF EXISTS(SELECT 1 FROM CALIFICACION WHERE id_cita=@id_cita) --Validar que no tenga ya calificación.
			BEGIN
				PRINT 'La cita ya tiene calificación.';
				ROLLBACK TRANSACTION;
				RETURN;
			END
			INSERT INTO CALIFICACION (puntaje, comentario, id_cita)--Insertar calificación
			VALUES (@puntaje, @comentario, @id_cita);
			SELECT @promedio= AVG(Ca.puntaje)--Calcular promedio de calificaciones
			FROM CALIFICACION Ca;
				PRINT 'Calificacion Registrada Correctamente.'
				PRINT 'Promedio Actual de Calificaciones: ' + CAST(@promedio AS VARCHAR);
				COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		PRINT 'Error al registrar la calificación.';
	END CATCH
END

--EJEMPLO DE USO--La cita debe existir, debe estar en estado realizada, no debe tener calificacion previa. Valida las condiciones, inserta calificacion, calcula el promedio. Muestra "calificacion registrada" 
--Muestra el promedio general por consola.
EXEC RegistrarCalificacionCita      
    @id_cita = 4,
    @puntaje = 5,
    @comentario = 'Excelente servicio';

--PROCEDIMIENTO #4 (Visualizar o Listar PQRS registradas por los usuarios)
CREATE PROCEDURE ListarPQRSUsuarios
AS
BEGIN
	DECLARE @nombre VARCHAR(100);
	DECLARE @apellido VARCHAR(100);
	DECLARE @tipo VARCHAR(20);
	DECLARE @estado VARCHAR(20);

	DECLARE CursorPQRS CURSOR FOR
	SELECT U.nombre, U.apellido, P.tipo, P.estado
	FROM PQRS P 
	JOIN USUARIO U ON P.id_usuario=U.id_usuario;
	OPEN CursorPQRS;
	FETCH NEXT FROM CursorPQRS
	INTO @nombre, @apellido, @tipo, @estado;
	WHILE @@FETCH_STATUS=0
	BEGIN
		PRINT 'Usuario: ' + @nombre + ' ' + @apellido +
			  ' | Tipo: ' + @tipo +
			  ' | Estado: ' + @estado;
		FETCH NEXT FROM CursorPQRS
		INTO @nombre, @apellido, @tipo, @estado;
	END
	CLOSE CursorPQRS;
	DEALLOCATE CursorPQRS;
END;

--EJEMPLO DE USO--Deben existir registros de PQRS. Recorre cada PQRS con el cursor, lo une con el usuario y muestra Nombre, Tipo y Estado.
EXEC ListarPQRSUsuarios;