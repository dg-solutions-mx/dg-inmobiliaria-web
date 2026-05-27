# Guía rápida de edición — DG Inmobiliaria

## Qué incluye este proyecto

- Home completo en Astro basado en el mockup aprobado.
- Hero fotográfico de Mazatlán con overlay, CTA y tarjeta flotante.
- Navbar fija con cambio de apariencia al hacer scroll y menú móvil.
- Barra de confianza, tarjetas de ayuda, bloque editorial de Mazatlán, proceso, formulario, CTA final y footer.
- Animaciones suaves de entrada, parallax ligero, hover de tarjetas y botón flotante de WhatsApp.
- Diseño responsive.

## Archivos principales

- `src/pages/index.astro`: integra todas las secciones.
- `src/components/`: cada sección del home.
- `src/styles/global.css`: paleta, tipografías, responsividad y animaciones.
- `public/assets/`: imágenes y logotipo usados en el diseño.

## Cambios obligatorios antes de publicar

### Número de WhatsApp
Busca `WHATSAPP_URL` en:

- `src/components/Header.astro`
- `src/components/Hero.astro`
- `src/components/ContactForm.astro`
- `src/components/FinalCTA.astro`
- `src/components/Footer.astro`
- `src/components/WhatsAppButton.astro`

El número actual se colocó como referencia visual basado en tu portada. Sustitúyelo si será otro número comercial.

### Formulario
El formulario está maquetado visualmente; el botón aún no envía datos. Posteriormente puede conectarse a Formspark, Formspree, Resend, Supabase o un backend propio.

### Redes sociales
Los enlaces de Instagram y Facebook están como `#` en `src/components/Footer.astro`. Sustitúyelos por tus URLs reales.

### Imágenes secundarias
Las imágenes de las tarjetas y del bloque editorial se tomaron del mockup para igualar la apariencia. Cuando tengas fotografías reales, reemplaza:

- `public/assets/card-casa.webp`
- `public/assets/card-explorar.webp`
- `public/assets/card-asesoria.webp`
- `public/assets/mazatlan-lifestyle.webp`

## Ejecutar en local

```bash
npm install
npm run dev
```

## Generar versión lista para publicar

```bash
npm run build
```

La carpeta generada será `dist/`.
