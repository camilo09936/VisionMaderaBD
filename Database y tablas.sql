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
	documento VARCHAR (20) PRIMARY KEY NOT NULL,
	nombre1 VARCHAR(100) NOT NULL,
	nombre2 VARCHAR(100),
	apellido1 VARCHAR(100) NOT NULL,
	apellido2 VARCHAR(100),
	correo VARCHAR(100) NOT NULL UNIQUE,
	contrasena VARCHAR(255) NOT NULL,
	direccion VARCHAR(255) NOT NULL,
	telefono VARCHAR(20) NOT NULL,
	fecha_nacimiento DATE NOT NULL,
	);

CREATE TABLE SEDE (
	id_sede INT PRIMARY KEY IDENTITY(1,1),
	nombre VARCHAR(100) NOT NULL,
	direccion VARCHAR(200) NOT NULL,
	telefono VARCHAR(100) NOT NULL,
	);
INSERT INTO SEDE(nombre, direccion, telefono) VALUES
('Sede Norte', 'Calle 10 #20-30', '6041111111'),
('Sede Sur', 'Carrera 15 #40-20', '6042222222'),
('Sede Centro', 'Avenida 30 #12-10', '6043333333'),
('Sede Bello', 'Calle 45 #22-18', '6044444444'),
('Sede Itagui', 'Carrera 50 #33-12', '6045555555');

CREATE TABLE DISENADOR (
	id_disenador INT PRIMARY KEY IDENTITY(1,1),
	nombre VARCHAR(100) NOT NULL,
	apellido VARCHAR(100) NOT NULL,
	correo VARCHAR(100) NOT NULL UNIQUE,
	id_sede INT NOT NULL,
	CONSTRAINT FK_disenador_sede FOREIGN KEY (id_sede) REFERENCES SEDE(id_sede),
);
INSERT INTO DISENADOR(nombre, apellido, correo, id_sede) VALUES
('Daniel', 'Ruiz', 'daniel@gmail.com', 1),
('David', 'Gómez', 'David@gmail.com', 1),
('Laura', 'Mora', 'laura@gmail.com', 2),
('Dayana', 'Correa', 'Dayana@gmail.com', 2),
('Felipe', 'Castro', 'felipe@gmail.com', 3),
('Valentina', 'Gil', 'vale@gmail.com', 4),
('Sebastian', 'Rios', 'sebastian@gmail.com', 5);

CREATE TABLE BLOQUE_HORARIO(
    id_bloque INT PRIMARY KEY IDENTITY(1,1),
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL
);
INSERT INTO BLOQUE_HORARIO(hora_inicio, hora_fin) VALUES
('08:00', '10:00'),
('10:00', '12:00'),
('12:00', '14:00'),
('14:00', '16:00'),
('16:00', '18:00'),
('18:00', '20:00');

