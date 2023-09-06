-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Hôte : 127.0.0.1
-- Généré le : ven. 12 mai 2023 à 16:59
-- Version du serveur : 10.4.28-MariaDB
-- Version de PHP : 8.2.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de données : `picom`
--

DELIMITER $$
--
-- Procédures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `AjouterArret` (IN `p_nom_arret` VARCHAR(100), IN `p_id_zone` INT, IN `p_adresse_ip` VARCHAR(15))   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    INSERT INTO Arret (arret_nom, id_zone, adresse_ip_raspberry)
    VALUES (p_nom_arret, p_id_zone, p_adresse_ip);
    
    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `nouvelle_annonce` (IN `p_utilisateur_id` INT, IN `p_contenu` TEXT, IN `p_format` BOOLEAN, IN `p_chemin_fichier` VARCHAR(255), IN `p_date_creation` DATETIME, IN `p_statut` VARCHAR(100), IN `p_id_arret` INT, IN `p_date_debut_diffusion` DATETIME, IN `p_date_fin_diffusion` DATETIME)   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    INSERT INTO Annonce (id_utilisateur, format, contenu, chemin_fichier, date_creation, statut)
    VALUES (p_utilisateur_id, p_format, p_contenu, p_chemin_fichier, p_date_creation, p_statut);
    SET @annonce_id = LAST_INSERT_ID();

    INSERT INTO Diffusion (id_annonce, id_arret, date_debut_diffusion, date_fin_diffusion)
    VALUES (@annonce_id, p_id_arret, p_date_debut_diffusion, p_date_fin_diffusion);

    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `SupprimerClient` (IN `p_utilisateur_id` INT)   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    DELETE FROM annonce WHERE id_utilisateur = p_utilisateur_id;

    DELETE FROM log WHERE id_utilisateur = p_utilisateur_id;

    DELETE FROM utilisateur WHERE utilisateur_id = p_utilisateur_id;

    COMMIT;
END$$

--
-- Fonctions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `calcul_cout_total` (`p_zone_id` INT, `p_tranche_horaire_id` INT, `p_nombre_jours` INT) RETURNS DECIMAL(10,2)  BEGIN
    DECLARE v_tarif DECIMAL(10,2);
    DECLARE v_tarif_id INT;
    
    SELECT tarif_id INTO v_tarif_id
    FROM Tarif
    WHERE zone_id = p_zone_id AND tranche_horaire_id = p_tranche_horaire_id;
    
    SELECT tarif_diffusion INTO v_tarif
    FROM Tarif
    WHERE tarif_id = v_tarif_id;
    
    RETURN v_tarif * p_nombre_jours;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `nbr_campagnes_actives` (`p_utilisateur_id` INT) RETURNS INT(11)  BEGIN
    DECLARE v_nbr_campagnes INT;
    
    SELECT COUNT(*) INTO v_nbr_campagnes
    FROM Annonce
    WHERE id_utilisateur = p_utilisateur_id
    AND statut = 'En cours';
    
    RETURN v_nbr_campagnes;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `welcome` (`p_client_nom` VARCHAR(100)) RETURNS VARCHAR(255) CHARSET utf8mb4 COLLATE utf8mb4_general_ci  BEGIN
    DECLARE v_last_modification_date DATE;
    DECLARE v_message VARCHAR(255);
    
    -- Récupérer la dernière date de modification de campagne du client
    SELECT MAX(date_creation) INTO v_last_modification_date
    FROM Annonce
    WHERE id_utilisateur = (SELECT utilisateur_id FROM Utilisateur WHERE nom = p_client_nom);
    
    -- Formater la date au format souhaité (ex : vendredi 12 mai 2023)
    SET v_message = CONCAT('Bienvenue ', p_client_nom, ', votre dernière modification de campagne remonte au ', DATE_FORMAT(v_last_modification_date, '%W %e %M %Y'), '.');
    
    RETURN v_message;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `annonce`
--

