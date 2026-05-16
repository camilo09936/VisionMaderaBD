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
('Sede Itagui', 'Carrera 50 #33-12', '6045555555'),
('Sede Envigado', 'Calle 60 #19-11', '6046666666'),
('Sede Laureles', 'Carrera 70 #44-15', '6047777777');

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
('Laura', 'Mora', 'laura@gmail.com', 2),
('Felipe', 'Castro', 'felipe@gmail.com', 3),
('Valentina', 'Gil', 'vale@gmail.com', 4),
('Sebastian', 'Rios', 'sebastian@gmail.com', 5);

CREATE TABLE AGENDA_DISENADOR (
    id_horario INT PRIMARY KEY IDENTITY(1,1),
    id_disenador INT NOT NULL,
    dia_semana VARCHAR(20) NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    CONSTRAINT FK_horario_disenador
    FOREIGN KEY (id_disenador)
    REFERENCES DISENADOR(id_disenador)
);
INSERT INTO AGENDA_DISENADOR(id_disenador, dia_semana, hora_inicio, hora_fin) VALUES
-- DISEÑADOR 1
(1, 'Monday',    '08:00', '17:00'),
(1, 'Tuesday',   '08:00', '17:00'),
(1, 'Wednesday', '08:00', '17:00'),
(1, 'Thursday',  '08:00', '17:00'),
(1, 'Friday',    '08:00', '17:00'),
(1, 'Saturday',  '08:00', '12:00'),

-- DISEÑADOR 2
(2, 'Monday',    '09:00', '18:00'),
(2, 'Tuesday',   '09:00', '18:00'),
(2, 'Wednesday', '09:00', '18:00'),
(2, 'Thursday',  '09:00', '18:00'),
(2, 'Friday',    '09:00', '18:00'),
(2, 'Saturday',  '09:00', '13:00'),

-- DISEÑADOR 3
(3, 'Monday',    '07:00', '16:00'),
(3, 'Tuesday',   '07:00', '16:00'),
(3, 'Wednesday', '07:00', '16:00'),
(3, 'Thursday',  '07:00', '16:00'),
(3, 'Friday',    '07:00', '16:00'),
(3, 'Saturday',  '08:00', '12:00'),

-- DISEÑADOR 4
(4, 'Monday',    '10:00', '19:00'),
(4, 'Tuesday',   '10:00', '19:00'),
(4, 'Wednesday', '10:00', '19:00'),
(4, 'Thursday',  '10:00', '19:00'),
(4, 'Friday',    '10:00', '19:00'),
(4, 'Saturday',  '09:00', '14:00'),

-- DISEÑADOR 5
(5, 'Monday',    '08:30', '17:30'),
(5, 'Tuesday',   '08:30', '17:30'),
(5, 'Wednesday', '08:30', '17:30'),
(5, 'Thursday',  '08:30', '17:30'),
(5, 'Friday',    '08:30', '17:30'),
(5, 'Saturday',  '08:00', '12:00');

CREATE TABLE CITA (
    id_cita INT IDENTITY(1,1) PRIMARY KEY,
	fecha DATE NOT NULL,
	hora TIME NOT NULL,
	id_estado_cita INT NOT NULL DEFAULT 1,
	documento VARCHAR (20) NOT NULL,
	id_sede INT NOT NULL,
	id_disenador INT NOT NULL,
	CONSTRAINT FK_cita_estado FOREIGN KEY (id_estado_cita) REFERENCES ESTADO_CITA(id_estado_cita),
	CONSTRAINT FK_cita_usuario FOREIGN KEY (documento) REFERENCES USUARIO(documento),
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
	documento VARCHAR (20) NOT NULL,
	CONSTRAINT FK_pqrs_tipo FOREIGN KEY (id_tipo_pqrs) REFERENCES TIPO_PQRS(id_tipo_pqrs),
	CONSTRAINT FK_pqrs_estado FOREIGN KEY (id_estado_pqrs) REFERENCES ESTADO_PQRS(id_estado_pqrs),
	CONSTRAINT FK_pqrs_usuario FOREIGN KEY (documento) REFERENCES USUARIO(documento)
);

 CREATE PROCEDURE sp_agendar_cita
 (
     @fecha DATE,
     @hora TIME,
     @documento INT,
     @id_sede INT,
     @id_disenador INT )
  AS
  BEGIN
 
     DECLARE @dia VARCHAR(20);
 
     -- Obtener día de la semana
     SET @dia = DATENAME(WEEKDAY, @fecha);

     -- VALIDAR SI EL DISEÑADOR TRABAJA ESE DÍA Y HORA
 
     IF NOT EXISTS (
         SELECT 1
         FROM AGENDA_DISENADOR
         WHERE id_disenador = @id_disenador
         AND dia_semana = @dia
         AND @hora BETWEEN hora_inicio AND hora_fin
     )
     BEGIN
         PRINT 'El diseñador no trabaja en ese horario';
         RETURN;
     END
 

     -- VALIDAR SI YA TIENE UNA CITA

     IF EXISTS (
         SELECT 1
         FROM CITA
         WHERE fecha = @fecha
         AND hora = @hora
         AND id_disenador = @id_disenador
         AND id_estado_cita <> 4
     )
     BEGIN
         PRINT 'El diseñador ya tiene una cita';
         RETURN;
     END
     -- INSERTAR CITA
 
     INSERT INTO CITA
     (
        fecha,
         hora,
         documento,
         id_sede,
         id_disenador
     )
    VALUES (
         @fecha,
         @hora,
         @documento,
         @id_sede,
         @id_disenador
     );
 
     PRINT 'Cita agendada correctamente';

 END;
 GO
