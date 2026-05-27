-- ============================================================
-- DG Inmobiliaria — Schema
-- ============================================================

-- Función updated_at con search_path seguro
create or replace function update_updated_at()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ============================================================
-- Tabla: propiedades
-- ============================================================
create table propiedades (
  -- PRIMARY KEY: bigint identity (secuencial, 8 bytes, sin fragmentación de índice)
  -- Para IDs expuestos en URLs se usa el slug; el id interno no se expone.
  id                   bigint      generated always as identity primary key,
  slug                 text        not null unique,

  -- Contenido
  titulo               text        not null,
  descripcion          text,

  -- Clasificación
  tipo                 text        not null check (tipo in ('casa', 'departamento', 'terreno', 'desarrollo')),
  estado_venta         text        not null default 'disponible' check (estado_venta in ('disponible', 'apartado', 'vendido')),
  estado_publicacion   text        not null default 'disponible' check (estado_publicacion in ('disponible', 'destacada', 'preventa')),

  -- Precio — numeric(12,2): exactitud decimal, sin overflow para MXN
  precio               numeric(12,2) not null,
  precio_por_m2        numeric(10,2),
  moneda               text        not null default 'MXN' check (moneda in ('MXN', 'USD')),

  -- Ubicación
  zona                 text        not null check (zona in (
                         'Cerritos', 'Marina Mazatlán', 'Zona Dorada',
                         'El Cid', 'Centro Histórico', 'Lomas del Mar',
                         'Brujas', 'Los Pinos'
                       )),
  direccion_aprox      text,
  -- Coordenadas: numeric(10,7) — precisión suficiente para ~1 cm en GPS
  latitud              numeric(10,7),
  longitud             numeric(10,7),

  -- Dimensiones: numeric(10,2) — hasta 9,999,999.99 m²
  metros_terreno       numeric(10,2),
  metros_construccion  numeric(10,2),

  -- Legal y servicios
  uso_de_suelo         text        check (uso_de_suelo in ('habitacional', 'mixto', 'comercial')),
  servicios            text[],
  escrituras           boolean,
  acepta_creditos      text[],

  -- Atributos y media
  caracteristicas      text[],
  imagenes             text[],

  -- Control
  destacada            boolean     not null default false,
  activa               boolean     not null default true,
  visitas              integer     not null default 0,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);

-- Trigger updated_at
create trigger propiedades_updated_at
  before update on propiedades
  for each row execute function update_updated_at();

-- ============================================================
-- Índices
-- ============================================================

-- Partial indexes: solo filas activas (el 95%+ de las consultas filtran activa = true)
create index propiedades_tipo_activa_idx        on propiedades (tipo)              where activa = true;
create index propiedades_zona_activa_idx        on propiedades (zona)              where activa = true;
create index propiedades_estado_venta_idx       on propiedades (estado_venta)      where activa = true;
create index propiedades_estado_pub_idx         on propiedades (estado_publicacion) where activa = true;
create index propiedades_destacada_idx          on propiedades (destacada)         where activa = true;
create index propiedades_precio_idx             on propiedades (precio)            where activa = true;

-- Índice compuesto para el filtro más común en el sitio: tipo + zona + estado_venta
create index propiedades_filtro_principal_idx
  on propiedades (tipo, zona, estado_venta)
  where activa = true;

-- ============================================================
-- RLS — Row Level Security
-- ============================================================

alter table propiedades enable row level security;
alter table propiedades force row level security;

-- Lectura pública: solo propiedades activas
create policy "Lectura pública de propiedades activas"
  on propiedades
  for select
  using (activa = true);

-- Escritura: solo usuarios autenticados (usando `to` en lugar de auth.role() por fila)
create policy "Escritura autenticada"
  on propiedades
  for all
  to authenticated
  using (true)
  with check (true);

-- ============================================================
-- Datos de ejemplo — 9 propiedades en Mazatlán
-- ============================================================

insert into propiedades (
  slug, titulo, descripcion,
  tipo, estado_venta, estado_publicacion,
  precio, precio_por_m2, moneda,
  zona, direccion_aprox, latitud, longitud,
  metros_terreno, metros_construccion,
  uso_de_suelo, servicios, escrituras, acepta_creditos,
  caracteristicas, imagenes,
  destacada, activa
) values