CREATE TABLE AGENDA_DISENADOR(
    id_agenda INT PRIMARY KEY IDENTITY(1,1),
    id_disenador INT NOT NULL,
    dia_semana VARCHAR(20) NOT NULL,
    id_bloque INT NOT NULL,
    CONSTRAINT FK_agenda_disenador FOREIGN KEY(id_disenador) REFERENCES DISENADOR(id_disenador),
    CONSTRAINT FK_agenda_bloque FOREIGN KEY(id_bloque) REFERENCES BLOQUE_HORARIO(id_bloque)
);
INSERT INTO AGENDA_DISENADOR(id_disenador, dia_semana, id_bloque) VALUES
(1, 'Monday', 1), (1, 'Monday', 2), (1, 'Monday', 3), (1, 'Monday', 4), (1, 'Monday', 5), 
(1, 'Tuesday', 1),(1, 'Tuesday', 2),(1, 'Tuesday', 3),(1, 'Tuesday', 4),(1, 'Tuesday', 5), 
(1, 'Wednesday', 1),(1, 'Wednesday', 2),(1, 'Wednesday', 3),(1, 'Wednesday', 4),(1, 'Wednesday', 5),
(1, 'Thursday', 1),(1, 'Thursday', 2),(1, 'Thursday', 3),(1, 'Thursday', 4),(1, 'Thursday', 5),
(1, 'Friday', 1),(1, 'Friday', 2),(1, 'Friday', 3),(1, 'Friday', 4),(1, 'Friday', 5),
(1, 'Saturday', 1),(1, 'Saturday', 2),(1, 'Saturday', 3),
(2, 'Monday', 2),(2, 'Monday', 3),(2, 'Monday', 4),(2, 'Monday', 5),(2, 'Monday', 6),
(2, 'Tuesday', 2),(2, 'Tuesday', 3),(2, 'Tuesday', 4),(2, 'Tuesday', 5),(2, 'Tuesday', 6),
(2, 'Wednesday', 2),(2, 'Wednesday', 3),(2, 'Wednesday', 4),(2, 'Wednesday', 5),(2, 'Wednesday', 6),
(2, 'Thursday', 2),(2, 'Thursday', 3),(2, 'Thursday', 4),(2, 'Thursday', 5),(2, 'Thursday', 6),
(2, 'Friday', 2),(2, 'Friday', 3),(2, 'Friday', 4),(2, 'Friday', 5),(2, 'Friday', 6),
(2, 'Saturday', 2),(2, 'Saturday', 3),
(3, 'Monday', 2),(3, 'Monday', 3),(3, 'Monday', 4),(3, 'Monday', 5),(3, 'Monday', 6),
(3, 'Tuesday', 2),(3, 'Tuesday', 3),(3, 'Tuesday', 4),(3, 'Tuesday', 5),(3, 'Tuesday', 6),
(3, 'Wednesday', 2),(3, 'Wednesday', 3),(3, 'Wednesday', 4),(3, 'Wednesday', 5),(3, 'Wednesday', 6),
(3, 'Thursday', 2),(3, 'Thursday', 3),(3, 'Thursday', 4),(3, 'Thursday', 5),(3, 'Thursday', 6),
(3, 'Friday', 2),(3, 'Friday', 3),(3, 'Friday', 4),(3, 'Friday', 5),(3, 'Friday', 6),
(3, 'Saturday', 2),(3, 'Saturday', 3),
(4, 'Monday', 3),(4, 'Monday', 4),(4, 'Monday', 5),(4, 'Monday', 6),
(4, 'Tuesday', 3),(4, 'Tuesday', 4),(4, 'Tuesday', 5),(4, 'Tuesday', 6),
(4, 'Wednesday', 3),(4, 'Wednesday', 4),(4, 'Wednesday', 5),(4, 'Wednesday', 6),
(4, 'Thursday', 3),(4, 'Thursday', 4),(4, 'Thursday', 5),(4, 'Thursday', 6),
(4, 'Friday', 3),(4, 'Friday', 4),(4, 'Friday', 5),(4, 'Friday', 6),
(4, 'Saturday', 2),(4, 'Saturday', 3),
(5, 'Monday', 1),(5, 'Monday', 2),(5, 'Monday', 3),(5, 'Monday', 4),(5, 'Monday', 5),(5, 'Monday', 6),
(5, 'Tuesday', 1),(5, 'Tuesday', 2),(5, 'Tuesday', 3),(5, 'Tuesday', 4),(5, 'Tuesday', 5),(5, 'Tuesday', 6),
(5, 'Wednesday', 1),(5, 'Wednesday', 2),(5, 'Wednesday', 3),(5, 'Wednesday', 4),(5, 'Wednesday', 5),(5, 'Wednesday', 6),
(5, 'Thursday', 1),(5, 'Thursday', 2),(5, 'Thursday', 3),(5, 'Thursday', 4),(5, 'Thursday', 5),(5, 'Thursday', 6),
(5, 'Friday', 1),(5, 'Friday', 2),(5, 'Friday', 3),(5, 'Friday', 4),(5, 'Friday', 5),
(5, 'Saturday', 1),(5, 'Saturday', 2),(5, 'Saturday', 3),(5, 'Saturday', 4),
(6, 'Monday', 1),(6, 'Monday', 2),(6, 'Monday', 3),
(6, 'Tuesday', 1),(6, 'Tuesday', 2),(6, 'Tuesday', 3),
(6, 'Wednesday', 1),(6, 'Wednesday', 2),(6, 'Wednesday', 3),
(6, 'Thursday', 1),(6, 'Thursday', 2),(6, 'Thursday', 3),
(6, 'Friday', 1),(6, 'Friday', 2),(6, 'Friday', 3),
(6, 'Saturday', 1),(6, 'Saturday', 2),
(7, 'Monday', 4),(7, 'Monday', 5),(7, 'Monday', 6),
(7, 'Tuesday', 4),(7, 'Tuesday', 5),(7, 'Tuesday', 6),
(7, 'Wednesday', 4),(7, 'Wednesday', 5),(7, 'Wednesday', 6),
(7, 'Thursday', 4),(7, 'Thursday', 5),(7, 'Thursday', 6),
(7, 'Friday', 4),(7, 'Friday', 5),(7, 'Friday', 6),
(7, 'Saturday', 4),(7, 'Saturday', 5);

