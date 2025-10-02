# Author: Juan Fernando Zuluaga Restrepo
# Co-Author: Juan Diego Campuzano

echo "---> Original sync branch name: $SYNC_BRANCH"

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
echo "New Sync branch: $SYNC_BRANCH" # Nombre de la rama intermedia que se crea apartir de la rama SOURCE_BRANCH
echo "Number of original PR: $PR_NUMBER" # Número del PR original que disparó este flujo
echo "File with the ours files: $OURS_FILES_LIST"
echo "------------------------------------------"

echo "---> Showing current branches and which one we are on:"
git branch

# Vamos para la rama base y hacemos pull para tenerla actualizada
echo "---> Switching to base branch: '$BASE_BRANCH'..."
git fetch origin
git checkout $BASE_BRANCH

echo "---> Verifying we are on base branch: '$BASE_BRANCH':"
git branch

echo "---> Updating base branch '$BASE_BRANCH'..."
git pull

echo "---> Creating/Updating intermediate branch '$SYNC_BRANCH' from '$BASE_BRANCH'..."
git checkout -b "$SYNC_BRANCH" "origin/$BASE_BRANCH"

echo "---> Showing current branches and which one we are on:"
git branch

# Realizamos el merge de la rama SOURCE_BRANCH en la rama SYNC_BRANCH
echo "---> Merging '$SOURCE_BRANCH' into '$SYNC_BRANCH'..."

git merge "origin/$SOURCE_BRANCH" --no-commit || true

echo "---> Running git status"
git status

if git status | grep -q "Unmerged paths"; then
    echo "---> Conflicts detected. Resolving automatically..."
    # Resolver archivos específicos
    if [ -f "$OURS_FILES_LIST" ]; then
        echo "----> Checking files to keep from 'ours' branch in: $OURS_FILES_LIST"
       while IFS= read -r file || [ -n "$file" ]; do
            [ -z "$file" ] && continue  # Salta líneas vacías
            if [ -f "$file" ]; then
                echo "---> Adding file from ours branch: $file"
                git checkout --ours "$file" 
                git add "$file"
            else
                echo "---> File does not exist: $file"
            fi
        done < "$OURS_FILES_LIST"
    else
        echo "---> No configuration file for ours files found: $OURS_FILES_LIST"
    fi

    # Solucionamos los demás conflictos tomando los cambios de la rama que se está mergeando
    git checkout --theirs .
    # Agregamos todos los archivos
    git add .
    # Agregamos todos los archivos al staging
    git commit -m "chore: merge $SOURCE_BRANCH into $SYNC_BRANCH (auto-resuelto)"
    echo "---> Conflicts automatically resolved."
else
    echo "---> No conflicts found"
    git add .
    git commit -m "chore: merge $SOURCE_BRANCH into $SYNC_BRANCH"
fi

# Sube la rama intermedia al repositorio. 
# El '--force' es necesario para sobreescribir la versión anterior de la rama.
echo "---> Pushing branch '$SYNC_BRANCH' to remote repository..."
git push --force origin "$SYNC_BRANCH"

# Verifica si ya existe un PR abierto desde la rama intermedia
echo "---> Checking if a PR already exists from '$SYNC_BRANCH'..."
EXISTING_PR=$(gh pr list --head "$SYNC_BRANCH" --base "$BASE_BRANCH" --json url --jq '.[0].url')

if [ -z "$EXISTING_PR" ]; then
echo "---> No existing PR found. Creating a new one..."

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
echo "---> A Pull Request already exists for this homologation: $EXISTING_PR"
echo "---> The PR branch has been updated with the latest changes from '$SOURCE_BRANCH'."
fi

echo "===> Powered by Galatea 🐺, Grupo Cibest ❤️"