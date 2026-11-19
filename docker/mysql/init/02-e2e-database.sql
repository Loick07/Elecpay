-- Base des tests d'intégration sur le téléphone (frontend/mobile/tool/integration.ps1), vidée et
-- remplie à chaque passage : la base de démo `elecpay` n'est jamais remise à zéro par ces tests.
-- Exécuté à la création du volume MySQL, et rejoué (sans risque) par integration.ps1 sur un volume
-- déjà créé.
CREATE DATABASE IF NOT EXISTS elecpay_e2e
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

GRANT ALL PRIVILEGES ON elecpay_e2e.* TO 'elecpay'@'%';
FLUSH PRIVILEGES;
