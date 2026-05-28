-- ================================================================
-- QUICKSEND DB - VERSION ADAPTADA PARA ORACLE FREESQL / LIVE SQL
-- ================================================================
-- Esta version fue adaptada automaticamente para funcionar en:
--   freesql.oracle.com / livesql.oracle.com
-- Cambios vs version original:
--   - Seccion 00 eliminada (tablespaces y usuario: no aplica en FreeSQL)
--   - Clausulas TABLESPACE eliminadas de todas las tablas e indices
--   - Seccion 12 (ROLES) comentada (requiere privilegios DBA)
-- INSTRUCCIONES: Pega todo este contenido en el SQL Worksheet y
-- haz clic en "Run Script" (el boton con el triangulo y las rayas).
-- ================================================================


/* ================================================================
   ██████╗ ██╗   ██╗██╗ ██████╗██╗  ██╗███████╗███████╗███╗   ██╗██████╗
   ██╔═══██╗██║   ██║██║██╔════╝██║ ██╔╝██╔════╝██╔════╝████╗  ██║██╔══██╗
   ██║   ██║██║   ██║██║██║     █████╔╝ ███████╗█████╗  ██╔██╗ ██║██║  ██║
   ██║▄▄ ██║██║   ██║██║██║     ██╔═██╗ ╚════██║██╔══╝  ██║╚██╗██║██║  ██║
   ╚██████╔╝╚██████╔╝██║╚██████╗██║  ██╗███████║███████╗██║ ╚████║██████╔╝
    ╚══▀▀═╝  ╚═════╝ ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═══╝╚═════╝
   ================================================================
   BASE DE DATOS EMPRESARIAL - SISTEMA DE GESTION LOGISTICA
   Empresa     : QuickSend - Soluciones Digitales de Paqueteria
   Motor       : Oracle Database 19c / 21c
   Esquema     : QUICKSEND
   Version     : 1.0.0
   Autores     : Sebastián Gil - Valery Liñán
   Compatible  : Oracle SQL Developer / SQL*Plus
   ================================================================

   INDICE DE SECCIONES:
   ─────────────────────────────────────────────────────────────
   SEC 00 - CONFIGURACION INICIAL (Tablespace, Schema)
   SEC 01 - TABLAS MAESTRAS (Catalogos)
   SEC 02 - TABLAS DE NEGOCIO PRINCIPALES
   SEC 03 - TABLAS DE OPERACION LOGISTICA
   SEC 04 - TABLAS FINANCIERAS
   SEC 05 - TABLAS DE COMUNICACION Y AUDITORIA
   SEC 06 - SECUENCIAS
   SEC 07 - INDICES DE RENDIMIENTO
   SEC 08 - TRIGGERS AUTOMATICOS
   SEC 09 - VISTAS DE NEGOCIO
   SEC 10 - PROCEDIMIENTOS ALMACENADOS
   SEC 11 - FUNCIONES
   SEC 12 - ROLES Y SEGURIDAD
   SEC 13 - DATOS DE EJEMPLO (INSERTs)
   SEC 14 - CONSULTAS UTILES
   ─────────────────────────────────────────────────────────────
*/

-- ================================================================
-- SECCION 01: TABLAS MAESTRAS (CATALOGOS)
-- ================================================================
/*
  Las tablas maestras son catalogos con datos relativamente estaticos.
  Son el nucleo de referencia para el resto del sistema.
  Seguimos la Tercera Forma Normal (3FN) para evitar redundancia.
*/

-- ----------------------------------------------------------------
-- 1.1 TABLA: QS_ESTADOS_PAQUETE
-- Catalogo de todos los estados posibles de un paquete
-- ----------------------------------------------------------------
CREATE TABLE QS_ESTADOS_PAQUETE (
    ID_ESTADO       NUMBER(3)       NOT NULL,
    CODIGO_ESTADO   VARCHAR2(20)    NOT NULL,  -- Codigo corto, ej: 'EN_CAMINO'
    NOMBRE_ESTADO   VARCHAR2(60)    NOT NULL,  -- Nombre legible, ej: 'En Camino'
    DESCRIPCION     VARCHAR2(200),
    COLOR_HEX       VARCHAR2(7),               -- Para mostrar en UI, ej: '#FF6B00'
    ES_FINAL        CHAR(1)         DEFAULT 'N' NOT NULL,
    ACTIVO          CHAR(1)         DEFAULT 'S' NOT NULL,
    FECHA_CREACION  TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,

    -- PRIMARY KEY
    CONSTRAINT PK_ESTADOS_PAQUETE PRIMARY KEY (ID_ESTADO),

    -- UNIQUE: no puede haber dos estados con el mismo codigo
    CONSTRAINT UK_ESTADO_CODIGO UNIQUE (CODIGO_ESTADO),

    -- CHECK: solo S o N como valores booleanos
    CONSTRAINT CK_ESTADO_FINAL   CHECK (ES_FINAL IN ('S','N')),
    CONSTRAINT CK_ESTADO_ACTIVO  CHECK (ACTIVO   IN ('S','N')),

    -- CHECK: formato de color hexadecimal valido
    CONSTRAINT CK_ESTADO_COLOR   CHECK (
        COLOR_HEX IS NULL OR REGEXP_LIKE(COLOR_HEX, '^#[0-9A-Fa-f]{6}$')
    )
);

COMMENT ON TABLE  QS_ESTADOS_PAQUETE            IS 'Catalogo de estados del ciclo de vida de un paquete';
COMMENT ON COLUMN QS_ESTADOS_PAQUETE.ES_FINAL   IS 'S = Este estado es terminal (no puede cambiar)';
COMMENT ON COLUMN QS_ESTADOS_PAQUETE.COLOR_HEX  IS 'Color HTML para representacion visual en dashboards';


-- ----------------------------------------------------------------
-- 1.2 TABLA: QS_TIPOS_PAQUETE
-- Catalogo de tipos de paquete (sobre, caja pequena, etc.)
-- ----------------------------------------------------------------
CREATE TABLE QS_TIPOS_PAQUETE (
    ID_TIPO         NUMBER(3)       NOT NULL,
    CODIGO_TIPO     VARCHAR2(20)    NOT NULL,
    NOMBRE_TIPO     VARCHAR2(60)    NOT NULL,
    DESCRIPCION     VARCHAR2(200),
    PESO_MAX_KG     NUMBER(8,3)     NOT NULL,  -- Peso maximo permitido en kg
    LARGO_MAX_CM    NUMBER(6,2),               -- Dimensiones maximas
    ANCHO_MAX_CM    NUMBER(6,2),
    ALTO_MAX_CM     NUMBER(6,2),
    ACTIVO          CHAR(1)         DEFAULT 'S' NOT NULL,
    FECHA_CREACION  TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,

    CONSTRAINT PK_TIPOS_PAQUETE  PRIMARY KEY (ID_TIPO),
    CONSTRAINT UK_TIPO_CODIGO    UNIQUE (CODIGO_TIPO),
    CONSTRAINT CK_TIPO_PESO      CHECK (PESO_MAX_KG > 0),
    CONSTRAINT CK_TIPO_ACTIVO    CHECK (ACTIVO IN ('S','N'))
);

COMMENT ON TABLE QS_TIPOS_PAQUETE IS 'Catalogo de tipos/categorias de paquetes segun tamanio y peso';


-- ----------------------------------------------------------------
-- 1.3 TABLA: QS_TIPOS_DOCUMENTO
-- Catalogo de tipos de documento de identidad
-- ----------------------------------------------------------------
CREATE TABLE QS_TIPOS_DOCUMENTO (
    ID_TIPO_DOC     NUMBER(3)       NOT NULL,
    CODIGO_DOC      VARCHAR2(10)    NOT NULL,  -- CC, NIT, CE, PA, etc.
    NOMBRE_DOC      VARCHAR2(60)    NOT NULL,
    PAIS_APLICA     VARCHAR2(50)    DEFAULT 'COLOMBIA',
    ACTIVO          CHAR(1)         DEFAULT 'S' NOT NULL,

    CONSTRAINT PK_TIPOS_DOCUMENTO PRIMARY KEY (ID_TIPO_DOC),
    CONSTRAINT UK_TIPO_DOC_CODIGO UNIQUE (CODIGO_DOC),
    CONSTRAINT CK_TIPO_DOC_ACTIVO CHECK (ACTIVO IN ('S','N'))
);

COMMENT ON TABLE QS_TIPOS_DOCUMENTO IS 'Catalogo de tipos de documento de identidad (CC, NIT, CE, PA)';


-- ----------------------------------------------------------------
-- 1.4 TABLA: QS_CIUDADES
-- Catalogo de ciudades/municipios para direcciones
-- ----------------------------------------------------------------
CREATE TABLE QS_CIUDADES (
    ID_CIUDAD       NUMBER(6)       NOT NULL,
    CODIGO_DANE     VARCHAR2(10),              -- Codigo DANE para Colombia
    NOMBRE_CIUDAD   VARCHAR2(100)   NOT NULL,
    DEPARTAMENTO    VARCHAR2(100)   NOT NULL,
    PAIS            VARCHAR2(60)    DEFAULT 'COLOMBIA' NOT NULL,
    CODIGO_POSTAL   VARCHAR2(10),
    ZONA_HORARIA    VARCHAR2(40)    DEFAULT 'America/Bogota',
    ACTIVO          CHAR(1)         DEFAULT 'S' NOT NULL,

    CONSTRAINT PK_CIUDADES        PRIMARY KEY (ID_CIUDAD),
    CONSTRAINT UK_CIUDAD_DANE     UNIQUE (CODIGO_DANE),
    CONSTRAINT CK_CIUDAD_ACTIVO   CHECK (ACTIVO IN ('S','N'))
);

COMMENT ON TABLE QS_CIUDADES IS 'Catalogo de ciudades y municipios de cobertura de QuickSend';


-- ----------------------------------------------------------------
-- 1.5 TABLA: QS_TARIFAS
-- Tabla de tarifas de envio por tipo de paquete y distancia
-- ----------------------------------------------------------------
CREATE TABLE QS_TARIFAS (
    ID_TARIFA       NUMBER(6)       NOT NULL,
    ID_TIPO         NUMBER(3)       NOT NULL,   -- FK a QS_TIPOS_PAQUETE
    NOMBRE_TARIFA   VARCHAR2(100)   NOT NULL,
    PRECIO_BASE     NUMBER(12,2)    NOT NULL,   -- Precio base del envio
    PRECIO_KM       NUMBER(8,4)     DEFAULT 0,  -- Precio adicional por km
    PRECIO_KG       NUMBER(8,4)     DEFAULT 0,  -- Precio adicional por kg
    APLICA_IVA      CHAR(1)         DEFAULT 'S' NOT NULL,
    PORCENTAJE_IVA  NUMBER(5,2)     DEFAULT 19, -- 19% en Colombia
    FECHA_VIGENCIA  DATE            NOT NULL,   -- Desde cuando aplica
    FECHA_FIN       DATE,                       -- NULL = vigente indefinidamente
    ACTIVO          CHAR(1)         DEFAULT 'S' NOT NULL,
    FECHA_CREACION  TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,

    CONSTRAINT PK_TARIFAS         PRIMARY KEY (ID_TARIFA),
    CONSTRAINT FK_TARIFA_TIPO     FOREIGN KEY (ID_TIPO)
        REFERENCES QS_TIPOS_PAQUETE(ID_TIPO),
    CONSTRAINT CK_TARIFA_PRECIO   CHECK (PRECIO_BASE >= 0),
    CONSTRAINT CK_TARIFA_IVA      CHECK (APLICA_IVA IN ('S','N')),
    CONSTRAINT CK_TARIFA_IVA_PCT  CHECK (PORCENTAJE_IVA BETWEEN 0 AND 100),
    CONSTRAINT CK_TARIFA_FECHAS   CHECK (FECHA_FIN IS NULL OR FECHA_FIN > FECHA_VIGENCIA),
    CONSTRAINT CK_TARIFA_ACTIVO   CHECK (ACTIVO IN ('S','N'))
);

COMMENT ON TABLE QS_TARIFAS IS 'Tabla de tarifas de envio vigentes por tipo de paquete';


-- ================================================================
-- SECCION 02: TABLAS DE NEGOCIO PRINCIPALES
-- ================================================================
/*
  Estas tablas representan las entidades core del negocio:
  Clientes, Destinatarios y Paquetes.
  Aplicamos todas las restricciones de integridad aqui.
*/

