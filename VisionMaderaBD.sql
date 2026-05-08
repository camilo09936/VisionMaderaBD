CREATE DATABASE VisionMadera;
GO
USE VisionMadera;
GO

CREATE TABLE ESTADO_CITA(
	id_estado_cita INT PRIMARY KEY IDENTITY (1,1),
	nombre VARCHAR(50) NOT NULL UNIQUE
);
INSERT INTO ESTADO_CITA (nombre) VALUES
('Pendiente'),('Confirmada'),('Realizada'),('Cancelada');

CREATE TABLE METODO_PAGO(
	id_metodo_pago INT PRIMARY KEY IDENTITY(1,1),
	nombre VARCHAR(50) NOT NULL UNIQUE
);
INSERT INTO METODO_PAGO (nombre) VALUES
('Tarjeta'),('PSE'),('Transferencia');

CREATE TABLE ESTADO_PAGO(
	id_estado_pago INT PRIMARY KEY IDENTITY(1,1),
	nombre VARCHAR(50) NOT NULL UNIQUE
);
INSERT INTO ESTADO_PAGO (nombre) VALUES
('Pendiente'),('Aprobado'),('Fallido');

CREATE TABLE TIPO_PQRS(
	id_tipo_pqrs INT PRIMARY KEY IDENTITY(1,1),
	nombre VARCHAR(50) NOT NULL UNIQUE
);
INSERT INTO TIPO_PQRS (nombre) VALUES
('Peticion'),('Queja'),('Reclamo'),('Sugerencia');

CREATE TABLE ESTADO_PQRS (
	id_estado_pqrs INT PRIMARY KEY IDENTITY(1,1),
	nombre VARCHAR(50) NOT NULL UNIQUE
);
INSERT INTO ESTADO_PQRS (nombre) VALUES
('Abierto'),('En Proceso'),('Cerrado');

CREATE TABLE USUARIO(
	id_usuario INT PRIMARY KEY IDENTITY(1,1),
	nombre VARCHAR(100) NOT NULL,
	apellido VARCHAR(100) NOT NULL,
	correo VARCHAR(100) NOT NULL UNIQUE,
	contrasena VARCHAR(255) NOT NULL,
	telefono VARCHAR(20),
	cedula VARCHAR (20) NOT NULL UNIQUE,
	fecha_nacimiento DATE NOT NULL,
	);

CREATE TABLE SEDE (
	id_sede INT PRIMARY KEY IDENTITY(1,1),
	nombre VARCHAR(100) NOT NULL,
	direccion VARCHAR(200) NOT NULL,
	telefono VARCHAR(100) NOT NULL,
	);

CREATE TABLE DISENADOR (
	id_disenador INT PRIMARY KEY IDENTITY(1,1),
	nombre VARCHAR(100) NOT NULL,
	apellido VARCHAR(100) NOT NULL,
	correo VARCHAR(100) NOT NULL UNIQUE,
	id_sede INT NOT NULL,
	CONSTRAINT FK_disenador_sede FOREIGN KEY (id_sede) REFERENCES SEDE(id_sede),
);

CREATE TABLE CITA (
    id_cita INT IDENTITY(1,1) PRIMARY KEY,
	fecha DATE NOT NULL,
	hora TIME NOT NULL,
	id_estado_cita INT NOT NULL DEFAULT 1,
	id_usuario INT NOT NULL,
	id_sede INT NOT NULL,
	id_disenador INT NOT NULL,
	CONSTRAINT FK_cita_estado FOREIGN KEY (id_estado_cita) REFERENCES ESTADO_CITA(id_estado_cita),
	CONSTRAINT FK_cita_usuario FOREIGN KEY (id_usuario) REFERENCES USUARIO(id_usuario),
	CONSTRAINT FK_cita_sede FOREIGN KEY (id_sede) REFERENCES SEDE(id_sede),
	CONSTRAINT FK_cita_disenador FOREIGN KEY (id_disenador) REFERENCES DISENADOR(id_disenador)
);

CREATE TABLE PAGO (
	id_pago INT IDENTITY(1,1) PRIMARY KEY,
	monto DECIMAL(10, 2) NOT NULL,
	id_metodo_pago INT NOT NULL,
	id_estado_pago INT NOT NULL DEFAULT 1,
	fecha_pago DATETIME DEFAULT GETDATE(),
	id_cita INT NOT NULL UNIQUE,
	CONSTRAINT FK_pago_metodo FOREIGN KEY (id_metodo_pago) REFERENCES METODO_PAGO(id_metodo_pago),
	CONSTRAINT FK_pago_estado FOREIGN KEY (id_estado_pago) REFERENCES ESTADO_PAGO(id_estado_pago),
	CONSTRAINT FK_pago_cita FOREIGN KEY (id_cita) REFERENCES CITA(id_cita)
);

