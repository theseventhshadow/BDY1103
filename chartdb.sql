{
    "fk_info": [
        {
            "schema": "AMUNOZ",
            "table": "CARRERAS",
            "column": "NIVEL_CARRERA_ID",
            "foreign_key_name": "FK_CARRERAS_NIVELES_CARRERA",
            "reference_schema": "AMUNOZ",
            "reference_table": "NIVELES_CARRERA",
            "reference_column": "NIVEL_CARRERA_ID",
            "fk_def": "FOREIGN KEY (NIVEL_CARRERA_ID) REFERENCES NIVELES_CARRERA(NIVEL_CARRERA_ID) ON DELETE NO ACTION"
        },
        {
            "schema": "AMUNOZ",
            "table": "CARRERAS",
            "column": "AREA_CONOCIMIENTO_ID",
            "foreign_key_name": "FK_CARRERAS_AREAS_CONOCIMIENTO",
            "reference_schema": "AMUNOZ",
            "reference_table": "AREAS_CONOCIMIENTO",
            "reference_column": "AREA_CONOCIMIENTO_ID",
            "fk_def": "FOREIGN KEY (AREA_CONOCIMIENTO_ID) REFERENCES AREAS_CONOCIMIENTO(AREA_CONOCIMIENTO_ID) ON DELETE NO ACTION"
        },
        {
            "schema": "AMUNOZ",
            "table": "CARRERAS",
            "column": "REQUISITO_INGRESO_ID",
            "foreign_key_name": "FK_CARRERAS_REQUISITOS_INGRESO",
            "reference_schema": "AMUNOZ",
            "reference_table": "REQUISITOS_INGRESO",
            "reference_column": "REQUISITO_INGRESO_ID",
            "fk_def": "FOREIGN KEY (REQUISITO_INGRESO_ID) REFERENCES REQUISITOS_INGRESO(REQUISITO_INGRESO_ID) ON DELETE NO ACTION"
        },
        {
            "schema": "AMUNOZ",
            "table": "CARRERAS",
            "column": "MODALIDAD_ID",
            "foreign_key_name": "FK_CARRERAS_MODALIDADES",
            "reference_schema": "AMUNOZ",
            "reference_table": "MODALIDADES",
            "reference_column": "MODALIDAD_ID",
            "fk_def": "FOREIGN KEY (MODALIDAD_ID) REFERENCES MODALIDADES(MODALIDAD_ID) ON DELETE NO ACTION"
        },
        {
            "schema": "AMUNOZ",
            "table": "CARRERAS",
            "column": "JORNADA_ID",
            "foreign_key_name": "FK_CARRERAS_JORNADAS",
            "reference_schema": "AMUNOZ",
            "reference_table": "JORNADAS",
            "reference_column": "JORNADA_ID",
            "fk_def": "FOREIGN KEY (JORNADA_ID) REFERENCES JORNADAS(JORNADA_ID) ON DELETE NO ACTION"
        },
        {
            "schema": "AMUNOZ",
            "table": "CARRERAS",
            "column": "TIPO_PLAN_ID",
            "foreign_key_name": "FK_CARRERAS_TIPOS_PLAN",
            "reference_schema": "AMUNOZ",
            "reference_table": "TIPOS_PLAN",
            "reference_column": "TIPO_PLAN_ID",
            "fk_def": "FOREIGN KEY (TIPO_PLAN_ID) REFERENCES TIPOS_PLAN(TIPO_PLAN_ID) ON DELETE NO ACTION"
        },
        {
            "schema": "AMUNOZ",
            "table": "PROVINCIAS",
            "column": "REGION_ID",
            "foreign_key_name": "FK_PROVINCIAS_REGIONES",
            "reference_schema": "AMUNOZ",
            "reference_table": "REGIONES",
            "reference_column": "REGION_ID",
            "fk_def": "FOREIGN KEY (REGION_ID) REFERENCES REGIONES(REGION_ID) ON DELETE NO ACTION"
        },
        {
            "schema": "AMUNOZ",
            "table": "COMUNAS",
            "column": "REGION_ID",
            "foreign_key_name": "FK_COMUNAS_REGIONES",
            "reference_schema": "AMUNOZ",
            "reference_table": "REGIONES",
            "reference_column": "REGION_ID",
            "fk_def": "FOREIGN KEY (REGION_ID) REFERENCES REGIONES(REGION_ID) ON DELETE NO ACTION"
        },
        {
            "schema": "AMUNOZ",
            "table": "COMUNAS",
            "column": "PROVINCIA_ID",
            "foreign_key_name": "FK_COMUNAS_PROVINCIAS",
            "reference_schema": "AMUNOZ",
            "reference_table": "PROVINCIAS",
            "reference_column": "PROVINCIA_ID",
            "fk_def": "FOREIGN KEY (PROVINCIA_ID) REFERENCES PROVINCIAS(PROVINCIA_ID) ON DELETE NO ACTION"
        },
        {
            "schema": "AMUNOZ",
            "table": "MATRICULAS",
            "column": "COMUNA_ID",
            "foreign_key_name": "FK_MATRICULAS_COMUNAS",
            "reference_schema": "AMUNOZ",
            "reference_table": "COMUNAS",
            "reference_column": "COMUNA_ID",
            "fk_def": "FOREIGN KEY (COMUNA_ID) REFERENCES COMUNAS(COMUNA_ID) ON DELETE NO ACTION"
        },
        {
            "schema": "AMUNOZ",
            "table": "NIVELES_CARRERA",
            "column": "TIPO_EDUCACION_ID",
            "foreign_key_name": "FK_NIVELES_CARRERA_TIPOS_EDUCACION",
            "reference_schema": "AMUNOZ",
            "reference_table": "TIPOS_EDUCACION",
            "reference_column": "TIPO_EDUCACION_ID",
            "fk_def": "FOREIGN KEY (TIPO_EDUCACION_ID) REFERENCES TIPOS_EDUCACION(TIPO_EDUCACION_ID) ON DELETE NO ACTION"
        },
        {
            "schema": "AMUNOZ",
            "table": "NIVELES_CARRERA",
            "column": "NIVEL_FORMACION_ID",
            "foreign_key_name": "FK_NIVELES_CARRERA_NIVELES_FORMACION",
            "reference_schema": "AMUNOZ",
            "reference_table": "NIVELES_FORMACION",
            "reference_column": "NIVEL_FORMACION_ID",
            "fk_def": "FOREIGN KEY (NIVEL_FORMACION_ID) REFERENCES NIVELES_FORMACION(NIVEL_FORMACION_ID) ON DELETE NO ACTION"
        },
        {
            "schema": "AMUNOZ",
            "table": "MATRICULAS",
            "column": "CARRERA_ID",
            "foreign_key_name": "FK_MATRICULAS_CARRERAS",
            "reference_schema": "AMUNOZ",
            "reference_table": "CARRERAS",
            "reference_column": "CARRERA_ID",
            "fk_def": "FOREIGN KEY (CARRERA_ID) REFERENCES CARRERAS(CARRERA_ID) ON DELETE NO ACTION"
        },
        {
            "schema": "AMUNOZ",
            "table": "INSTITUCIONES",
            "column": "ACREDITACION_ID",
            "foreign_key_name": "FK_INSTITUCIONES_TIPOS_ACREDITACION",
            "reference_schema": "AMUNOZ",
            "reference_table": "TIPOS_ACREDITACION",
            "reference_column": "TIPO_ACREDITACION_ID",
            "fk_def": "FOREIGN KEY (ACREDITACION_ID) REFERENCES TIPOS_ACREDITACION(TIPO_ACREDITACION_ID) ON DELETE NO ACTION"
        },
        {
            "schema": "AMUNOZ",
            "table": "INSTITUCIONES",
            "column": "TIPO_INSTITUCION_ID",
            "foreign_key_name": "FK_INSTITUCIONES_TIPOS_INSTITUCION",
            "reference_schema": "AMUNOZ",
            "reference_table": "TIPOS_INSTITUCION",
            "reference_column": "TIPO_INSTITUCION_ID",
            "fk_def": "FOREIGN KEY (TIPO_INSTITUCION_ID) REFERENCES TIPOS_INSTITUCION(TIPO_INSTITUCION_ID) ON DELETE NO ACTION"
        },
        {
            "schema": "AMUNOZ",
            "table": "MATRICULAS",
            "column": "INSTITUCION_ID",
            "foreign_key_name": "FK_MATRICULAS_INSTITUCIONES",
            "reference_schema": "AMUNOZ",
            "reference_table": "INSTITUCIONES",
            "reference_column": "INSTITUCION_ID",
            "fk_def": "FOREIGN KEY (INSTITUCION_ID) REFERENCES INSTITUCIONES(INSTITUCION_ID) ON DELETE NO ACTION"
        },
        {
            "schema": "AMUNOZ",
            "table": "MATRICULAS",
            "column": "VIA_INGRESO_ID",
            "foreign_key_name": "FK_MATRICULAS_VIAS_INGRESO",
            "reference_schema": "AMUNOZ",
            "reference_table": "VIAS_INGRESO",
            "reference_column": "VIA_INGRESO_ID",
            "fk_def": "FOREIGN KEY (VIA_INGRESO_ID) REFERENCES VIAS_INGRESO(VIA_INGRESO_ID) ON DELETE NO ACTION"
        },
        {
            "schema": "AMUNOZ",
            "table": "MATRICULAS",
            "column": "RANGO_EDAD_ID",
            "foreign_key_name": "FK_MATRICULAS_RANGOS_EDAD",
            "reference_schema": "AMUNOZ",
            "reference_table": "RANGOS_EDAD",
            "reference_column": "RANGO_EDAD_ID",
            "fk_def": "FOREIGN KEY (RANGO_EDAD_ID) REFERENCES RANGOS_EDAD(RANGO_EDAD_ID) ON DELETE NO ACTION"
        }
    ],
    "pk_info": [
        {
            "schema": "AMUNOZ",
            "table": "COMUNAS",
            "column": "COMUNA_ID",
            "pk_def": "PRIMARY KEY (COMUNA_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "GENEROS",
            "column": "GENERO_ID",
            "pk_def": "PRIMARY KEY (GENERO_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "JORNADAS",
            "column": "JORNADA_ID",
            "pk_def": "PRIMARY KEY (JORNADA_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "MATRICULAS",
            "column": "MATRICULA_ID",
            "pk_def": "PRIMARY KEY (MATRICULA_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "PROVINCIAS",
            "column": "PROVINCIA_ID",
            "pk_def": "PRIMARY KEY (PROVINCIA_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "MODALIDADES",
            "column": "MODALIDAD_ID",
            "pk_def": "PRIMARY KEY (MODALIDAD_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "NIVELES_CARRERA",
            "column": "NIVEL_CARRERA_ID",
            "pk_def": "PRIMARY KEY (NIVEL_CARRERA_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "TIPOS_EDUCACION",
            "column": "TIPO_EDUCACION_ID",
            "pk_def": "PRIMARY KEY (TIPO_EDUCACION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "TIPOS_INSTITUCION",
            "column": "TIPO_INSTITUCION_ID",
            "pk_def": "PRIMARY KEY (TIPO_INSTITUCION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "REQUISITOS_INGRESO",
            "column": "REQUISITO_INGRESO_ID",
            "pk_def": "PRIMARY KEY (REQUISITO_INGRESO_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "TIPOS_ACREDITACION",
            "column": "TIPO_ACREDITACION_ID",
            "pk_def": "PRIMARY KEY (TIPO_ACREDITACION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PrmNCyQupajgY6xeAAoY/g==$0",
            "column": "REGION_ID",
            "pk_def": "PRIMARY KEY (REGION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PrmNCyRIpajgY6xeAAoY/g==$0",
            "column": "CARRERA_NIVEL_ID",
            "pk_def": "PRIMARY KEY (CARRERA_NIVEL_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PrmNCyRcpajgY6xeAAoY/g==$0",
            "column": "COMUNA_ID",
            "pk_def": "PRIMARY KEY (COMUNA_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PrmNCyRkpajgY6xeAAoY/g==$0",
            "column": "PROVINCIA_ID",
            "pk_def": "PRIMARY KEY (PROVINCIA_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PrmNCyRspajgY6xeAAoY/g==$0",
            "column": "REGION_ID",
            "pk_def": "PRIMARY KEY (REGION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PrmNCyS8pajgY6xeAAoY/g==$0",
            "column": "RANGO_EDAD_ID",
            "pk_def": "PRIMARY KEY (RANGO_EDAD_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PrmNCySIpajgY6xeAAoY/g==$0",
            "column": "REQUISITO_INGRESO_ID",
            "pk_def": "PRIMARY KEY (REQUISITO_INGRESO_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PrmNCySPpajgY6xeAAoY/g==$0",
            "column": "MODALIDAD_ID",
            "pk_def": "PRIMARY KEY (MODALIDAD_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PrmNCySWpajgY6xeAAoY/g==$0",
            "column": "JORNADA_ID",
            "pk_def": "PRIMARY KEY (JORNADA_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PrmNCySrpajgY6xeAAoY/g==$0",
            "column": "TIPO_INSTITUCION_ID",
            "pk_def": "PRIMARY KEY (TIPO_INSTITUCION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PrmNCySypajgY6xeAAoY/g==$0",
            "column": "VIA_INGRESO_ID",
            "pk_def": "PRIMARY KEY (VIA_INGRESO_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PrmNCyTDpajgY6xeAAoY/g==$0",
            "column": "GENERO_ID",
            "pk_def": "PRIMARY KEY (GENERO_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PsUJAZg2USvgY6xeAAofwA==$0",
            "column": "CARRERA_NIVEL_ID",
            "pk_def": "PRIMARY KEY (CARRERA_NIVEL_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PsUJAZgcUSvgY6xeAAofwA==$0",
            "column": "MATRICULA_ID",
            "pk_def": "PRIMARY KEY (MATRICULA_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PsUJAZguUSvgY6xeAAofwA==$0",
            "column": "CARRERA_ID",
            "pk_def": "PRIMARY KEY (CARRERA_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PsUJAZh2USvgY6xeAAofwA==$0",
            "column": "REQUISITO_INGRESO_ID",
            "pk_def": "PRIMARY KEY (REQUISITO_INGRESO_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PsUJAZhKUSvgY6xeAAofwA==$0",
            "column": "COMUNA_ID",
            "pk_def": "PRIMARY KEY (COMUNA_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PsUJAZhSUSvgY6xeAAofwA==$0",
            "column": "PROVINCIA_ID",
            "pk_def": "PRIMARY KEY (PROVINCIA_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PsUJAZhaUSvgY6xeAAofwA==$0",
            "column": "REGION_ID",
            "pk_def": "PRIMARY KEY (REGION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PsUJAZhhUSvgY6xeAAofwA==$0",
            "column": "TIPO_EDUCACION_ID",
            "pk_def": "PRIMARY KEY (TIPO_EDUCACION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PsUJAZi5USvgY6xeAAofwA==$0",
            "column": "CARRERA_NIVEL_ID",
            "pk_def": "PRIMARY KEY (CARRERA_NIVEL_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PsUJAZiEUSvgY6xeAAofwA==$0",
            "column": "JORNADA_ID",
            "pk_def": "PRIMARY KEY (JORNADA_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PsUJAZiSUSvgY6xeAAofwA==$0",
            "column": "TIPO_ACREDITACION_ID",
            "pk_def": "PRIMARY KEY (TIPO_ACREDITACION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PsUJAZiZUSvgY6xeAAofwA==$0",
            "column": "TIPO_INSTITUCION_ID",
            "pk_def": "PRIMARY KEY (TIPO_INSTITUCION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PsUJAZigUSvgY6xeAAofwA==$0",
            "column": "VIA_INGRESO_ID",
            "pk_def": "PRIMARY KEY (VIA_INGRESO_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$Pshk8GkkupbgY3RYAArJ9w==$0",
            "column": "INSTITUCION_ID",
            "pk_def": "PRIMARY KEY (INSTITUCION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$Pshk8GkrupbgY3RYAArJ9w==$0",
            "column": "TIPO_ACREDITACION_ID",
            "pk_def": "PRIMARY KEY (TIPO_ACREDITACION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PsiR4+UO3XngY3RYAApsGQ==$0",
            "column": "TIPO_ACREDITACION_ID",
            "pk_def": "PRIMARY KEY (TIPO_ACREDITACION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$Psm4m6iUysXgY3RYAAr/HQ==$0",
            "column": "INSTITUCION_ID",
            "pk_def": "PRIMARY KEY (INSTITUCION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkE5T3bgY3RYAAqkhg==$0",
            "column": "MODALIDAD_ID",
            "pk_def": "PRIMARY KEY (MODALIDAD_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkEGT3bgY3RYAAqkhg==$0",
            "column": "COMUNA_ID",
            "pk_def": "PRIMARY KEY (COMUNA_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkEOT3bgY3RYAAqkhg==$0",
            "column": "PROVINCIA_ID",
            "pk_def": "PRIMARY KEY (PROVINCIA_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkEWT3bgY3RYAAqkhg==$0",
            "column": "REGION_ID",
            "pk_def": "PRIMARY KEY (REGION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkErT3bgY3RYAAqkhg==$0",
            "column": "AREA_CONOCIMIENTO_ID",
            "pk_def": "PRIMARY KEY (AREA_CONOCIMIENTO_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkF5T3bgY3RYAAqkhg==$0",
            "column": "MATRICULA_ID",
            "pk_def": "PRIMARY KEY (MATRICULA_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkFHT3bgY3RYAAqkhg==$0",
            "column": "TIPO_PLAN_ID",
            "pk_def": "PRIMARY KEY (TIPO_PLAN_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkFVT3bgY3RYAAqkhg==$0",
            "column": "TIPO_INSTITUCION_ID",
            "pk_def": "PRIMARY KEY (TIPO_INSTITUCION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkFcT3bgY3RYAAqkhg==$0",
            "column": "VIA_INGRESO_ID",
            "pk_def": "PRIMARY KEY (VIA_INGRESO_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkFmT3bgY3RYAAqkhg==$0",
            "column": "RANGO_EDAD_ID",
            "pk_def": "PRIMARY KEY (RANGO_EDAD_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkFtT3bgY3RYAAqkhg==$0",
            "column": "GENERO_ID",
            "pk_def": "PRIMARY KEY (GENERO_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkG6T3bgY3RYAAqkhg==$0",
            "column": "TIPO_EDUCACION_ID",
            "pk_def": "PRIMARY KEY (TIPO_EDUCACION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkGRT3bgY3RYAAqkhg==$0",
            "column": "NIVEL_CARRERA_ID",
            "pk_def": "PRIMARY KEY (NIVEL_CARRERA_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkGaT3bgY3RYAAqkhg==$0",
            "column": "INSTITUCION_ID",
            "pk_def": "PRIMARY KEY (INSTITUCION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkGjT3bgY3RYAAqkhg==$0",
            "column": "COMUNA_ID",
            "pk_def": "PRIMARY KEY (COMUNA_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkGrT3bgY3RYAAqkhg==$0",
            "column": "PROVINCIA_ID",
            "pk_def": "PRIMARY KEY (PROVINCIA_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkHWT3bgY3RYAAqkhg==$0",
            "column": "MODALIDAD_ID",
            "pk_def": "PRIMARY KEY (MODALIDAD_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkHdT3bgY3RYAAqkhg==$0",
            "column": "JORNADA_ID",
            "pk_def": "PRIMARY KEY (JORNADA_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkHrT3bgY3RYAAqkhg==$0",
            "column": "TIPO_ACREDITACION_ID",
            "pk_def": "PRIMARY KEY (TIPO_ACREDITACION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkHyT3bgY3RYAAqkhg==$0",
            "column": "TIPO_INSTITUCION_ID",
            "pk_def": "PRIMARY KEY (TIPO_INSTITUCION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkIKT3bgY3RYAAqkhg==$0",
            "column": "GENERO_ID",
            "pk_def": "PRIMARY KEY (GENERO_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "CARRERAS",
            "column": "CARRERA_ID",
            "pk_def": "PRIMARY KEY (CARRERA_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "REGIONES",
            "column": "REGION_ID",
            "pk_def": "PRIMARY KEY (REGION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "TIPOS_PLAN",
            "column": "TIPO_PLAN_ID",
            "pk_def": "PRIMARY KEY (TIPO_PLAN_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "RANGOS_EDAD",
            "column": "RANGO_EDAD_ID",
            "pk_def": "PRIMARY KEY (RANGO_EDAD_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "VIAS_INGRESO",
            "column": "VIA_INGRESO_ID",
            "pk_def": "PRIMARY KEY (VIA_INGRESO_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "INSTITUCIONES",
            "column": "INSTITUCION_ID",
            "pk_def": "PRIMARY KEY (INSTITUCION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "NIVELES_FORMACION",
            "column": "NIVEL_FORMACION_ID",
            "pk_def": "PRIMARY KEY (NIVEL_FORMACION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "AREAS_CONOCIMIENTO",
            "column": "AREA_CONOCIMIENTO_ID",
            "pk_def": "PRIMARY KEY (AREA_CONOCIMIENTO_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PrmNCyR6pajgY6xeAAoY/g==$0",
            "column": "NIVEL_FORMACION_ID",
            "pk_def": "PRIMARY KEY (NIVEL_FORMACION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PrmNCyRApajgY6xeAAoY/g==$0",
            "column": "CARRERA_ID",
            "pk_def": "PRIMARY KEY (CARRERA_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PrmNCyRTpajgY6xeAAoY/g==$0",
            "column": "INSTITUCION_ID",
            "pk_def": "PRIMARY KEY (INSTITUCION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PrmNCyRzpajgY6xeAAoY/g==$0",
            "column": "TIPO_EDUCACION_ID",
            "pk_def": "PRIMARY KEY (TIPO_EDUCACION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PrmNCySBpajgY6xeAAoY/g==$0",
            "column": "AREA_CONOCIMIENTO_ID",
            "pk_def": "PRIMARY KEY (AREA_CONOCIMIENTO_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PrmNCySdpajgY6xeAAoY/g==$0",
            "column": "TIPO_PLAN_ID",
            "pk_def": "PRIMARY KEY (TIPO_PLAN_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PrmNCySkpajgY6xeAAoY/g==$0",
            "column": "TIPO_ACREDITACION_ID",
            "pk_def": "PRIMARY KEY (TIPO_ACREDITACION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$Ps4Pnau1W9vgY3RYAAoSQQ==$0",
            "column": "CARRERA_ID",
            "pk_def": "PRIMARY KEY (CARRERA_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$Ps5PEVK6j+/gY3RYAAqiqw==$0",
            "column": "CARRERA_ID",
            "pk_def": "PRIMARY KEY (CARRERA_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PsUJAZh9USvgY6xeAAofwA==$0",
            "column": "MODALIDAD_ID",
            "pk_def": "PRIMARY KEY (MODALIDAD_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PsUJAZhBUSvgY6xeAAofwA==$0",
            "column": "INSTITUCION_ID",
            "pk_def": "PRIMARY KEY (INSTITUCION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PsUJAZhoUSvgY6xeAAofwA==$0",
            "column": "NIVEL_FORMACION_ID",
            "pk_def": "PRIMARY KEY (NIVEL_FORMACION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PsUJAZhvUSvgY6xeAAofwA==$0",
            "column": "AREA_CONOCIMIENTO_ID",
            "pk_def": "PRIMARY KEY (AREA_CONOCIMIENTO_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PsUJAZiLUSvgY6xeAAofwA==$0",
            "column": "TIPO_PLAN_ID",
            "pk_def": "PRIMARY KEY (TIPO_PLAN_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PsUJAZiqUSvgY6xeAAofwA==$0",
            "column": "RANGO_EDAD_ID",
            "pk_def": "PRIMARY KEY (RANGO_EDAD_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PsUJAZixUSvgY6xeAAofwA==$0",
            "column": "GENERO_ID",
            "pk_def": "PRIMARY KEY (GENERO_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$Psm4m6iJysXgY3RYAAr/HQ==$0",
            "column": "INSTITUCION_ID",
            "pk_def": "PRIMARY KEY (INSTITUCION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkD0T3bgY3RYAAqkhg==$0",
            "column": "NIVEL_CARRERA_ID",
            "pk_def": "PRIMARY KEY (NIVEL_CARRERA_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkD9T3bgY3RYAAqkhg==$0",
            "column": "INSTITUCION_ID",
            "pk_def": "PRIMARY KEY (INSTITUCION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkDcT3bgY3RYAAqkhg==$0",
            "column": "MATRICULA_ID",
            "pk_def": "PRIMARY KEY (MATRICULA_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkDsT3bgY3RYAAqkhg==$0",
            "column": "CARRERA_ID",
            "pk_def": "PRIMARY KEY (CARRERA_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkEdT3bgY3RYAAqkhg==$0",
            "column": "TIPO_EDUCACION_ID",
            "pk_def": "PRIMARY KEY (TIPO_EDUCACION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkEkT3bgY3RYAAqkhg==$0",
            "column": "NIVEL_FORMACION_ID",
            "pk_def": "PRIMARY KEY (NIVEL_FORMACION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkEyT3bgY3RYAAqkhg==$0",
            "column": "REQUISITO_INGRESO_ID",
            "pk_def": "PRIMARY KEY (REQUISITO_INGRESO_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkFAT3bgY3RYAAqkhg==$0",
            "column": "JORNADA_ID",
            "pk_def": "PRIMARY KEY (JORNADA_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkFOT3bgY3RYAAqkhg==$0",
            "column": "TIPO_ACREDITACION_ID",
            "pk_def": "PRIMARY KEY (TIPO_ACREDITACION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkGJT3bgY3RYAAqkhg==$0",
            "column": "CARRERA_ID",
            "pk_def": "PRIMARY KEY (CARRERA_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkGzT3bgY3RYAAqkhg==$0",
            "column": "REGION_ID",
            "pk_def": "PRIMARY KEY (REGION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkH5T3bgY3RYAAqkhg==$0",
            "column": "VIA_INGRESO_ID",
            "pk_def": "PRIMARY KEY (VIA_INGRESO_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkHBT3bgY3RYAAqkhg==$0",
            "column": "NIVEL_FORMACION_ID",
            "pk_def": "PRIMARY KEY (NIVEL_FORMACION_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkHIT3bgY3RYAAqkhg==$0",
            "column": "AREA_CONOCIMIENTO_ID",
            "pk_def": "PRIMARY KEY (AREA_CONOCIMIENTO_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkHPT3bgY3RYAAqkhg==$0",
            "column": "REQUISITO_INGRESO_ID",
            "pk_def": "PRIMARY KEY (REQUISITO_INGRESO_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkHkT3bgY3RYAAqkhg==$0",
            "column": "TIPO_PLAN_ID",
            "pk_def": "PRIMARY KEY (TIPO_PLAN_ID)"
        },
        {
            "schema": "AMUNOZ",
            "table": "BIN$PtCWdkIDT3bgY3RYAAqkhg==$0",
            "column": "RANGO_EDAD_ID",
            "pk_def": "PRIMARY KEY (RANGO_EDAD_ID)"
        }
    ],
    "columns": [
        {
            "schema": "AMUNOZ",
            "table": "PROVINCIAS",
            "name": "PROVINCIA_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 1,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "PROVINCIAS",
            "name": "REGION_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 3,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "COMUNAS",
            "name": "COMUNA_NOMBRE",
            "type": "varchar2",
            "character_maximum_length": "64",
            "precision": "null",
            "ordinal_position": 2,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "COMUNAS",
            "name": "REGION_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 4,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "TIPOS_EDUCACION",
            "name": "TIPO_EDUCACION_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 1,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "REQUISITOS_INGRESO",
            "name": "REQUISITO_INGRESO_NOMBRE",
            "type": "varchar2",
            "character_maximum_length": "100",
            "precision": "null",
            "ordinal_position": 2,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "REQUISITOS_INGRESO",
            "name": "REQUISITO_INGRESO_DESCRIPCION",
            "type": "varchar2",
            "character_maximum_length": "500",
            "precision": "null",
            "ordinal_position": 3,
            ""null"able": true,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "MODALIDADES",
            "name": "MODALIDAD_NOMBRE",
            "type": "varchar2",
            "character_maximum_length": "15",
            "precision": "null",
            "ordinal_position": 2,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "JORNADAS",
            "name": "JORNADA_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 1,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "MATRICULAS",
            "name": "MATRICULA_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 1,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "MATRICULAS",
            "name": "GENERO_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 2,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "MATRICULAS",
            "name": "EDAD",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 3,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "MATRICULAS",
            "name": "CARRERA_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 8,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "MATRICULAS",
            "name": "VIA_INGRESO_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 9,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "MATRICULAS",
            "name": "COMUNA_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 10,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "TIPOS_ACREDITACION",
            "name": "ESTADO_ACREDITACION",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": 1,
                "scale": 0
            },
            "ordinal_position": 2,
            ""null"able": true,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "PROVINCIAS",
            "name": "PROVINCIA_NOMBRE",
            "type": "varchar2",
            "character_maximum_length": "64",
            "precision": "null",
            "ordinal_position": 2,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "COMUNAS",
            "name": "COMUNA_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 1,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "COMUNAS",
            "name": "PROVINCIA_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 3,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "TIPOS_EDUCACION",
            "name": "TIPO_EDUCACION_NOMBRE",
            "type": "varchar2",
            "character_maximum_length": "30",
            "precision": "null",
            "ordinal_position": 2,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "TIPOS_EDUCACION",
            "name": "TIPO_EDUCACION_DESCRIPCION",
            "type": "varchar2",
            "character_maximum_length": "100",
            "precision": "null",
            "ordinal_position": 3,
            ""null"able": true,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "NIVELES_FORMACION",
            "name": "NIVEL_FORMACION_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 1,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "NIVELES_FORMACION",
            "name": "NIVEL_FORMACION_NOMBRE",
            "type": "varchar2",
            "character_maximum_length": "20",
            "precision": "null",
            "ordinal_position": 2,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "NIVELES_FORMACION",
            "name": "NIVEL_FORMACION_DESCRIPCION",
            "type": "varchar2",
            "character_maximum_length": "100",
            "precision": "null",
            "ordinal_position": 3,
            ""null"able": true,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "REQUISITOS_INGRESO",
            "name": "REQUISITO_INGRESO_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 1,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "MODALIDADES",
            "name": "MODALIDAD_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 1,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "MODALIDADES",
            "name": "MODALIDAD_DESCRIPCION",
            "type": "varchar2",
            "character_maximum_length": "100",
            "precision": "null",
            "ordinal_position": 3,
            ""null"able": true,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "JORNADAS",
            "name": "JORNADA_NOMBRE",
            "type": "varchar2",
            "character_maximum_length": "15",
            "precision": "null",
            "ordinal_position": 2,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "JORNADAS",
            "name": "JORNADA_DESCRIPCION",
            "type": "varchar2",
            "character_maximum_length": "100",
            "precision": "null",
            "ordinal_position": 3,
            ""null"able": true,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "TIPOS_PLAN",
            "name": "TIPO_PLAN_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 1,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "TIPOS_PLAN",
            "name": "TIPO_PLAN_NOMBRE",
            "type": "varchar2",
            "character_maximum_length": "50",
            "precision": "null",
            "ordinal_position": 2,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "TIPOS_PLAN",
            "name": "TIPO_PLAN_DESCRIPCION",
            "type": "varchar2",
            "character_maximum_length": "200",
            "precision": "null",
            "ordinal_position": 3,
            ""null"able": true,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "MATRICULAS",
            "name": "RANGO_EDAD_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 4,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "MATRICULAS",
            "name": "ANIO_INGRESO",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 5,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "MATRICULAS",
            "name": "SEMESTRE_INGRESO",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 6,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "MATRICULAS",
            "name": "INSTITUCION_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 7,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "TIPOS_ACREDITACION",
            "name": "TIPO_ACREDITACION_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 1,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "TIPOS_ACREDITACION",
            "name": "TIPO_ACREDITACION_DESCRIPCION",
            "type": "varchar2",
            "character_maximum_length": "200",
            "precision": "null",
            "ordinal_position": 3,
            ""null"able": true,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "REGIONES",
            "name": "REGION_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 1,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "NIVELES_CARRERA",
            "name": "TIPO_EDUCACION_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 2,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "NIVELES_CARRERA",
            "name": "NIVEL_CARRERA_DESCRIPCION",
            "type": "varchar2",
            "character_maximum_length": "100",
            "precision": "null",
            "ordinal_position": 4,
            ""null"able": true,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "AREAS_CONOCIMIENTO",
            "name": "AREA_CONOCIMIENTO_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 1,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "AREAS_CONOCIMIENTO",
            "name": "AREA_CONOCIMIENTO_NOMBRE",
            "type": "varchar2",
            "character_maximum_length": "100",
            "precision": "null",
            "ordinal_position": 2,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "CARRERAS",
            "name": "CARRERA_DESCRIPCION",
            "type": "varchar2",
            "character_maximum_length": "500",
            "precision": "null",
            "ordinal_position": 3,
            ""null"able": true,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "CARRERAS",
            "name": "REQUISITO_INGRESO_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 5,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "CARRERAS",
            "name": "MODALIDAD_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 6,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "CARRERAS",
            "name": "JORNADA_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 7,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "CARRERAS",
            "name": "TIPO_PLAN_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 8,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "CARRERAS",
            "name": "DURACION_TITULACION",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 11,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "CARRERAS",
            "name": "VALORACION_MATRICULA",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 13,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "INSTITUCIONES",
            "name": "TIPO_INSTITUCION_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 3,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "VIAS_INGRESO",
            "name": "VIA_INGRESO_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 1,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "RANGOS_EDAD",
            "name": "RANGO_EDAD_DESCRIPCION",
            "type": "varchar2",
            "character_maximum_length": "50",
            "precision": "null",
            "ordinal_position": 2,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "SDW$ERR$_INSTITUCIONES",
            "name": "INSTITUCION_NOMBRE",
            "type": "varchar2",
            "character_maximum_length": "32767",
            "precision": "null",
            "ordinal_position": 7,
            ""null"able": true,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "SDW$ERR$_INSTITUCIONES",
            "name": "ORA_ERR_OPTYP$",
            "type": "varchar2",
            "character_maximum_length": "2",
            "precision": "null",
            "ordinal_position": 4,
            ""null"able": true,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "SDW$ERR$_INSTITUCIONES",
            "name": "INSTITUCION_ID",
            "type": "varchar2",
            "character_maximum_length": "4000",
            "precision": "null",
            "ordinal_position": 6,
            ""null"able": true,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "SDW$ERR$_INSTITUCIONES",
            "name": "PERIODO_ACREDITACION_INICIO",
            "type": "varchar2",
            "character_maximum_length": "4000",
            "precision": "null",
            "ordinal_position": 10,
            ""null"able": true,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "SDW$ERR$_INSTITUCIONES",
            "name": "ORA_ERR_MESG$",
            "type": "varchar2",
            "character_maximum_length": "2000",
            "precision": "null",
            "ordinal_position": 2,
            ""null"able": true,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "REGIONES",
            "name": "REGION_NOMBRE",
            "type": "varchar2",
            "character_maximum_length": "64",
            "precision": "null",
            "ordinal_position": 2,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "REGIONES",
            "name": "REGION_ORDINAL",
            "type": "varchar2",
            "character_maximum_length": "4",
            "precision": "null",
            "ordinal_position": 3,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "NIVELES_CARRERA",
            "name": "NIVEL_CARRERA_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 1,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "NIVELES_CARRERA",
            "name": "NIVEL_FORMACION_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 3,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "AREAS_CONOCIMIENTO",
            "name": "AREA_CONOCIMIENTO_DESCRIPCION",
            "type": "varchar2",
            "character_maximum_length": "500",
            "precision": "null",
            "ordinal_position": 3,
            ""null"able": true,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "CARRERAS",
            "name": "CARRERA_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 1,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "CARRERAS",
            "name": "CARRERA_NOMBRE",
            "type": "varchar2",
            "character_maximum_length": "100",
            "precision": "null",
            "ordinal_position": 2,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "CARRERAS",
            "name": "NIVEL_CARRERA_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 4,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "CARRERAS",
            "name": "AREA_CONOCIMIENTO_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 9,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "CARRERAS",
            "name": "DURACION_PLAN",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 10,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "CARRERAS",
            "name": "DURACION_TOTAL",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 12,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "CARRERAS",
            "name": "VALORACION_ARANCEL",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 14,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "TIPOS_INSTITUCION",
            "name": "TIPO_INSTITUCION_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 1,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "TIPOS_INSTITUCION",
            "name": "TIPO_INSTITUCION_NOMBRE",
            "type": "varchar2",
            "character_maximum_length": "50",
            "precision": "null",
            "ordinal_position": 2,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "TIPOS_INSTITUCION",
            "name": "TIPO_INSTITUCION_DESCRIPCION",
            "type": "varchar2",
            "character_maximum_length": "200",
            "precision": "null",
            "ordinal_position": 3,
            ""null"able": true,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "INSTITUCIONES",
            "name": "INSTITUCION_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 1,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "INSTITUCIONES",
            "name": "INSTITUCION_NOMBRE",
            "type": "varchar2",
            "character_maximum_length": "100",
            "precision": "null",
            "ordinal_position": 2,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "INSTITUCIONES",
            "name": "ACREDITACION_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 4,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "INSTITUCIONES",
            "name": "PERIODO_ACREDITACION_INICIO",
            "type": "date",
            "character_maximum_length": "null",
            "precision": "null",
            "ordinal_position": 5,
            ""null"able": true,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "INSTITUCIONES",
            "name": "PERIODO_ACREDITACION_FIN",
            "type": "date",
            "character_maximum_length": "null",
            "precision": "null",
            "ordinal_position": 6,
            ""null"able": true,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "VIAS_INGRESO",
            "name": "VIA_INGRESO_NOMBRE",
            "type": "varchar2",
            "character_maximum_length": "100",
            "precision": "null",
            "ordinal_position": 2,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "VIAS_INGRESO",
            "name": "VIA_INGRESO_DESCRIPCION",
            "type": "varchar2",
            "character_maximum_length": "200",
            "precision": "null",
            "ordinal_position": 3,
            ""null"able": true,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "RANGOS_EDAD",
            "name": "RANGO_EDAD_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 1,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "RANGOS_EDAD",
            "name": "EDAD_MINIMA",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 3,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "RANGOS_EDAD",
            "name": "EDAD_MAXIMA",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 4,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "GENEROS",
            "name": "GENERO_ID",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": 0
            },
            "ordinal_position": 1,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "GENEROS",
            "name": "GENERO_NOMBRE",
            "type": "varchar2",
            "character_maximum_length": "20",
            "precision": "null",
            "ordinal_position": 2,
            ""null"able": false,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "SDW$ERR$_INSTITUCIONES",
            "name": "ACREDITACION_ID",
            "type": "varchar2",
            "character_maximum_length": "4000",
            "precision": "null",
            "ordinal_position": 9,
            ""null"able": true,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "SDW$ERR$_INSTITUCIONES",
            "name": "ORA_ERR_NUMBER$",
            "type": "number",
            "character_maximum_length": "null",
            "precision": {
                "precision": "null",
                "scale": "null"
            },
            "ordinal_position": 1,
            ""null"able": true,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "SDW$ERR$_INSTITUCIONES",
            "name": "ORA_ERR_TAG$",
            "type": "varchar2",
            "character_maximum_length": "2000",
            "precision": "null",
            "ordinal_position": 5,
            ""null"able": true,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "SDW$ERR$_INSTITUCIONES",
            "name": "TIPO_INSTITUCION_ID",
            "type": "varchar2",
            "character_maximum_length": "4000",
            "precision": "null",
            "ordinal_position": 8,
            ""null"able": true,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "SDW$ERR$_INSTITUCIONES",
            "name": "PERIODO_ACREDITACION_FIN",
            "type": "varchar2",
            "character_maximum_length": "4000",
            "precision": "null",
            "ordinal_position": 11,
            ""null"able": true,
            "default": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "SDW$ERR$_INSTITUCIONES",
            "name": "ORA_ERR_ROWID$",
            "type": "urowid",
            "character_maximum_length": "null",
            "precision": "null",
            "ordinal_position": 3,
            ""null"able": true,
            "default": "",
            "collation": ""
        }
    ],
    "indexes": [
        {
            "schema": "AMUNOZ",
            "table": "AREAS_CONOCIMIENTO",
            "name": "UK_AREAS_CONOCIMIENTO",
            "size": -1,
            "column": "AREA_CONOCIMIENTO_NOMBRE",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "COMUNAS",
            "name": "UK_COMUNAS",
            "size": -1,
            "column": "COMUNA_NOMBRE",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "COMUNAS",
            "name": "UK_COMUNAS",
            "size": -1,
            "column": "PROVINCIA_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 2,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "COMUNAS",
            "name": "UK_COMUNAS",
            "size": -1,
            "column": "REGION_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 3,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "GENEROS",
            "name": "UK_GENEROS",
            "size": -1,
            "column": "GENERO_NOMBRE",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "JORNADAS",
            "name": "UK_JORNADAS",
            "size": -1,
            "column": "JORNADA_NOMBRE",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "MODALIDADES",
            "name": "UK_MODALIDADES",
            "size": -1,
            "column": "MODALIDAD_NOMBRE",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "NIVELES_FORMACION",
            "name": "UK_NIVELES_FORMACION",
            "size": -1,
            "column": "NIVEL_FORMACION_NOMBRE",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "PROVINCIAS",
            "name": "UK_PROVINCIAS",
            "size": -1,
            "column": "PROVINCIA_NOMBRE",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "PROVINCIAS",
            "name": "UK_PROVINCIAS",
            "size": -1,
            "column": "REGION_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 2,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "RANGOS_EDAD",
            "name": "UK_RANGOS_EDAD",
            "size": -1,
            "column": "EDAD_MINIMA",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "RANGOS_EDAD",
            "name": "UK_RANGOS_EDAD",
            "size": -1,
            "column": "EDAD_MAXIMA",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 2,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "REGIONES",
            "name": "UK_REGIONES",
            "size": -1,
            "column": "REGION_NOMBRE",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "REGIONES",
            "name": "UK_REGIONES",
            "size": -1,
            "column": "REGION_ORDINAL",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 2,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "REQUISITOS_INGRESO",
            "name": "UK_REQUISITOS_INGRESO",
            "size": -1,
            "column": "REQUISITO_INGRESO_NOMBRE",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "TIPOS_EDUCACION",
            "name": "UK_TIPOS_EDUCACION",
            "size": -1,
            "column": "TIPO_EDUCACION_NOMBRE",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "CARRERAS",
            "name": "IDX_CARRERAS_AREA_CONOCIMIENTO",
            "size": -1,
            "column": "AREA_CONOCIMIENTO_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "CARRERAS",
            "name": "IDX_CARRERAS_AREA_NIVEL",
            "size": -1,
            "column": "AREA_CONOCIMIENTO_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "CARRERAS",
            "name": "IDX_CARRERAS_AREA_NIVEL",
            "size": -1,
            "column": "NIVEL_CARRERA_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 2,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "CARRERAS",
            "name": "IDX_CARRERAS_JORNADA",
            "size": -1,
            "column": "JORNADA_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "CARRERAS",
            "name": "IDX_CARRERAS_MODALIDAD",
            "size": -1,
            "column": "MODALIDAD_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "CARRERAS",
            "name": "IDX_CARRERAS_MODALIDAD_JORNADA",
            "size": -1,
            "column": "MODALIDAD_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "CARRERAS",
            "name": "IDX_CARRERAS_MODALIDAD_JORNADA",
            "size": -1,
            "column": "JORNADA_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 2,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "CARRERAS",
            "name": "IDX_CARRERAS_NIVEL_CARRERA",
            "size": -1,
            "column": "NIVEL_CARRERA_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "CARRERAS",
            "name": "IDX_CARRERAS_REQUISITO_INGRESO",
            "size": -1,
            "column": "REQUISITO_INGRESO_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "CARRERAS",
            "name": "IDX_CARRERAS_TIPO_PLAN",
            "size": -1,
            "column": "TIPO_PLAN_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "COMUNAS",
            "name": "IDX_COMUNAS_PROVINCIA",
            "size": -1,
            "column": "PROVINCIA_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "COMUNAS",
            "name": "IDX_COMUNAS_REGION",
            "size": -1,
            "column": "REGION_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "COMUNAS",
            "name": "IDX_COMUNAS_REGION_PROVINCIA",
            "size": -1,
            "column": "REGION_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "COMUNAS",
            "name": "IDX_COMUNAS_REGION_PROVINCIA",
            "size": -1,
            "column": "PROVINCIA_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 2,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "PROVINCIAS",
            "name": "IDX_PROVINCIAS_REGION",
            "size": -1,
            "column": "REGION_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "RANGOS_EDAD",
            "name": "IDX_RANGOS_EDAD_MAXIMA",
            "size": -1,
            "column": "EDAD_MAXIMA",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "RANGOS_EDAD",
            "name": "IDX_RANGOS_EDAD_MINIMA",
            "size": -1,
            "column": "EDAD_MINIMA",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "REGIONES",
            "name": "SYS_C0027569",
            "size": -1,
            "column": "REGION_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "PROVINCIAS",
            "name": "SYS_C0027574",
            "size": -1,
            "column": "PROVINCIA_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "COMUNAS",
            "name": "SYS_C0027580",
            "size": -1,
            "column": "COMUNA_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "TIPOS_EDUCACION",
            "name": "SYS_C0027584",
            "size": -1,
            "column": "TIPO_EDUCACION_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "NIVELES_FORMACION",
            "name": "SYS_C0027588",
            "size": -1,
            "column": "NIVEL_FORMACION_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "AREAS_CONOCIMIENTO",
            "name": "SYS_C0027597",
            "size": -1,
            "column": "AREA_CONOCIMIENTO_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "REQUISITOS_INGRESO",
            "name": "SYS_C0027601",
            "size": -1,
            "column": "REQUISITO_INGRESO_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "MODALIDADES",
            "name": "SYS_C0027605",
            "size": -1,
            "column": "MODALIDAD_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "JORNADAS",
            "name": "SYS_C0027609",
            "size": -1,
            "column": "JORNADA_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "CARRERAS",
            "name": "SYS_C0027628",
            "size": -1,
            "column": "CARRERA_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "RANGOS_EDAD",
            "name": "SYS_C0027652",
            "size": -1,
            "column": "RANGO_EDAD_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "GENEROS",
            "name": "SYS_C0027656",
            "size": -1,
            "column": "GENERO_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "INSTITUCIONES",
            "name": "UK_INSTITUCION",
            "size": -1,
            "column": "INSTITUCION_NOMBRE",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "INSTITUCIONES",
            "name": "UK_INSTITUCION",
            "size": -1,
            "column": "TIPO_INSTITUCION_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 2,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "NIVELES_CARRERA",
            "name": "UK_NIVELES_CARRERA",
            "size": -1,
            "column": "TIPO_EDUCACION_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "NIVELES_CARRERA",
            "name": "UK_NIVELES_CARRERA",
            "size": -1,
            "column": "NIVEL_FORMACION_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 2,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "TIPOS_ACREDITACION",
            "name": "UK_TIPOS_ACREDITACION",
            "size": -1,
            "column": "ESTADO_ACREDITACION",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "TIPOS_INSTITUCION",
            "name": "UK_TIPOS_INSTITUCION",
            "size": -1,
            "column": "TIPO_INSTITUCION_NOMBRE",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "TIPOS_PLAN",
            "name": "UK_TIPOS_PLAN",
            "size": -1,
            "column": "TIPO_PLAN_NOMBRE",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "VIAS_INGRESO",
            "name": "UK_VIAS_INGRESO",
            "size": -1,
            "column": "VIA_INGRESO_NOMBRE",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "INSTITUCIONES",
            "name": "IDX_INSTITUCIONES_ACREDITACION",
            "size": -1,
            "column": "ACREDITACION_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "INSTITUCIONES",
            "name": "IDX_INSTITUCIONES_PERIODO_ACRED",
            "size": -1,
            "column": "PERIODO_ACREDITACION_INICIO",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "INSTITUCIONES",
            "name": "IDX_INSTITUCIONES_PERIODO_ACRED",
            "size": -1,
            "column": "PERIODO_ACREDITACION_FIN",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 2,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "INSTITUCIONES",
            "name": "IDX_INSTITUCIONES_TIPO",
            "size": -1,
            "column": "TIPO_INSTITUCION_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "MATRICULAS",
            "name": "IDX_MATRICULAS_ANIO_GENERO",
            "size": -1,
            "column": "ANIO_INGRESO",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "MATRICULAS",
            "name": "IDX_MATRICULAS_ANIO_GENERO",
            "size": -1,
            "column": "GENERO_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 2,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "MATRICULAS",
            "name": "IDX_MATRICULAS_ANIO_SEMESTRE",
            "size": -1,
            "column": "ANIO_INGRESO",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "MATRICULAS",
            "name": "IDX_MATRICULAS_ANIO_SEMESTRE",
            "size": -1,
            "column": "SEMESTRE_INGRESO",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 2,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "MATRICULAS",
            "name": "IDX_MATRICULAS_CARRERA",
            "size": -1,
            "column": "CARRERA_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "MATRICULAS",
            "name": "IDX_MATRICULAS_CARRERA_GENERO",
            "size": -1,
            "column": "CARRERA_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "MATRICULAS",
            "name": "IDX_MATRICULAS_CARRERA_GENERO",
            "size": -1,
            "column": "GENERO_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 2,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "MATRICULAS",
            "name": "IDX_MATRICULAS_COMUNA",
            "size": -1,
            "column": "COMUNA_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "MATRICULAS",
            "name": "IDX_MATRICULAS_GENERO",
            "size": -1,
            "column": "GENERO_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "MATRICULAS",
            "name": "IDX_MATRICULAS_INSTITUCION",
            "size": -1,
            "column": "INSTITUCION_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "MATRICULAS",
            "name": "IDX_MATRICULAS_INST_CARRERA",
            "size": -1,
            "column": "INSTITUCION_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "MATRICULAS",
            "name": "IDX_MATRICULAS_INST_CARRERA",
            "size": -1,
            "column": "CARRERA_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 2,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "MATRICULAS",
            "name": "IDX_MATRICULAS_RANGO_EDAD",
            "size": -1,
            "column": "RANGO_EDAD_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "MATRICULAS",
            "name": "IDX_MATRICULAS_VIA_INGRESO",
            "size": -1,
            "column": "VIA_INGRESO_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "NIVELES_CARRERA",
            "name": "IDX_NIVELES_CARRERA_NIVEL_FORMACION",
            "size": -1,
            "column": "NIVEL_FORMACION_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "NIVELES_CARRERA",
            "name": "IDX_NIVELES_CARRERA_TIPO_EDUCACION",
            "size": -1,
            "column": "TIPO_EDUCACION_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": false
        },
        {
            "schema": "AMUNOZ",
            "table": "NIVELES_CARRERA",
            "name": "SYS_C0027593",
            "size": -1,
            "column": "NIVEL_CARRERA_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "TIPOS_PLAN",
            "name": "SYS_C0027613",
            "size": -1,
            "column": "TIPO_PLAN_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "TIPOS_ACREDITACION",
            "name": "SYS_C0027631",
            "size": -1,
            "column": "TIPO_ACREDITACION_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "TIPOS_INSTITUCION",
            "name": "SYS_C0027635",
            "size": -1,
            "column": "TIPO_INSTITUCION_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "INSTITUCIONES",
            "name": "SYS_C0027641",
            "size": -1,
            "column": "INSTITUCION_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "VIAS_INGRESO",
            "name": "SYS_C0027645",
            "size": -1,
            "column": "VIA_INGRESO_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        },
        {
            "schema": "AMUNOZ",
            "table": "MATRICULAS",
            "name": "SYS_C0027667",
            "size": -1,
            "column": "MATRICULA_ID",
            "index_type": "normal",
            "cardinality": 0,
            "direction": "asc",
            "column_position": 1,
            "unique": true
        }
    ],
    "tables": [
        {
            "schema": "AMUNOZ",
            "table": "AREAS_CONOCIMIENTO",
            "rows": 10,
            "type": "TABLE",
            "engine": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "GENEROS",
            "rows": 3,
            "type": "TABLE",
            "engine": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "MODALIDADES",
            "rows": 3,
            "type": "TABLE",
            "engine": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "RANGOS_EDAD",
            "rows": 6,
            "type": "TABLE",
            "engine": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "REQUISITOS_INGRESO",
            "rows": 5,
            "type": "TABLE",
            "engine": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "TIPOS_ACREDITACION",
            "rows": "null",
            "type": "TABLE",
            "engine": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "TIPOS_INSTITUCION",
            "rows": 4,
            "type": "TABLE",
            "engine": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "VIAS_INGRESO",
            "rows": 11,
            "type": "TABLE",
            "engine": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "PROVINCIAS",
            "rows": 56,
            "type": "TABLE",
            "engine": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "COMUNAS",
            "rows": 346,
            "type": "TABLE",
            "engine": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "NIVELES_CARRERA",
            "rows": 5,
            "type": "TABLE",
            "engine": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "CARRERAS",
            "rows": 319,
            "type": "TABLE",
            "engine": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "MATRICULAS",
            "rows": 18646,
            "type": "TABLE",
            "engine": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "JORNADAS",
            "rows": 5,
            "type": "TABLE",
            "engine": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "NIVELES_FORMACION",
            "rows": 3,
            "type": "TABLE",
            "engine": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "REGIONES",
            "rows": 16,
            "type": "TABLE",
            "engine": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "TIPOS_EDUCACION",
            "rows": 5,
            "type": "TABLE",
            "engine": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "TIPOS_PLAN",
            "rows": 3,
            "type": "TABLE",
            "engine": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "INSTITUCIONES",
            "rows": 15,
            "type": "TABLE",
            "engine": "",
            "collation": ""
        },
        {
            "schema": "AMUNOZ",
            "table": "SDW$ERR$_INSTITUCIONES",
            "rows": "null",
            "type": "TABLE",
            "engine": "",
            "collation": ""
        }
    ],
    "views": "null",
    "schema": "AMUNOZ",
    "database_name": "GD0DFBFF1D28F8F_MAT4141",
    "version": "GD0DFBFF1D28F8F_MAT4141"
}