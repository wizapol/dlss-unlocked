# DLSS-Unlocked: revisión de Warcry

Fecha: 2026-10-05. Resultado: mecanismo real y experimental; paquete observado, no aprobado para distribución como binario auditado. Crear este fork no certifica su seguridad ni demuestra ganancias de FPS.

## Qué se revisó

- Empaquetador `ShyVortex/dlss-unlocked` en commit `0798222ff1852574d8987a6fab12955174776371`: script PowerShell, workflow de publicación, instalador Inno Setup, licencias y configuración.
- Código OptiScaler en `73fab132f9f48d194926b27124d9320b0b4cc870`, correspondiente al tag `v0.9.34`: cargador Ampere, selección de proveedores FG, comprobación de versiones y configuración. Revisión dirigida, no revisión línea por línea de todo el repositorio.
- ZIP de la release `NR-v0.9.34`, publicado 2026-10-04: descargado y extraído en una carpeta de auditoría, sin ejecutar DLL, instalador, scripts del paquete ni juegos.
- SHA-256 calculado: `5da85b5d829b391f36936f434f50ae1fbfce4b9e75f823e26debc9df8edb984f`, coincide con el digest del asset en GitHub. Tamaño: 468772985 bytes.
- Inventario completo de archivos con hashes en `WARCRY-OBSERVED-INPUTS.json`; inventario de firmas de las 36 DLL en `WARCRY-BINARY-INVENTORY.csv`. No contienen rutas del equipo.

## Evidencia funcional

OptiScaler intercepta llamadas gráficas del juego y dirige las entradas a proveedores de escalado o generación de fotogramas. `AmpereMfgLoader.cpp` busca y carga un módulo `dlssg_sm86.dll`; el arranque configura el modo de generación externa cuando corresponde. Esto respalda la existencia de una implementación, pero no verifica que el binario distribuido coincida con todo el código fuente ni su funcionamiento en un juego concreto.

El ZIP contiene `External=true` y `AmpereMfgUnlock=true`. Neural Rendering está configurado como `Enabled=auto`, documentado en el propio INI como desactivado por defecto. Instalar el paquete no implica activar todas las funciones de su descripción.

El módulo FG observado proviene de `SilyNoMeta/dlssg_for_sm86`, commit `329b4c85927c64a8dba2e25125e6d02a42ab63fe`, según `.source_repo` y `.commit_sha` dentro del paquete. El script local tiene como predeterminado sdli1995: no debe asumirse que todas las releases usan ese proveedor. El módulo se distribuye precompilado; el árbol consultado de SilyNoMeta no incluye el código C++ completo de su implementación. Por tanto, un fork del empaquetador no permite reconstruir y auditar todo el módulo FG.

## Hallazgos

| Prioridad | Hallazgo | Consecuencia |
|---|---|---|
| Alta | DLL de Neural Rendering descargadas de Catbox con URLs sin versión/hash esperado en el empaquetador y el workflow. | No existe una referencia independiente fijada que garantice cuáles bytes se integraron. HTTPS y el hash final del ZIP no resuelven esta trazabilidad. |
| Alta | `HEAD`, releases `latest` y acciones por tags mutables en la cadena de publicación. | El mismo script puede producir contenido distinto; falta un manifiesto completo de inputs y revisiones fijadas. |
| Alta | La selección de hash del script local sirve como identificador de caché; no compara sistemáticamente el SHA-256 completo del archivo descargado con el esperado. | Un nombre de hash o un checksum calculado después de descargar no equivale a validación del input. |
| Alta | `nvngx_dlssnr.dll` devuelve `HashMismatch` en Authenticode. | Su firma NVIDIA no valida los bytes actuales. Es consistente con que se presenta como DLL parcheada, pero no establece que el parche sea correcto o inocuo. |
| Media | 8 DLL sin firma, 27 con firma válida, 1 con firma alterada. | Ni ausencia de firma prueba malware ni firma válida demuestra compatibilidad o seguridad absoluta. |
| Media | Se incluyen Neural Rendering, kernels/modelos experimentales, múltiples proveedores y utilidades, no únicamente FG para RTX 3070. | Más dependencias y superficie de fallo de las necesarias para una prueba mínima. NR puede consumir rendimiento. |
| Media | `CheckForUpdate=auto`; el código tiene la comprobación habilitada por defecto y consulta GitHub mediante WinHTTP. | Puede haber tráfico de comprobación de versiones desde el juego. El código examinado obtiene metadatos; no es evidencia de autoejecución de actualizaciones. |
| Media | Inno Setup sobrescribe archivos y su desinstalación no implementa un registro/restauración equivalente al de Warcry. | Instalar un mod sobre DLL existentes exige conservar originales; un desinstalador convencional no basta para restituirlos. |