CREATE TABLE CALIFICACION (
	id_calificacion INT IDENTITY(1,1) PRIMARY KEY,
	puntaje INT NOT NULL CHECK (puntaje BETWEEN 1 AND 5),
	comentario VARCHAR(500),
	fecha DATE DEFAULT GETDATE() NOT NULL,
	id_cita INT NOT NULL UNIQUE,
	CONSTRAINT FK_calificacion_cita FOREIGN KEY (id_cita) REFERENCES CITA(id_cita)
);

CREATE TABLE PQRS (
	id_pqrs INT IDENTITY(1,1) PRIMARY KEY,
	id_tipo_pqrs INT NOT NULL,
	descripcion VARCHAR(1000) NOT NULL,
	fecha DATE DEFAULT GETDATE() NOT NULL,
	id_estado_pqrs INT NOT NULL DEFAULT 1,
	id_usuario INT NOT NULL,
	CONSTRAINT FK_pqrs_tipo FOREIGN KEY (id_tipo_pqrs) REFERENCES TIPO_PQRS(id_tipo_pqrs),
	CONSTRAINT FK_pqrs_estado FOREIGN KEY (id_estado_pqrs) REFERENCES ESTADO_PQRS(id_estado_pqrs),
	CONSTRAINT FK_pqrs_usuario FOREIGN KEY (id_usuario) REFERENCES USUARIO(id_usuario)
);

SET IDENTITY_INSERT SEDE ON;
SET IDENTITY_INSERT USUARIO ON;
SET IDENTITY_INSERT DISENADOR ON;
SET IDENTITY_INSERT CITA ON;
SET IDENTITY_INSERT PAGO ON;
SET IDENTITY_INSERT CALIFICACION ON;
SET IDENTITY_INSERT PQRS ON;
GO

-- 1. SEDE
BULK INSERT SEDE 
FROM '/var/opt/mssql/bulkdata/SEDE.csv'
WITH (
  FIRSTROW = 2,
  FIELDTERMINATOR = ';',
  ROWTERMINATOR = '\n'
);
-- 2. USUARIO
BULK INSERT USUARIO 
FROM '/var/opt/mssql/bulkdata/USUARIO.csv'
WITH (
  FIRSTROW = 2,
  FIELDTERMINATOR = ';',
  ROWTERMINATOR = '\n'
);

-- 3. DISENADOR
BULK INSERT DISENADOR 
FROM '/var/opt/mssql/bulkdata/DISENADOR.csv'
WITH (
  FIRSTROW = 2,
  FIELDTERMINATOR = ';',
  ROWTERMINATOR = '\n'
);

-- 4. CITA
BULK INSERT CITA 
FROM '/var/opt/mssql/bulkdata/CITA.csv'
WITH (
  FIRSTROW = 2,
  FIELDTERMINATOR = ';',
  ROWTERMINATOR = '\n'
);

-- 5. PAGO
BULK INSERT PAGO 
FROM '/var/opt/mssql/bulkdata/PAGO.csv'
WITH (
  FIRSTROW = 2,
  FIELDTERMINATOR = ';',
  ROWTERMINATOR = '\n'
);

-- 6. CALIFICACION
BULK INSERT CALIFICACION 
FROM '/var/opt/mssql/bulkdata/CALIFICACION.csv'
WITH (
  FIRSTROW = 2,
  FIELDTERMINATOR = ';',
  ROWTERMINATOR = '\n'
);

-- 7. PQRS
BULK INSERT PQRS 
FROM '/var/opt/mssql/bulkdata/PQRS.csv'
WITH (
  FIRSTROW = 2,
  FIELDTERMINATOR = ';',
  ROWTERMINATOR = '\n'
);

--PROCEDIMIENTO #1 (Registrar Pago de Cita): 
CREATE PROCEDURE sp_RegistrarPagoCita
	@id_cita INT,
	@monto_base DECIMAL (10,2),
	@id_metodo_pago INT
