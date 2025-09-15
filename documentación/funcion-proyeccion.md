# Propósito General
Calcula una proyección de cuántos estudiantes se matricularán en los próximos semestres para una institución y carrera específica, basándose en datos históricos.

# Parámetros de Entrada
```sql
p_institucion_id INTEGER    -- ID de la institución
p_carrera_id INTEGER        -- ID de la carrera  
p_next_n NUMBER DEFAULT 4   -- Número de semestres a proyectar (por defecto 4
```

# Valor de Retorno
- `proy_sem_t`: VARRAY con las proyecciones numéricas para cada semestre futuro

# Declaración de Variables
Variables principales:
```sql
v_resultado proy_sem_t := proy_sem_t();  -- VARRAY resultado (inicialmente vacío)
```

Estructura de datos para el cursor:
```sql
TYPE cnt_rec IS RECORD (
    anio SMALLINT, 
    semestre SMALLINT, 
    cnt NUMBER
);
```

Cursor para datos históricos:
```sql
CURSOR c_hist IS
    SELECT ANIO_INGRESO, SEMESTRE_INGRESO, COUNT(*) cnt
    FROM MATRICULAS
    WHERE INSTITUCION_ID = p_institucion_id
      AND CARRERA_ID = p_carrera_id
    GROUP BY ANIO_INGRESO, SEMESTRE_INGRESO
    ORDER BY ANIO_INGRESO DESC, SEMESTRE_INGRESO DESC;  -- Más reciente primero
```

Variables de trabajo:
```sql
v_counts SYS.ODCINUMBERLIST := SYS.ODCINUMBERLIST();  -- Lista temporal de conteos
idx INTEGER := 0;        -- Índice contador
v_last NUMBER := 0;      -- Conteo más reciente
v_prev NUMBER := 0;      -- Conteo anterior  
v_growth NUMBER := 0;    -- Tasa de crecimiento
```

# Lógica Principal
## Paso 1: Recolección de Datos Históricos
```sql
FOR r IN c_hist LOOP
    idx := idx + 1;
    v_counts.EXTEND;           -- Agregar espacio para nuevo elemento
    v_counts(idx) := r.cnt;    -- Guardar el conteo
    EXIT WHEN idx = 2;         -- Solo necesita los 2 más recientes
END LOOP;
```
¿Qué hace? Obtiene los 2 períodos más recientes de matrícula y sus cantidades.

## Paso 2: Análisis de Escenarios
### Escenario A: Sin historial (idx = 0)
```sql
IF idx = 0 THEN
    -- Proyección: todos ceros
    FOR i IN 1..p_next_n LOOP 
        v_resultado.EXTEND; 
        v_resultado(i) := 0; 
    END LOOP;
    RETURN v_resultado;
```

### Escenario B: Solo un período histórico (idx = 1)
```sql
ELSIF idx = 1 THEN
    -- Proyección: repetir el único valor
    FOR i IN 1..p_next_n LOOP 
        v_resultado.EXTEND; 
        v_resultado(i) := v_counts(1); 
    END LOOP;
    RETURN v_resultado;
```

### Escenario C: Dos o más períodos históricos (idx >= 2)
```sql
ELSE
    v_last := v_counts(1);  -- Período más reciente
    v_prev := v_counts(2);  -- Período anterior
    
    -- Calcular tasa de crecimiento
    IF v_prev = 0 THEN
        v_growth := 0;      -- Evitar división por cero
    ELSE
        v_growth := (v_last - v_prev) / v_prev;  -- Tasa porcentual
    END IF;
```

### Paso 3: Generación de Proyección
```sql
FOR i IN 1..p_next_n LOOP
    v_resultado.EXTEND;
    IF i = 1 THEN
        -- Primer semestre proyectado
        v_resultado(i) := ROUND(v_last * (1 + v_growth));
    ELSE
        -- Semestres subsiguientes (crecimiento compuesto)
        v_resultado(i) := ROUND(v_resultado(i-1) * (1 + v_growth));
    END IF;
END LOOP;
```

# Fórmula de Proyección
La función usa crecimiento compuesto:

```
Tasa_crecimiento = (Último_conteo - Conteo_anterior) / Conteo_anterior

Semestre_1 = Último_conteo × (1 + Tasa_crecimiento)
Semestre_2 = Semestre_1 × (1 + Tasa_crecimiento)
Semestre_3 = Semestre_2 × (1 + Tasa_crecimiento)
...y así sucesivamente
```

# Ejemplo Práctico
- Semestre anterior: 100 estudiantes
- Semestre más reciente: 120 estudiantes
- Proyección para 3 semestres

```
Crecimiento = (120 - 100) / 100 = 0.20 (20%)

Proyecciones:
- Semestre 1: 120 × (1 + 0.20) = 144
- Semestre 2: 144 × (1 + 0.20) = 173  
- Semestre 3: 173 × (1 + 0.20) = 207
```

# Manejo de Errores
```sql
EXCEPTION
  WHEN OTHERS THEN
    -- En caso de error, devolver vector de ceros
    v_resultado := proy_sem_t();
    FOR i IN 1..p_next_n LOOP 
        v_resultado.EXTEND; 
        v_resultado(i) := 0; 
    END LOOP;
    RETURN v_resultado;
```

La función es robusta y maneja todos los casos posibles, desde falta de datos hasta errores inesperados.