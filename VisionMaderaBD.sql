CREATE DATABASE VisonMadera;
GO
USE VisonMadera;
GO

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

	SELECT * FROM USUARIO;

CREATE TABLE SEDE (
	id_sede INT PRIMARY KEY IDENTITY(1,1),
	nombre VARCHAR(100) NOT NULL,
	direccion VARCHAR(200) NOT NULL,
	telefono VARCHAR(100) NOT NULL,
	);

	SELECT * FROM SEDE;

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
	estado VARCHAR (20) NOT NULL DEFAULT 'pendiente',
		CHECK ( estado IN ('realizada','pendiente', 'confirmada', 'cancelada')),
	id_usuario INT NOT NULL,
	id_sede INT NOT NULL,
	id_disenador INT NOT NULL,
	CONSTRAINT FK_cita_usuario FOREIGN KEY (id_usuario) REFERENCES USUARIO(id_usuario),
	CONSTRAINT FK_cita_sede FOREIGN KEY (id_sede) REFERENCES SEDE(id_sede),
	CONSTRAINT FK_cita_disenador FOREIGN KEY (id_disenador) REFERENCES DISENADOR(id_disenador)
);

SELECT * FROM CITA;

CREATE TABLE PAGO (
	id_pago INT IDENTITY(1,1) PRIMARY KEY,
	monto DECIMAL(10, 2) NOT NULL,
	metodo_pago VARCHAR(20) NOT NULL
		CHECK (metodo_pago IN ('tarjeta', 'PSE', 'transferencia')),
	estado_pago VARCHAR (20) NOT NULL DEFAULT 'pendiente'
		CHECK (estado_pago IN ('pendiente', 'aprobado', 'fallido')),
	fecha_pago DATETIME DEFAULT GETDATE(),
	id_cita INT NOT NULL UNIQUE,
	CONSTRAINT FK_pago_cita FOREIGN KEY (id_cita) REFERENCES CITA(id_cita)
);

CREATE TABLE CALIFICACION (
	id_calificacion INT IDENTITY(1,1) PRIMARY KEY,
	puntaje INT NOT NULL CHECK (puntaje BETWEEN 1 AND 5),
	comentario VARCHAR(500),
	fecha DATE DEFAULT GETDATE(),
	id_cita INT NOT NULL UNIQUE,
	CONSTRAINT FK_calificacion_cita FOREIGN KEY (id_cita) REFERENCES CITA(id_cita)
);

CREATE TABLE PQRS (
	id_pqrs INT IDENTITY(1,1) PRIMARY KEY,
	tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('peticion', 'queja', 'reclamo', 'sugerencia')),
	descripcion VARCHAR(1000) NOT NULL,
	fecha DATE DEFAULT GETDATE(),
	estado VARCHAR(20) NOT NULL DEFAULT 'abierto' CHECK (estado IN ('abierto', 'en proceso','cerrado')),
	id_usuario INT NOT NULL,
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
		PRINT 'Error en la transaccion del pago.';
	END CATCH
END

--EJEMPLO DE USO-- Debe existir una cita, la cita debe estar asociada a un usuario. Se calcula el iva (19%), Calcula el valor total, Registra el pago en la tabla PAGO
--Cambia estado de cita a confirmada: Muestra pago registrado, Cita confirmada, Mensaje con el total pagado.
EXEC RegistrarPagoCita 
    @id_cita = 3, 
    @monto_base = 100000, 
    @metodo_pago = 'tarjeta';

--PROCEDIMIENTO #2 (Calcular Comision Dise�adores segun citas realizadas)
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
	LEFT JOIN CITA C ON D.id_disenador=C.id_disenador --Muestra todos los dise�adore, incluso si no tienen citas, pero solo calcula comiison si las citas estan realizadas
	WHERE (C.estado= 'realizada' OR C.id_cita IS NULL)
	GROUP BY D.nombre, D.apellido;
	OPEN CursorComision;
	FETCH NEXT FROM CursorComision 
	INTO @nombre, @apellido, @cantidad_citas;
	WHILE @@FETCH_STATUS =0
	BEGIN
		SET @comision_total=@cantidad_citas*50000; --Comision de 50.000 por cada cita realizada
		PRINT 'Dise�ador: ' + ISNULL(@nombre, '') + ' ' + ISNULL(@apellido, '') + 
			  ' --> Citas Realizadas: ' +CAST(@cantidad_citas AS VARCHAR) + 
			  ' --> Comisi�n Total: $' + CAST(@comision_total AS VARCHAR);
		FETCH NEXT FROM CursorComision INTO @nombre, @apellido, @cantidad_citas;
	END
	CLOSE CursorComision;
	DEALLOCATE CursorComision;
END;

--EJEMPLO DE USO--Deben existir dise�adores, no importa si tuvieron citas o no. Recorre todos los dise�adores con un cursor cuenta cuantas citas tienen con estado realizada
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
			IF NOT EXISTS(SELECT 1 FROM CITA WHERE id_cita=@id_cita AND estado = 'realizada') --Validar que la cita exista y est� realizada
			BEGIN
				PRINT 'La cita no existe o no se ha realizado.';
				ROLLBACK TRANSACTION;
				RETURN;
			END
			IF EXISTS(SELECT 1 FROM CALIFICACION WHERE id_cita=@id_cita) --Validar que no tenga ya calificaci�n.
			BEGIN
				PRINT 'La cita ya tiene calificaci�n.';
				ROLLBACK TRANSACTION;
				RETURN;
			END
			INSERT INTO CALIFICACION (puntaje, comentario, id_cita)--Insertar calificaci�n
			VALUES (@puntaje, @comentario, @id_cita);
			SELECT @promedio= AVG(Ca.puntaje)--Calcular promedio de calificaciones
			FROM CALIFICACION Ca;
				PRINT 'Calificacion Registrada Correctamente.'
				PRINT 'Promedio Actual de Calificaciones: ' + CAST(@promedio AS VARCHAR);
				COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		PRINT 'Error al registrar la calificaci�n.';
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