-- 1 — Departamento Zona Dorada
(
  'departamento-frente-al-mar-zona-dorada',
  'Departamento frente al mar — Zona Dorada',
  'Moderno departamento con vista directa al mar. Acabados de lujo, cocina integral, amplia terraza y ventanas de piso a techo. Edificio con alberca, gimnasio y seguridad 24 hrs. A pasos de restaurantes y el malecón.',
  'departamento', 'disponible', 'destacada',
  2850000.00, 33529.41, 'MXN',
  'Zona Dorada', 'Av. del Mar, frente a Playa Gaviotas', 23.2494000, -106.4108000,
  null, 85.00,
  'habitacional',
  ARRAY['Agua', 'Luz', 'Gas natural', 'Internet', 'Drenaje'],
  true,
  ARRAY['Bancario', 'Contado'],
  ARRAY['2 recámaras', '2 baños completos', '1 estacionamiento', 'Cocina integral', 'Terraza privada', 'Alberca en edificio', 'Gimnasio', 'Seguridad 24 hrs', 'Elevador', 'Amueblado parcialmente'],
  ARRAY[]::text[],
  true, true
),

-- 2 — Casa El Cid
(
  'casa-privada-el-cid-con-alberca',
  'Casa en privada El Cid con alberca',
  'Amplia residencia en privada con vigilancia. Sala, comedor, cocina equipada, cuarto de servicio y jardín. Alberca privada y terraza cubierta. Colonia tranquila a 10 minutos de playa. Excelente plusvalía.',
  'casa', 'disponible', 'disponible',
  4200000.00, 23333.33, 'MXN',
  'El Cid', 'Fracc. El Cid Golf, cerca del campo de golf', 23.2234000, -106.4321000,
  220.00, 180.00,
  'habitacional',
  ARRAY['Agua', 'Luz', 'Gas estacionario', 'Internet', 'Drenaje', 'Teléfono'],
  true,
  ARRAY['INFONAVIT', 'FOVISSSTE', 'Bancario', 'Contado'],
  ARRAY['3 recámaras', '2.5 baños', '2 estacionamientos', 'Cuarto de servicio', 'Alberca privada', 'Jardín', 'Terraza cubierta', 'Cocina equipada', 'Privada con vigilancia', 'Área de lavado'],
  ARRAY[]::text[],
  false, true
),

-- 3 — Depto preventa Marina
(
  'departamento-preventa-marina-mazatlan',
  'Departamento en preventa — Marina Mazatlán',
  'Proyecto residencial a orillas de la marina. Entrega estimada segundo semestre 2026. Precio de lanzamiento con opción a enganche flexible. Amenidades: rooftop, alberca, coworking y lobby de doble altura.',
  'departamento', 'disponible', 'preventa',
  3950000.00, 32916.67, 'MXN',
  'Marina Mazatlán', 'Blvd. Marina, frente a la marina deportiva', 23.2151000, -106.4389000,
  null, 120.00,
  'habitacional',
  ARRAY['Agua', 'Luz', 'Gas natural', 'Internet', 'Drenaje'],
  false,
  ARRAY['Bancario', 'Contado'],
  ARRAY['3 recámaras', '2 baños completos', '2 estacionamientos', 'Rooftop compartido', 'Alberca', 'Coworking', 'Lobby doble altura', 'Cocina integral', 'Balcón', 'Vista a la marina'],
  ARRAY[]::text[],
  true, true
),

-- 4 — Residencia Cerritos
(
  'residencia-lujo-cerritos-vista-al-mar',
  'Residencia de lujo en Cerritos con vista al mar',
  'Casa de autor con arquitectura contemporánea en la zona de mayor plusvalía de Mazatlán. 4 recámaras en suite, sala de cine, bar, alberca infinity y vista panorámica al océano Pacífico.',
  'casa', 'disponible', 'destacada',
  6500000.00, 26000.00, 'MXN',
  'Cerritos', 'Av. Sábalo Cerritos, zona residencial frente al mar', 23.3012000, -106.3891000,
  320.00, 250.00,
  'habitacional',
  ARRAY['Agua', 'Luz', 'Gas natural', 'Internet fibra óptica', 'Drenaje'],
  true,
  ARRAY['Bancario', 'Contado'],
  ARRAY['4 recámaras en suite', '3 baños completos', '1 medio baño', '3 estacionamientos', 'Alberca infinity', 'Vista al mar', 'Sala de cine', 'Bar', 'Jardín', 'Roof garden', 'Cocina de isla', 'Cuarto de servicio', 'Bodega'],
  ARRAY[]::text[],
  true, true
),

-- 5 — Depto Centro Histórico
(
  'departamento-centro-historico-mazatlan',
  'Departamento en Centro Histórico',
  'Departamento ideal para inversión o primer hogar. A dos cuadras del Teatro Ángela Peralta y Olas Altas. Edificio restaurado con encanto colonial, techos altos y patio interior.',
  'departamento', 'disponible', 'disponible',
  1350000.00, 24545.45, 'MXN',
  'Centro Histórico', 'Calle Constitución, Centro Histórico', 23.2289000, -106.4175000,
  null, 55.00,
  'habitacional',
  ARRAY['Agua', 'Luz', 'Internet', 'Drenaje'],
  true,
  ARRAY['INFONAVIT', 'FOVISSSTE', 'Bancario', 'Contado'],
  ARRAY['1 recámara', '1 baño completo', '1 estacionamiento', 'Patio interior', 'Techos altos', 'Edificio restaurado', 'Zona peatonal', 'Cerca de restaurantes y museos'],
  ARRAY[]::text[],
  false, true
),

