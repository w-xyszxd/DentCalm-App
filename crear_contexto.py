import os

# --- CONFIGURACIÓN ---
# Añade aquí las carpetas que quieres ignorar.
directorios_ignorados = {'.dart_tool', '.idea', '.git', 'previous', 'node_modules', '.gradle', '.next', 'venv', 'build', '.vscode', 'target', 'release', 'linux','macos','ios','android','windows'}

# Añade aquí los archivos específicos que quieres ignorar.
archivos_ignorados = {'package-lock.json', '.env', '.env.prod', 'project_context.txt', 'crear_contexto.py', 'app_odontologo.iml'}

# Añade las extensiones de archivo que quieres ignorar (archivos binarios, etc.).
extensiones_ignoradas = {
    '.png', '.lock','.csv', '.svg', '.ico', '.jar', '.bin', '.webp', '.lib', '.exe',
    '.pdf', '.docx', '.exe',    '.exp', '.so', '.pro',              # Documentos
    '.zip', '.rar', '.gz',        '.txt',  '.dot',               # Comprimidos
    '.pyc', '.css', '.pyd', '.yml','.metadata'                         # Python compilado
}

# Nombre del archivo de salida donde se guardará todo el contexto.
archivo_salida = 'project_context.txt'
# --- FIN DE LA CONFIGURACIÓN ---

def obtener_archivos_del_proyecto(directorio_raiz):
    """Recorre el directorio del proyecto y genera la ruta de los archivos válidos."""
    for dirpath, dirnames, filenames in os.walk(directorio_raiz):
        # Excluir directorios de la lista de ignorados
        dirnames[:] = [d for d in dirnames if d not in directorios_ignorados]
        
        for filename in filenames:
            # Comprobar si el archivo o su extensión deben ser ignorados
            if filename in archivos_ignorados:
                continue
            
            _, extension = os.path.splitext(filename)
            if extension in extensiones_ignoradas:
                continue

            yield os.path.join(dirpath, filename)

def main():
    """Función principal que crea el archivo de contexto."""
    directorio_actual = os.getcwd()
    print(f"Iniciando el escaneo del proyecto en: {directorio_actual}")

    try:
        with open(archivo_salida, 'w', encoding='utf-8', errors='ignore') as f_out:
            for filepath in obtener_archivos_del_proyecto(directorio_actual):
                # Obtenemos la ruta relativa para que sea más limpia
                relative_path = os.path.relpath(filepath, directorio_actual)
                # Usamos barras inclinadas (/) para consistencia entre sistemas operativos
                relative_path = relative_path.replace('\\', '/')

                print(f"Procesando: {relative_path}")

                try:
                    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f_in:
                        contenido = f_in.read()
                    
                    # Escribimos la cabecera, el contenido y el separador
                    f_out.write(f"// {relative_path}\n")
                    f_out.write(contenido)
                    f_out.write("\n\n" + "-" * 80 + "\n\n")

                except Exception as e:
                    print(f"  -> Error leyendo el archivo {relative_path}: {e}")

        print(f"\n¡Éxito! El contexto del proyecto ha sido guardado en '{archivo_salida}'")

    except Exception as e:
        print(f"\nOcurrió un error general: {e}")

if __name__ == "__main__":
    main()