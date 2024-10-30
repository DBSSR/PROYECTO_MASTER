USE BASE_PROYECTO
GO

CREATE PROCEDURE SP_CALCULACUPOS
(
@Start INT,
@Max INT
)
AS
BEGIN
	IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'MATRIZ_PAGOS') AND type = N'U')
		DROP TABLE MATRIZ_PAGOS;

	create table MATRIZ_PAGOS
	(
		Id INT IDENTITY,
		Cupo decimal(16,2),
		Plazo24 int,
		Resultado24 decimal(16,2),
		Plazo36 int,
		Resultado36 decimal(16,2)
	)

	declare @tasa float
	--DECLARE @Start INT = 5000;
	--DECLARE @Max INT = 1000;

	select @tasa = valorfloat/ 100 from parametros
	select @tasa = @tasa/12;

	WHILE @Max <= @Start 
	BEGIN
		-- Realiza la acción que necesites aquí
		insert into MATRIZ_PAGOS
		values(@Start, 24, dbo.PagoMensualCredito(@tasa, 24, @Start), 36, dbo.PagoMensualCredito(@tasa, 36, @Start))
		SET @Start = @Start - 1000;
	END;

	insert into MATRIZ_PAGOS
	values(500, 24, dbo.PagoMensualCredito(@tasa, 24, 500), 36, dbo.PagoMensualCredito(@tasa, 36, 500))
	insert into MATRIZ_PAGOS
	values(300, 24, dbo.PagoMensualCredito(@tasa, 24, 300), 36, dbo.PagoMensualCredito(@tasa, 36, 300))

	DECLARE @INI INT = 1;
	DECLARE @SIG INT = 2;
	DECLARE @TOTAL INT = 0;
	DECLARE @CUPOMAYOR FLOAT
	DECLARE @CUPOMENOR FLOAT

	SELECT @TOTAL = COUNT(1)  FROM MATRIZ_PAGOS

	WHILE @SIG <= @TOTAL 
	BEGIN
		-- Realiza la acción que necesites aquí
		SELECT @CUPOMAYOR = Resultado24  
		FROM MATRIZ_PAGOS
		WHERE Id = @INI

		SELECT @CUPOMENOR = Resultado24  
		FROM MATRIZ_PAGOS
		WHERE Id = @SIG

		IF(@INI = 1 )
		BEGIN
			UPDATE R
			SET R.CUPOASIGNADO = (SELECT CUPO  
									FROM MATRIZ_PAGOS
									WHERE Id = @INI)
			FROM RESTCALIFICACION R
			WHERE R.CAPACIDADMENSUAL >= @CUPOMAYOR 
		END
	
		UPDATE R
		SET R.CUPOASIGNADO = (SELECT CUPO  
								FROM MATRIZ_PAGOS
								WHERE Id = @SIG)
		FROM RESTCALIFICACION R
		WHERE R.CAPACIDADMENSUAL >= @CUPOMENOR
		AND R.CAPACIDADMENSUAL <= @CUPOMAYOR

		IF(@SIG = @TOTAL )
		BEGIN
			UPDATE R
			SET R.CUPOASIGNADO = 0
			FROM RESTCALIFICACION R
			WHERE R.CAPACIDADMENSUAL < @CUPOMENOR 
		END

		SET @INI = @SIG;
		SET @SIG = @SIG + 1;
	END;

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'BASE_APLICA') AND type = N'U')
		DROP TABLE BASE_APLICA;

	SELECT * 
	INTO BASE_APLICA 
	FROM RESTCALIFICACION
	WHERE APLICACALIF = 1
	AND APLICASCORE = 1
	AND APLICACAPPAGO = 1
	AND APLICACARTCAST = 1
	AND APLICADEMJUD = 1
	AND APLICAEDAD = 1
	AND APLICANUMTJS = 1
	AND APLICATJ = 1

SELECT * FROM  BASE_APLICA 
END
