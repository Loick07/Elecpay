-- Exécuté une seule fois, à la création du volume MySQL.
-- La base `elecpay` et l'utilisateur `elecpay` sont créés par l'image officielle.
-- On ajoute la base de test, vidée et recréée par les tests automatiques.
CREATE DATABASE IF NOT EXISTS elecpay_test
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

GRANT ALL PRIVILEGES ON elecpay_test.* TO 'elecpay'@'%';
FLUSH PRIVILEGES;