AS
BEGIN
	DECLARE @monto_total DECIMAL (10,2);
	DECLARE @iva DECIMAL (10,2);
	DECLARE @id_estado_confirmada INT= (SELECT id_estado_cita FROM ESTADO_CITA WHERE nombre= 'Confirmada');
	DECLARE @id_pago_aprobado INT= (SELECT id_estado_pago FROM ESTADO_PAGO WHERE nombre= 'Aprobado');
	BEGIN TRY
		BEGIN TRANSACTION
			SET @iva = @monto_base*0.19;
			SET @monto_total= @monto_base + @iva;
			IF NOT EXISTS (SELECT 1 FROM CITA C WHERE id_cita= @id_cita)  --Validacion para ver si la cita existe y quien es el usuario
			BEGIN  
				PRINT 'La cita no existe.';
				ROLLBACK TRANSACTION;
				RETURN;
			END
			IF EXISTS (SELECT 1 FROM PAGO WHERE id_cita=@id_cita)
			BEGIN
				PRINT 'Esta cita ya cuenta con pago registrado.'
				ROLLBACK TRANSACTION;
				RETURN;
			END
			INSERT INTO PAGO (monto,id_metodo_pago,id_estado_pago,id_cita) --Insertar en la tabla pago
			VALUES (@monto_total, @id_metodo_pago, @id_pago_aprobado, @id_cita);
			UPDATE CITA SET id_estado_cita= @id_estado_confirmada WHERE id_cita=@id_cita; --Actualizar cita con id de 'Confirmada'
			PRINT 'Pago registrado por un total de: $' +CAST(@monto_total AS VARCHAR);
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		PRINT 'Error: ' +ERROR_MESSAGE();
	END CATCH
END;
--EJEMPLO DE USO-- Debe existir una cita, la cita debe estar asociada a un usuario. Se calcula el iva (19%), Calcula el valor total, Registra el pago en la tabla PAGO
--Cambia estado de cita a confirmada: Muestra pago registrado, Cita confirmada, Mensaje con el total pagado.

--PROCEDIMIENTO #2 (Calcular Comision Diseñadores segun citas realizadas)
CREATE PROCEDURE sp_CalcularComisionDisenadores 
AS
BEGIN
	DECLARE @nombre VARCHAR(100);
	DECLARE @apellido VARCHAR(100);
	DECLARE @cantidad_citas INT;
	DECLARE @comision_total DECIMAL(18,2);

	DECLARE @id_realizada INT= (SELECT id_estado_cita FROM ESTADO_CITA WHERE nombre= 'Realizada');

	DECLARE CursorComision CURSOR FOR
	SELECT D.nombre, D.apellido, COUNT(C.id_cita) AS CitasRealizadas
	FROM DISENADOR D 
	LEFT JOIN CITA C ON D.id_disenador=C.id_disenador --Muestra todos los diseñadore, incluso si no tienen citas, pero solo calcula comiison si las citas estan realizadas
		AND C.id_estado_cita= @id_realizada --Se filtra para no perder los diseñadores sin citas
	GROUP BY D.nombre, D.apellido;
	OPEN CursorComision;
	FETCH NEXT FROM CursorComision 
	INTO @nombre, @apellido, @cantidad_citas;
	WHILE @@FETCH_STATUS =0
	BEGIN
		SET @comision_total=@cantidad_citas*5000; --Comision de 5.000 por cada cita realizada
		PRINT 'Diseñador: ' + ISNULL(@nombre, '') + ' ' + ISNULL(@apellido, '') + 
			  ' --> Citas Realizadas: ' +CAST(@cantidad_citas AS VARCHAR) + 
			  ' --> Comisión Total: $' + CAST(@comision_total AS VARCHAR);
		FETCH NEXT FROM CursorComision INTO @nombre, @apellido, @cantidad_citas;
	END
	CLOSE CursorComision;
	DEALLOCATE CursorComision;
END;
--EJEMPLO DE USO--Deben existir diseñadores, no importa si tuvieron citas o no. Recorre todos los diseñadores con un cursor cuenta cuantas citas tienen con estado realizada
--Calcula comision de $5.000 por cada cita y muestra resultado en consola.

--PROCEDIMIENTO #3 (Registrar Calificacion de Una Cita): Se usa cuando un usuario califica una cita despues de haber sido realizada.
CREATE PROCEDURE sp_RegistrarCalificacionCita
	@id_cita INT,
	@puntaje INT,
	@comentario VARCHAR(500)
