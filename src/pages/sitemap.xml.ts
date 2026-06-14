import type { APIRoute } from 'astro';
import { getPropiedades } from '../lib/supabase';

const BASE = 'https://dginmobiliaria.mx';

export const GET: APIRoute = async () => {
  let slugs: string[] = [];
  try {
    const props = await getPropiedades();
    slugs = props.map(p => p.slug).filter(Boolean);
  } catch {}

  const today = new Date().toISOString().split('T')[0];

  const pages = [
    { loc: BASE,                   priority: '1.0', changefreq: 'weekly'  },
    { loc: `${BASE}/propiedades`,  priority: '0.9', changefreq: 'daily'   },
    ...slugs.map(slug => ({
      loc: `${BASE}/propiedades/${slug}`,
      priority: '0.8',
      changefreq: 'weekly',
    })),
  ];

  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${pages.map(p => `  <url>
    <loc>${p.loc}</loc>
    <lastmod>${today}</lastmod>
    <changefreq>${p.changefreq}</changefreq>
    <priority>${p.priority}</priority>
  </url>`).join('\n')}
</urlset>`;

  return new Response(xml, {
    headers: {
      'Content-Type': 'application/xml; charset=utf-8',
      'Cache-Control': 'public, max-age=3600',
    },
  });
};
