# Memoire recente

## Fenetre active

- Mise en place d'une couche de documentation exhaustive des fonctions Lua addon.
- Ajout d'une couche de personnalisation Copilot dans `.github/`.
- Ajout d'un garde-fou de style francais via `fingerprint_check.py`.
- Ajout d'un rappel de workflow sur les demandes de code pour penser a `research-scout`, `research-review` et a la mise a jour de `docs/memory/`.
- Generation initiale de `docs/functions/` executee et validee sans erreur Python.

## Etat technique recent

- `MJ_ANNOUNCE` transporte maintenant l'etat active/desactive du MJ.
- L'export MJ utilise `EASYSANALUNE_EXPORT_V2` tout en important `V1`.
- Le popup offensif ne s'ouvre que si un MJ connu est present dans le groupe.
- Les non-offensifs locaux passent par `RandomRoll(...)` en Lua.
- `core/logic.lua` reutilise maintenant `_G.EasySanaluneCore` au lieu de le recreer, ce qui preserve `Core.Text` et les helpers deja charges par le TOC.
- La modale buffs peut maintenant cibler un rand existant precis du profil courant, y compris dans une categorie personnalisee, et le mode multi utilise un dropdown scrollable.
- Les libelles longs du dropdown de selection buffs sont maintenant contraints au cadre pour eviter le debordement visuel.
- Le menu profil permet maintenant d'importer un export EasySanalune sur un autre personnage en creant un nouveau profil local.
- L'export/import de profil conserve maintenant aussi les categories de rands, leurs issues, les buffs/debuffs et leurs categories a l'identique entre personnages.
- La modale `Fiche` gere maintenant aussi `PDV` (base `5`, minimum `-2`) et le type d'`Armure` (`Nue`, `Légère`, `Intermédiaire`, `Lourde`, `Spéciale`), persistés par profil et exportés/importés.
- Une couche de survie partagée joueur/mob est en place: `Actuellement`, `Durabilité`, `RDA`, `RDA critique`, normalisation dans `core/logic.lua` et support export/import.
- `Actuellement` n'est plus dans le mainframe: l'etat est maintenant partage entre joueurs via `PLAYER_SURVIVAL_SYNC` et s'affiche au survol du personnage dans l'infobulle.
- Le survol ne doit plus dependre du groupe seul: une requete `PLAYER_SURVIVAL_REQUEST` en `WHISPER` demande maintenant les donnees du joueur survole, avec ancrage prefere a cote du tooltip TRP3.
- Le bloc de survol EasySanalune se ferme maintenant plus proprement quand on quitte le personnage: hook de fermeture sur le tooltip TRP3 + garde-fou `OnUpdate` cote frame pour eviter les restes visuels.
- Le survol s'aligne maintenant mieux sur TRP3: ancrage prefere au `TRP3_MainTooltip`, re-ancrage si le tooltip TRP3 apparait apres coup, et disparition en degrade.
- Ajustement UX apres test en jeu: le bloc EasySanalune de survol est maintenant fixe cote droit de l'ecran pour eviter l'effet de flottement non ancre vu en pratique.
- Le bloc de survol reste maintenant visible tant que le curseur est encore sur un personnage et attend 1 seconde avant de lancer son fade-out, pour un ressenti plus proche de TRP3.
- La modale `Fiche` rafraichit maintenant tout de suite `Durabilité`, `RDA` et `RDA critique` quand le type d'armure change; les champs sont grises pour les armures classiques, `Nue` n'a pas de durabilite et `Intermédiaire` est fixe a `3/3`.
- Les skills `research-scout`, `research-review` et `consolidate-memory` ont maintenant une frontmatter exploitable pour une meilleure detection.
- Correction anti-bruit chat: suppression de l'inscription auto au canal texte public `easysanalune` et de l'annonce `EasySanalune <version>` en `CHANNEL` dans le bootstrap.
- Le transport protocolaire addon reste uniquement en `C_ChatInfo.SendAddonMessage` (`RAID`/`PARTY`/`WHISPER`) pour eviter l'affichage de types bruts comme `PLAYER_SURVIVAL_REQUEST` dans le chat.

## A surveiller

- Regenerer `docs/functions/` apres tout changement de signatures Lua.
- Garder `docs/PROTOCOL.md` synchronise avec les messages addon.
- Le research-scout du jour confirme que `FontString:SetWordWrap(false)` et `FontString:SetMaxLines(1)` sont les pistes WoW propres pour contenir les libelles longs si un nouveau polish UI devient necessaire.
- Verifier en jeu que la fenetre MJ expose bien les nouveaux champs de survie avec le meme comportement que la fiche joueur.
- Les hooks peuvent rappeler un workflow, pas lancer seuls un skill Copilot de maniere garantie.
- Si la session suivante touche encore la customisation Copilot, verifier en usage reel que l'environnement charge bien les hooks workspace `.github/hooks/`.