AS
BEGIN
	DECLARE @promedio DECIMAL(5,2);
	DECLARE @id_realizada INT= (SELECT id_estado_cita FROM ESTADO_CITA WHERE nombre= 'Realizada');
	BEGIN TRY
		BEGIN TRANSACTION
			IF NOT EXISTS(SELECT 1 FROM CITA WHERE id_cita=@id_cita AND id_estado_cita = @id_realizada) --Validar que la cita exista y esté realizada
			BEGIN
				PRINT 'La cita no existe o no se ha marcado como realizada.';
				ROLLBACK TRANSACTION;
				RETURN;
			END
			IF EXISTS(SELECT 1 FROM CALIFICACION WHERE id_cita=@id_cita) --Validar que no tenga ya calificación.
			BEGIN
				PRINT 'La cita ya tiene calificación registrada.';
				ROLLBACK TRANSACTION;
				RETURN;
			END
			INSERT INTO CALIFICACION (puntaje, comentario, id_cita)--Insertar calificación
			VALUES (@puntaje, @comentario, @id_cita);
			SELECT @promedio= AVG(CAST(puntaje AS DECIMAL(5,2)))--Calcular promedio de calificaciones
			FROM CALIFICACION;
				PRINT 'Calificacion Registrada Correctamente.'
				PRINT 'Promedio Actual de Todas las Calificaciones: ' + CAST(@promedio AS VARCHAR);
				COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		PRINT 'Error al registrar la calificación: ' +ERROR_MESSAGE();
	END CATCH
END
--EJEMPLO DE USO--La cita debe existir, debe estar en estado realizada, no debe tener calificacion previa. Valida las condiciones, inserta calificacion, calcula el promedio. Muestra "calificacion registrada" 
--Muestra el promedio general por consola.

--PROCEDIMIENTO #4 (Visualizar o Listar PQRS registradas por los usuarios)
CREATE PROCEDURE sp_ListarPQRSUsuarios
AS
BEGIN
	DECLARE @nombre_u VARCHAR(100);
	DECLARE @apellido_u VARCHAR(100);
	DECLARE @tipo VARCHAR(50);
	DECLARE @estado VARCHAR(50);

	DECLARE CursorPQRS CURSOR FOR
	SELECT U.nombre, U.apellido, T.nombre, E.nombre
	FROM PQRS P 
	JOIN USUARIO U ON P.id_usuario=U.id_usuario
	JOIN TIPO_PQRS T ON P.id_tipo_pqrs=T.id_tipo_pqrs
	JOIN ESTADO_PQRS E ON P.id_estado_pqrs=E.id_estado_pqrs;
	OPEN CursorPQRS;
	FETCH NEXT FROM CursorPQRS
	INTO @nombre_u, @apellido_u, @tipo, @estado;
	WHILE @@FETCH_STATUS=0
	BEGIN
		PRINT 'Usuario: ' + @nombre_u + ' ' + @apellido_u +
			  ' | Tipo: ' + @tipo +
			  ' | Estado: ' + @estado;
		FETCH NEXT FROM CursorPQRS
		INTO @nombre_u, @apellido_u, @tipo, @estado;
	END
	CLOSE CursorPQRS;
	DEALLOCATE CursorPQRS;
END;
--EJEMPLO DE USO--Deben existir registros de PQRS. Recorre cada PQRS con el cursor, lo une con el usuario y muestra Nombre, Tipo y Estado.

--PROCEDIMIENTO #5 (Registrar PQRS)
CREATE PROCEDURE sp_RegistrarPQRS
	@id_usuario INT, 
	@tipo_nombre VARCHAR(50),
	@descripcion VARCHAR(1000)
AS
BEGIN
	DECLARE @id_tipo INT;
	DECLARE @id_abierto INT= (SELECT id_estado_pqrs FROM ESTADO_PQRS WHERE nombre= 'Abierto');
	BEGIN TRY
		BEGIN TRANSACTION
			SELECT @id_tipo= T.id_tipo_pqrs
			FROM TIPO_PQRS T WHERE nombre= @tipo_nombre;
			IF @id_tipo IS NULL
			BEGIN
				PRINT 'El tipo de PQRS "' + @tipo_nombre + '" no existe.';
				ROLLBACK TRANSACTION;
				RETURN;
			END
			IF NOT EXISTS(SELECT 1 FROM USUARIO WHERE id_usuario= @id_usuario) --valida si el usuario existe
			BEGIN
				PRINT 'El usuario con ID ' + CAST(@id_usuario AS VARCHAR) + ' no está registrado';
				ROLLBACK TRANSACTION;
				RETURN;
			END
			INSERT INTO PQRS (id_tipo_pqrs, descripcion, id_usuario, fecha, id_estado_pqrs)
			VALUES (@id_tipo, @descripcion, @id_usuario, GETDATE(), @id_abierto);
			PRINT 'PQRS registrada exitosamente bajo el estado: Abierto.'
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		PRINT 'Error al registrar PQRS: ' +ERROR_MESSAGE();
	END CATCH