-- 6 — Casa Lomas del Mar
(
  'casa-lomas-del-mar-con-jardin',
  'Casa en Lomas del Mar con jardín',
  'Casa funcional en fraccionamiento cerrado con parque y cancha. Recámaras amplias, cocina abierta al jardín y cuarto de lavado. Acceso rápido a zona comercial, escuelas y la playa.',
  'casa', 'disponible', 'disponible',
  3200000.00, 20000.00, 'MXN',
  'Lomas del Mar', 'Fracc. Lomas del Mar, cerca de Plaza Sendero', 23.2623000, -106.4231000,
  200.00, 160.00,
  'habitacional',
  ARRAY['Agua', 'Luz', 'Gas estacionario', 'Internet', 'Drenaje'],
  true,
  ARRAY['INFONAVIT', 'FOVISSSTE', 'Bancario', 'Contado'],
  ARRAY['3 recámaras', '2 baños completos', '2 estacionamientos', 'Jardín', 'Cocina abierta', 'Cuarto de lavado', 'Fraccionamiento cerrado', 'Parque y cancha', 'Sala-comedor integrado'],
  ARRAY[]::text[],
  false, true
),

-- 7 — Depto Brujas
(
  'departamento-fraccionamiento-brujas',
  'Departamento en Fracc. Brujas',
  'Departamento bien distribuido en zona residencial consolidada. Sala-comedor integrado, dos recámaras con clóset y estacionamiento propio. Tranquilo y céntrico, cerca de escuelas y supermercados.',
  'departamento', 'disponible', 'disponible',
  2100000.00, 22105.26, 'MXN',
  'Brujas', 'Fracc. Jacarandas, Col. Brujas', 23.2501000, -106.4298000,
  null, 95.00,
  'habitacional',
  ARRAY['Agua', 'Luz', 'Gas estacionario', 'Internet', 'Drenaje'],
  true,
  ARRAY['INFONAVIT', 'FOVISSSTE', 'Bancario', 'Contado'],
  ARRAY['2 recámaras', '2 baños completos', '1 estacionamiento', 'Clósets en recámaras', 'Sala-comedor integrado', 'Área de lavado', 'Zona residencial tranquila'],
  ARRAY[]::text[],
  false, true
),

-- 8 — Casa Los Pinos preventa
(
  'casa-preventa-los-pinos-residencial',
  'Casa en preventa — Los Pinos Residencial',
  'Nuevo desarrollo residencial en zona de alto crecimiento. Preventa con precio preferencial. 4 recámaras, recámara principal con vestidor y baño completo. Jardín, alberca y dos plantas. Entrega estimada Q1 2026.',
  'casa', 'disponible', 'preventa',
  5800000.00, 20714.29, 'MXN',
  'Los Pinos', 'Nuevo desarrollo Los Pinos Residencial, Mazatlán Norte', 23.2445000, -106.4356000,
  350.00, 280.00,
  'habitacional',
  ARRAY['Agua', 'Luz', 'Gas natural', 'Internet fibra óptica', 'Drenaje'],
  false,
  ARRAY['Bancario', 'Contado'],
  ARRAY['4 recámaras', '3.5 baños', '3 estacionamientos', 'Recámara principal con vestidor', 'Alberca', 'Jardín', 'Dos plantas', 'Cocina integral', 'Cuarto de servicio', 'Desarrollo nuevo'],
  ARRAY[]::text[],
  false, true
),

-- 9 — Depto Zona Dorada con terraza
(
  'departamento-terraza-zona-dorada',
  'Departamento con terraza — Zona Dorada',
  'Luminoso departamento en piso alto con terraza privada y vista parcial al mar. Acabados modernos, 3 recámaras, cocina integral y dos cajones de estacionamiento. Listo para habitar.',
  'departamento', 'disponible', 'destacada',
  3450000.00, 31363.64, 'MXN',
  'Zona Dorada', 'Av. Camarón Sábalo, Zona Dorada', 23.2521000, -106.4134000,
  null, 110.00,
  'habitacional',
  ARRAY['Agua', 'Luz', 'Gas natural', 'Internet', 'Drenaje'],
  true,
  ARRAY['Bancario', 'Contado'],
  ARRAY['3 recámaras', '2 baños completos', '2 estacionamientos', 'Terraza privada', 'Vista parcial al mar', 'Piso alto', 'Cocina integral', 'Elevador', 'Seguridad', 'Listo para habitar'],
  ARRAY[]::text[],
  true, true
);
