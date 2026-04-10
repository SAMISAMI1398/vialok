#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────
#  VIALOK — GitHub Deploy Script
#  Prérequis : git, gh (GitHub CLI, authentifié)
# ─────────────────────────────────────────────────────────

REPO_NAME="vialok"
BRANCH="main"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'
BOLD='\033[1m'

log()  { echo -e "${BLUE}▶${RESET} $1"; }
ok()   { echo -e "${GREEN}✓${RESET} $1"; }
warn() { echo -e "${YELLOW}⚠${RESET}  $1"; }
fail() { echo -e "${RED}✗ ERROR:${RESET} $1"; exit 1; }

echo ""
echo -e "${BOLD}  VIALOK — GitHub Deployment${RESET}"
echo -e "  ────────────────────────────"
echo ""

# ── 0. Vérifications ───────────────────────────────────────
log "Vérification des dépendances..."

command -v git &>/dev/null || fail "git n'est pas installé."
command -v gh  &>/dev/null || fail "GitHub CLI (gh) n'est pas installé. Installe-le via : brew install gh"

gh auth status &>/dev/null || fail "gh n'est pas authentifié. Lance : gh auth login"

ok "Dépendances OK"

# ── 1. Init Git local ──────────────────────────────────────
cd "$DIR"
log "Initialisation du dépôt Git local dans : $DIR"

if [ -d ".git" ]; then
  warn "Dépôt Git déjà initialisé — étape ignorée."
else
  git init -b "$BRANCH"
  ok "git init — branche '$BRANCH' créée"
fi

# ── 2. Création du dépôt GitHub ────────────────────────────
log "Création du dépôt public '$REPO_NAME' sur GitHub..."

if gh repo view "$REPO_NAME" &>/dev/null 2>&1; then
  warn "Le dépôt '$REPO_NAME' existe déjà sur GitHub — étape ignorée."
else
  gh repo create "$REPO_NAME" \
    --public \
    --description "VIALOK — Absolute Security. Instant Inventory." \
    --source=. \
    --remote=origin
  ok "Dépôt GitHub créé"
fi

# Vérifie que le remote 'origin' est bien configuré
if ! git remote get-url origin &>/dev/null; then
  GITHUB_USER=$(gh api user --jq '.login')
  git remote add origin "https://github.com/${GITHUB_USER}/${REPO_NAME}.git"
  ok "Remote 'origin' configuré"
fi

# ── 3. Commit ──────────────────────────────────────────────
log "Staging et commit des fichiers..."

git add .

if git diff --cached --quiet; then
  warn "Rien à committer — working tree propre."
else
  git commit -m "feat: initial VIALOK landing page

Dark industrial design, Tailwind CSS, fully static.
Sections: Hero, Problem/Solution, Contact CTA."
  ok "Commit créé"
fi

# ── 4. Push ────────────────────────────────────────────────
log "Push sur origin/$BRANCH..."

git push -u origin "$BRANCH"
ok "Code pushé sur GitHub"

# ── 5. Activation de GitHub Pages ─────────────────────────
log "Activation de GitHub Pages (branche $BRANCH, dossier /)..."

GITHUB_USER=$(gh api user --jq '.login')

gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  "/repos/${GITHUB_USER}/${REPO_NAME}/pages" \
  -f "source[branch]=$BRANCH" \
  -f "source[path]=/" \
  &>/dev/null && ok "GitHub Pages activé" \
  || warn "GitHub Pages déjà activé ou configuration déjà existante."

# ── 6. URL finale ──────────────────────────────────────────
PAGES_URL="https://${GITHUB_USER}.github.io/${REPO_NAME}/"

echo ""
echo -e "  ────────────────────────────────────────────"
echo -e "  ${GREEN}${BOLD}Déploiement terminé.${RESET}"
echo ""
echo -e "  ${BOLD}Dépôt GitHub :${RESET}  https://github.com/${GITHUB_USER}/${REPO_NAME}"
echo -e "  ${BOLD}Site en ligne :${RESET} ${BLUE}${PAGES_URL}${RESET}"
echo ""
echo -e "  ${YELLOW}Note :${RESET} GitHub Pages peut prendre 1–2 minutes"
echo -e "         avant d'être accessible."
echo -e "  ────────────────────────────────────────────"
echo ""