-- ----------------------------------------------------------------
-- 2.1 TABLA: QS_CLIENTES
-- Personas o empresas que solicitan envios
-- ----------------------------------------------------------------
CREATE TABLE QS_CLIENTES (
    ID_CLIENTE          NUMBER(10)      NOT NULL,
    ID_TIPO_DOC         NUMBER(3)       NOT NULL,   -- FK a QS_TIPOS_DOCUMENTO
    NUM_DOCUMENTO       VARCHAR2(20)    NOT NULL,   -- Numero de documento
    TIPO_PERSONA        CHAR(1)         DEFAULT 'N' NOT NULL,  -- N=Natural, J=Juridica
    -- Persona Natural
    PRIMER_NOMBRE       VARCHAR2(60),
    SEGUNDO_NOMBRE      VARCHAR2(60),
    PRIMER_APELLIDO     VARCHAR2(60),
    SEGUNDO_APELLIDO    VARCHAR2(60),
    -- Persona Juridica
    RAZON_SOCIAL        VARCHAR2(200),
    NIT_EMPRESA         VARCHAR2(20),
    -- Datos de contacto
    EMAIL               VARCHAR2(150)   NOT NULL,
    TELEFONO            VARCHAR2(20),
    CELULAR             VARCHAR2(20)    NOT NULL,
    -- Direccion principal
    ID_CIUDAD           NUMBER(6)       NOT NULL,   -- FK a QS_CIUDADES
    DIRECCION           VARCHAR2(200)   NOT NULL,
    BARRIO              VARCHAR2(100),
    CODIGO_POSTAL       VARCHAR2(10),
    -- Control
    FECHA_REGISTRO      TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    FECHA_ACTUALIZACION TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    ACTIVO              CHAR(1)         DEFAULT 'S' NOT NULL,
    OBSERVACIONES       VARCHAR2(500),

    CONSTRAINT PK_CLIENTES           PRIMARY KEY (ID_CLIENTE),

    -- Un cliente es unico por tipo+numero de documento
    CONSTRAINT UK_CLIENTE_DOCUMENTO  UNIQUE (ID_TIPO_DOC, NUM_DOCUMENTO),

    -- Email unico por cliente
    CONSTRAINT UK_CLIENTE_EMAIL      UNIQUE (EMAIL),

    CONSTRAINT FK_CLIENTE_TIPO_DOC   FOREIGN KEY (ID_TIPO_DOC)
        REFERENCES QS_TIPOS_DOCUMENTO(ID_TIPO_DOC),
    CONSTRAINT FK_CLIENTE_CIUDAD     FOREIGN KEY (ID_CIUDAD)
        REFERENCES QS_CIUDADES(ID_CIUDAD),

    -- Validacion de email con expresion regular
    CONSTRAINT CK_CLIENTE_EMAIL      CHECK (
        REGEXP_LIKE(EMAIL, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
    ),
    -- Tipo persona: N=Natural, J=Juridica
    CONSTRAINT CK_CLIENTE_TIPO_PER   CHECK (TIPO_PERSONA IN ('N','J')),
    CONSTRAINT CK_CLIENTE_ACTIVO     CHECK (ACTIVO IN ('S','N')),
    -- Si es persona juridica, razon social no puede ser nula
    CONSTRAINT CK_CLIENTE_JURIDICA   CHECK (
        TIPO_PERSONA = 'J' AND RAZON_SOCIAL IS NOT NULL
        OR TIPO_PERSONA = 'N'
    )
);

COMMENT ON TABLE  QS_CLIENTES                   IS 'Clientes registrados en QuickSend (remitentes de envios)';
COMMENT ON COLUMN QS_CLIENTES.TIPO_PERSONA       IS 'N=Persona Natural, J=Persona Juridica/Empresa';
COMMENT ON COLUMN QS_CLIENTES.NUM_DOCUMENTO      IS 'Numero de documento segun ID_TIPO_DOC';


-- ----------------------------------------------------------------
-- 2.2 TABLA: QS_DESTINATARIOS
-- Personas que reciben los paquetes
-- Nota: Un cliente puede ser tambien destinatario
-- ----------------------------------------------------------------
CREATE TABLE QS_DESTINATARIOS (
    ID_DESTINATARIO     NUMBER(10)      NOT NULL,
    ID_TIPO_DOC         NUMBER(3)       NOT NULL,
    NUM_DOCUMENTO       VARCHAR2(20)    NOT NULL,
    NOMBRES             VARCHAR2(100)   NOT NULL,
    APELLIDOS           VARCHAR2(100)   NOT NULL,
    EMAIL               VARCHAR2(150),
    TELEFONO            VARCHAR2(20),
    CELULAR             VARCHAR2(20)    NOT NULL,
    ID_CIUDAD           NUMBER(6)       NOT NULL,
    DIRECCION_ENTREGA   VARCHAR2(300)   NOT NULL,
    BARRIO              VARCHAR2(100),
    REFERENCIA_DIR      VARCHAR2(200),  -- "Casa con puerta azul, al lado de..."
    CODIGO_POSTAL       VARCHAR2(10),
    FECHA_REGISTRO      TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    ACTIVO              CHAR(1)         DEFAULT 'S' NOT NULL,

    CONSTRAINT PK_DESTINATARIOS          PRIMARY KEY (ID_DESTINATARIO),
    CONSTRAINT UK_DESTINATARIO_DOC       UNIQUE (ID_TIPO_DOC, NUM_DOCUMENTO),
    CONSTRAINT FK_DEST_TIPO_DOC          FOREIGN KEY (ID_TIPO_DOC)
        REFERENCES QS_TIPOS_DOCUMENTO(ID_TIPO_DOC),
    CONSTRAINT FK_DEST_CIUDAD            FOREIGN KEY (ID_CIUDAD)
        REFERENCES QS_CIUDADES(ID_CIUDAD),
    CONSTRAINT CK_DEST_EMAIL             CHECK (
        EMAIL IS NULL OR
        REGEXP_LIKE(EMAIL, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
    ),
    CONSTRAINT CK_DEST_ACTIVO            CHECK (ACTIVO IN ('S','N'))
);

COMMENT ON TABLE QS_DESTINATARIOS IS 'Personas o empresas que reciben los paquetes enviados';


-- ----------------------------------------------------------------
-- 2.3 TABLA: QS_PAQUETES
-- Entidad central: representa cada paquete fisico
-- ----------------------------------------------------------------
CREATE TABLE QS_PAQUETES (
    ID_PAQUETE          NUMBER(12)      NOT NULL,
    CODIGO_PAQUETE      VARCHAR2(25)    NOT NULL,   -- Codigo unico legible: QS-2024-000001
    ID_TIPO             NUMBER(3)       NOT NULL,   -- FK a QS_TIPOS_PAQUETE
    ID_CLIENTE          NUMBER(10)      NOT NULL,   -- FK a QS_CLIENTES (remitente)
    ID_DESTINATARIO     NUMBER(10)      NOT NULL,   -- FK a QS_DESTINATARIOS
    -- Caracteristicas fisicas
    DESCRIPCION         VARCHAR2(500)   NOT NULL,   -- Que contiene el paquete
    PESO_KG             NUMBER(8,3)     NOT NULL,
    LARGO_CM            NUMBER(6,2),
    ANCHO_CM            NUMBER(6,2),
    ALTO_CM             NUMBER(6,2),
    -- Valor declarado para seguro
    VALOR_DECLARADO     NUMBER(14,2)    DEFAULT 0,
    REQUIERE_SEGURO     CHAR(1)         DEFAULT 'N' NOT NULL,
    -- Instrucciones especiales
    FRAGIL              CHAR(1)         DEFAULT 'N' NOT NULL,
    REFRIGERADO         CHAR(1)         DEFAULT 'N' NOT NULL,
    INSTRUCCIONES       VARCHAR2(500),
    -- Fechas
    FECHA_REGISTRO      TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    FECHA_ENVIO         DATE,
    FECHA_ENTREGA_EST   DATE,           -- Fecha estimada de entrega
    FECHA_ENTREGA_REAL  DATE,           -- Fecha real de entrega
    -- Estado actual (desnormalizacion controlada para rendimiento)
    ID_ESTADO_ACTUAL    NUMBER(3)       NOT NULL,
    -- Tarifa aplicada
    ID_TARIFA           NUMBER(6)       NOT NULL,
    COSTO_ENVIO         NUMBER(12,2)    NOT NULL,
    -- Control
    FECHA_ACTUALIZACION TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    USUARIO_REGISTRO    VARCHAR2(60)    DEFAULT USER NOT NULL,

    CONSTRAINT PK_PAQUETES              PRIMARY KEY (ID_PAQUETE),
    CONSTRAINT UK_PAQUETE_CODIGO        UNIQUE (CODIGO_PAQUETE),
    CONSTRAINT FK_PAQUETE_TIPO          FOREIGN KEY (ID_TIPO)
        REFERENCES QS_TIPOS_PAQUETE(ID_TIPO),
    CONSTRAINT FK_PAQUETE_CLIENTE       FOREIGN KEY (ID_CLIENTE)
        REFERENCES QS_CLIENTES(ID_CLIENTE),
    CONSTRAINT FK_PAQUETE_DESTINATARIO  FOREIGN KEY (ID_DESTINATARIO)
        REFERENCES QS_DESTINATARIOS(ID_DESTINATARIO),
    CONSTRAINT FK_PAQUETE_ESTADO        FOREIGN KEY (ID_ESTADO_ACTUAL)
        REFERENCES QS_ESTADOS_PAQUETE(ID_ESTADO),
    CONSTRAINT FK_PAQUETE_TARIFA        FOREIGN KEY (ID_TARIFA)
        REFERENCES QS_TARIFAS(ID_TARIFA),
    CONSTRAINT CK_PAQUETE_PESO          CHECK (PESO_KG > 0),
    CONSTRAINT CK_PAQUETE_COSTO         CHECK (COSTO_ENVIO >= 0),
    CONSTRAINT CK_PAQUETE_VALOR         CHECK (VALOR_DECLARADO >= 0),
    CONSTRAINT CK_PAQUETE_FRAGIL        CHECK (FRAGIL IN ('S','N')),
    CONSTRAINT CK_PAQUETE_REFRIG        CHECK (REFRIGERADO IN ('S','N')),
    CONSTRAINT CK_PAQUETE_SEGURO        CHECK (REQUIERE_SEGURO IN ('S','N')),
    CONSTRAINT CK_PAQUETE_FECHAS        CHECK (
        FECHA_ENTREGA_REAL IS NULL OR
        FECHA_ENTREGA_REAL >= TRUNC(FECHA_REGISTRO)
    )
);

COMMENT ON TABLE  QS_PAQUETES                    IS 'Tabla central: cada paquete fisico registrado en el sistema';
COMMENT ON COLUMN QS_PAQUETES.CODIGO_PAQUETE     IS 'Codigo unico legible para el cliente: QS-AAAA-NNNNNN';
COMMENT ON COLUMN QS_PAQUETES.ID_ESTADO_ACTUAL   IS 'Desnormalizacion controlada: evita joins costosos para consultas frecuentes';
COMMENT ON COLUMN QS_PAQUETES.VALOR_DECLARADO    IS 'Valor asegurado del contenido declarado por el remitente';


-- ----------------------------------------------------------------
-- 2.4 TABLA: QS_SEGUIMIENTO
-- Historial completo de cambios de estado de cada paquete
-- Esta tabla es APPEND-ONLY (nunca se modifica, solo se inserta)
-- ----------------------------------------------------------------
CREATE TABLE QS_SEGUIMIENTO (
    ID_SEGUIMIENTO      NUMBER(15)      NOT NULL,
    ID_PAQUETE          NUMBER(12)      NOT NULL,   -- FK a QS_PAQUETES
    ID_ESTADO_ANTERIOR  NUMBER(3),                  -- NULL si es el primer estado
    ID_ESTADO_NUEVO     NUMBER(3)       NOT NULL,
    ID_CIUDAD           NUMBER(6),                  -- Donde esta el paquete ahora
    LATITUD             NUMBER(10,7),               -- GPS del evento
    LONGITUD            NUMBER(10,7),
    DESCRIPCION_EVENTO  VARCHAR2(500)   NOT NULL,
    FECHA_EVENTO        TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    ID_USUARIO          NUMBER(8),                  -- Quien registro el evento
    NOMBRE_USUARIO      VARCHAR2(100),
    -- Datos del dispositivo/sistema que registro
    IP_ORIGEN           VARCHAR2(45),               -- IPv4 o IPv6
    DISPOSITIVO         VARCHAR2(200),

    CONSTRAINT PK_SEGUIMIENTO            PRIMARY KEY (ID_SEGUIMIENTO),
    CONSTRAINT FK_SEG_PAQUETE            FOREIGN KEY (ID_PAQUETE)
        REFERENCES QS_PAQUETES(ID_PAQUETE),
    CONSTRAINT FK_SEG_ESTADO_ANT         FOREIGN KEY (ID_ESTADO_ANTERIOR)
        REFERENCES QS_ESTADOS_PAQUETE(ID_ESTADO),
    CONSTRAINT FK_SEG_ESTADO_NVO         FOREIGN KEY (ID_ESTADO_NUEVO)
        REFERENCES QS_ESTADOS_PAQUETE(ID_ESTADO),
    CONSTRAINT FK_SEG_CIUDAD             FOREIGN KEY (ID_CIUDAD)
        REFERENCES QS_CIUDADES(ID_CIUDAD),
    -- El estado nuevo debe ser diferente al anterior
    CONSTRAINT CK_SEG_ESTADOS_DISTINTOS  CHECK (
        ID_ESTADO_ANTERIOR IS NULL OR ID_ESTADO_ANTERIOR <> ID_ESTADO_NUEVO
    )
);

-- Particionar por mes para mejor rendimiento en tabla de alto volumen
-- (Requiere Oracle Partitioning Option)
-- ALTER TABLE QS_SEGUIMIENTO MODIFY PARTITION BY RANGE (FECHA_EVENTO)
-- INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))
-- (PARTITION P_INICIAL VALUES LESS THAN (DATE '2024-01-01'));

COMMENT ON TABLE QS_SEGUIMIENTO IS 'Historial inmutable de todos los cambios de estado de cada paquete (log de trazabilidad)';


-- ================================================================
-- SECCION 03: TABLAS DE OPERACION LOGISTICA
-- ================================================================

-- ----------------------------------------------------------------
-- 3.1 TABLA: QS_VEHICULOS
-- Flotilla de vehiculos de entrega
-- ----------------------------------------------------------------
CREATE TABLE QS_VEHICULOS (
    ID_VEHICULO         NUMBER(8)       NOT NULL,
    PLACA               VARCHAR2(10)    NOT NULL,
    TIPO_VEHICULO       VARCHAR2(30)    NOT NULL,   -- MOTO, FURGON, CAMION, BICICLETA
    MARCA               VARCHAR2(50),
    MODELO              VARCHAR2(50),
    ANIO                NUMBER(4),
    COLOR               VARCHAR2(30),
    CAPACIDAD_KG        NUMBER(8,2)     NOT NULL,   -- Carga maxima en kg
    CAPACIDAD_M3        NUMBER(6,3),                -- Volumen maximo en m3
    ESTADO_VEHICULO     VARCHAR2(20)    DEFAULT 'DISPONIBLE', -- DISPONIBLE, EN_RUTA, MANTENIMIENTO
    FECHA_VTO_TECNO     DATE,           -- Vencimiento tecnomecanica
    FECHA_VTO_SOAT      DATE,           -- Vencimiento SOAT
    ACTIVO              CHAR(1)         DEFAULT 'S' NOT NULL,
    FECHA_REGISTRO      TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,

    CONSTRAINT PK_VEHICULOS             PRIMARY KEY (ID_VEHICULO),
    CONSTRAINT UK_VEHICULO_PLACA        UNIQUE (PLACA),
    CONSTRAINT CK_VEHICULO_TIPO         CHECK (TIPO_VEHICULO IN ('MOTO','FURGON','CAMION','BICICLETA','VAN')),
    CONSTRAINT CK_VEHICULO_ESTADO       CHECK (ESTADO_VEHICULO IN ('DISPONIBLE','EN_RUTA','MANTENIMIENTO','BAJA')),
    CONSTRAINT CK_VEHICULO_CAPACIDAD    CHECK (CAPACIDAD_KG > 0),
    CONSTRAINT CK_VEHICULO_ANIO         CHECK (ANIO IS NULL OR ANIO BETWEEN 1990 AND EXTRACT(YEAR FROM SYSDATE)+1),
    CONSTRAINT CK_VEHICULO_ACTIVO       CHECK (ACTIVO IN ('S','N'))
);

COMMENT ON TABLE QS_VEHICULOS IS 'Flotilla de vehiculos disponibles para entrega de paquetes';


