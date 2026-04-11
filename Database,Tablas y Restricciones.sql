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
	estado VARCHAR (20) NOT NULL DEFAULT 'pendiente',
		CHECK ( estado IN ('realizada','pendiente', 'confirmada', 'cancelada')),
	id_usuario INT NOT NULL,
	id_sede INT NOT NULL,
	id_disenador INT NOT NULL,
	CONSTRAINT FK_cita_usuario FOREIGN KEY (id_usuario) REFERENCES USUARIO(id_usuario),
	CONSTRAINT FK_cita_sede FOREIGN KEY (id_sede) REFERENCES SEDE(id_sede),
	CONSTRAINT FK_cita_disenador FOREIGN KEY (id_disenador) REFERENCES DISENADOR(id_disenador)
);

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