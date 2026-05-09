USE VisionMadera;
GO

-- TRIGGER 1: Cita pagada, cita confirmada 
CREATE TRIGGER trg_ConfirmarCitaTrasPago
ON PAGO
AFTER INSERT
AS
BEGIN
    DECLARE @id_confirmada INT = (
        SELECT id_estado_cita FROM ESTADO_CITA WHERE nombre = 'Confirmada'
    );
    DECLARE @id_aprobado INT = (
        SELECT id_estado_pago FROM ESTADO_PAGO WHERE nombre = 'Aprobado'
    );
    UPDATE CITA
    SET id_estado_cita = @id_confirmada
    FROM CITA c
    JOIN inserted i ON c.id_cita = i.id_cita
    WHERE i.id_estado_pago = @id_aprobado;
END;
GO

-- TRIGGER 2: Bloquea la oportunidad de cancelar una cita que tiene un pago aprobado, sugiere reagendar en su lugar
CREATE TRIGGER trg_SugerirReagendaSiPagada
ON CITA
AFTER UPDATE
AS
BEGIN
    DECLARE @id_cancelada INT = (
        SELECT id_estado_cita FROM ESTADO_CITA WHERE nombre = 'Cancelada'
    );
    DECLARE @id_aprobado INT = (
        SELECT id_estado_pago FROM ESTADO_PAGO WHERE nombre = 'Aprobado'
    );
    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN deleted d ON i.id_cita = d.id_cita
        JOIN PAGO p ON i.id_cita = p.id_cita
        WHERE i.id_estado_cita = @id_cancelada
          AND d.id_estado_cita <> @id_cancelada
          AND p.id_estado_pago = @id_aprobado
    )
    BEGIN
        RAISERROR('Esta cita tiene un pago aprobado. No puede cancelarse. Use sp_ReagendarCita para cambiar fecha y hora.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- TRIGGER 3: Evita eliminar una cita, se debe conservar el historial del usuario
CREATE TRIGGER trg_ProtegerEliminacionCita
ON CITA
AFTER DELETE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM PAGO p JOIN deleted d ON p.id_cita = d.id_cita)
    OR EXISTS (SELECT 1 FROM CALIFICACION c JOIN deleted d ON c.id_cita = d.id_cita)
    BEGIN
        RAISERROR('No se puede eliminar una cita que tiene pago o calificación registrada.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- TRIGGER 4: Permite calificar las citas, siempre y cuando estas no cuenten con una o tengan un estado diferente a "Realizada"
CREATE TRIGGER trg_ValidarCalificacion
ON CALIFICACION
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @id_realizada INT = (
        SELECT id_estado_cita FROM ESTADO_CITA WHERE nombre = 'Realizada'
    );
    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN CITA c ON i.id_cita = c.id_cita
        WHERE c.id_estado_cita <> @id_realizada
    )
    BEGIN
        RAISERROR('Solo se puede calificar una cita que haya sido realizada.', 16, 1);
        RETURN;
    END
    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN CALIFICACION cal ON i.id_cita = cal.id_cita
    )
    BEGIN
        RAISERROR('Esta cita ya tiene una calificación registrada.', 16, 1);
        RETURN;
    END
    INSERT INTO CALIFICACION (puntaje, comentario, fecha, id_cita)
    SELECT puntaje, comentario, ISNULL(fecha, GETDATE()), id_cita
    FROM inserted;
END;
GO

-- TRIGGER 5: No se puede eliminar el usuario
CREATE TRIGGER trg_ProtegerEliminacionUsuario
ON USUARIO
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM CITA c JOIN deleted d ON c.id_usuario = d.id_usuario)
    OR EXISTS (SELECT 1 FROM PQRS p JOIN deleted d ON p.id_usuario = d.id_usuario)
    BEGIN
        RAISERROR('No se puede eliminar un usuario que tiene citas o PQRS registradas.', 16, 1);
        RETURN;
    END
    DELETE FROM USUARIO WHERE id_usuario IN (SELECT id_usuario FROM deleted);
END;
GO