No se encontraron en el ZIP observado archivos EXE, BAT, PS1 ni REG. La revisión dirigida del código del cargador y la comprobación de versiones no identificó una operación de robo de credenciales o persistencia. Esto es una observación acotada, no una declaración de ausencia de malware: quedan DLL precompiladas cuyo comportamiento completo no se reconstruyó ni analizó dinámicamente.

Los README de los módulos originales documentan correcciones de fallos que podían producir corrupción visual y reinicios del driver. No hay evidencia para atribuirles el cuelgue anterior del equipo, ni una prueba realizada aquí que confirme estabilidad en Diablo IV.

## Licencias y afirmaciones

El LICENSE del empaquetador es MIT, pero sus DLL/modelos tienen licencias separadas, incluidas las de NVIDIA. OptiScaler y otros componentes no quedan relicenciados por el empaquetador. No se realizó una evaluación legal ni se autorizó una redistribución de todos los binarios.

Generación de fotogramas puede aumentar los fotogramas presentados, sin equivaler al mismo aumento de simulación del juego o capacidad de respuesta. No se midieron FPS, latencia, VRAM, artefactos ni estabilidad en este equipo. Las afirmaciones de calidad idéntica o ganancias del README son afirmaciones de sus autores, no resultados de esta auditoría.

## Cambios concretos en este fork

1. Los dos jobs heredados de publicación quedan condicionados al repositorio original. No se construye/publica automáticamente un paquete con el nombre de este fork.
2. Se añade `Verify-WarcryInputs.ps1`: verificación offline de aprobación explícita, SHA-256 completo, archivos inesperados, rutas fuera de la carpeta y reparse points. No descarga ni ejecuta entradas.
3. El manifiesto observado tiene `Approved=false`. Registra la evidencia, no convierte esos binarios en aprobados. La herramienta debe rechazarlo.
4. Pruebas con fixtures verifican caso válido y rechazo de manifiesto no aprobado, hash cambiado, archivo adicional y ruta escapada.

La herramienta no está conectada al empaquetador original: este fork es una base de auditoría, no un reemplazo listo del ZIP. Warcry sigue apuntando al upstream; no se cambió silenciosamente de proveedor ni se modificaron juegos.

## Lo que falta para un paquete controlado

Fijar commits/URLs/hashes de cada input, obtener código y método de construcción verificable de los módulos precompilados, retirar componentes NR opcionales de una variante mínima, verificar derechos de distribución, construir OptiScaler desde el tag revisado y comparar artefactos. Después, una prueba en un juego compatible con mediciones separadas de FPS base/presentados, latencia, VRAM, imágenes y recuperación ante fallos. Ninguna de estas etapas debe presentarse como realizada por esta revisión estática.

También quedan hallazgos en la integración Warcry: descarga `latest`, copia todo el payload, no revierte automáticamente una copia parcial, el marcador se escribe después de copiar y el desinstalador necesita tratar INI modificados/reparse points. Sus pruebas de fixtures no sustituyen una auditoría de DLL ni prueban rendimiento. No se ejecutó el instalador contra un juego real durante esta revisión.

## Fuentes

- [Empaquetador revisado](https://github.com/ShyVortex/dlss-unlocked/tree/0798222ff1852574d8987a6fab12955174776371).
- [Release examinada](https://github.com/ShyVortex/dlss-unlocked/releases/tag/NR-v0.9.34).
- [Código OptiScaler revisado](https://github.com/ShyVortex/OptiScaler-DLSSNR-PreSR-Multipass/tree/73fab132f9f48d194926b27124d9320b0b4cc870).
- [Módulo realmente incluido](https://github.com/SilyNoMeta/dlssg_for_sm86/tree/329b4c85927c64a8dba2e25125e6d02a42ab63fe).
- [Documentación sdli1995 consultada](https://github.com/sdli1995/dlssg_for_sm86/tree/9621db573e07ed54f50c15bbb585ed9a7bdfac28).
