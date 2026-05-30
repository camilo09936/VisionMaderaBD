USE VisionMadera;
GO

-- TRIGGER 1: Cita pagada, cita confirmada

CREATE TRIGGER trg_ConfirmarCitaTrasPago
ON PAGO
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @id_confirmada INT;
    DECLARE @id_aprobado INT;

    SET @id_confirmada = (SELECT id_estado_cita FROM ESTADO_CITA WHERE nombre = 'Confirmada');
    SET @id_aprobado   = (SELECT id_estado_pago FROM ESTADO_PAGO  WHERE nombre = 'Aprobado');

    IF @id_confirmada IS NULL OR @id_aprobado IS NULL
    BEGIN
        RAISERROR('Error de configuracion: no se encontro el estado Confirmada o Aprobado.', 16, 1);
        RETURN;
    END

    UPDATE CITA
    SET id_estado_cita = @id_confirmada
    FROM CITA c
    JOIN inserted i ON c.id_cita = i.id_cita
    WHERE i.id_estado_pago = @id_aprobado;
END;
GO


-- TRIGGER 2: Bloquea cancelar una cita con pago aprobado

CREATE TRIGGER trg_SugerirReagendaSiPagada
ON CITA
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @id_cancelada INT;
    DECLARE @id_aprobado  INT;

    SET @id_cancelada = (SELECT id_estado_cita FROM ESTADO_CITA WHERE nombre = 'Cancelada');
    SET @id_aprobado  = (SELECT id_estado_pago FROM ESTADO_PAGO  WHERE nombre = 'Aprobado');

    IF @id_cancelada IS NULL OR @id_aprobado IS NULL
    BEGIN
        RAISERROR('Error de configuracion: no se encontro el estado Cancelada o Aprobado.', 16, 1);
        RETURN;
    END

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN deleted d ON i.id_cita = d.id_cita
        JOIN PAGO p    ON i.id_cita = p.id_cita
                      AND p.id_estado_pago = @id_aprobado
        WHERE i.id_estado_cita = @id_cancelada
          AND d.id_estado_cita <> @id_cancelada
    )
    BEGIN
        RAISERROR('Esta cita tiene un pago aprobado. No puede cancelarse. Use sp_ReagendarCita para cambiar fecha y hora.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO
