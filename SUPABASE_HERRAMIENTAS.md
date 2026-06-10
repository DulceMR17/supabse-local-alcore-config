# 📘 Herramientas de Supabase y para qué sirven

Este documento explica de forma didáctica por qué usamos cada herramienta de Supabase, cómo se conectan entre sí y por qué elegimos los puertos que aparecen en esta configuración.

Está pensado para estudiantes que quieren comprender la arquitectura completa, no solo copiar y pegar código.

---

## 1. ¿Qué es Supabase?

Supabase es una plataforma open source que transforma una base de datos PostgreSQL en una plataforma completa de backend. Incluye autenticación, APIs, almacenamiento, datos en tiempo real y una interfaz gráfica.

En este repo estamos armando una versión self-hosted que se ejecuta localmente con Docker.

---

## 2. Componentes principales y su función

### 2.1 PostgreSQL (`db`)

- Qué es: la base de datos principal.
- Para qué sirve: guarda todos los datos de la aplicación, usuarios, tablas, políticas, historiales y configuraciones.
- Por qué lo instalamos: sin PostgreSQL no hay datos, no hay API y no hay forma de persistir información.
- Puerto usado: `5432`.
  - Este es el puerto estándar de PostgreSQL.
  - En nuestra configuración lo exponemos localmente para poder conectar herramientas directamente si hace falta.

### 2.2 Auth / GoTrue (`auth`)

- Qué es: el servicio de autenticación de Supabase.
- Para qué sirve: gestiona registros, inicios de sesión, recuperación de contraseña, JWT y OAuth.
- Por qué lo instalamos: es la forma en que los usuarios se identifican y obtienen tokens para acceder a la plataforma.
- Puerto usado en el contenedor: `9999`.
  - Este puerto no se expone directamente al host en el compose, porque Kong lo enruta de forma interna.
  - Así mantenemos la seguridad y centralizamos el acceso.

### 2.3 Realtime (`realtime`)

- Qué es: un servicio que detecta cambios en la base de datos y los transmite en tiempo real.
- Para qué sirve: permite notificaciones, chats y actualizaciones instantáneas sin recargar la página.
- Por qué lo instalamos: queremos que la aplicación pueda reaccionar a cambios de datos inmediatamente.
- Puerto usado en el contenedor: `4000`.
  - Se usa internamente para que Kong pueda redirigir tráfico del endpoint `/realtime/v1`.

### 2.4 PostgREST (`rest`)

- Qué es: el generador automático de API REST para PostgreSQL.
- Para qué sirve: convierte las tablas y vistas de PostgreSQL en endpoints HTTP listos para usar.
- Por qué lo instalamos: evita tener que escribir una API manual desde cero.
- Puerto usado en el contenedor: `3000`.
  - Kong lo usa para enrutar `/rest/v1` hacia este servicio.

### 2.5 Storage (`storage`)

- Qué es: el servicio de archivos de Supabase.
- Para qué sirve: guarda imágenes, PDFs, videos y cualquier archivo que la aplicación necesite.
- Por qué lo instalamos: muchas apps requieren persistir archivos y accederlos desde URLs.
- Puerto usado internamente: `5000`.
  - Es el puerto que usa el servicio dentro del contenedor.
  - Kong lo expone como `/storage/v1`.

### 2.6 ImgProxy (`imgproxy`)

- Qué es: un servicio de optimización de imágenes.
- Para qué sirve: convierte y redimensiona imágenes automáticamente.
- Por qué lo instalamos: mejora el rendimiento de la app y reduce el peso de las imágenes.
- Puerto usado internamente: `5001`.
  - No se expone directamente al host.
  - Storage lo usa para procesar imágenes antes de entregarlas.

### 2.7 Postgres Meta (`meta`)

- Qué es: un servicio que proporciona metadatos para la consola de Supabase.
- Para qué sirve: permite a Studio saber cómo conectarse a la base de datos y manejar esquemas.
- Por qué lo instalamos: Studio necesita este servicio para administrar la base de datos de forma visual.
- Puerto usado internamente: `8080`.

