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