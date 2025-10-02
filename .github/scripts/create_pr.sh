# Author: Juan Fernando Zuluaga Restrepo
# Co-Author: Juan Diego Campuzano

echo "---> Nombre original de la rama sync: $SYNC_BRANCH"

# Separamos el prefijo (todo ANTES del primer '/')
# Ejemplo: de "feature/stable/5.x-to-trunk", esto extrae "feature"
PREFIX="${SYNC_BRANCH%%/*}"

# Obtenemos el resto de la cadena (todo DESPUÉS del primer '/')
# Ejemplo: extrae "stable/5.x-to-trunk"
SUFFIX="${SYNC_BRANCH#*/}"

# En el resto de la cadena, reemplazamos todos los '/' por una cadena vacía
# Ejemplo: "stable/5.x-to-trunk" se convierte en "stable5.x-to-trunk"
CLEANED_SUFFIX="${SUFFIX//\//}"

# Reconstruimos la variable SYNC_BRANCH con el formato deseado
SYNC_BRANCH="$PREFIX/$CLEANED_SUFFIX-$PR_NUMBER"


echo "------------------------------------------"
echo "Base branch: $BASE_BRANCH"  # Rama base a la que se quiere hacer el merge 
echo "Source branch: $SOURCE_BRANCH"  # Rama que se actualizó y desde la cual se crea la rama intermedia
echo "Nueva Sync branch: $SYNC_BRANCH" # Nombre de la rama intermedia que se crea apartir de la rama SOURCE_BRANCH
echo "Número del PR original: $PR_NUMBER" # Número del PR original que disparó este flujo
echo "Archivo a leer con los archivos a ignorar: $OURS_FILES_LIST"
echo "------------------------------------------"

echo "---> Mostrando las ramas actuales y en cuál estamos:"
git branch

# Vamos para la rama base y hacemos pull para tenerla actualizada
echo "---> Cambiando a la rama base: '$BASE_BRANCH'..."
git fetch origin
git checkout $BASE_BRANCH

echo "---> Verificando si estamos en la rama base: '$BASE_BRANCH':"
git branch

echo "---> Actualizando la rama base '$BASE_BRANCH'..."
git pull

echo "---> Creando/Actualizando la rama intermedia '$SYNC_BRANCH' desde '$BASE_BRANCH'..."
git checkout -b "$SYNC_BRANCH" "origin/$BASE_BRANCH"

echo "---> Mostrando las ramas actuales y en cuál estamos:"
git branch

# Realizamos el merge de la rama SOURCE_BRANCH en la rama SYNC_BRANCH
echo "---> Realizando merge de '$SOURCE_BRANCH' en '$SYNC_BRANCH'..."

git merge "origin/$SOURCE_BRANCH" --no-commit || true

echo "---> Realizamos un git status"
git status

if git status | grep -q "Unmerged paths"; then
    echo "---> Conflictos detectados. Resolviendo automáticamente..."
    # Resolver archivos específicos
    if [ -f "$OURS_FILES_LIST" ]; then
        echo "----> Verificando archivos para mantener desde la rama 'ours' en: $OURS_FILES_LIST"
       while IFS= read -r file || [ -n "$file" ]; do
            [ -z "$file" ] && continue  # Salta líneas vacías
            if [ -f "$file" ]; then
                echo "---> Agregando archivo de la rama ours: $file"
                git checkout --ours "$file" 
                git add "$file"
            else
                echo "---> El archivo no existe: $file"
            fi
        done < "$OURS_FILES_LIST"
    else
        echo "No se encontró el archivo de configuración de archivos ours: $OURS_FILES_LIST"
    fi

    # Solucionamos los demás conflictos tomando los cambios de la rama que se está mergeando
    git checkout --theirs .
    # Agregamos todos los archivos
    git add .
    # Agregamos todos los archivos al staging
    git commit -m "chore: merge $SOURCE_BRANCH into $SYNC_BRANCH (auto-resuelto)"
    echo "---> Conflictos automáticamente resueltos."
else
    echo "---> No hay conflictos"
    git add .
    git commit -m "chore: merge $SOURCE_BRANCH into $SYNC_BRANCH"
fi

# Sube la rama intermedia al repositorio. 
# El '--force' es necesario para sobreescribir la versión anterior de la rama.
echo "---> Subiendo la rama '$SYNC_BRANCH' al repositorio remoto..."
git push --force origin "$SYNC_BRANCH"

# Verifica si ya existe un PR abierto desde la rama intermedia
echo "---> Verificando si ya existe un PR desde '$SYNC_BRANCH'..."
EXISTING_PR=$(gh pr list --head "$SYNC_BRANCH" --base "$BASE_BRANCH" --json url --jq '.[0].url')

if [ -z "$EXISTING_PR" ]; then
echo "---> No existe un PR. Creando uno nuevo..."

# Crea el PR desde la rama intermedia hacia trunk
gh pr create \
    --base "$BASE_BRANCH" \
    --head "$SYNC_BRANCH" \
    --title "🤖 Homologacion: Merge $SOURCE_BRANCH a $BASE_BRANCH, pr origen: $PR_NUMBER" \
    --body "Este PR ha sido generado automáticamente para sincronizar los cambios de la rama \`$SOURCE_BRANCH\` a \`$BASE_BRANCH\` a través de la rama intermedia \`$SYNC_BRANCH\`.

Pull Request origen de los cambios: #$PR_NUMBER

resolve #" \
    --label "automated-pr"
else
echo "---> Ya existe un Pull Request para esta homologación: $EXISTING_PR"
echo "---> La rama del PR ha sido actualizada con los últimos cambios de '$SOURCE_BRANCH'."
fi

echo "---> Power by Galatea 🐺, Grupo Cibest ❤️"