CREATE TABLE CITA (
    id_cita INT IDENTITY(1,1) PRIMARY KEY,
    fecha DATE NOT NULL,
    id_bloque INT NOT NULL,
    id_estado_cita INT NOT NULL DEFAULT 1,
    documento VARCHAR(20) NOT NULL,
    id_sede INT NOT NULL,
    id_disenador INT NOT NULL,
    CONSTRAINT FK_cita_estado FOREIGN KEY (id_estado_cita) REFERENCES ESTADO_CITA(id_estado_cita),
    CONSTRAINT FK_cita_usuario FOREIGN KEY (documento) REFERENCES USUARIO(documento),
    CONSTRAINT FK_cita_sede FOREIGN KEY (id_sede) REFERENCES SEDE(id_sede),
    CONSTRAINT FK_cita_disenador FOREIGN KEY (id_disenador) REFERENCES DISENADOR(id_disenador),
	CONSTRAINT FK_cita_bloque FOREIGN KEY (id_bloque) REFERENCES BLOQUE_HORARIO(id_bloque)
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
	documento VARCHAR (20) NOT NULL,
	CONSTRAINT FK_pqrs_tipo FOREIGN KEY (id_tipo_pqrs) REFERENCES TIPO_PQRS(id_tipo_pqrs),
	CONSTRAINT FK_pqrs_estado FOREIGN KEY (id_estado_pqrs) REFERENCES ESTADO_PQRS(id_estado_pqrs),
	CONSTRAINT FK_pqrs_usuario FOREIGN KEY (documento) REFERENCES USUARIO(documento)
);

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
    IF EXISTS (
        SELECT 1 FROM CITA 
        WHERE fecha = @fecha 
          AND id_bloque = @id_bloque 
          AND documento = @documento
    )
    BEGIN
        RAISERROR ('Error: Ya tienes otra cita agendada en este mismo día y bloque horario.', 16, 1);
        RETURN;
    END

    -- 2. VALIDACIÓN CRÍTICA: El diseñador ya está ocupado en ese bloque y fecha?
    IF EXISTS (
        SELECT 1 FROM CITA 
        WHERE fecha = @fecha 
          AND id_bloque = @id_bloque 
          AND id_disenador = @id_disenador
    )
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

 --PRUEBAS
EXEC sp_agendar_cita
    @fecha = '2026-05-18',
    @id_bloque = 1,
    @documento = '1001',
    @id_sede = 1,
    @id_disenador = 1;

SELECT * FROM CITA; 
SELECT * FROM USUARIO;