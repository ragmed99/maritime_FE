// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'TAR FISHING';

  @override
  String get startupMessage => 'Préparation de votre espace maritime…';

  @override
  String get loginTitle => 'Connexion';

  @override
  String get username => 'Nom d’utilisateur';

  @override
  String get password => 'Mot de passe';

  @override
  String get loginAction => 'Se connecter';

  @override
  String get invalidCredentialsError =>
      'Identifiants incorrects ou compte désactivé.';

  @override
  String get networkError =>
      'Connexion au serveur impossible. Vérifiez votre réseau.';

  @override
  String get serverError => 'Une erreur du serveur est survenue. Réessayez.';

  @override
  String get usernameRequired => 'Saisissez votre nom d’utilisateur.';

  @override
  String get passwordRequired => 'Saisissez votre mot de passe.';

  @override
  String get dashboard => 'Tableau de bord';

  @override
  String get ships => 'Navires';

  @override
  String get clients => 'Clients';

  @override
  String get partners => 'Partenaires';

  @override
  String get owners => 'Propriétaires';

  @override
  String get transactions => 'Transactions';

  @override
  String get reports => 'Rapports';

  @override
  String get settings => 'Paramètres';

  @override
  String get logout => 'Déconnexion';

  @override
  String get language => 'Langue';

  @override
  String get french => 'Français';

  @override
  String get arabic => 'Arabe';

  @override
  String get appearance => 'Apparence';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get foundationMessage =>
      'Cette section est prête à recevoir ses fonctionnalités.';

  @override
  String get expectedCash => 'Espèces attendues';

  @override
  String get peopleOweUs => 'Les tiers nous doivent';

  @override
  String get weOwePeople => 'Nous devons aux tiers';

  @override
  String get receivables => 'Créances';

  @override
  String get liabilities => 'Dettes';

  @override
  String get netPosition => 'Position nette';

  @override
  String get totalRevenue => 'Revenus totaux';

  @override
  String get totalExpenses => 'Dépenses totales';

  @override
  String get profitLoss => 'Bénéfice / perte';

  @override
  String get shipSummary => 'Résumé des navires';

  @override
  String get clientBalances => 'Soldes clients';

  @override
  String get partnerBalances => 'Soldes partenaires';

  @override
  String get shipName => 'Navire';

  @override
  String get name => 'Nom';

  @override
  String get currentBalance => 'Solde actuel';

  @override
  String get balanceStatus => 'Situation';

  @override
  String get clientOwesUs => 'Le client nous doit';

  @override
  String get clientCredit => 'Solde en faveur du client';

  @override
  String get partnerOwesUs => 'Le partenaire nous doit';

  @override
  String get weOwePartner => 'Nous devons au partenaire';

  @override
  String get balanced => 'Solde nul';

  @override
  String get noShips => 'Aucun navire à afficher.';

  @override
  String get noClients => 'Aucun client à afficher.';

  @override
  String get noPartners => 'Aucun partenaire à afficher.';

  @override
  String get dashboardError => 'Impossible de charger le tableau de bord.';

  @override
  String get refresh => 'Actualiser';

  @override
  String get addShip => 'Ajouter un navire';

  @override
  String get editShip => 'Modifier le navire';

  @override
  String get deleteShip => 'Supprimer le navire';

  @override
  String get searchShips => 'Rechercher par nom du navire';

  @override
  String get noSearchResults => 'Aucun navire ne correspond à la recherche.';

  @override
  String get registrationNumber => 'Numéro d’immatriculation';

  @override
  String get owner => 'Propriétaire';

  @override
  String get actions => 'Actions';

  @override
  String get edit => 'Modifier';

  @override
  String get delete => 'Supprimer';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get deleteConfirmation =>
      'Cette suppression est définitive. Voulez-vous continuer ?';

  @override
  String get shipsLoadError => 'Impossible de charger les navires.';

  @override
  String get shipDetailsError => 'Impossible de charger les détails du navire.';

  @override
  String get trips => 'Voyages';

  @override
  String get addTrip => 'Ajouter un voyage';

  @override
  String get editTrip => 'Modifier le voyage';

  @override
  String get noTrips => 'Aucun voyage pour ce navire.';

  @override
  String get ongoing => 'En cours';

  @override
  String get departureDate => 'Date de départ';

  @override
  String get departureTime => 'Heure de départ';

  @override
  String get arrivalTime => 'Heure d’arrivée';

  @override
  String get openingExpenses => 'Dépenses du voyage';

  @override
  String get openingRevenues => 'Revenus du voyage';

  @override
  String get addExpenseLine => 'Ajouter une dépense';

  @override
  String get addRevenueLine => 'Ajouter un revenu';

  @override
  String get expenseDetailsRequired =>
      'Les détails sont obligatoires pour chaque dépense';

  @override
  String get invalidAmount => 'Saisissez un montant valide supérieur à zéro';

  @override
  String get returnDate => 'Date de retour';

  @override
  String get origin => 'Origine';

  @override
  String get destination => 'Destination';

  @override
  String get notes => 'Notes';

  @override
  String get requiredFields => 'Renseignez tous les champs obligatoires.';

  @override
  String get tripDetails => 'Détails du voyage';

  @override
  String get tripDetailsError => 'Impossible de charger les détails du voyage.';

  @override
  String get tripTransactions => 'Transactions du voyage';

  @override
  String get noTripTransactions => 'Aucune transaction pour ce voyage.';

  @override
  String get addRevenue => 'Ajouter un revenu';

  @override
  String get addExpense => 'Ajouter une dépense';

  @override
  String get addClientPurchase => 'Ajouter un achat client';

  @override
  String get revenue => 'Revenu';

  @override
  String get expense => 'Dépense';

  @override
  String get clientPurchase => 'Achat client';

  @override
  String get client => 'Client';

  @override
  String get description => 'Description / motif';

  @override
  String get amountMru => 'Montant (MRU)';

  @override
  String get validAmountRequired =>
      'Saisissez un montant positif et les champs obligatoires.';

  @override
  String get addClient => 'Ajouter un client';

  @override
  String get editClient => 'Modifier le client';

  @override
  String get deleteClient => 'Supprimer le client';

  @override
  String get searchClients => 'Rechercher par nom du client';

  @override
  String get noClientSearchResults =>
      'Aucun client ne correspond à la recherche.';

  @override
  String get clientsLoadError => 'Impossible de charger les clients.';

  @override
  String get clientDetailsError =>
      'Impossible de charger les détails du client.';

  @override
  String get phone => 'Téléphone';

  @override
  String get email => 'E-mail';

  @override
  String get clientValidationError => 'Le nom est obligatoire.';

  @override
  String get addPurchase => 'Ajouter un achat';

  @override
  String get addPayment => 'Ajouter un paiement';

  @override
  String get purchase => 'Achat';

  @override
  String get payment => 'Paiement';

  @override
  String get filters => 'Filtres';

  @override
  String get clientTransactions => 'Transactions du client';

  @override
  String get noClientTransactions => 'Aucun achat ou paiement pour ce client.';

  @override
  String get recordedBy => 'Enregistré par';

  @override
  String get dateTime => 'Date et heure';

  @override
  String get transactionType => 'Type de transaction';

  @override
  String get trip => 'Voyage';

  @override
  String get date => 'Date';

  @override
  String get theyOweUs => 'Il nous doit';

  @override
  String get weOweThem => 'Nous lui devons';

  @override
  String get shipOptional => 'Navire (facultatif)';

  @override
  String get tripOptional => 'Voyage (facultatif)';

  @override
  String get none => 'Aucun';

  @override
  String get all => 'Tous';

  @override
  String get allDates => 'Toutes les dates';

  @override
  String get startDate => 'Date de début';

  @override
  String get endDate => 'Date de fin';

  @override
  String get clearFilters => 'Effacer';

  @override
  String get apply => 'Appliquer';

  @override
  String get downloadSharePdf => 'PDF / Partager';

  @override
  String get clientStatement => 'Relevé client';

  @override
  String get pdfError => 'Impossible de générer ou partager le relevé PDF.';

  @override
  String get saveError => 'Impossible d’enregistrer la transaction.';

  @override
  String get addPartner => 'Ajouter un partenaire';

  @override
  String get editPartner => 'Modifier le partenaire';

  @override
  String get deletePartner => 'Supprimer le partenaire';

  @override
  String get searchPartners => 'Rechercher par nom du partenaire';

  @override
  String get noPartnerSearchResults =>
      'Aucun partenaire ne correspond à la recherche.';

  @override
  String get partnersLoadError => 'Impossible de charger les partenaires.';

  @override
  String get partnerDetailsError =>
      'Impossible de charger les détails du partenaire.';

  @override
  String get partnerValidationError => 'Le nom est obligatoire.';

  @override
  String get partnerTransactions => 'Transactions du partenaire';

  @override
  String get noPartnerTransactions =>
      'Aucun prêt ou remboursement pour ce partenaire.';

  @override
  String get borrowFromPartner => 'Emprunter au partenaire';

  @override
  String get lendToPartner => 'Prêter au partenaire';

  @override
  String get repayPartner => 'Rembourser le partenaire';

  @override
  String get receiveRepayment => 'Recevoir un remboursement';

  @override
  String get loanReceived => 'Prêt reçu';

  @override
  String get loanGiven => 'Prêt accordé';

  @override
  String get repaymentPaid => 'Remboursement payé';

  @override
  String get repaymentReceived => 'Remboursement reçu';

  @override
  String get addOwner => 'Ajouter un propriétaire';

  @override
  String get editOwner => 'Modifier le propriétaire';

  @override
  String get deleteOwner => 'Supprimer le propriétaire';

  @override
  String get searchOwners => 'Rechercher par nom du propriétaire';

  @override
  String get noOwners => 'Aucun propriétaire enregistré.';

  @override
  String get noOwnerSearchResults =>
      'Aucun propriétaire ne correspond à la recherche.';

  @override
  String get ownersLoadError => 'Impossible de charger les propriétaires.';

  @override
  String get ownerDetailsError =>
      'Impossible de charger les détails du propriétaire.';

  @override
  String get ownerValidationError => 'Le nom est obligatoire.';

  @override
  String get ownerShips => 'Navires du propriétaire';

  @override
  String get noOwnerShips => 'Aucun navire pour ce propriétaire.';

  @override
  String get ownerTransactions => 'Transactions du compte propriétaire';

  @override
  String get noOwnerTransactions =>
      'Aucun dépôt ou retrait pour ce propriétaire.';

  @override
  String get addDeposit => 'Ajouter un dépôt';

  @override
  String get addWithdrawal => 'Ajouter un retrait';

  @override
  String get deposit => 'Dépôt';

  @override
  String get withdrawal => 'Retrait';

  @override
  String get businessOwesOwner => 'L’entreprise doit au propriétaire';

  @override
  String get ownerOwesBusiness => 'Le propriétaire doit à l’entreprise';

  @override
  String get shipRevenue => 'Revenu du navire';

  @override
  String get shipExpense => 'Dépense du navire';

  @override
  String get clientPayment => 'Paiement client';

  @override
  String get ownerDeposit => 'Dépôt du propriétaire';

  @override
  String get ownerWithdrawal => 'Retrait du propriétaire';

  @override
  String get relatedTo => 'Éléments liés';

  @override
  String get reference => 'Référence';

  @override
  String get searchTransactions =>
      'Rechercher par description, référence ou personne liée';

  @override
  String get noTransactionsFound =>
      'Aucune transaction ne correspond aux critères.';

  @override
  String get transactionsLoadError => 'Impossible de charger les transactions.';

  @override
  String get loadMore => 'Charger plus';

  @override
  String get editTransaction => 'Modifier la transaction';

  @override
  String get deleteTransaction => 'Supprimer la transaction';

  @override
  String get deleteTransactionConfirmation =>
      'Cette transaction sera supprimée et conservée dans l’historique d’audit. Continuer ?';

  @override
  String get transactionSaveError => 'Impossible de modifier la transaction.';

  @override
  String get transactionDeleteError =>
      'Impossible de supprimer la transaction.';

  @override
  String get shipStatement => 'Relevé du navire';

  @override
  String get partnerStatement => 'Relevé du partenaire';

  @override
  String get ownerStatement => 'Relevé du propriétaire';

  @override
  String get dailySummary => 'Résumé journalier';

  @override
  String get customDateReport => 'Rapport par période';

  @override
  String get reportsLoadError =>
      'Impossible de charger les données des rapports.';

  @override
  String get selectTrips => 'Sélectionner un ou plusieurs voyages';

  @override
  String get reportSelectionError =>
      'Sélectionnez une entité et vérifiez la période.';

  @override
  String get previewReport => 'Prévisualiser le rapport';

  @override
  String get reportPreview => 'Aperçu du rapport';

  @override
  String get reportPreviewError => 'Impossible de charger le rapport.';

  @override
  String get tripResults => 'Résultats par voyage';

  @override
  String get remainingResult => 'Résultat restant';

  @override
  String get openingBalance => 'Solde d’ouverture';

  @override
  String get closingBalance => 'Solde de clôture';

  @override
  String get totalClientPurchases => 'Total des achats clients';

  @override
  String get totalPurchases => 'Total des achats';

  @override
  String get totalPayments => 'Total des paiements';

  @override
  String get totalDeposits => 'Total des dépôts';

  @override
  String get totalWithdrawals => 'Total des retraits';

  @override
  String get periodMovement => 'Mouvement de la période';

  @override
  String get administration => 'Administration';

  @override
  String get userManagement => 'Gestion des utilisateurs';

  @override
  String get auditLogs => 'Journaux d’audit';

  @override
  String get createUser => 'Créer un utilisateur';

  @override
  String get firstName => 'Prénom';

  @override
  String get lastName => 'Nom';

  @override
  String get role => 'Rôle';

  @override
  String get status => 'Statut';

  @override
  String get administrator => 'Administrateur';

  @override
  String get normalUser => 'Utilisateur';

  @override
  String get active => 'Actif';

  @override
  String get inactive => 'Désactivé';

  @override
  String get activate => 'Activer';

  @override
  String get deactivate => 'Désactiver';

  @override
  String get resetPassword => 'Réinitialiser le mot de passe';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get userValidationError =>
      'Le nom d’utilisateur est obligatoire et le mot de passe doit contenir au moins 6 caractères.';

  @override
  String get passwordValidationError =>
      'Les mots de passe doivent correspondre et contenir au moins 6 caractères.';

  @override
  String get usersLoadError => 'Impossible de charger les utilisateurs.';

  @override
  String get noUsers => 'Aucun utilisateur.';

  @override
  String get userSaveError => 'Impossible d’enregistrer l’utilisateur.';

  @override
  String get passwordResetSuccess => 'Mot de passe réinitialisé.';

  @override
  String get passwordResetError =>
      'Impossible de réinitialiser le mot de passe.';

  @override
  String get auditLoadError => 'Impossible de charger les journaux d’audit.';

  @override
  String get noAuditLogs => 'Aucun journal d’audit.';

  @override
  String get user => 'Utilisateur';

  @override
  String get action => 'Action';

  @override
  String get entity => 'Entité / modèle';

  @override
  String get entityId => 'ID de l’entité';

  @override
  String get oldValues => 'Anciennes valeurs';

  @override
  String get newValues => 'Nouvelles valeurs';

  @override
  String get systemUser => 'Système';

  @override
  String get createAction => 'Création';

  @override
  String get updateAction => 'Modification';

  @override
  String get deleteAction => 'Suppression';

  @override
  String get companyInformation => 'Informations de l’entreprise';

  @override
  String get companyName => 'Nom de l’entreprise';

  @override
  String get address => 'Adresse';

  @override
  String get companySettingsError =>
      'Impossible de charger les informations de l’entreprise.';

  @override
  String get welcomeTitle => 'Vue financière maritime';

  @override
  String get welcomeSubtitle =>
      'Suivez les indicateurs essentiels depuis un espace sécurisé.';

  @override
  String get showPassword => 'Afficher le mot de passe';

  @override
  String get hidePassword => 'Masquer le mot de passe';

  @override
  String get menu => 'Menu';

  @override
  String get retry => 'Réessayer';
}