-- ----------------------------------------------------------------
-- 3.2 TABLA: QS_REPARTIDORES
-- Personal de entrega (mensajeros)
-- ----------------------------------------------------------------
CREATE TABLE QS_REPARTIDORES (
    ID_REPARTIDOR       NUMBER(8)       NOT NULL,
    ID_TIPO_DOC         NUMBER(3)       NOT NULL,
    NUM_DOCUMENTO       VARCHAR2(20)    NOT NULL,
    NOMBRES             VARCHAR2(100)   NOT NULL,
    APELLIDOS           VARCHAR2(100)   NOT NULL,
    EMAIL               VARCHAR2(150)   NOT NULL,
    CELULAR             VARCHAR2(20)    NOT NULL,
    NUM_LICENCIA        VARCHAR2(30),              -- Licencia de conducir
    TIPO_LICENCIA       VARCHAR2(5),               -- A1, A2, B1, B2, C1, etc.
    ID_CIUDAD_BASE      NUMBER(6)       NOT NULL,  -- Ciudad donde trabaja
    ID_VEHICULO_ASIG    NUMBER(8),                 -- Vehiculo asignado (puede ser NULL)
    ESTADO_REPARTIDOR   VARCHAR2(20)    DEFAULT 'DISPONIBLE',
    CALIFICACION        NUMBER(3,2)     DEFAULT 5.0, -- Promedio 0-5
    TOTAL_ENTREGAS      NUMBER(10)      DEFAULT 0,
    ENTREGAS_EXITOSAS   NUMBER(10)      DEFAULT 0,
    FECHA_INGRESO       DATE            NOT NULL,
    ACTIVO              CHAR(1)         DEFAULT 'S' NOT NULL,
    FOTO_URL            VARCHAR2(500),
    FECHA_ACTUALIZACION TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,

    CONSTRAINT PK_REPARTIDORES           PRIMARY KEY (ID_REPARTIDOR),
    CONSTRAINT UK_REPARTIDOR_DOC         UNIQUE (ID_TIPO_DOC, NUM_DOCUMENTO),
    CONSTRAINT UK_REPARTIDOR_EMAIL       UNIQUE (EMAIL),
    CONSTRAINT FK_REPARTIDOR_TIPO_DOC    FOREIGN KEY (ID_TIPO_DOC)
        REFERENCES QS_TIPOS_DOCUMENTO(ID_TIPO_DOC),
    CONSTRAINT FK_REPARTIDOR_CIUDAD      FOREIGN KEY (ID_CIUDAD_BASE)
        REFERENCES QS_CIUDADES(ID_CIUDAD),
    CONSTRAINT FK_REPARTIDOR_VEHICULO    FOREIGN KEY (ID_VEHICULO_ASIG)
        REFERENCES QS_VEHICULOS(ID_VEHICULO),
    CONSTRAINT CK_REPARTIDOR_ESTADO      CHECK (ESTADO_REPARTIDOR IN ('DISPONIBLE','EN_RUTA','DESCANSO','INACTIVO')),
    CONSTRAINT CK_REPARTIDOR_CALIF       CHECK (CALIFICACION BETWEEN 0 AND 5),
    CONSTRAINT CK_REPARTIDOR_ENTREGAS    CHECK (ENTREGAS_EXITOSAS <= TOTAL_ENTREGAS),
    CONSTRAINT CK_REPARTIDOR_EMAIL       CHECK (
        REGEXP_LIKE(EMAIL, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
    ),
    CONSTRAINT CK_REPARTIDOR_ACTIVO      CHECK (ACTIVO IN ('S','N'))
);

COMMENT ON TABLE QS_REPARTIDORES IS 'Personal de entrega (mensajeros y conductores) de QuickSend';


-- ----------------------------------------------------------------
-- 3.3 TABLA: QS_RUTAS
-- Rutas de entrega planificadas
-- ----------------------------------------------------------------
CREATE TABLE QS_RUTAS (
    ID_RUTA             NUMBER(10)      NOT NULL,
    CODIGO_RUTA         VARCHAR2(20)    NOT NULL,  -- RT-BOG-001
    NOMBRE_RUTA         VARCHAR2(150)   NOT NULL,
    ID_CIUDAD_ORIGEN    NUMBER(6)       NOT NULL,
    ID_CIUDAD_DESTINO   NUMBER(6)       NOT NULL,
    DISTANCIA_KM        NUMBER(8,2),
    TIEMPO_EST_MIN      NUMBER(6),                 -- Tiempo estimado en minutos
    ESTADO_RUTA         VARCHAR2(20)    DEFAULT 'ACTIVA',
    FECHA_CREACION      TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    ACTIVO              CHAR(1)         DEFAULT 'S' NOT NULL,

    CONSTRAINT PK_RUTAS                 PRIMARY KEY (ID_RUTA),
    CONSTRAINT UK_RUTA_CODIGO           UNIQUE (CODIGO_RUTA),
    CONSTRAINT FK_RUTA_CIUDAD_ORIGEN    FOREIGN KEY (ID_CIUDAD_ORIGEN)
        REFERENCES QS_CIUDADES(ID_CIUDAD),
    CONSTRAINT FK_RUTA_CIUDAD_DESTINO   FOREIGN KEY (ID_CIUDAD_DESTINO)
        REFERENCES QS_CIUDADES(ID_CIUDAD),
    CONSTRAINT CK_RUTA_ESTADO           CHECK (ESTADO_RUTA IN ('ACTIVA','INACTIVA','SUSPENDIDA')),
    CONSTRAINT CK_RUTA_CIUDADES         CHECK (ID_CIUDAD_ORIGEN <> ID_CIUDAD_DESTINO),
    CONSTRAINT CK_RUTA_DISTANCIA        CHECK (DISTANCIA_KM IS NULL OR DISTANCIA_KM > 0),
    CONSTRAINT CK_RUTA_ACTIVO           CHECK (ACTIVO IN ('S','N'))
);

COMMENT ON TABLE QS_RUTAS IS 'Rutas logicas de entrega entre ciudades de cobertura';


-- ----------------------------------------------------------------
-- 3.4 TABLA: QS_ASIGNACIONES
-- Asignacion de paquetes a repartidores y rutas
-- Tabla de union con datos propios (patron N:M enriquecido)
-- ----------------------------------------------------------------
CREATE TABLE QS_ASIGNACIONES (
    ID_ASIGNACION       NUMBER(12)      NOT NULL,
    ID_PAQUETE          NUMBER(12)      NOT NULL,
    ID_REPARTIDOR       NUMBER(8)       NOT NULL,
    ID_RUTA             NUMBER(10)      NOT NULL,
    ID_VEHICULO         NUMBER(8),
    FECHA_ASIGNACION    TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    FECHA_INICIO_EST    TIMESTAMP,                 -- Inicio estimado de entrega
    FECHA_FIN_EST       TIMESTAMP,                 -- Fin estimado de entrega
    FECHA_INICIO_REAL   TIMESTAMP,
    FECHA_FIN_REAL      TIMESTAMP,
    ESTADO_ASIGNACION   VARCHAR2(20)    DEFAULT 'PENDIENTE',
    ORDEN_ENTREGA       NUMBER(4),                 -- Posicion en la ruta del dia
    NOTAS               VARCHAR2(500),
    CALIFICACION_ENT    NUMBER(3,2),               -- Calificacion dada por el cliente al recibir

    CONSTRAINT PK_ASIGNACIONES          PRIMARY KEY (ID_ASIGNACION),
    -- Un paquete solo puede tener UNA asignacion activa
    CONSTRAINT UK_ASIGNACION_PAQUETE    UNIQUE (ID_PAQUETE),
    CONSTRAINT FK_ASIG_PAQUETE          FOREIGN KEY (ID_PAQUETE)
        REFERENCES QS_PAQUETES(ID_PAQUETE),
    CONSTRAINT FK_ASIG_REPARTIDOR       FOREIGN KEY (ID_REPARTIDOR)
        REFERENCES QS_REPARTIDORES(ID_REPARTIDOR),
    CONSTRAINT FK_ASIG_RUTA             FOREIGN KEY (ID_RUTA)
        REFERENCES QS_RUTAS(ID_RUTA),
    CONSTRAINT FK_ASIG_VEHICULO         FOREIGN KEY (ID_VEHICULO)
        REFERENCES QS_VEHICULOS(ID_VEHICULO),
    CONSTRAINT CK_ASIG_ESTADO           CHECK (ESTADO_ASIGNACION IN ('PENDIENTE','EN_PROCESO','COMPLETADA','CANCELADA','REPROGRAMADA')),
    CONSTRAINT CK_ASIG_CALIF            CHECK (CALIFICACION_ENT IS NULL OR CALIFICACION_ENT BETWEEN 0 AND 5),
    CONSTRAINT CK_ASIG_FECHAS           CHECK (
        FECHA_FIN_REAL IS NULL OR FECHA_INICIO_REAL IS NULL OR
        FECHA_FIN_REAL >= FECHA_INICIO_REAL
    )
);

COMMENT ON TABLE QS_ASIGNACIONES IS 'Registro de asignacion de paquetes a repartidores y rutas especificas';


-- ================================================================
-- SECCION 04: TABLAS FINANCIERAS
-- ================================================================

-- ----------------------------------------------------------------
-- 4.1 TABLA: QS_FACTURAS
-- Cabecera de factura por envio(s)
-- ----------------------------------------------------------------
CREATE TABLE QS_FACTURAS (
    ID_FACTURA          NUMBER(12)      NOT NULL,
    NUMERO_FACTURA      VARCHAR2(25)    NOT NULL,  -- FACT-2024-000001
    ID_CLIENTE          NUMBER(10)      NOT NULL,
    TIPO_FACTURA        VARCHAR2(15)    DEFAULT 'VENTA',
    FECHA_EMISION       DATE            DEFAULT TRUNC(SYSDATE) NOT NULL,
    FECHA_VENCIMIENTO   DATE            NOT NULL,
    SUBTOTAL            NUMBER(14,2)    NOT NULL,
    DESCUENTO           NUMBER(14,2)    DEFAULT 0,
    BASE_GRAVABLE       NUMBER(14,2)    NOT NULL,
    IVA                 NUMBER(14,2)    DEFAULT 0,
    TOTAL               NUMBER(14,2)    NOT NULL,
    ESTADO_FACTURA      VARCHAR2(20)    DEFAULT 'PENDIENTE',
    FECHA_PAGO          DATE,
    METODO_PAGO         VARCHAR2(30),
    REFERENCIA_PAGO     VARCHAR2(100),
    OBSERVACIONES       VARCHAR2(500),
    FECHA_CREACION      TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    USUARIO_EMISION     VARCHAR2(60)    DEFAULT USER,

    CONSTRAINT PK_FACTURAS              PRIMARY KEY (ID_FACTURA),
    CONSTRAINT UK_FACTURA_NUMERO        UNIQUE (NUMERO_FACTURA),
    CONSTRAINT FK_FACTURA_CLIENTE       FOREIGN KEY (ID_CLIENTE)
        REFERENCES QS_CLIENTES(ID_CLIENTE),
    CONSTRAINT CK_FACTURA_TIPO          CHECK (TIPO_FACTURA IN ('VENTA','CREDITO','NOTA_DEBITO','NOTA_CREDITO')),
    CONSTRAINT CK_FACTURA_ESTADO        CHECK (ESTADO_FACTURA IN ('PENDIENTE','PAGADA','VENCIDA','ANULADA','PARCIAL')),
    CONSTRAINT CK_FACTURA_TOTAL         CHECK (TOTAL >= 0),
    CONSTRAINT CK_FACTURA_SUBTOTAL      CHECK (SUBTOTAL >= 0),
    CONSTRAINT CK_FACTURA_DESCUENTO     CHECK (DESCUENTO >= 0),
    CONSTRAINT CK_FACTURA_IVA           CHECK (IVA >= 0),
    CONSTRAINT CK_FACTURA_FECHA_VTO     CHECK (FECHA_VENCIMIENTO >= FECHA_EMISION),
    CONSTRAINT CK_FACTURA_METODO_PAGO   CHECK (
        METODO_PAGO IS NULL OR
        METODO_PAGO IN ('EFECTIVO','TARJETA_CREDITO','TARJETA_DEBITO',
                        'TRANSFERENCIA','PSE','NEQUI','DAVIPLATA','OTRO')
    )
);

COMMENT ON TABLE QS_FACTURAS IS 'Cabecera de facturas generadas a clientes por servicios de envio';


-- ----------------------------------------------------------------
-- 4.2 TABLA: QS_DETALLE_FACTURA
-- Lineas de detalle de cada factura (paquetes facturados)
-- ----------------------------------------------------------------
CREATE TABLE QS_DETALLE_FACTURA (
    ID_DETALLE          NUMBER(15)      NOT NULL,
    ID_FACTURA          NUMBER(12)      NOT NULL,
    ID_PAQUETE          NUMBER(12),                -- Puede ser NULL si es cargo adicional
    DESCRIPCION_ITEM    VARCHAR2(300)   NOT NULL,
    CANTIDAD            NUMBER(6,2)     DEFAULT 1  NOT NULL,
    PRECIO_UNITARIO     NUMBER(12,2)    NOT NULL,
    DESCUENTO_ITEM      NUMBER(12,2)    DEFAULT 0,
    IVA_ITEM            NUMBER(12,2)    DEFAULT 0,
    TOTAL_ITEM          NUMBER(12,2)    NOT NULL,

    CONSTRAINT PK_DETALLE_FACTURA       PRIMARY KEY (ID_DETALLE),
    CONSTRAINT FK_DETALLE_FACTURA       FOREIGN KEY (ID_FACTURA)
        REFERENCES QS_FACTURAS(ID_FACTURA) ON DELETE CASCADE,
    CONSTRAINT FK_DETALLE_PAQUETE       FOREIGN KEY (ID_PAQUETE)
        REFERENCES QS_PAQUETES(ID_PAQUETE),
    CONSTRAINT CK_DETALLE_CANTIDAD      CHECK (CANTIDAD > 0),
    CONSTRAINT CK_DETALLE_PRECIO        CHECK (PRECIO_UNITARIO >= 0),
    CONSTRAINT CK_DETALLE_TOTAL         CHECK (TOTAL_ITEM >= 0)
);

COMMENT ON TABLE QS_DETALLE_FACTURA IS 'Lineas de detalle de facturas (un registro por paquete o cargo adicional)';


-- ================================================================
-- SECCION 05: TABLAS DE COMUNICACION Y AUDITORIA
-- ================================================================

-- ----------------------------------------------------------------
-- 5.1 TABLA: QS_NOTIFICACIONES
-- Registro de notificaciones enviadas a clientes
-- ----------------------------------------------------------------
CREATE TABLE QS_NOTIFICACIONES (
    ID_NOTIFICACION     NUMBER(15)      NOT NULL,
    ID_PAQUETE          NUMBER(12)      NOT NULL,
    ID_CLIENTE          NUMBER(10),
    ID_DESTINATARIO     NUMBER(10),
    TIPO_NOTIF          VARCHAR2(20)    NOT NULL,  -- EMAIL, SMS, PUSH, WHATSAPP
    ASUNTO              VARCHAR2(200),
    MENSAJE             CLOB            NOT NULL,
    ESTADO_NOTIF        VARCHAR2(20)    DEFAULT 'PENDIENTE',
    FECHA_CREACION      TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    FECHA_ENVIO         TIMESTAMP,
    FECHA_LECTURA       TIMESTAMP,
    INTENTOS            NUMBER(3)       DEFAULT 0,
    ERROR_DETALLE       VARCHAR2(500),
    REFERENCIA_EXTERNA  VARCHAR2(200),  -- ID del proveedor de notificaciones (SendGrid, Twilio, etc.)

    CONSTRAINT PK_NOTIFICACIONES        PRIMARY KEY (ID_NOTIFICACION),
    CONSTRAINT FK_NOTIF_PAQUETE         FOREIGN KEY (ID_PAQUETE)
        REFERENCES QS_PAQUETES(ID_PAQUETE),
    CONSTRAINT FK_NOTIF_CLIENTE         FOREIGN KEY (ID_CLIENTE)
        REFERENCES QS_CLIENTES(ID_CLIENTE),
    CONSTRAINT FK_NOTIF_DESTINATARIO    FOREIGN KEY (ID_DESTINATARIO)
        REFERENCES QS_DESTINATARIOS(ID_DESTINATARIO),
    CONSTRAINT CK_NOTIF_TIPO            CHECK (TIPO_NOTIF IN ('EMAIL','SMS','PUSH','WHATSAPP','IN_APP')),
    CONSTRAINT CK_NOTIF_ESTADO          CHECK (ESTADO_NOTIF IN ('PENDIENTE','ENVIADA','ENTREGADA','LEIDA','ERROR','CANCELADA')),
    CONSTRAINT CK_NOTIF_INTENTOS        CHECK (INTENTOS BETWEEN 0 AND 10)
);

COMMENT ON TABLE QS_NOTIFICACIONES IS 'Registro de todas las notificaciones enviadas a clientes y destinatarios';


-- ----------------------------------------------------------------
-- 5.2 TABLA: QS_USUARIOS_SISTEMA
-- Usuarios del sistema backoffice de QuickSend
-- ----------------------------------------------------------------
CREATE TABLE QS_USUARIOS_SISTEMA (
    ID_USUARIO          NUMBER(8)       NOT NULL,
    USERNAME            VARCHAR2(50)    NOT NULL,
    PASSWORD_HASH       VARCHAR2(256)   NOT NULL,  -- NUNCA almacenar passwords en texto plano
    SALT                VARCHAR2(64)    NOT NULL,  -- Salt para el hash
    ID_REPARTIDOR       NUMBER(8),                 -- Si es repartidor, enlace
    NOMBRES             VARCHAR2(100)   NOT NULL,
    APELLIDOS           VARCHAR2(100)   NOT NULL,
    EMAIL               VARCHAR2(150)   NOT NULL,
    TELEFONO            VARCHAR2(20),
    ROL_PRINCIPAL       VARCHAR2(30)    NOT NULL,  -- ADMIN, OPERADOR, REPARTIDOR, AUDITOR
    ACTIVO              CHAR(1)         DEFAULT 'S' NOT NULL,
    FECHA_CREACION      TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    ULTIMO_ACCESO       TIMESTAMP,
    INTENTOS_FALLIDOS   NUMBER(3)       DEFAULT 0,
    BLOQUEADO           CHAR(1)         DEFAULT 'N' NOT NULL,
    FECHA_BLOQUEO       TIMESTAMP,
    TOKEN_RESET         VARCHAR2(200),             -- Token para restablecer password
    FECHA_VTO_TOKEN     TIMESTAMP,                 -- Vencimiento del token

    CONSTRAINT PK_USUARIOS_SISTEMA      PRIMARY KEY (ID_USUARIO),
    CONSTRAINT UK_USUARIO_USERNAME      UNIQUE (USERNAME),
    CONSTRAINT UK_USUARIO_EMAIL         UNIQUE (EMAIL),
    CONSTRAINT FK_USUARIO_REPARTIDOR    FOREIGN KEY (ID_REPARTIDOR)
        REFERENCES QS_REPARTIDORES(ID_REPARTIDOR),
    CONSTRAINT CK_USUARIO_ROL           CHECK (ROL_PRINCIPAL IN ('ADMIN','OPERADOR','REPARTIDOR','AUDITOR','SUPERVISOR')),
    CONSTRAINT CK_USUARIO_ACTIVO        CHECK (ACTIVO IN ('S','N')),
    CONSTRAINT CK_USUARIO_BLOQUEADO     CHECK (BLOQUEADO IN ('S','N')),
    CONSTRAINT CK_USUARIO_EMAIL         CHECK (
        REGEXP_LIKE(EMAIL, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
    ),
    CONSTRAINT CK_USUARIO_INTENTOS      CHECK (INTENTOS_FALLIDOS BETWEEN 0 AND 10)
);

COMMENT ON TABLE  QS_USUARIOS_SISTEMA                  IS 'Usuarios del sistema interno de QuickSend';
COMMENT ON COLUMN QS_USUARIOS_SISTEMA.PASSWORD_HASH    IS 'Hash SHA-256 del password + salt. NUNCA texto plano.';
COMMENT ON COLUMN QS_USUARIOS_SISTEMA.SALT             IS 'Cadena aleatoria unica por usuario usada en el hash';


-- ----------------------------------------------------------------
-- 5.3 TABLA: QS_AUDITORIA
-- Log de auditoria de todas las operaciones criticas
-- Esta tabla NUNCA se borra ni modifica
-- ----------------------------------------------------------------
CREATE TABLE QS_AUDITORIA (
    ID_AUDITORIA        NUMBER(18)      NOT NULL,
    TABLA_AFECTADA      VARCHAR2(60)    NOT NULL,
    ID_REGISTRO         VARCHAR2(50)    NOT NULL,  -- PK del registro afectado
    OPERACION           CHAR(1)         NOT NULL,  -- I=Insert, U=Update, D=Delete
    COLUMNA_MODIFICADA  VARCHAR2(100),             -- Para UPDATE, que columna cambio
    VALOR_ANTERIOR      VARCHAR2(4000),
    VALOR_NUEVO         VARCHAR2(4000),
    USUARIO_DB          VARCHAR2(100)   DEFAULT USER NOT NULL,
    USUARIO_APP         VARCHAR2(100),             -- Usuario de la aplicacion
    IP_CLIENTE          VARCHAR2(45),
    FECHA_OPERACION     TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    PROGRAMA_ORIGEN     VARCHAR2(200),             -- Nombre del proc/trigger origen
    INFO_ADICIONAL      VARCHAR2(1000),

    CONSTRAINT PK_AUDITORIA             PRIMARY KEY (ID_AUDITORIA),
    CONSTRAINT CK_AUDITORIA_OPERACION   CHECK (OPERACION IN ('I','U','D'))
);

COMMENT ON TABLE QS_AUDITORIA IS 'Tabla de auditoria inmutable: registra INSERT/UPDATE/DELETE en tablas criticas';


-- ================================================================
-- SECCION 06: SECUENCIAS
-- ================================================================
/*
  Las secuencias de Oracle generan numeros unicos y auto-incrementales.
  Son la forma estandar de generar PKs en Oracle (equivalente a IDENTITY en otros motores).
  NOCACHE = para mayor integridad (puede afectar performance en alto volumen)
  CACHE 20 = buena opcion de balance entre seguridad y rendimiento
*/

-- Catalogo
CREATE SEQUENCE SEQ_ESTADOS_PAQUETE   START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_TIPOS_PAQUETE     START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_TIPOS_DOCUMENTO   START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_CIUDADES          START WITH 1 INCREMENT BY 1 CACHE 20 NOCYCLE;
CREATE SEQUENCE SEQ_TARIFAS           START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

-- Negocio principal
CREATE SEQUENCE SEQ_CLIENTES          START WITH 1  INCREMENT BY 1 CACHE 20 NOCYCLE;
CREATE SEQUENCE SEQ_DESTINATARIOS     START WITH 1  INCREMENT BY 1 CACHE 20 NOCYCLE;
CREATE SEQUENCE SEQ_PAQUETES          START WITH 1  INCREMENT BY 1 CACHE 20 NOCYCLE;
CREATE SEQUENCE SEQ_SEGUIMIENTO       START WITH 1  INCREMENT BY 1 CACHE 50 NOCYCLE;

-- Logistica
CREATE SEQUENCE SEQ_VEHICULOS         START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_REPARTIDORES      START WITH 1 INCREMENT BY 1 CACHE 10 NOCYCLE;
CREATE SEQUENCE SEQ_RUTAS             START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_ASIGNACIONES      START WITH 1 INCREMENT BY 1 CACHE 20 NOCYCLE;

-- Financiero
CREATE SEQUENCE SEQ_FACTURAS          START WITH 1 INCREMENT BY 1 CACHE 10 NOCYCLE;
CREATE SEQUENCE SEQ_DETALLE_FACTURA   START WITH 1 INCREMENT BY 1 CACHE 50 NOCYCLE;

-- Comunicacion y seguridad
CREATE SEQUENCE SEQ_NOTIFICACIONES    START WITH 1 INCREMENT BY 1 CACHE 50 NOCYCLE;
CREATE SEQUENCE SEQ_USUARIOS_SISTEMA  START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_AUDITORIA         START WITH 1 INCREMENT BY 1 CACHE 100 NOCYCLE;

COMMENT ON SEQUENCE SEQ_PAQUETES      IS 'Genera el ID numerico interno de cada paquete';
COMMENT ON SEQUENCE SEQ_AUDITORIA     IS 'Generador de IDs para la tabla de auditoria - CACHE alto por alto volumen';


-- ================================================================
-- SECCION 07: INDICES DE RENDIMIENTO
-- ================================================================
/*
  Los indices aceleran las consultas SELECT pero tienen costo en INSERT/UPDATE.
  Regla: indizar columnas que aparecen frecuentemente en WHERE, JOIN y ORDER BY.
  Oracle crea indices automaticamente para PRIMARY KEY y UNIQUE constraints.
*/

-- Indices en QS_PAQUETES (tabla mas consultada)
CREATE INDEX IDX_PKG_CLIENTE
    ON QS_PAQUETES(ID_CLIENTE);
-- Para: "Dame todos los paquetes del cliente X"

CREATE INDEX IDX_PKG_DESTINATARIO
    ON QS_PAQUETES(ID_DESTINATARIO);
-- Para: "Que paquetes tiene pendientes el destinatario Y"

CREATE INDEX IDX_PKG_ESTADO_FECHA
    ON QS_PAQUETES(ID_ESTADO_ACTUAL, FECHA_REGISTRO DESC);
-- Para: "Todos los paquetes en estado EN_CAMINO de hoy"

CREATE INDEX IDX_PKG_FECHA_ENVIO
    ON QS_PAQUETES(FECHA_ENVIO);
-- Para: consultas por rango de fechas

-- Indices en QS_SEGUIMIENTO (tabla de mayor volumen)
CREATE INDEX IDX_SEG_PAQUETE_FECHA
    ON QS_SEGUIMIENTO(ID_PAQUETE, FECHA_EVENTO DESC);
-- Para: "Historial del paquete X ordenado por fecha"

CREATE INDEX IDX_SEG_ESTADO_NVO
    ON QS_SEGUIMIENTO(ID_ESTADO_NUEVO, FECHA_EVENTO DESC);

-- Indices en QS_CLIENTES
CREATE INDEX IDX_CLI_CIUDAD
    ON QS_CLIENTES(ID_CIUDAD);
-- Para: "Clientes de Bogota"

-- Indices en QS_ASIGNACIONES
CREATE INDEX IDX_ASIG_REPARTIDOR
    ON QS_ASIGNACIONES(ID_REPARTIDOR, FECHA_ASIGNACION DESC);
-- Para: "Todas las asignaciones del repartidor hoy"

CREATE INDEX IDX_ASIG_ESTADO
    ON QS_ASIGNACIONES(ESTADO_ASIGNACION);

-- Indices en QS_FACTURAS
CREATE INDEX IDX_FACT_CLIENTE
    ON QS_FACTURAS(ID_CLIENTE, FECHA_EMISION DESC);

CREATE INDEX IDX_FACT_ESTADO_FECHA
    ON QS_FACTURAS(ESTADO_FACTURA, FECHA_VENCIMIENTO);
-- Para: "Facturas vencidas pendientes de cobro"

-- Indices en QS_NOTIFICACIONES
CREATE INDEX IDX_NOTIF_PAQUETE
    ON QS_NOTIFICACIONES(ID_PAQUETE);

CREATE INDEX IDX_NOTIF_ESTADO
    ON QS_NOTIFICACIONES(ESTADO_NOTIF, FECHA_CREACION);
-- Para: "Notificaciones pendientes de envio"

-- Indices en QS_AUDITORIA
CREATE INDEX IDX_AUD_TABLA_REGISTRO
    ON QS_AUDITORIA(TABLA_AFECTADA, ID_REGISTRO, FECHA_OPERACION DESC);
-- Para: "Todo lo que le paso al cliente 123"

CREATE INDEX IDX_AUD_USUARIO_FECHA
    ON QS_AUDITORIA(USUARIO_APP, FECHA_OPERACION DESC);
-- Para: "Que hizo el usuario JPEREZ hoy"


-- ================================================================
-- SECCION 08: TRIGGERS AUTOMATICOS
-- ================================================================
/*
  Los triggers son codigo que se ejecuta AUTOMATICAMENTE cuando ocurre
  un evento (INSERT, UPDATE, DELETE) en una tabla.
  Aqui usamos triggers para:
  1. Auto-generar PKs desde secuencias
  2. Generar codigos de negocio legibles
  3. Actualizar timestamps automaticamente
  4. Validar reglas de negocio complejas
  5. Registrar auditoria automaticamente
*/

-- ----------------------------------------------------------------
-- TRIGGER 8.1: Auto-PK y codigo para QS_CLIENTES
-- ----------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_CLIENTES_BI
    BEFORE INSERT ON QS_CLIENTES
    FOR EACH ROW
/*
  BEFORE INSERT: se ejecuta ANTES de que el registro se guarde
  FOR EACH ROW: se ejecuta una vez por cada fila insertada
*/
BEGIN
    -- Si no se proporciona ID, lo genera automaticamente desde la secuencia
    IF :NEW.ID_CLIENTE IS NULL THEN
        :NEW.ID_CLIENTE := SEQ_CLIENTES.NEXTVAL;
    END IF;
    -- Normalizar texto a mayusculas
    :NEW.PRIMER_NOMBRE   := UPPER(TRIM(:NEW.PRIMER_NOMBRE));
    :NEW.SEGUNDO_NOMBRE  := UPPER(TRIM(:NEW.SEGUNDO_NOMBRE));
    :NEW.PRIMER_APELLIDO := UPPER(TRIM(:NEW.PRIMER_APELLIDO));
    :NEW.SEGUNDO_APELLIDO:= UPPER(TRIM(:NEW.SEGUNDO_APELLIDO));
    :NEW.RAZON_SOCIAL    := UPPER(TRIM(:NEW.RAZON_SOCIAL));
    :NEW.EMAIL           := LOWER(TRIM(:NEW.EMAIL));
    -- Timestamps
    :NEW.FECHA_REGISTRO      := SYSTIMESTAMP;
    :NEW.FECHA_ACTUALIZACION := SYSTIMESTAMP;
END TRG_CLIENTES_BI;
/

-- Trigger para UPDATE de clientes (actualizar timestamp)
CREATE OR REPLACE TRIGGER TRG_CLIENTES_BU
    BEFORE UPDATE ON QS_CLIENTES
    FOR EACH ROW
BEGIN
    :NEW.FECHA_ACTUALIZACION := SYSTIMESTAMP;
    :NEW.EMAIL := LOWER(TRIM(:NEW.EMAIL));
END TRG_CLIENTES_BU;
/

-- ----------------------------------------------------------------
-- TRIGGER 8.2: Auto-PK para QS_DESTINATARIOS
-- ----------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_DESTINATARIOS_BI
    BEFORE INSERT ON QS_DESTINATARIOS
    FOR EACH ROW
BEGIN
    IF :NEW.ID_DESTINATARIO IS NULL THEN
        :NEW.ID_DESTINATARIO := SEQ_DESTINATARIOS.NEXTVAL;
    END IF;
    :NEW.NOMBRES    := UPPER(TRIM(:NEW.NOMBRES));
    :NEW.APELLIDOS  := UPPER(TRIM(:NEW.APELLIDOS));
    :NEW.EMAIL      := LOWER(TRIM(:NEW.EMAIL));
    :NEW.FECHA_REGISTRO := SYSTIMESTAMP;
END TRG_DESTINATARIOS_BI;
/

-- ----------------------------------------------------------------
-- TRIGGER 8.3: Auto-PK y CODIGO_PAQUETE para QS_PAQUETES
-- ----------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_PAQUETES_BI
    BEFORE INSERT ON QS_PAQUETES
    FOR EACH ROW
/*
  Genera el codigo legible del paquete en formato: QS-AAAA-NNNNNN
  Ejemplo: QS-2024-000001
*/
DECLARE
    v_seq   NUMBER;
    v_anio  VARCHAR2(4);
BEGIN
    IF :NEW.ID_PAQUETE IS NULL THEN
        v_seq  := SEQ_PAQUETES.NEXTVAL;
        :NEW.ID_PAQUETE := v_seq;
    ELSE
        v_seq := :NEW.ID_PAQUETE;
    END IF;

    -- Generar codigo legible si no se proporciono
    IF :NEW.CODIGO_PAQUETE IS NULL THEN
        v_anio := TO_CHAR(SYSDATE, 'YYYY');
        :NEW.CODIGO_PAQUETE := 'QS-' || v_anio || '-' || LPAD(v_seq, 6, '0');
    END IF;

    :NEW.FECHA_REGISTRO      := SYSTIMESTAMP;
    :NEW.FECHA_ACTUALIZACION := SYSTIMESTAMP;
    :NEW.USUARIO_REGISTRO    := NVL(:NEW.USUARIO_REGISTRO, USER);

    -- Calcular fecha estimada de entrega (3 dias habiles por defecto si no se proporciona)
    IF :NEW.FECHA_ENTREGA_EST IS NULL AND :NEW.FECHA_ENVIO IS NOT NULL THEN
        :NEW.FECHA_ENTREGA_EST := :NEW.FECHA_ENVIO + 3;
    END IF;
END TRG_PAQUETES_BI;
/

-- Trigger para UPDATE de paquetes
CREATE OR REPLACE TRIGGER TRG_PAQUETES_BU
    BEFORE UPDATE ON QS_PAQUETES
    FOR EACH ROW
BEGIN
    :NEW.FECHA_ACTUALIZACION := SYSTIMESTAMP;

    -- Si el estado nuevo es ENTREGADO y no hay fecha real, se pone ahora
    IF :NEW.ID_ESTADO_ACTUAL = 3 AND :OLD.ID_ESTADO_ACTUAL <> 3 THEN
        IF :NEW.FECHA_ENTREGA_REAL IS NULL THEN
            :NEW.FECHA_ENTREGA_REAL := TRUNC(SYSDATE);
        END IF;
    END IF;
END TRG_PAQUETES_BU;
/

-- ----------------------------------------------------------------
-- TRIGGER 8.4: Auto-registro en QS_SEGUIMIENTO al cambiar estado
-- ----------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_PAQUETES_SEGUIMIENTO
    AFTER UPDATE OF ID_ESTADO_ACTUAL ON QS_PAQUETES
    FOR EACH ROW
/*
  AFTER UPDATE: se ejecuta DESPUES de guardar el cambio
  Solo se dispara cuando cambia la columna ID_ESTADO_ACTUAL
  Registra automaticamente el cambio en el historial de seguimiento
*/
BEGIN
    IF :OLD.ID_ESTADO_ACTUAL <> :NEW.ID_ESTADO_ACTUAL THEN
        INSERT INTO QS_SEGUIMIENTO (
            ID_SEGUIMIENTO, ID_PAQUETE,
            ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO,
            DESCRIPCION_EVENTO, FECHA_EVENTO,
            NOMBRE_USUARIO
        ) VALUES (
            SEQ_SEGUIMIENTO.NEXTVAL,
            :NEW.ID_PAQUETE,
            :OLD.ID_ESTADO_ACTUAL,
            :NEW.ID_ESTADO_ACTUAL,
            'Cambio automatico de estado registrado por el sistema',
            SYSTIMESTAMP,
            USER
        );
    END IF;
END TRG_PAQUETES_SEGUIMIENTO;
/

-- ----------------------------------------------------------------
-- TRIGGER 8.5: Auto-PK para QS_SEGUIMIENTO
-- ----------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_SEGUIMIENTO_BI
    BEFORE INSERT ON QS_SEGUIMIENTO
    FOR EACH ROW
BEGIN
    IF :NEW.ID_SEGUIMIENTO IS NULL THEN
        :NEW.ID_SEGUIMIENTO := SEQ_SEGUIMIENTO.NEXTVAL;
    END IF;
    :NEW.FECHA_EVENTO := NVL(:NEW.FECHA_EVENTO, SYSTIMESTAMP);
END TRG_SEGUIMIENTO_BI;
/

-- ----------------------------------------------------------------
-- TRIGGER 8.6: Auto-numero de factura
-- ----------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_FACTURAS_BI
    BEFORE INSERT ON QS_FACTURAS
    FOR EACH ROW
BEGIN
    IF :NEW.ID_FACTURA IS NULL THEN
        :NEW.ID_FACTURA := SEQ_FACTURAS.NEXTVAL;
    END IF;
    IF :NEW.NUMERO_FACTURA IS NULL THEN
        :NEW.NUMERO_FACTURA := 'FACT-' || TO_CHAR(SYSDATE,'YYYY') ||
                               '-' || LPAD(:NEW.ID_FACTURA, 6, '0');
    END IF;
    :NEW.FECHA_CREACION := SYSTIMESTAMP;
    :NEW.USUARIO_EMISION := NVL(:NEW.USUARIO_EMISION, USER);
END TRG_FACTURAS_BI;
/

-- ----------------------------------------------------------------
-- TRIGGER 8.7: Auto-calcular total en QS_DETALLE_FACTURA
-- ----------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_DETALLE_FACT_BI
    BEFORE INSERT OR UPDATE ON QS_DETALLE_FACTURA
    FOR EACH ROW
BEGIN
    IF :NEW.ID_DETALLE IS NULL THEN
        :NEW.ID_DETALLE := SEQ_DETALLE_FACTURA.NEXTVAL;
    END IF;
    -- Calcular total del item automaticamente
    :NEW.TOTAL_ITEM := (:NEW.CANTIDAD * :NEW.PRECIO_UNITARIO)
                       - NVL(:NEW.DESCUENTO_ITEM, 0)
                       + NVL(:NEW.IVA_ITEM, 0);
END TRG_DETALLE_FACT_BI;
/

-- ----------------------------------------------------------------
-- TRIGGER 8.8: Auditoria automatica en QS_CLIENTES
-- ----------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_AUDITORIA_CLIENTES
    AFTER INSERT OR UPDATE OR DELETE ON QS_CLIENTES
    FOR EACH ROW
DECLARE
    v_operacion  CHAR(1);
    v_id         VARCHAR2(50);
BEGIN
    IF    INSERTING THEN v_operacion := 'I'; v_id := TO_CHAR(:NEW.ID_CLIENTE);
    ELSIF UPDATING  THEN v_operacion := 'U'; v_id := TO_CHAR(:OLD.ID_CLIENTE);
    ELSIF DELETING  THEN v_operacion := 'D'; v_id := TO_CHAR(:OLD.ID_CLIENTE);
    END IF;

    INSERT INTO QS_AUDITORIA (
        ID_AUDITORIA, TABLA_AFECTADA, ID_REGISTRO, OPERACION,
        VALOR_ANTERIOR, VALOR_NUEVO,
        USUARIO_DB, FECHA_OPERACION, PROGRAMA_ORIGEN
    ) VALUES (
        SEQ_AUDITORIA.NEXTVAL,
        'QS_CLIENTES',
        v_id,
        v_operacion,
        CASE WHEN UPDATING OR DELETING THEN
            'EMAIL=' || :OLD.EMAIL || '; DOC=' || :OLD.NUM_DOCUMENTO
        END,
        CASE WHEN INSERTING OR UPDATING THEN
            'EMAIL=' || :NEW.EMAIL || '; DOC=' || :NEW.NUM_DOCUMENTO
        END,
        USER,
        SYSTIMESTAMP,
        'TRG_AUDITORIA_CLIENTES'
    );
END TRG_AUDITORIA_CLIENTES;
/

-- ----------------------------------------------------------------
-- TRIGGER 8.9: Bloqueo de usuario tras 5 intentos fallidos
-- ----------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_USUARIOS_BLOQUEO
    BEFORE UPDATE OF INTENTOS_FALLIDOS ON QS_USUARIOS_SISTEMA
    FOR EACH ROW
BEGIN
    -- Si supera 5 intentos, bloquear automaticamente
    IF :NEW.INTENTOS_FALLIDOS >= 5 AND :OLD.BLOQUEADO = 'N' THEN
        :NEW.BLOQUEADO    := 'S';
        :NEW.FECHA_BLOQUEO := SYSTIMESTAMP;
    END IF;
END TRG_USUARIOS_BLOQUEO;
/

-- ----------------------------------------------------------------
-- TRIGGER 8.10: Actualizar estadisticas del repartidor
-- ----------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_ASIG_ESTADISTICAS
    AFTER UPDATE OF ESTADO_ASIGNACION ON QS_ASIGNACIONES
    FOR EACH ROW
BEGIN
    -- Cuando se completa una asignacion, actualizar contador del repartidor
    IF :NEW.ESTADO_ASIGNACION = 'COMPLETADA' AND :OLD.ESTADO_ASIGNACION <> 'COMPLETADA' THEN
        UPDATE QS_REPARTIDORES
        SET TOTAL_ENTREGAS   = TOTAL_ENTREGAS   + 1,
            ENTREGAS_EXITOSAS = ENTREGAS_EXITOSAS + 1,
            FECHA_ACTUALIZACION = SYSTIMESTAMP
        WHERE ID_REPARTIDOR = :NEW.ID_REPARTIDOR;

    ELSIF :NEW.ESTADO_ASIGNACION = 'CANCELADA' AND :OLD.ESTADO_ASIGNACION = 'EN_PROCESO' THEN
        UPDATE QS_REPARTIDORES
        SET TOTAL_ENTREGAS = TOTAL_ENTREGAS + 1,
            FECHA_ACTUALIZACION = SYSTIMESTAMP
        WHERE ID_REPARTIDOR = :NEW.ID_REPARTIDOR;
    END IF;
END TRG_ASIG_ESTADISTICAS;
/


-- ================================================================
-- SECCION 09: VISTAS DE NEGOCIO
-- ================================================================
/*
  Las vistas son consultas guardadas que se comportan como tablas virtuales.
  Sirven para simplificar consultas complejas y controlar el acceso a datos.
*/

-- ----------------------------------------------------------------
-- VISTA 9.1: Estado actual de todos los paquetes activos
-- La mas usada en el operativo diario
-- ----------------------------------------------------------------
CREATE OR REPLACE VIEW VW_PAQUETES_ACTIVOS AS
SELECT
    p.ID_PAQUETE,
    p.CODIGO_PAQUETE,
    -- Datos del remitente
    c.ID_CLIENTE,
    CASE c.TIPO_PERSONA
        WHEN 'N' THEN c.PRIMER_NOMBRE || ' ' || c.PRIMER_APELLIDO
        WHEN 'J' THEN c.RAZON_SOCIAL
    END                             AS NOMBRE_CLIENTE,
    c.EMAIL                         AS EMAIL_CLIENTE,
    c.CELULAR                       AS CELULAR_CLIENTE,
    -- Datos del destinatario
    d.ID_DESTINATARIO,
    d.NOMBRES || ' ' || d.APELLIDOS AS NOMBRE_DESTINATARIO,
    d.CELULAR                       AS CELULAR_DESTINATARIO,
    d.DIRECCION_ENTREGA,
    cdd.NOMBRE_CIUDAD               AS CIUDAD_DESTINO,
    cdd.DEPARTAMENTO                AS DEPARTAMENTO_DESTINO,
    -- Datos del paquete
    tp.NOMBRE_TIPO                  AS TIPO_PAQUETE,
    p.PESO_KG,
    p.DESCRIPCION,
    p.FRAGIL,
    -- Estado
    ep.CODIGO_ESTADO,
    ep.NOMBRE_ESTADO,
    ep.COLOR_HEX,
    -- Fechas clave
    p.FECHA_REGISTRO,
    p.FECHA_ENVIO,
    p.FECHA_ENTREGA_EST,
    p.FECHA_ENTREGA_REAL,
    -- Calcular dias restantes para entrega estimada
    CASE
        WHEN p.FECHA_ENTREGA_REAL IS NOT NULL THEN 0
        WHEN p.FECHA_ENTREGA_EST < TRUNC(SYSDATE) THEN -1  -- Retrasado
        ELSE p.FECHA_ENTREGA_EST - TRUNC(SYSDATE)
    END                             AS DIAS_PARA_ENTREGA,
    -- Costo
    p.COSTO_ENVIO
FROM QS_PAQUETES       p
JOIN QS_CLIENTES       c   ON c.ID_CLIENTE      = p.ID_CLIENTE
JOIN QS_DESTINATARIOS  d   ON d.ID_DESTINATARIO = p.ID_DESTINATARIO
JOIN QS_TIPOS_PAQUETE  tp  ON tp.ID_TIPO        = p.ID_TIPO
JOIN QS_ESTADOS_PAQUETE ep ON ep.ID_ESTADO      = p.ID_ESTADO_ACTUAL
JOIN QS_CIUDADES       cdd ON cdd.ID_CIUDAD     = d.ID_CIUDAD
WHERE ep.ES_FINAL = 'N';  -- Solo paquetes que NO han terminado su ciclo

COMMENT ON TABLE VW_PAQUETES_ACTIVOS IS 'Vista de paquetes en estado activo (no entregados ni cancelados definitivamente)';


-- ----------------------------------------------------------------
-- VISTA 9.2: Repartidores con su carga actual del dia
-- ----------------------------------------------------------------
CREATE OR REPLACE VIEW VW_REPARTIDORES_CARGA AS
SELECT
    r.ID_REPARTIDOR,
    r.NOMBRES || ' ' || r.APELLIDOS    AS NOMBRE_REPARTIDOR,
    r.CELULAR,
    r.ESTADO_REPARTIDOR,
    r.CALIFICACION,
    v.PLACA                            AS PLACA_VEHICULO,
    v.TIPO_VEHICULO,
    c.NOMBRE_CIUDAD                    AS CIUDAD_BASE,
    COUNT(a.ID_ASIGNACION)             AS PAQUETES_ASIGNADOS_HOY,
    SUM(CASE WHEN a.ESTADO_ASIGNACION = 'COMPLETADA' THEN 1 ELSE 0 END)
                                       AS PAQUETES_ENTREGADOS_HOY,
    SUM(CASE WHEN a.ESTADO_ASIGNACION = 'PENDIENTE'
                 OR a.ESTADO_ASIGNACION = 'EN_PROCESO' THEN 1 ELSE 0 END)
                                       AS PAQUETES_PENDIENTES,
    r.TOTAL_ENTREGAS,
    r.ENTREGAS_EXITOSAS,
    ROUND(CASE WHEN r.TOTAL_ENTREGAS > 0
               THEN (r.ENTREGAS_EXITOSAS / r.TOTAL_ENTREGAS) * 100
               ELSE 0 END, 2)          AS PCT_EFICIENCIA
FROM QS_REPARTIDORES r
LEFT JOIN QS_VEHICULOS   v ON v.ID_VEHICULO  = r.ID_VEHICULO_ASIG
LEFT JOIN QS_CIUDADES    c ON c.ID_CIUDAD    = r.ID_CIUDAD_BASE
LEFT JOIN QS_ASIGNACIONES a
    ON  a.ID_REPARTIDOR   = r.ID_REPARTIDOR
    AND TRUNC(a.FECHA_ASIGNACION) = TRUNC(SYSDATE)
WHERE r.ACTIVO = 'S'
GROUP BY
    r.ID_REPARTIDOR, r.NOMBRES, r.APELLIDOS, r.CELULAR,
    r.ESTADO_REPARTIDOR, r.CALIFICACION,
    v.PLACA, v.TIPO_VEHICULO, c.NOMBRE_CIUDAD,
    r.TOTAL_ENTREGAS, r.ENTREGAS_EXITOSAS;

COMMENT ON TABLE VW_REPARTIDORES_CARGA IS 'Vista de repartidores con su carga de trabajo del dia actual';


-- ----------------------------------------------------------------
-- VISTA 9.3: Ultimo estado de cada paquete con detalles completos
-- ----------------------------------------------------------------
CREATE OR REPLACE VIEW VW_HISTORIAL_SEGUIMIENTO AS
SELECT
    s.ID_SEGUIMIENTO,
    s.ID_PAQUETE,
    p.CODIGO_PAQUETE,
    ea.NOMBRE_ESTADO                    AS ESTADO_ANTERIOR,
    en.NOMBRE_ESTADO                    AS ESTADO_NUEVO,
    en.COLOR_HEX,
    s.DESCRIPCION_EVENTO,
    s.FECHA_EVENTO,
    c.NOMBRE_CIUDAD                     AS CIUDAD_EVENTO,
    s.LATITUD,
    s.LONGITUD,
    s.NOMBRE_USUARIO
FROM QS_SEGUIMIENTO           s
JOIN QS_PAQUETES              p  ON p.ID_PAQUETE  = s.ID_PAQUETE
JOIN QS_ESTADOS_PAQUETE       en ON en.ID_ESTADO  = s.ID_ESTADO_NUEVO
LEFT JOIN QS_ESTADOS_PAQUETE  ea ON ea.ID_ESTADO  = s.ID_ESTADO_ANTERIOR
LEFT JOIN QS_CIUDADES         c  ON c.ID_CIUDAD   = s.ID_CIUDAD
ORDER BY s.ID_PAQUETE, s.FECHA_EVENTO DESC;

COMMENT ON TABLE VW_HISTORIAL_SEGUIMIENTO IS 'Vista completa del historial de seguimiento con nombres descriptivos';


-- ----------------------------------------------------------------
-- VISTA 9.4: Resumen financiero por cliente
-- ----------------------------------------------------------------
CREATE OR REPLACE VIEW VW_RESUMEN_FINANCIERO_CLIENTE AS
SELECT
    cl.ID_CLIENTE,
    CASE cl.TIPO_PERSONA
        WHEN 'N' THEN cl.PRIMER_NOMBRE || ' ' || cl.PRIMER_APELLIDO
        WHEN 'J' THEN cl.RAZON_SOCIAL
    END                            AS NOMBRE_CLIENTE,
    cl.EMAIL,
    cl.CELULAR,
    ciud.NOMBRE_CIUDAD,
    COUNT(DISTINCT p.ID_PAQUETE)   AS TOTAL_PAQUETES,
    COUNT(DISTINCT f.ID_FACTURA)   AS TOTAL_FACTURAS,
    NVL(SUM(f.TOTAL), 0)           AS MONTO_TOTAL_FACTURADO,
    NVL(SUM(CASE WHEN f.ESTADO_FACTURA = 'PAGADA' THEN f.TOTAL ELSE 0 END), 0)
                                   AS MONTO_PAGADO,
    NVL(SUM(CASE WHEN f.ESTADO_FACTURA IN ('PENDIENTE','VENCIDA') THEN f.TOTAL ELSE 0 END), 0)
                                   AS SALDO_PENDIENTE,
    MIN(f.FECHA_EMISION)           AS PRIMERA_FACTURA,
    MAX(f.FECHA_EMISION)           AS ULTIMA_FACTURA
FROM QS_CLIENTES    cl
LEFT JOIN QS_PAQUETES  p  ON p.ID_CLIENTE  = cl.ID_CLIENTE
LEFT JOIN QS_FACTURAS  f  ON f.ID_CLIENTE  = cl.ID_CLIENTE
LEFT JOIN QS_CIUDADES  ciud ON ciud.ID_CIUDAD = cl.ID_CIUDAD
WHERE cl.ACTIVO = 'S'
GROUP BY
    cl.ID_CLIENTE, cl.TIPO_PERSONA, cl.PRIMER_NOMBRE, cl.PRIMER_APELLIDO,
    cl.RAZON_SOCIAL, cl.EMAIL, cl.CELULAR, ciud.NOMBRE_CIUDAD;

COMMENT ON TABLE VW_RESUMEN_FINANCIERO_CLIENTE IS 'Resumen financiero consolidado por cliente';


-- ----------------------------------------------------------------
-- VISTA 9.5: Dashboard gerencial - KPIs diarios
-- ----------------------------------------------------------------
CREATE OR REPLACE VIEW VW_KPI_DIARIOS AS
SELECT
    TRUNC(SYSDATE)                        AS FECHA_HOY,
    -- Paquetes
    COUNT(CASE WHEN TRUNC(p.FECHA_REGISTRO) = TRUNC(SYSDATE) THEN 1 END)
                                          AS PKG_REGISTRADOS_HOY,
    COUNT(CASE WHEN p.ID_ESTADO_ACTUAL = 2 THEN 1 END)
                                          AS PKG_EN_CAMINO,
    COUNT(CASE WHEN p.ID_ESTADO_ACTUAL = 3
                    AND TRUNC(p.FECHA_ENTREGA_REAL) = TRUNC(SYSDATE) THEN 1 END)
                                          AS PKG_ENTREGADOS_HOY,
    COUNT(CASE WHEN p.ID_ESTADO_ACTUAL = 4 THEN 1 END)
                                          AS PKG_RETRASADOS,
    -- Financiero del dia
    NVL(SUM(CASE WHEN TRUNC(p.FECHA_REGISTRO) = TRUNC(SYSDATE) THEN p.COSTO_ENVIO END), 0)
                                          AS INGRESOS_HOY,
    -- Repartidores activos hoy
    (SELECT COUNT(DISTINCT ID_REPARTIDOR)
     FROM QS_ASIGNACIONES
     WHERE TRUNC(FECHA_ASIGNACION) = TRUNC(SYSDATE)) AS REPARTIDORES_ACTIVOS_HOY
FROM QS_PAQUETES p;

COMMENT ON TABLE VW_KPI_DIARIOS IS 'Vista de indicadores clave de rendimiento del dia actual';


-- ================================================================
-- SECCION 10: PROCEDIMIENTOS ALMACENADOS
-- ================================================================

-- ----------------------------------------------------------------
-- PROC 10.1: Registrar un nuevo paquete completo
-- ----------------------------------------------------------------
CREATE OR REPLACE PROCEDURE SP_REGISTRAR_PAQUETE (
    p_id_tipo          IN  QS_TIPOS_PAQUETE.ID_TIPO%TYPE,
    p_id_cliente       IN  QS_CLIENTES.ID_CLIENTE%TYPE,
    p_id_destinatario  IN  QS_DESTINATARIOS.ID_DESTINATARIO%TYPE,
    p_descripcion      IN  QS_PAQUETES.DESCRIPCION%TYPE,
    p_peso_kg          IN  QS_PAQUETES.PESO_KG%TYPE,
    p_id_tarifa        IN  QS_TARIFAS.ID_TARIFA%TYPE,
    p_fragil           IN  CHAR DEFAULT 'N',
    p_valor_declarado  IN  NUMBER DEFAULT 0,
    p_instrucciones    IN  VARCHAR2 DEFAULT NULL,
    -- Output: datos del paquete creado
    p_id_paquete       OUT QS_PAQUETES.ID_PAQUETE%TYPE,
    p_codigo_paquete   OUT QS_PAQUETES.CODIGO_PAQUETE%TYPE,
    p_costo_envio      OUT QS_PAQUETES.COSTO_ENVIO%TYPE,
    p_mensaje          OUT VARCHAR2
)
AS
/*
  DESCRIPCION: Registra un nuevo paquete y crea el primer evento de seguimiento.
  USO: EXEC SP_REGISTRAR_PAQUETE(1, 1, 1, 'Ropa', 0.5, 1, 'N', 50000, NULL, :v1, :v2, :v3, :v4);
*/
    v_precio_base   QS_TARIFAS.PRECIO_BASE%TYPE;
    v_precio_kg     QS_TARIFAS.PRECIO_KG%TYPE;
    v_aplica_iva    QS_TARIFAS.APLICA_IVA%TYPE;
    v_pct_iva       QS_TARIFAS.PORCENTAJE_IVA%TYPE;
    v_costo_base    NUMBER;
    v_costo_final   NUMBER;
    v_id_estado_ini NUMBER := 1;  -- 1 = EN PREPARACION
    v_peso_max      QS_TIPOS_PAQUETE.PESO_MAX_KG%TYPE;
BEGIN
    -- Validar que el tipo de paquete existe y el peso no excede el maximo
    SELECT PESO_MAX_KG INTO v_peso_max
    FROM QS_TIPOS_PAQUETE
    WHERE ID_TIPO = p_id_tipo AND ACTIVO = 'S';

    IF p_peso_kg > v_peso_max THEN
        RAISE_APPLICATION_ERROR(-20001,
            'El peso ' || p_peso_kg || ' kg supera el maximo del tipo (' || v_peso_max || ' kg)');
    END IF;

    -- Obtener tarifa vigente
    SELECT PRECIO_BASE, PRECIO_KG, APLICA_IVA, PORCENTAJE_IVA
    INTO v_precio_base, v_precio_kg, v_aplica_iva, v_pct_iva
    FROM QS_TARIFAS
    WHERE ID_TARIFA = p_id_tarifa
      AND ACTIVO    = 'S'
      AND FECHA_VIGENCIA <= TRUNC(SYSDATE)
      AND (FECHA_FIN IS NULL OR FECHA_FIN >= TRUNC(SYSDATE));

    -- Calcular costo
    v_costo_base  := v_precio_base + (p_peso_kg * v_precio_kg);
    IF v_aplica_iva = 'S' THEN
        v_costo_final := v_costo_base * (1 + (v_pct_iva / 100));
    ELSE
        v_costo_final := v_costo_base;
    END IF;

    p_costo_envio := ROUND(v_costo_final, 2);

    -- Insertar el paquete (el trigger TRG_PAQUETES_BI genera el ID y codigo)
    INSERT INTO QS_PAQUETES (
        ID_TIPO, ID_CLIENTE, ID_DESTINATARIO,
        DESCRIPCION, PESO_KG, FRAGIL,
        VALOR_DECLARADO, INSTRUCCIONES,
        ID_ESTADO_ACTUAL, ID_TARIFA, COSTO_ENVIO
    ) VALUES (
        p_id_tipo, p_id_cliente, p_id_destinatario,
        p_descripcion, p_peso_kg, p_fragil,
        NVL(p_valor_declarado, 0), p_instrucciones,
        v_id_estado_ini, p_id_tarifa, p_costo_envio
    ) RETURNING ID_PAQUETE, CODIGO_PAQUETE INTO p_id_paquete, p_codigo_paquete;

    -- Registrar el primer evento de seguimiento manualmente
    INSERT INTO QS_SEGUIMIENTO (
        ID_SEGUIMIENTO, ID_PAQUETE,
        ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO,
        DESCRIPCION_EVENTO, NOMBRE_USUARIO
    ) VALUES (
        SEQ_SEGUIMIENTO.NEXTVAL, p_id_paquete,
        NULL, v_id_estado_ini,
        'Paquete registrado en el sistema QuickSend. Codigo: ' || p_codigo_paquete,
        USER
    );

    COMMIT;
    p_mensaje := 'OK: Paquete registrado correctamente. Codigo: ' || p_codigo_paquete;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        p_mensaje := 'ERROR: Tarifa, tipo de paquete, cliente o destinatario no encontrado o inactivo.';
    WHEN OTHERS THEN
        ROLLBACK;
        p_mensaje := 'ERROR: ' || SQLERRM;
END SP_REGISTRAR_PAQUETE;
/


-- ----------------------------------------------------------------
-- PROC 10.2: Cambiar estado de un paquete
-- ----------------------------------------------------------------
CREATE OR REPLACE PROCEDURE SP_CAMBIAR_ESTADO_PAQUETE (
    p_id_paquete        IN  QS_PAQUETES.ID_PAQUETE%TYPE,
    p_nuevo_estado      IN  QS_ESTADOS_PAQUETE.CODIGO_ESTADO%TYPE,
    p_descripcion       IN  VARCHAR2,
    p_id_ciudad         IN  QS_CIUDADES.ID_CIUDAD%TYPE DEFAULT NULL,
    p_latitud           IN  NUMBER DEFAULT NULL,
    p_longitud          IN  NUMBER DEFAULT NULL,
    p_id_usuario        IN  NUMBER DEFAULT NULL,
    p_nombre_usuario    IN  VARCHAR2 DEFAULT NULL,
    p_mensaje           OUT VARCHAR2
)
AS
    v_id_estado_nuevo   QS_ESTADOS_PAQUETE.ID_ESTADO%TYPE;
    v_id_estado_actual  QS_PAQUETES.ID_ESTADO_ACTUAL%TYPE;
    v_es_final          QS_ESTADOS_PAQUETE.ES_FINAL%TYPE;
BEGIN
    -- Obtener ID del nuevo estado
    SELECT ID_ESTADO INTO v_id_estado_nuevo
    FROM QS_ESTADOS_PAQUETE
    WHERE CODIGO_ESTADO = UPPER(TRIM(p_nuevo_estado)) AND ACTIVO = 'S';

    -- Obtener estado actual del paquete
    SELECT ID_ESTADO_ACTUAL INTO v_id_estado_actual
    FROM QS_PAQUETES
    WHERE ID_PAQUETE = p_id_paquete
    FOR UPDATE;  -- Bloquear el registro para evitar condicion de carrera

    -- Verificar que el estado actual no sea ya final
    SELECT ES_FINAL INTO v_es_final
    FROM QS_ESTADOS_PAQUETE
    WHERE ID_ESTADO = v_id_estado_actual;

    IF v_es_final = 'S' THEN
        RAISE_APPLICATION_ERROR(-20010,
            'El paquete ya esta en un estado final y no puede cambiar.');
    END IF;

    IF v_id_estado_actual = v_id_estado_nuevo THEN
        RAISE_APPLICATION_ERROR(-20011,
            'El paquete ya se encuentra en el estado solicitado.');
    END IF;

    -- Actualizar el paquete (el trigger TRG_PAQUETES_SEGUIMIENTO registra el cambio)
    UPDATE QS_PAQUETES
    SET ID_ESTADO_ACTUAL = v_id_estado_nuevo
    WHERE ID_PAQUETE = p_id_paquete;

    -- Enriquecer el seguimiento con datos de ubicacion si se proporcionaron
    IF p_id_ciudad IS NOT NULL OR p_latitud IS NOT NULL THEN
        UPDATE QS_SEGUIMIENTO
        SET ID_CIUDAD      = p_id_ciudad,
            LATITUD        = p_latitud,
            LONGITUD       = p_longitud,
            DESCRIPCION_EVENTO = NVL(p_descripcion, DESCRIPCION_EVENTO),
            ID_USUARIO     = p_id_usuario,
            NOMBRE_USUARIO = NVL(p_nombre_usuario, NOMBRE_USUARIO)
        WHERE ID_SEGUIMIENTO = (
            SELECT MAX(ID_SEGUIMIENTO)
            FROM QS_SEGUIMIENTO
            WHERE ID_PAQUETE = p_id_paquete
        );
    END IF;

    -- Crear notificacion automatica para el cliente
    INSERT INTO QS_NOTIFICACIONES (
        ID_NOTIFICACION, ID_PAQUETE, ID_CLIENTE,
        TIPO_NOTIF, ASUNTO, MENSAJE
    )
    SELECT
        SEQ_NOTIFICACIONES.NEXTVAL,
        p_id_paquete,
        pk.ID_CLIENTE,
        'EMAIL',
        'QuickSend: Actualizacion de tu paquete ' || pk.CODIGO_PAQUETE,
        'Tu paquete ' || pk.CODIGO_PAQUETE || ' ha cambiado de estado a: ' ||
        (SELECT NOMBRE_ESTADO FROM QS_ESTADOS_PAQUETE WHERE ID_ESTADO = v_id_estado_nuevo) ||
        '. ' || NVL(p_descripcion, 'Consulta el seguimiento en la app.')
    FROM QS_PAQUETES pk
    WHERE pk.ID_PAQUETE = p_id_paquete;

    COMMIT;
    p_mensaje := 'OK: Estado actualizado exitosamente.';

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        p_mensaje := 'ERROR: Paquete o estado no encontrado.';
    WHEN OTHERS THEN
        ROLLBACK;
        p_mensaje := 'ERROR: ' || SQLERRM;
END SP_CAMBIAR_ESTADO_PAQUETE;
/


-- ----------------------------------------------------------------
-- PROC 10.3: Generar factura para un cliente
-- ----------------------------------------------------------------
CREATE OR REPLACE PROCEDURE SP_GENERAR_FACTURA (
    p_id_cliente    IN  QS_CLIENTES.ID_CLIENTE%TYPE,
    p_id_paquete    IN  QS_PAQUETES.ID_PAQUETE%TYPE,
    p_dias_vto      IN  NUMBER DEFAULT 30,
    p_id_factura    OUT QS_FACTURAS.ID_FACTURA%TYPE,
    p_numero        OUT QS_FACTURAS.NUMERO_FACTURA%TYPE,
    p_total         OUT QS_FACTURAS.TOTAL%TYPE,
    p_mensaje       OUT VARCHAR2
)
AS
    v_costo_envio   QS_PAQUETES.COSTO_ENVIO%TYPE;
    v_aplica_iva    QS_TARIFAS.APLICA_IVA%TYPE;
    v_pct_iva       QS_TARIFAS.PORCENTAJE_IVA%TYPE;
    v_subtotal      NUMBER;
    v_iva           NUMBER;
    v_total         NUMBER;
    v_cod_paquete   QS_PAQUETES.CODIGO_PAQUETE%TYPE;
    v_descripcion   QS_PAQUETES.DESCRIPCION%TYPE;
BEGIN
    -- Obtener datos del paquete
    SELECT pk.COSTO_ENVIO, pk.CODIGO_PAQUETE, pk.DESCRIPCION,
           t.APLICA_IVA, t.PORCENTAJE_IVA
    INTO v_costo_envio, v_cod_paquete, v_descripcion, v_aplica_iva, v_pct_iva
    FROM QS_PAQUETES pk
    JOIN QS_TARIFAS t ON t.ID_TARIFA = pk.ID_TARIFA
    WHERE pk.ID_PAQUETE = p_id_paquete
      AND pk.ID_CLIENTE = p_id_cliente;

    -- Calcular montos
    IF v_aplica_iva = 'S' THEN
        v_subtotal := ROUND(v_costo_envio / (1 + v_pct_iva/100), 2);
        v_iva      := ROUND(v_costo_envio - v_subtotal, 2);
    ELSE
        v_subtotal := v_costo_envio;
        v_iva      := 0;
    END IF;
    v_total    := v_subtotal + v_iva;
    p_total    := v_total;

    -- Crear la factura
    INSERT INTO QS_FACTURAS (
        ID_CLIENTE, FECHA_VENCIMIENTO,
        SUBTOTAL, BASE_GRAVABLE, IVA, TOTAL
    ) VALUES (
        p_id_cliente,
        TRUNC(SYSDATE) + p_dias_vto,
        v_subtotal, v_subtotal, v_iva, v_total
    ) RETURNING ID_FACTURA, NUMERO_FACTURA INTO p_id_factura, p_numero;

    -- Crear el detalle de la factura
    INSERT INTO QS_DETALLE_FACTURA (
        ID_FACTURA, ID_PAQUETE,
        DESCRIPCION_ITEM, CANTIDAD, PRECIO_UNITARIO
    ) VALUES (
        p_id_factura, p_id_paquete,
        'Servicio de envio - Paquete ' || v_cod_paquete || ': ' || v_descripcion,
        1, v_subtotal
    );

    COMMIT;
    p_mensaje := 'OK: Factura generada: ' || p_numero;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        p_mensaje := 'ERROR: Paquete no encontrado para el cliente indicado.';
    WHEN OTHERS THEN
        ROLLBACK;
        p_mensaje := 'ERROR: ' || SQLERRM;
END SP_GENERAR_FACTURA;
/


-- ================================================================
-- SECCION 11: FUNCIONES
-- ================================================================

-- ----------------------------------------------------------------
-- FUNC 11.1: Obtener nombre completo de cliente
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION FN_NOMBRE_CLIENTE (
    p_id_cliente IN QS_CLIENTES.ID_CLIENTE%TYPE
) RETURN VARCHAR2
AS
    v_nombre VARCHAR2(300);
BEGIN
    SELECT CASE TIPO_PERSONA
               WHEN 'N' THEN
                   TRIM(PRIMER_NOMBRE  || ' ' ||
                   NVL(SEGUNDO_NOMBRE  || ' ', '') ||
                   PRIMER_APELLIDO     || ' ' ||
                   NVL(SEGUNDO_APELLIDO, ''))
               WHEN 'J' THEN RAZON_SOCIAL
           END
    INTO v_nombre
    FROM QS_CLIENTES
    WHERE ID_CLIENTE = p_id_cliente;

    RETURN v_nombre;
EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN 'CLIENTE NO ENCONTRADO';
END FN_NOMBRE_CLIENTE;
/


-- ----------------------------------------------------------------
-- FUNC 11.2: Calcular dias habiles entre dos fechas
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION FN_DIAS_HABILES (
    p_fecha_inicio IN DATE,
    p_fecha_fin    IN DATE
) RETURN NUMBER
AS
    v_dias_habiles  NUMBER := 0;
    v_fecha_actual  DATE;
    v_dia_semana    NUMBER;
BEGIN
    v_fecha_actual := TRUNC(p_fecha_inicio);
    WHILE v_fecha_actual <= TRUNC(p_fecha_fin) LOOP
        v_dia_semana := TO_NUMBER(TO_CHAR(v_fecha_actual, 'D'));
        -- 1=Domingo, 7=Sabado en NLS_TERRITORY=COLOMBIA
        IF v_dia_semana NOT IN (1, 7) THEN
            v_dias_habiles := v_dias_habiles + 1;
        END IF;
        v_fecha_actual := v_fecha_actual + 1;
    END LOOP;
    RETURN v_dias_habiles;
END FN_DIAS_HABILES;
/


-- ----------------------------------------------------------------
-- FUNC 11.3: Obtener historial de un paquete como texto formateado
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION FN_HISTORIAL_PAQUETE (
    p_codigo_paquete IN VARCHAR2
) RETURN CLOB
AS
    v_resultado CLOB := EMPTY_CLOB();
    v_linea     VARCHAR2(500);
BEGIN
    DBMS_LOB.CREATETEMPORARY(v_resultado, TRUE);

    FOR reg IN (
        SELECT
            TO_CHAR(s.FECHA_EVENTO, 'DD/MM/YYYY HH24:MI')  AS FECHA_F,
            ep.NOMBRE_ESTADO                                 AS ESTADO,
            s.DESCRIPCION_EVENTO,
            NVL(c.NOMBRE_CIUDAD, 'Sin ubicacion')           AS CIUDAD
        FROM QS_SEGUIMIENTO     s
        JOIN QS_PAQUETES        p  ON p.ID_PAQUETE  = s.ID_PAQUETE
        JOIN QS_ESTADOS_PAQUETE ep ON ep.ID_ESTADO  = s.ID_ESTADO_NUEVO
        LEFT JOIN QS_CIUDADES   c  ON c.ID_CIUDAD   = s.ID_CIUDAD
        WHERE p.CODIGO_PAQUETE = UPPER(TRIM(p_codigo_paquete))
        ORDER BY s.FECHA_EVENTO ASC
    ) LOOP
        v_linea := '[' || reg.FECHA_F || '] ' || RPAD(reg.ESTADO, 20) ||
                   ' | ' || reg.CIUDAD || CHR(13) ||
                   '   ' || reg.DESCRIPCION_EVENTO || CHR(10);
        DBMS_LOB.WRITEAPPEND(v_resultado, LENGTH(v_linea), v_linea);
    END LOOP;

    RETURN v_resultado;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'Error al obtener historial: ' || SQLERRM;
END FN_HISTORIAL_PAQUETE;
/


-- ----------------------------------------------------------------
-- FUNC 11.4: Verificar si un paquete puede cambiar de estado
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION FN_PUEDE_CAMBIAR_ESTADO (
    p_id_paquete   IN NUMBER,
    p_nuevo_estado IN VARCHAR2
) RETURN VARCHAR2
AS
    v_estado_actual  VARCHAR2(20);
    v_es_final       CHAR(1);
    v_estado_nuevo   VARCHAR2(20);
BEGIN
    SELECT ep.CODIGO_ESTADO, ep.ES_FINAL
    INTO v_estado_actual, v_es_final
    FROM QS_PAQUETES pk
    JOIN QS_ESTADOS_PAQUETE ep ON ep.ID_ESTADO = pk.ID_ESTADO_ACTUAL
    WHERE pk.ID_PAQUETE = p_id_paquete;

    IF v_es_final = 'S' THEN
        RETURN 'NO: Estado actual es final (' || v_estado_actual || ')';
    END IF;

    SELECT CODIGO_ESTADO INTO v_estado_nuevo
    FROM QS_ESTADOS_PAQUETE
    WHERE CODIGO_ESTADO = UPPER(p_nuevo_estado) AND ACTIVO = 'S';

    IF v_estado_actual = v_estado_nuevo THEN
        RETURN 'NO: Ya esta en ese estado';
    END IF;

    RETURN 'SI';
EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN 'NO: Paquete o estado no encontrado';
    WHEN OTHERS        THEN RETURN 'ERROR: ' || SQLERRM;
END FN_PUEDE_CAMBIAR_ESTADO;
/


-- ================================================================
-- ================================================================
-- SECCION 12: ROLES Y SEGURIDAD
-- ================================================================
-- NOTA FREESQL: Los CREATE ROLE y GRANT requieren privilegios DBA.
-- En FreeSQL estos comandos no aplican (ya tienes tu propio esquema).
-- En un entorno Oracle real, ejecuta la seccion 12 como DBA.

-- SECCION 13: DATOS DE EJEMPLO (INSERTs)
-- ================================================================
/*
  Datos de ejemplo para probar el sistema.
  Seguimos el orden de dependencias (padres antes que hijos).
*/

-- ─── Tipos de documento ────────────────────────────────────────
INSERT INTO QS_TIPOS_DOCUMENTO VALUES (1, 'CC',  'Cedula de Ciudadania',     'COLOMBIA', 'S');
INSERT INTO QS_TIPOS_DOCUMENTO VALUES (2, 'NIT', 'NIT Empresa',              'COLOMBIA', 'S');
INSERT INTO QS_TIPOS_DOCUMENTO VALUES (3, 'CE',  'Cedula de Extranjeria',    'COLOMBIA', 'S');
INSERT INTO QS_TIPOS_DOCUMENTO VALUES (4, 'PA',  'Pasaporte',                'GENERAL',  'S');
INSERT INTO QS_TIPOS_DOCUMENTO VALUES (5, 'TI',  'Tarjeta de Identidad',     'COLOMBIA', 'S');

-- ─── Tipos de paquete ──────────────────────────────────────────
INSERT INTO QS_TIPOS_PAQUETE VALUES (1,'SOBRE','Sobre/Documento', 'Documentos hasta 0.5 kg', 0.500, 35, 25, 1, 'S', SYSTIMESTAMP);
INSERT INTO QS_TIPOS_PAQUETE VALUES (2,'CAJA_P','Caja Pequeña',   'Hasta 2 kg',              2.000, 20, 20, 20,'S', SYSTIMESTAMP);
INSERT INTO QS_TIPOS_PAQUETE VALUES (3,'CAJA_M','Caja Mediana',   'Hasta 10 kg',             10.00, 40, 30, 30,'S', SYSTIMESTAMP);
INSERT INTO QS_TIPOS_PAQUETE VALUES (4,'CAJA_G','Caja Grande',    'Hasta 30 kg',             30.00, 60, 50, 50,'S', SYSTIMESTAMP);
INSERT INTO QS_TIPOS_PAQUETE VALUES (5,'PALETA','Paleta/Palet',   'Hasta 500 kg',            500.0, 120,100,150,'S',SYSTIMESTAMP);

-- ─── Estados del paquete ───────────────────────────────────────
INSERT INTO QS_ESTADOS_PAQUETE VALUES (1,'EN_PREPARACION', 'En Preparacion', 'Paquete registrado, en proceso de alistamiento', '#FFA500','N','S',SYSTIMESTAMP);
INSERT INTO QS_ESTADOS_PAQUETE VALUES (2,'EN_CAMINO',      'En Camino',      'Paquete en transito hacia el destino',            '#007BFF','N','S',SYSTIMESTAMP);
INSERT INTO QS_ESTADOS_PAQUETE VALUES (3,'ENTREGADO',      'Entregado',      'Paquete entregado exitosamente al destinatario',  '#28A745','S','S',SYSTIMESTAMP);
INSERT INTO QS_ESTADOS_PAQUETE VALUES (4,'RETRASADO',      'Retrasado',      'Entrega demorada por inconvenientes en la ruta',  '#DC3545','N','S',SYSTIMESTAMP);
INSERT INTO QS_ESTADOS_PAQUETE VALUES (5,'CANCELADO',      'Cancelado',      'Envio cancelado por el cliente o el sistema',    '#6C757D','S','S',SYSTIMESTAMP);
INSERT INTO QS_ESTADOS_PAQUETE VALUES (6,'DEVUELTO',       'Devuelto',       'Paquete devuelto al remitente',                   '#795548','S','S',SYSTIMESTAMP);
INSERT INTO QS_ESTADOS_PAQUETE VALUES (7,'EN_BODEGA',      'En Bodega',      'Paquete retenido en bodega por falta de datos',   '#FF9800','N','S',SYSTIMESTAMP);

-- ─── Ciudades ──────────────────────────────────────────────────
INSERT INTO QS_CIUDADES VALUES (1,'11001','Bogota D.C.', 'Cundinamarca','COLOMBIA','110111','America/Bogota','S');
INSERT INTO QS_CIUDADES VALUES (2,'76001','Cali',        'Valle del Cauca','COLOMBIA','760001','America/Bogota','S');
INSERT INTO QS_CIUDADES VALUES (3,'05001','Medellin',    'Antioquia',    'COLOMBIA','050001','America/Bogota','S');
INSERT INTO QS_CIUDADES VALUES (4,'08001','Barranquilla','Atlantico',    'COLOMBIA','080001','America/Bogota','S');
INSERT INTO QS_CIUDADES VALUES (5,'13001','Cartagena',   'Bolivar',      'COLOMBIA','130001','America/Bogota','S');
INSERT INTO QS_CIUDADES VALUES (6,'17001','Manizales',   'Caldas',       'COLOMBIA','170001','America/Bogota','S');
INSERT INTO QS_CIUDADES VALUES (7,'63001','Armenia',     'Quindio',      'COLOMBIA','630001','America/Bogota','S');
INSERT INTO QS_CIUDADES VALUES (8,'66001','Pereira',     'Risaralda',    'COLOMBIA','660001','America/Bogota','S');

-- ─── Tarifas ───────────────────────────────────────────────────
INSERT INTO QS_TARIFAS VALUES (1,1,'Tarifa Sobre Nacional',      5000,  200,   0,   'S',19,DATE '2024-01-01',NULL,'S',SYSTIMESTAMP);
INSERT INTO QS_TARIFAS VALUES (2,2,'Tarifa Caja Pequeña Nacional',8000,  300, 500, 'S',19,DATE '2024-01-01',NULL,'S',SYSTIMESTAMP);
INSERT INTO QS_TARIFAS VALUES (3,3,'Tarifa Caja Mediana Nacional',15000, 400,1000, 'S',19,DATE '2024-01-01',NULL,'S',SYSTIMESTAMP);
INSERT INTO QS_TARIFAS VALUES (4,4,'Tarifa Caja Grande Nacional', 35000, 500,1500, 'S',19,DATE '2024-01-01',NULL,'S',SYSTIMESTAMP);
INSERT INTO QS_TARIFAS VALUES (5,2,'Tarifa Express Ciudad',       12000, 200, 500, 'S',19,DATE '2024-01-01',NULL,'S',SYSTIMESTAMP);

-- ─── Vehiculos ─────────────────────────────────────────────────
INSERT INTO QS_VEHICULOS VALUES (1,'ABC123','MOTO',     'Honda','CBF 150',2022,'Rojo',   10,  0.2,'DISPONIBLE',DATE '2025-06-01',DATE '2025-12-31','S',SYSTIMESTAMP);
INSERT INTO QS_VEHICULOS VALUES (2,'XYZ789','FURGON',   'Renault','Kangoo',2020,'Blanco',300, 2.0,'DISPONIBLE',DATE '2025-03-01',DATE '2025-08-31','S',SYSTIMESTAMP);
INSERT INTO QS_VEHICULOS VALUES (3,'PQR456','CAMION',   'Chevrolet','NHR', 2021,'Azul', 2000,15.0,'DISPONIBLE',DATE '2025-09-01',DATE '2025-11-30','S',SYSTIMESTAMP);
INSERT INTO QS_VEHICULOS VALUES (4,'LMN321','MOTO',     'Yamaha','FZ 150',2023,'Negro',  10,  0.2,'DISPONIBLE',DATE '2025-07-01',DATE '2026-01-31','S',SYSTIMESTAMP);

-- ─── Clientes ──────────────────────────────────────────────────
INSERT INTO QS_CLIENTES (
    ID_TIPO_DOC,NUM_DOCUMENTO,TIPO_PERSONA,PRIMER_NOMBRE,PRIMER_APELLIDO,
    SEGUNDO_APELLIDO,EMAIL,CELULAR,ID_CIUDAD,DIRECCION,BARRIO
) VALUES (1,'1234567890','N','JUAN','CARLOS','PEREZ','juan.perez@gmail.com',
          '3001234567',1,'Cra 15 # 85-30 Apto 301','Chapinero');

INSERT INTO QS_CLIENTES (
    ID_TIPO_DOC,NUM_DOCUMENTO,TIPO_PERSONA,PRIMER_NOMBRE,PRIMER_APELLIDO,
    EMAIL,CELULAR,ID_CIUDAD,DIRECCION,BARRIO
) VALUES (1,'0987654321','N','MARIA','RODRIGUEZ',
          'maria.rodriguez@hotmail.com','3159876543',2,'Cll 5 # 24-60','Granada');

INSERT INTO QS_CLIENTES (
    ID_TIPO_DOC,NUM_DOCUMENTO,TIPO_PERSONA,RAZON_SOCIAL,
    EMAIL,CELULAR,ID_CIUDAD,DIRECCION
) VALUES (2,'900123456-1','J','TECNOLOGIA AVANZADA S.A.S.',
          'envios@tecnavanzada.com','6016543210',1,'Cra 7 # 32-16 Piso 4, Edificio Trade Center');

-- ─── Destinatarios ─────────────────────────────────────────────
INSERT INTO QS_DESTINATARIOS (
    ID_TIPO_DOC,NUM_DOCUMENTO,NOMBRES,APELLIDOS,
    EMAIL,CELULAR,ID_CIUDAD,DIRECCION_ENTREGA,BARRIO,REFERENCIA_DIR
) VALUES (1,'5557778880','CARLOS ANDRES','MARTINEZ LOPEZ',
          'carlos.martinez@yahoo.com','3207654321',3,
          'Cll 10 # 43-55 Casa 12','Laureles',
          'Casa de dos pisos, fachada verde, porteria con intercom');

INSERT INTO QS_DESTINATARIOS (
    ID_TIPO_DOC,NUM_DOCUMENTO,NOMBRES,APELLIDOS,
    CELULAR,ID_CIUDAD,DIRECCION_ENTREGA,BARRIO
) VALUES (1,'6664449990','ANA LUCIA','GOMEZ VARGAS',
          '3112223334',2,'Av 6N # 25-10 Apto 502','San Antonio');

-- ─── Repartidores ──────────────────────────────────────────────
INSERT INTO QS_REPARTIDORES (
    ID_TIPO_DOC,NUM_DOCUMENTO,NOMBRES,APELLIDOS,
    EMAIL,CELULAR,NUM_LICENCIA,TIPO_LICENCIA,
    ID_CIUDAD_BASE,ID_VEHICULO_ASIG,FECHA_INGRESO
) VALUES (1,'11222333','PEDRO JOSE','SANCHEZ DIAZ',
          'pedro.sanchez@quicksend.com','3054441122',
          ' LIC-COL-001','A2',1,1,DATE '2023-03-15');

INSERT INTO QS_REPARTIDORES (
    ID_TIPO_DOC,NUM_DOCUMENTO,NOMBRES,APELLIDOS,
    EMAIL,CELULAR,NUM_LICENCIA,TIPO_LICENCIA,
    ID_CIUDAD_BASE,ID_VEHICULO_ASIG,FECHA_INGRESO
) VALUES (1,'44555666','LUISA FERNANDA','TORRES GARCIA',
          'luisa.torres@quicksend.com','3183332211',
          'LIC-COL-002','B1',2,2,DATE '2022-07-01');

-- ─── Rutas ─────────────────────────────────────────────────────
INSERT INTO QS_RUTAS VALUES (1,'RT-BOG-CAL','Bogota - Cali',        1,2,470,540,'ACTIVA',SYSTIMESTAMP,'S');
INSERT INTO QS_RUTAS VALUES (2,'RT-BOG-MED','Bogota - Medellin',    1,3,415,480,'ACTIVA',SYSTIMESTAMP,'S');
INSERT INTO QS_RUTAS VALUES (3,'RT-BOG-URB','Bogota Urbana Norte',  1,1, 30, 60,'ACTIVA',SYSTIMESTAMP,'S');
INSERT INTO QS_RUTAS VALUES (4,'RT-CAL-URB','Cali Urbana',          2,2, 25, 45,'ACTIVA',SYSTIMESTAMP,'S');

-- ─── Paquetes de ejemplo ───────────────────────────────────────
DECLARE
    v_id  NUMBER;
    v_cod VARCHAR2(25);
    v_cos NUMBER;
    v_msg VARCHAR2(500);
BEGIN
    SP_REGISTRAR_PAQUETE(2,1,1,'Libro de programacion Oracle y laptop usada',1.2,2,'N',1500000,NULL,v_id,v_cod,v_cos,v_msg);
    DBMS_OUTPUT.PUT_LINE('Paquete 1: '||v_msg||' | Codigo: '||v_cod||' | Costo: '||v_cos);

    SP_REGISTRAR_PAQUETE(1,2,2,'Documentos legales notariados',0.1,1,'N',0,'URGENTE - Documentos judiciales',v_id,v_cod,v_cos,v_msg);
    DBMS_OUTPUT.PUT_LINE('Paquete 2: '||v_msg||' | Codigo: '||v_cod||' | Costo: '||v_cos);

    SP_REGISTRAR_PAQUETE(3,3,1,'Equipos electronicos - 5 tablets',8.5,3,'S',12000000,'FRAGIL: No voltear, no golpear',v_id,v_cod,v_cos,v_msg);
    DBMS_OUTPUT.PUT_LINE('Paquete 3: '||v_msg||' | Codigo: '||v_cod||' | Costo: '||v_cos);
END;
/

-- ─── Asignar paquetes a repartidor ─────────────────────────────
INSERT INTO QS_ASIGNACIONES (
    ID_ASIGNACION,ID_PAQUETE,ID_REPARTIDOR,ID_RUTA,ID_VEHICULO,
    FECHA_ASIGNACION,ESTADO_ASIGNACION,ORDEN_ENTREGA
) VALUES (
    SEQ_ASIGNACIONES.NEXTVAL,1,1,3,1,
    SYSTIMESTAMP,'PENDIENTE',1
);

-- ─── Cambios de estado con seguimiento ─────────────────────────
DECLARE
    v_msg VARCHAR2(500);
BEGIN
    -- Paquete 1 sale a ruta
    SP_CAMBIAR_ESTADO_PAQUETE(1,'EN_CAMINO','Paquete recogido y en transito hacia el destinatario',1,4.6099,-74.0817,1,'Pedro Sanchez',v_msg);
    DBMS_OUTPUT.PUT_LINE('Cambio estado: '||v_msg);
END;
/

-- ─── Usuario administrador del sistema ─────────────────────────
INSERT INTO QS_USUARIOS_SISTEMA (
    ID_USUARIO, USERNAME, PASSWORD_HASH, SALT,
    NOMBRES, APELLIDOS, EMAIL, ROL_PRINCIPAL
) VALUES (
    SEQ_USUARIOS_SISTEMA.NEXTVAL,
    'admin_qs',
    -- Hash SHA256 de 'Admin@QuickSend2024' + salt (en produccion usar DBMS_CRYPTO)
    'a7f8b2c94e1d3f6a0bc2e8d14f9c7b3a1e5d8f2c6b0a4e9d3f7c1b5a8e2d6f4',
    'QS7f3K9mN2pL8vR5',
    'Administrador','Sistema','admin@quicksend.com','ADMIN'
);

COMMIT;


-- ================================================================
-- SECCION 14: CONSULTAS UTILES
-- ================================================================

-- ─── CONSULTA 14.1: Rastreo de un paquete por codigo ────────────
-- Uso: Reemplaza 'QS-2024-000001' con el codigo real
SELECT
    p.CODIGO_PAQUETE,
    FN_NOMBRE_CLIENTE(p.ID_CLIENTE)      AS REMITENTE,
    d.NOMBRES || ' ' || d.APELLIDOS      AS DESTINATARIO,
    d.DIRECCION_ENTREGA,
    c.NOMBRE_CIUDAD                      AS CIUDAD_DESTINO,
    ep.NOMBRE_ESTADO                     AS ESTADO_ACTUAL,
    p.FECHA_REGISTRO,
    p.FECHA_ENTREGA_EST,
    p.FECHA_ENTREGA_REAL,
    p.COSTO_ENVIO
FROM QS_PAQUETES        p
JOIN QS_DESTINATARIOS   d  ON d.ID_DESTINATARIO = p.ID_DESTINATARIO
JOIN QS_CIUDADES        c  ON c.ID_CIUDAD        = d.ID_CIUDAD
JOIN QS_ESTADOS_PAQUETE ep ON ep.ID_ESTADO       = p.ID_ESTADO_ACTUAL
WHERE p.CODIGO_PAQUETE = 'QS-2024-000001';


-- ─── CONSULTA 14.2: Historial completo de un paquete ───────────
SELECT * FROM VW_HISTORIAL_SEGUIMIENTO
WHERE CODIGO_PAQUETE = 'QS-2024-000001'
ORDER BY FECHA_EVENTO ASC;

-- Tambien usando la funcion:
-- SELECT FN_HISTORIAL_PAQUETE('QS-2024-000001') FROM DUAL;


-- ─── CONSULTA 14.3: Paquetes retrasados con datos de contacto ──
SELECT
    p.CODIGO_PAQUETE,
    FN_NOMBRE_CLIENTE(p.ID_CLIENTE)     AS REMITENTE,
    cl.CELULAR                          AS CELULAR_REMITENTE,
    d.NOMBRES || ' ' || d.APELLIDOS     AS DESTINATARIO,
    d.CELULAR                           AS CELULAR_DEST,
    p.FECHA_ENTREGA_EST,
    TRUNC(SYSDATE) - p.FECHA_ENTREGA_EST AS DIAS_RETRASO
FROM QS_PAQUETES       p
JOIN QS_CLIENTES       cl ON cl.ID_CLIENTE      = p.ID_CLIENTE
JOIN QS_DESTINATARIOS  d  ON d.ID_DESTINATARIO  = p.ID_DESTINATARIO
JOIN QS_ESTADOS_PAQUETE ep ON ep.ID_ESTADO      = p.ID_ESTADO_ACTUAL
WHERE ep.CODIGO_ESTADO IN ('EN_CAMINO','EN_PREPARACION','RETRASADO')
  AND p.FECHA_ENTREGA_EST < TRUNC(SYSDATE)
ORDER BY DIAS_RETRASO DESC;


-- ─── CONSULTA 14.4: Rendimiento de repartidores ────────────────
SELECT * FROM VW_REPARTIDORES_CARGA
ORDER BY PCT_EFICIENCIA DESC;


-- ─── CONSULTA 14.5: Ingresos por mes (reporte financiero) ──────
SELECT
    TO_CHAR(f.FECHA_EMISION, 'YYYY-MM')    AS MES,
    COUNT(*)                                AS NUM_FACTURAS,
    SUM(f.SUBTOTAL)                         AS SUBTOTAL,
    SUM(f.IVA)                              AS TOTAL_IVA,
    SUM(f.TOTAL)                            AS TOTAL_FACTURADO,
    SUM(CASE WHEN f.ESTADO_FACTURA = 'PAGADA'  THEN f.TOTAL ELSE 0 END) AS COBRADO,
    SUM(CASE WHEN f.ESTADO_FACTURA = 'VENCIDA' THEN f.TOTAL ELSE 0 END) AS POR_COBRAR
FROM QS_FACTURAS f
GROUP BY TO_CHAR(f.FECHA_EMISION, 'YYYY-MM')
ORDER BY MES DESC;


-- ─── CONSULTA 14.6: Top 10 clientes por volumen de envios ──────
SELECT * FROM (
    SELECT
        FN_NOMBRE_CLIENTE(ID_CLIENTE)   AS CLIENTE,
        MONTO_TOTAL_FACTURADO,
        TOTAL_PAQUETES,
        SALDO_PENDIENTE
    FROM VW_RESUMEN_FINANCIERO_CLIENTE
    ORDER BY TOTAL_PAQUETES DESC
) WHERE ROWNUM <= 10;


-- ─── CONSULTA 14.7: KPIs del dia ───────────────────────────────
SELECT * FROM VW_KPI_DIARIOS;


-- ─── CONSULTA 14.8: Auditoria - quién modifico un cliente ──────
SELECT
    TO_CHAR(FECHA_OPERACION,'DD/MM/YYYY HH24:MI:SS') AS FECHA,
    OPERACION,
    USUARIO_DB,
    USUARIO_APP,
    VALOR_ANTERIOR,
    VALOR_NUEVO
FROM QS_AUDITORIA
WHERE TABLA_AFECTADA = 'QS_CLIENTES'
  AND ID_REGISTRO    = '1'
ORDER BY FECHA_OPERACION DESC;


-- ─── CONSULTA 14.9: Paquetes por estado hoy ────────────────────
SELECT
    ep.NOMBRE_ESTADO,
    ep.COLOR_HEX,
    COUNT(p.ID_PAQUETE)     AS CANTIDAD,
    ROUND(COUNT(p.ID_PAQUETE) * 100.0 /
          NULLIF(SUM(COUNT(p.ID_PAQUETE)) OVER(), 0), 2) AS PORCENTAJE
FROM QS_PAQUETES        p
JOIN QS_ESTADOS_PAQUETE ep ON ep.ID_ESTADO = p.ID_ESTADO_ACTUAL
WHERE TRUNC(p.FECHA_REGISTRO) = TRUNC(SYSDATE)
GROUP BY ep.NOMBRE_ESTADO, ep.COLOR_HEX
ORDER BY CANTIDAD DESC;


-- ─── CONSULTA 14.10: Notificaciones pendientes de envio ────────
SELECT
    n.ID_NOTIFICACION,
    p.CODIGO_PAQUETE,
    n.TIPO_NOTIF,
    n.ASUNTO,
    n.INTENTOS,
    n.FECHA_CREACION
FROM QS_NOTIFICACIONES n
JOIN QS_PAQUETES       p ON p.ID_PAQUETE = n.ID_PAQUETE
WHERE n.ESTADO_NOTIF = 'PENDIENTE'
  AND n.INTENTOS     < 3
ORDER BY n.FECHA_CREACION ASC;


-- ================================================================
-- VERIFICACION FINAL DEL ESQUEMA
-- ================================================================
-- Contar objetos creados
SELECT
    OBJECT_TYPE,
    COUNT(*) AS CANTIDAD
FROM USER_OBJECTS
WHERE OBJECT_TYPE IN ('TABLE','INDEX','SEQUENCE','TRIGGER',
                      'VIEW','PROCEDURE','FUNCTION')
GROUP BY OBJECT_TYPE
ORDER BY OBJECT_TYPE;

-- Verificar tablas con numero de filas
SELECT
    TABLE_NAME,
    NUM_ROWS
FROM USER_TABLES
ORDER BY TABLE_NAME;

