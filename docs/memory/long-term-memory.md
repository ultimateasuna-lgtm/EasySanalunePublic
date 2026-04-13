# Memoire long terme

## Preferences confirmees

- Reponses et documentation en francais direct.
- Priorite a la compatibilite WoW Retail 9.2.7.
- Les librairies embarquees dans `libs/` ne sont pas la cible normale des modifications.

## Decisions stables

- La doc fonctionnelle addon est generee dans `docs/functions/`.
- Les skills executables Copilot vivent dans `.github/skills/`.
- Les docs humaines de workflow vivent dans `docs/skills/`.
- Les notes de contexte persistantes du projet vivent dans `docs/memory/`.
- Les hooks workspace servent de rappels et de garde-fous deterministes, mais ne remplacent pas l'appel explicite ou la decision agentique d'executer un skill.