CREATE TABLE `annonce` (
  `annonce_id` int(11) NOT NULL,
  `id_utilisateur` int(11) NOT NULL,
  `format` tinyint(1) NOT NULL,
  `contenu` text DEFAULT NULL,
  `chemin_fichier` varchar(250) DEFAULT NULL,
  `date_creation` datetime NOT NULL,
  `statut` varchar(100) NOT NULL,
  `last_update` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `annonce`
--

INSERT INTO `annonce` (`annonce_id`, `id_utilisateur`, `format`, `contenu`, `chemin_fichier`, `date_creation`, `statut`, `last_update`) VALUES
(1, 3, 1, 'Bienvenue dans notre boutique!', 'chemin/vers/fichier.html', '2023-05-25 00:00:00', '1', '0000-00-00 00:00:00'),
(2, 6, 0, 'Promotion spéciale : 50% de réduction!', 'chemin/vers/fichier.png', '2023-05-23 00:00:00', '1', '0000-00-00 00:00:00'),
(5, 1, 1, 'Contenu de l\'annonce', 'chemin/fichier.png', '2023-05-12 13:46:55', 'Actif', '0000-00-00 00:00:00'),
(10, 1, 0, 'Lorem ipsum dolor sit amet', NULL, '2023-05-12 16:58:03', 'Actif', '0000-00-00 00:00:00');

--
-- Déclencheurs `annonce`
--
DELIMITER $$
CREATE TRIGGER `annonce_trigger` AFTER INSERT ON `annonce` FOR EACH ROW BEGIN
INSERT INTO log (action_date, action_type, id_utilisateur, message)
VALUES (NOW(), "Nouvelle campagne ajoutée", NEW.id_utilisateur, NULL);
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `arret`
--

CREATE TABLE `arret` (
  `arret_id` int(11) NOT NULL,
  `arret_nom` varchar(100) NOT NULL,
  `adresse_ip_raspberry` int(11) NOT NULL,
  `id_zone` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `arret`
--

INSERT INTO `arret` (`arret_id`, `arret_nom`, `adresse_ip_raspberry`, `id_zone`) VALUES
(12, 'Arrêt Gare Est', 192168, 23),
(16, 'Arrêt Centre-Ville', 192164, 25),
(19, 'Nom de l\'arrêt', 192148, 23),
(21, 'place_nuage', 192118, 24);

-- --------------------------------------------------------

--
-- Structure de la table `audit`
--

CREATE TABLE `audit` (
  `audit_id` int(11) NOT NULL,
  `id_utilisateur` int(11) NOT NULL,
  `action_effectuee` varchar(50) NOT NULL,
  `table_affectee` varchar(50) NOT NULL,
  `id_element` int(11) NOT NULL,
  `audit_date_heure` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Structure de la table `chat`
--

CREATE TABLE `chat` (
  `chat_id` int(11) NOT NULL,
  `id_utilisateur` int(11) NOT NULL,
  `message` text NOT NULL,
  `chat_date_heure` datetime NOT NULL,
  `id_message_reponse` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Structure de la table `diffusion`
--

CREATE TABLE `diffusion` (
  `diffusion_id` int(11) NOT NULL,
  `id_annonce` int(11) NOT NULL,
  `id_arret` int(11) NOT NULL,
  `date_debut_diffusion` datetime NOT NULL,
  `date_fin_diffusion` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `diffusion`
--

INSERT INTO `diffusion` (`diffusion_id`, `id_annonce`, `id_arret`, `date_debut_diffusion`, `date_fin_diffusion`) VALUES
(4, 5, 12, '2023-05-01 00:00:00', '2023-05-15 00:00:00');

-- --------------------------------------------------------

--
-- Structure de la table `log`
--

CREATE TABLE `log` (
  `log_id` int(11) NOT NULL,
  `id_utilisateur` int(11) NOT NULL,
  `action_date` datetime NOT NULL,
  `action_type` varchar(50) NOT NULL,
  `message` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `log`
--

INSERT INTO `log` (`log_id`, `id_utilisateur`, `action_date`, `action_type`, `message`) VALUES
(1, 1, '2023-05-12 16:58:03', 'Nouvelle campagne ajoutée', NULL);

-- --------------------------------------------------------

--
-- Structure de la table `programmation`
--

CREATE TABLE `programmation` (
  `programmation_id` int(11) NOT NULL,
  `id_annonce` int(11) NOT NULL,
  `id_tranche_horaire` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Structure de la table `tarif`
--

CREATE TABLE `tarif` (
  `tarif_id` int(11) NOT NULL,
  `id_zone` int(11) NOT NULL,
  `id_tranche_horaire` int(11) NOT NULL,
  `tarif_diffusion` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Structure de la table `tranche_horaire`
--

CREATE TABLE `tranche_horaire` (
  `tranche_horaire_id` int(11) NOT NULL,
  `tranche_horaire_debut` datetime NOT NULL,
  `tranche_horaire_fin` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Structure de la table `transaction`
--

CREATE TABLE `transaction` (
  `transaction_id` int(11) NOT NULL,
  `id_utilisateur` int(11) NOT NULL,
  `montant` int(11) NOT NULL,
  `transaction_date_heure` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Structure de la table `utilisateur`
--

CREATE TABLE `utilisateur` (
  `utilisateur_id` int(11) NOT NULL,
  `nom` varchar(100) NOT NULL,
  `prenom` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `mot_de_passe` varbinary(50) NOT NULL,
  `credit` int(11) DEFAULT NULL,
  `role` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `utilisateur`
--

INSERT INTO `utilisateur` (`utilisateur_id`, `nom`, `prenom`, `email`, `mot_de_passe`, `credit`, `role`) VALUES
(1, 'Sainz', 'Domitile', 'domiland@hotmail.fr', 0x617a6572747975696f70, NULL, 1),
(3, 'Casali', 'Giulia', 'giulia.casali9419@gmail.com', 0x617a6572747975696f70, 66, 0),
(4, 'Sainz', 'Matilde', 'mati@gmail.com', 0x617a6572747975696f70, 89, 0),
(5, 'Sainz', 'Eduardo', 'machaqa@gmail.com', 0x01687864, 542, 0),
(6, 'Samaran', 'Xavier', 'sam.xav@gmail.com', 0x86745648, 478, 0),
(7, 'So', 'Julia', 'juso@gmail.com', '', NULL, 0);

-- --------------------------------------------------------

--
-- Structure de la table `zone`
--

CREATE TABLE `zone` (
  `zone_id` int(11) NOT NULL,
  `zone_nom` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `zone`
--

INSERT INTO `zone` (`zone_id`, `zone_nom`) VALUES
(23, 'Zone Est'),
(25, 'Zone Nord'),
(24, 'Zone Ouest'),
(26, 'Zone Sud');

--
-- Index pour les tables déchargées
--

--
-- Index pour la table `annonce`
--
ALTER TABLE `annonce`
  ADD PRIMARY KEY (`annonce_id`),
  ADD KEY `id_utilisateur` (`id_utilisateur`);

--
-- Index pour la table `arret`
--
ALTER TABLE `arret`
  ADD PRIMARY KEY (`arret_id`),
  ADD UNIQUE KEY `arret_nom` (`arret_nom`),
  ADD UNIQUE KEY `adresse_ip_raspberry` (`adresse_ip_raspberry`),
  ADD KEY `id_zone` (`id_zone`);

--
-- Index pour la table `audit`
--
ALTER TABLE `audit`
  ADD PRIMARY KEY (`audit_id`),
  ADD KEY `id_utilisateur` (`id_utilisateur`);

--
-- Index pour la table `chat`
--
ALTER TABLE `chat`
  ADD PRIMARY KEY (`chat_id`),
  ADD KEY `id_utilisateur` (`id_utilisateur`),
  ADD KEY `id_message_reponse` (`id_message_reponse`);

--
-- Index pour la table `diffusion`
--
ALTER TABLE `diffusion`
  ADD PRIMARY KEY (`diffusion_id`),
  ADD KEY `id_annonce` (`id_annonce`),
  ADD KEY `id_arret` (`id_arret`);

--
-- Index pour la table `log`
--
ALTER TABLE `log`
  ADD PRIMARY KEY (`log_id`),
  ADD KEY `utilisateur_id` (`id_utilisateur`);

--
-- Index pour la table `programmation`
--
ALTER TABLE `programmation`
  ADD PRIMARY KEY (`programmation_id`),
  ADD KEY `id_annonce` (`id_annonce`),
  ADD KEY `id_tranche_horaire` (`id_tranche_horaire`);

--
-- Index pour la table `tarif`
--
ALTER TABLE `tarif`
  ADD PRIMARY KEY (`tarif_id`),
  ADD KEY `id_zone` (`id_zone`),
  ADD KEY `id_tranche_horaire` (`id_tranche_horaire`);

--
-- Index pour la table `tranche_horaire`
--
ALTER TABLE `tranche_horaire`
  ADD PRIMARY KEY (`tranche_horaire_id`);

--
-- Index pour la table `transaction`
--
ALTER TABLE `transaction`
  ADD PRIMARY KEY (`transaction_id`),
  ADD KEY `id_utilisateur` (`id_utilisateur`);

--
-- Index pour la table `utilisateur`
--
ALTER TABLE `utilisateur`
  ADD PRIMARY KEY (`utilisateur_id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Index pour la table `zone`
--
ALTER TABLE `zone`
  ADD PRIMARY KEY (`zone_id`),
  ADD UNIQUE KEY `zone_nom` (`zone_nom`);

--
-- AUTO_INCREMENT pour les tables déchargées
--

--
-- AUTO_INCREMENT pour la table `annonce`
--
ALTER TABLE `annonce`
  MODIFY `annonce_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT pour la table `arret`
--
ALTER TABLE `arret`
  MODIFY `arret_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- AUTO_INCREMENT pour la table `audit`
--
ALTER TABLE `audit`
  MODIFY `audit_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `chat`
--
ALTER TABLE `chat`
  MODIFY `chat_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `diffusion`
--
ALTER TABLE `diffusion`
  MODIFY `diffusion_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT pour la table `log`
--
ALTER TABLE `log`
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT pour la table `programmation`
--
ALTER TABLE `programmation`
  MODIFY `programmation_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `tarif`
--
ALTER TABLE `tarif`
  MODIFY `tarif_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `tranche_horaire`
--
ALTER TABLE `tranche_horaire`
  MODIFY `tranche_horaire_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `transaction`
--
ALTER TABLE `transaction`
  MODIFY `transaction_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `utilisateur`
--
ALTER TABLE `utilisateur`
  MODIFY `utilisateur_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT pour la table `zone`
--
ALTER TABLE `zone`
  MODIFY `zone_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

--
-- Contraintes pour les tables déchargées
--

--
-- Contraintes pour la table `annonce`
--
ALTER TABLE `annonce`
  ADD CONSTRAINT `annonce_ibfk_1` FOREIGN KEY (`id_utilisateur`) REFERENCES `utilisateur` (`utilisateur_id`);

--
-- Contraintes pour la table `arret`
--
ALTER TABLE `arret`
  ADD CONSTRAINT `arret_ibfk_1` FOREIGN KEY (`id_zone`) REFERENCES `zone` (`zone_id`);

--
-- Contraintes pour la table `audit`
--
ALTER TABLE `audit`
  ADD CONSTRAINT `audit_ibfk_1` FOREIGN KEY (`id_utilisateur`) REFERENCES `utilisateur` (`utilisateur_id`);

--
-- Contraintes pour la table `chat`
--
ALTER TABLE `chat`
  ADD CONSTRAINT `chat_ibfk_1` FOREIGN KEY (`id_utilisateur`) REFERENCES `utilisateur` (`utilisateur_id`),
  ADD CONSTRAINT `chat_ibfk_2` FOREIGN KEY (`id_message_reponse`) REFERENCES `chat` (`chat_id`);

--
-- Contraintes pour la table `diffusion`
--
ALTER TABLE `diffusion`
  ADD CONSTRAINT `diffusion_ibfk_1` FOREIGN KEY (`id_annonce`) REFERENCES `annonce` (`annonce_id`),
  ADD CONSTRAINT `diffusion_ibfk_2` FOREIGN KEY (`id_arret`) REFERENCES `arret` (`arret_id`);

--
-- Contraintes pour la table `log`
--
ALTER TABLE `log`
  ADD CONSTRAINT `log_ibfk_1` FOREIGN KEY (`id_utilisateur`) REFERENCES `utilisateur` (`utilisateur_id`);

--
-- Contraintes pour la table `programmation`
--
ALTER TABLE `programmation`
  ADD CONSTRAINT `programmation_ibfk_1` FOREIGN KEY (`id_annonce`) REFERENCES `annonce` (`annonce_id`),
  ADD CONSTRAINT `programmation_ibfk_2` FOREIGN KEY (`id_tranche_horaire`) REFERENCES `tranche_horaire` (`tranche_horaire_id`);

--
-- Contraintes pour la table `tarif`
--
ALTER TABLE `tarif`
  ADD CONSTRAINT `tarif_ibfk_1` FOREIGN KEY (`id_zone`) REFERENCES `zone` (`zone_id`),
  ADD CONSTRAINT `tarif_ibfk_2` FOREIGN KEY (`id_tranche_horaire`) REFERENCES `tranche_horaire` (`tranche_horaire_id`);

--
-- Contraintes pour la table `transaction`
--
ALTER TABLE `transaction`
  ADD CONSTRAINT `transaction_ibfk_1` FOREIGN KEY (`id_utilisateur`) REFERENCES `utilisateur` (`utilisateur_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
