-- ======================================================================
-- PACKAGE: PKG_PROYECCION_RECURSOS
-- ======================================================================
-- Package para manejo de proyecciones de estudiantes y planificación de recursos
-- Integra funciones de proyección, cálculo de recursos y logging
-- ======================================================================

CREATE OR REPLACE PACKAGE PKG_PROYECCION_RECURSOS AS

  -- ====================================================================
  -- TIPOS DE DATOS
  -- ====================================================================
  
  -- Tipo VARRAY para almacenar proyecciones de semestres
  -- Se crea dinámicamente basado en la duración máxima de carreras
  -- Si no existe tabla carreras, usa tamaño por defecto de 50
  
  -- Tipo RECORD para resultados de proyección detallados
  TYPE t_proyeccion_detalle IS RECORD (
    institucion_id INTEGER,
    institucion_nombre VARCHAR2(200),
    carrera_id INTEGER,
    carrera_nombre VARCHAR2(200),
    semestre_label VARCHAR2(10),
    estudiantes_proyectados NUMBER,
    profesores_requeridos NUMBER,
    salas_requeridas NUMBER
  );
  
  -- Tipo TABLE para múltiples proyecciones
  TYPE t_proyecciones_tabla IS TABLE OF t_proyeccion_detalle;
  
  -- ====================================================================
  -- CONSTANTES PÚBLICAS
  -- ====================================================================
  
  -- Configuración por defecto
  C_DEFAULT_STUDENT_TEACHER_RATIO CONSTANT NUMBER := 30;
  C_DEFAULT_CLASSROOM_CAPACITY CONSTANT NUMBER := 40;
  C_MAX_SEMESTERS CONSTANT NUMBER := 50;
  C_MIN_SEMESTERS CONSTANT NUMBER := 1;
  C_MAX_PROYECCION_SEMESTERS CONSTANT NUMBER := 20;
  
  -- Severidades de logging
  C_LOG_INFO CONSTANT VARCHAR2(10) := 'INFO';
  C_LOG_WARNING CONSTANT VARCHAR2(10) := 'WARNING';
  C_LOG_ERROR CONSTANT VARCHAR2(10) := 'ERROR';
  C_LOG_CRITICAL CONSTANT VARCHAR2(10) := 'CRITICAL';
  
  -- ====================================================================
  -- EXCEPCIONES PÚBLICAS
  -- ====================================================================
  
  e_parametros_invalidos EXCEPTION;
  e_no_historial EXCEPTION;
  e_capacidad_excedida EXCEPTION;
  e_institucion_inexistente EXCEPTION;
  e_carrera_inexistente EXCEPTION;
  e_funcion_no_disponible EXCEPTION;
  e_datos_inconsistentes EXCEPTION;
  
  -- Códigos de error asociados
  PRAGMA EXCEPTION_INIT(e_parametros_invalidos, -20100);
  PRAGMA EXCEPTION_INIT(e_no_historial, -20101);
  PRAGMA EXCEPTION_INIT(e_capacidad_excedida, -20020);
  PRAGMA EXCEPTION_INIT(e_institucion_inexistente, -20022);
  PRAGMA EXCEPTION_INIT(e_carrera_inexistente, -20023);
  PRAGMA EXCEPTION_INIT(e_funcion_no_disponible, -20024);
  PRAGMA EXCEPTION_INIT(e_datos_inconsistentes, -20025);
  
  -- ====================================================================
  -- FUNCIONES PÚBLICAS
  -- ====================================================================
  
  -- Función principal de proyección de estudiantes
  FUNCTION proyeccion_estudiantes_para_prox_semestres(
    p_institucion_id INTEGER,
    p_carrera_id INTEGER,
    p_next_n NUMBER DEFAULT 4
  ) RETURN proy_sem_t;
  
  -- Función para calcular profesores requeridos
  FUNCTION profs_req(
    p_estudiantes NUMBER, 
    p_razon NUMBER DEFAULT C_DEFAULT_STUDENT_TEACHER_RATIO
  ) RETURN NUMBER;
  
  -- Función para calcular aulas requeridas
  FUNCTION classrooms_needed(
    p_estudiantes NUMBER, 
    p_sala_capacidad NUMBER DEFAULT C_DEFAULT_CLASSROOM_CAPACITY
  ) RETURN NUMBER;
  
  -- Función de logging centralizado
  FUNCTION log_error(
    p_severity VARCHAR2,
    p_source_obj VARCHAR2,
    p_error_msg VARCHAR2
  ) RETURN NUMBER;
  
  -- Función para validar existencia de institución
  FUNCTION institucion_exists(p_institucion_id INTEGER) RETURN BOOLEAN;
  
  -- Función para validar existencia de carrera
  FUNCTION carrera_exists(p_carrera_id INTEGER) RETURN BOOLEAN;
  
  -- Función para obtener capacidad de institución
  FUNCTION get_institucion_capacity(
    p_institucion_id INTEGER,
    p_capacidad_por_aula OUT NUMBER,
    p_salas_disponibles OUT NUMBER
  ) RETURN BOOLEAN;
  
  -- Función para calcular etiqueta de semestre
  FUNCTION calcular_semestre_label(
    p_base_anio NUMBER,
    p_base_semestre NUMBER,
    p_offset NUMBER
  ) RETURN VARCHAR2;
  
  -- ====================================================================
  -- PROCEDIMIENTOS PÚBLICOS
  -- ====================================================================
  
  -- Procedimiento principal para generar plan de recursos
  PROCEDURE build_plan_recursos(
    p_next_n NUMBER DEFAULT 4,
    p_institucion_id NUMBER DEFAULT NULL,
    p_carrera_id NUMBER DEFAULT NULL,
    p_region_id NUMBER DEFAULT NULL
  );
  
  -- Procedimiento para limpiar datos antiguos
  PROCEDURE limpiar_planes_antiguos(p_dias_antiguedad NUMBER DEFAULT 30);
  
  -- Procedimiento para generar reporte de capacidad
  PROCEDURE generar_reporte_capacidad(
    p_institucion_id NUMBER DEFAULT NULL,
    p_mostrar_detalles BOOLEAN DEFAULT TRUE
  );
  
  -- Procedimiento para inicializar configuración por defecto
  PROCEDURE inicializar_configuracion;
  
  -- Procedimiento para verificar capacidad antes de insertar matrícula
  -- (usado por trigger trg_matriculas_check_capacidad)
  PROCEDURE verificar_capacidad_matricula(
    p_institucion_id INTEGER,
    p_carrera_id INTEGER,
    p_anio_ingreso INTEGER,
    p_semestre_ingreso INTEGER
  );
  
  -- ====================================================================
  -- FUNCIONES DE CONSULTA PÚBLICA
  -- ====================================================================
  
  -- Obtener proyecciones como tabla pipelined
  FUNCTION get_proyecciones_tabla(
    p_institucion_id INTEGER DEFAULT NULL,
    p_carrera_id INTEGER DEFAULT NULL,
    p_next_n NUMBER DEFAULT 4
  ) RETURN t_proyecciones_tabla PIPELINED;
  
  -- Obtener estadísticas de uso del package
  FUNCTION get_package_stats RETURN VARCHAR2;
  
  -- ====================================================================
  -- FUNCIONES PARA MANEJO DE VARRAY DINÁMICO
  -- ====================================================================
  
  -- Crear o recrear el tipo VARRAY proy_sem_t dinámicamente
  PROCEDURE crear_varray_dinamico;
  
  -- Obtener el tamaño máximo del VARRAY basado en duración de carreras
  FUNCTION get_max_duracion_carreras RETURN NUMBER;
  
  -- Verificar si el tipo proy_sem_t existe y es del tamaño adecuado
  FUNCTION verificar_varray_existente RETURN BOOLEAN;
  
END PKG_PROYECCION_RECURSOS;
/