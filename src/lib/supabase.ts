import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.PUBLIC_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.PUBLIC_SUPABASE_ANON_KEY;

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

// ─── Tipos ────────────────────────────────────────────────────

export type TipoPropiedad = 'casa' | 'departamento' | 'terreno' | 'desarrollo';
export type EstadoVenta = 'disponible' | 'apartado' | 'vendido';
export type EstadoPublicacion = 'disponible' | 'destacada' | 'preventa';
export type UsoSuelo = 'habitacional' | 'mixto' | 'comercial';
export type Zona =
  | 'Cerritos'
  | 'Marina Mazatlán'
  | 'Zona Dorada'
  | 'El Cid'
  | 'Centro Histórico'
  | 'Lomas del Mar'
  | 'Brujas'
  | 'Los Pinos';

export type Propiedad = {
  id: number;
  slug: string;
  titulo: string;
  descripcion: string | null;
  tipo: TipoPropiedad;
  estado_venta: EstadoVenta;
  estado_publicacion: EstadoPublicacion;
  precio: number;
  precio_por_m2: number | null;
  moneda: string;
  zona: Zona;
  direccion_aprox: string | null;
  latitud: number | null;
  longitud: number | null;
  metros_terreno: number | null;
  metros_construccion: number | null;
  uso_de_suelo: UsoSuelo | null;
  servicios: string[] | null;
  escrituras: boolean | null;
  acepta_creditos: string[] | null;
  caracteristicas: string[] | null;
  imagenes: string[] | null;
  destacada: boolean;
  activa: boolean;
  visitas: number;
  created_at: string;
  updated_at: string;
};

// ─── Helpers de consulta ──────────────────────────────────────

export const getPropiedades = async (filtros?: {
  tipo?: TipoPropiedad;
  zona?: Zona;
  estado_venta?: EstadoVenta;
  estado_publicacion?: EstadoPublicacion;
  destacada?: boolean;
}) => {
  let query = supabase
    .from('propiedades')
    .select('*')
    .eq('activa', true)
    .order('created_at', { ascending: false });

  if (filtros?.tipo)               query = query.eq('tipo', filtros.tipo);
  if (filtros?.zona)               query = query.eq('zona', filtros.zona);
  if (filtros?.estado_venta)       query = query.eq('estado_venta', filtros.estado_venta);
  if (filtros?.estado_publicacion) query = query.eq('estado_publicacion', filtros.estado_publicacion);
  if (filtros?.destacada !== undefined) query = query.eq('destacada', filtros.destacada);

  const { data, error } = await query;
  if (error) throw error;
  return data as Propiedad[];
};

export const getPropiedadBySlug = async (slug: string) => {
  const { data, error } = await supabase
    .from('propiedades')
    .select('*')
    .eq('slug', slug)
    .eq('activa', true)
    .single();

  if (error) throw error;
  return data as Propiedad;
};