### 2.8 Studio (`studio`)

- Qué es: la interfaz gráfica de Supabase.
- Para qué sirve: permite crear tablas, ver datos, ejecutar SQL, configurar reglas y administrar Storage.
- Por qué lo instalamos: facilita el aprendizaje y la administración sin tener que usar solo la consola.
- Puerto usado internamente: `3000`.
  - Kong lo expone como la raíz `/`.

### 2.9 Kong (`kong`)

- Qué es: un gateway / proxy que enruta el tráfico a los servicios correctos.
- Para qué sirve: recibe todas las peticiones externas y las envía al servicio adecuado.
- Por qué lo instalamos: centraliza el acceso y permite un único punto de entrada al sistema.
- Puerto expuesto al host: `8000`.
  - Es el único puerto que necesitamos abrir hacia afuera para el usuario.
  - Todas las demás rutas pasan por Kong.

---

## 3. ¿Por qué usamos Kong?

Kong hace dos cosas muy importantes:

1. centraliza el acceso a múltiples servicios, evitando tener que exponer cada puerto por separado;
2. permite unificar rutas y aplicar reglas de seguridad si lo necesitamos.

Por ejemplo, desde el navegador solo verás `http://localhost:8000/auth/v1` o `http://localhost:8000/rest/v1`.

---

## 4. ¿Qué significa "puerto interno" y "puerto externo"?

- Puerto interno: es el puerto que el servicio utiliza dentro de su contenedor Docker.
- Puerto externo: es el puerto que se expone fuera del contenedor en tu máquina.

En este proyecto solo exponemos los puertos que necesitamos en el host:

- `5432` para PostgreSQL si quieres conectar herramientas externas.
- `8000` para Kong como punto de entrada único.

Los demás servicios se comunican dentro de la red de Docker.

---

## 5. Ejemplo de uso para un estudiante

Imagina que quieres consultar datos desde una aplicación web:

1. El navegador hace una petición a `http://localhost:8000/rest/v1`.
2. Kong recibe la petición y la envía al servicio `rest`.
3. `rest` consulta PostgreSQL y devuelve los registros.

Si quieres autenticar a un usuario:

1. La aplicación pide un token a `http://localhost:8000/auth/v1`.
2. Auth genera el JWT y lo devuelve.
3. Después, el navegador puede usar ese token para llamar al resto de servicios.

---

## 6. ¿Por qué esta arquitectura es buena para aprender?

- Te permite ver cómo se separa el backend en servicios especializados.
- Puedes estudiar cada pieza por separado.
- Aprendes conceptos como proxy, API REST, realtime, almacenamiento y autenticación.
- Ves cómo una base de datos PostgreSQL se convierte en una plataforma completa.

---

## 7. Consejos para el estudiante

- Empieza por entender `db` y `rest`.
- Luego aprende `auth`, porque sin autenticación no hay control de acceso.
- Después estudia `realtime` y `storage`.
- Finalmente mira `kong`, que es el puente entre todo.

---

## 8. Cómo se conectan entre sí

- `auth`, `rest`, `realtime`, `storage`, `meta` y `studio` usan `db` como su fuente de datos.
- `kong` dirige el tráfico externo hacia esos servicios.
- `studio` usa `meta` para entender la configuración de la base de datos.
- `storage` usa `imgproxy` para recibir imágenes optimizadas.

---

## 9. Preguntas frecuentes

- ¿Necesito exponer todos los servicios a mi navegador? No. Solo Kong.
- ¿Por qué no expongo `studio` directamente en un puerto distinto? Porque queremos que el acceso pase por Kong.
- ¿Puedo cambiar los puertos? Sí, pero recuerda actualizar `.env` y `kong.yml` si cambias la configuración.

---

## 10. Resumen rápido

- `db`: datos
- `auth`: acceso de usuarios
- `rest`: API automática
- `realtime`: datos en vivo
- `storage`: archivos
- `imgproxy`: optimización de imágenes
- `meta`: configuración para Studio
- `studio`: interfaz gráfica
- `kong`: gateway único