END;
--EJEMPLO DE USO-- El usuario debe existir y el tipo de PQRS debe ser valido. Al final registra la PQRS con el estado abierto.

--PROCEDIMIENTO #6 (Reagendar Cita): Cambiar fecha y hora de una cita (aún no realizada)
CREATE PROCEDURE sp_ReagendarCita
	@id_cita INT,
	@nueva_fecha DATE,
	@nueva_hora TIME
AS
BEGIN
	DECLARE @id_estado_actual INT;
	DECLARE @id_realizada INT= (SELECT id_estado_cita FROM ESTADO_CITA WHERE nombre= 'Realizada');
	DECLARE @id_cancelada INT= (SELECT id_estado_cita FROM ESTADO_CITA WHERE nombre= 'Cancelada');
	BEGIN TRY
		BEGIN TRANSACTION
			SELECT @id_estado_actual= C.id_estado_cita
			FROM CITA C WHERE id_cita= @id_cita; --Obtener estado actual de cita
			IF @id_estado_actual IS NULL
			BEGIN
				PRINT 'La cita con ID ' + CAST(@id_cita AS VARCHAR) + ' no existe.';
				ROLLBACK TRANSACTION;
				RETURN;
			END
			IF @id_estado_actual= @id_realizada OR @id_estado_actual= @id_cancelada --Verificar que no este realizada o cancelada antes de reagendar.
				BEGIN
					PRINT 'No se puede reagendar la cita ya que fue realizada o cancelada.';
					ROLLBACK TRANSACTION;
					RETURN;
				END
				UPDATE CITA
				SET  fecha= @nueva_fecha,
					hora= @nueva_hora
				WHERE id_cita= @id_cita;
				PRINT 'Cita ' + CAST(@id_cita AS VARCHAR) + ' reagendada exitosamente para el ' + CAST(@nueva_fecha AS VARCHAR) + '.';
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			PRINT 'Error al intentar reagendar ' +ERROR_MESSAGE();
		END CATCH
	END;
--EJEMPLO DE USO-- La cita debe existir y no debe estar en estado 'Realizada o Cancelada'. Por ultimo actualiza los campos hora y fecha.

--PROCEDIMIENTO #7 (Reporte Citas Por Sede)--
CREATE PROCEDURE sp_ReporteCitasSedes
AS
BEGIN
	DECLARE @sede_nombre VARCHAR(100);
	DECLARE @total_citas INT;
	DECLARE CursorSedes CURSOR FOR --El cursor recorre las sedes y hace un COUNT de las citas vinculadas a estas
	SELECT S.nombre, COUNT(C.id_cita)
	FROM SEDE S
	LEFT JOIN CITA C ON S.id_sede= C.id_sede
	GROUP BY S.nombre;
	OPEN CursorSedes;
	FETCH NEXT FROM CursorSedes 
	INTO @sede_nombre, @total_citas;
	PRINT '---Reporte de Citas Por Sede---';
	WHILE @@FETCH_STATUS=0
	BEGIN
		PRINT 'Sede: ' + @sede_nombre + ' | Total de Citas Registradas: ' + CAST(@total_citas AS VARCHAR);
		FETCH NEXT FROM CursorSedes 
		INTO @sede_nombre, @total_citas;
	END
	CLOSE CursorSedes;
	DEALLOCATE CursorSedes;
END;
--EJEMPLO DE USO-- Recorre todas las sedes mediante un cursor, cuenta sus citas asociadas
--por cada sede incluso si no tiene y muestra el total en consola.

--PROCEDIMIENTO #8 (Actualizar Datos de Contacto)--
CREATE PROCEDURE sp_ActualizarContactoUsuario
	@id_usuario INT,
	@nuevo_telefono VARCHAR(20),
	@nuevo_correo VARCHAR(100)
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			IF NOT EXISTS (SELECT 1 FROM USUARIO WHERE id_usuario= @id_usuario) --Validar que el usuario exista antes de actualizar
			BEGIN
				PRINT 'El usuario con ID ' + CAST(@id_usuario AS VARCHAR) + ' no existe.';
				ROLLBACK TRANSACTION;
				RETURN;
			END
			UPDATE USUARIO --Acatualizar campos
			SET telefono= @nuevo_telefono,
				correo= @nuevo_correo
			WHERE id_usuario= @id_usuario;
			PRINT 'Datos de contacto actualizados para el usuario ' + CAST(@id_usuario AS VARCHAR) + '.';
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		PRINT 'Error en la actualizacion: ' +ERROR_MESSAGE();
	END CATCH
END;
--EJEMPLO DE USO--El usuario debe existir, valida que exista y actualiza.