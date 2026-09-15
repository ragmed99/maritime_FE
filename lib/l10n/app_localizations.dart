import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('fr'),
  ];

  /// No description provided for @appName.
  ///
  /// In fr, this message translates to:
  /// **'TAR FISHING'**
  String get appName;

  /// No description provided for @startupMessage.
  ///
  /// In fr, this message translates to:
  /// **'Préparation de votre espace maritime…'**
  String get startupMessage;

  /// No description provided for @loginTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get loginTitle;

  /// No description provided for @username.
  ///
  /// In fr, this message translates to:
  /// **'Nom d’utilisateur'**
  String get username;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @loginAction.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get loginAction;

  /// No description provided for @invalidCredentialsError.
  ///
  /// In fr, this message translates to:
  /// **'Identifiants incorrects ou compte désactivé.'**
  String get invalidCredentialsError;

  /// No description provided for @networkError.
  ///
  /// In fr, this message translates to:
  /// **'Connexion au serveur impossible. Vérifiez votre réseau.'**
  String get networkError;

  /// No description provided for @serverError.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur du serveur est survenue. Réessayez.'**
  String get serverError;

  /// No description provided for @usernameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez votre nom d’utilisateur.'**
  String get usernameRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez votre mot de passe.'**
  String get passwordRequired;

  /// No description provided for @dashboard.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get dashboard;

  /// No description provided for @ships.
  ///
  /// In fr, this message translates to:
  /// **'Navires'**
  String get ships;

  /// No description provided for @clients.
  ///
  /// In fr, this message translates to:
  /// **'Clients'**
  String get clients;

  /// No description provided for @partners.
  ///
  /// In fr, this message translates to:
  /// **'Partenaires'**
  String get partners;

  /// No description provided for @owners.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaires'**
  String get owners;

  /// No description provided for @transactions.
  ///
  /// In fr, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @reports.
  ///
  /// In fr, this message translates to:
  /// **'Rapports'**
  String get reports;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get logout;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @french.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @arabic.
  ///
  /// In fr, this message translates to:
  /// **'Arabe'**
  String get arabic;

  /// No description provided for @foundationMessage.
  ///
  /// In fr, this message translates to:
  /// **'Cette section est prête à recevoir ses fonctionnalités.'**
  String get foundationMessage;

  /// No description provided for @expectedCash.
  ///
  /// In fr, this message translates to:
  /// **'Espèces attendues'**
  String get expectedCash;

  /// No description provided for @peopleOweUs.
  ///
  /// In fr, this message translates to:
  /// **'Les tiers nous doivent'**
  String get peopleOweUs;

  /// No description provided for @weOwePeople.
  ///
  /// In fr, this message translates to:
  /// **'Nous devons aux tiers'**
  String get weOwePeople;

  /// No description provided for @receivables.
  ///
  /// In fr, this message translates to:
  /// **'Créances'**
  String get receivables;

  /// No description provided for @liabilities.
  ///
  /// In fr, this message translates to:
  /// **'Dettes'**
  String get liabilities;

  /// No description provided for @netPosition.
  ///
  /// In fr, this message translates to:
  /// **'Position nette'**
  String get netPosition;

  /// No description provided for @totalRevenue.
  ///
  /// In fr, this message translates to:
  /// **'Revenus totaux'**
  String get totalRevenue;

  /// No description provided for @totalExpenses.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses totales'**
  String get totalExpenses;

  /// No description provided for @profitLoss.
  ///
  /// In fr, this message translates to:
  /// **'Bénéfice / perte'**
  String get profitLoss;

  /// No description provided for @shipSummary.
  ///
  /// In fr, this message translates to:
  /// **'Résumé des navires'**
  String get shipSummary;

  /// No description provided for @clientBalances.
  ///
  /// In fr, this message translates to:
  /// **'Soldes clients'**
  String get clientBalances;

  /// No description provided for @partnerBalances.
  ///
  /// In fr, this message translates to:
  /// **'Soldes partenaires'**
  String get partnerBalances;

  /// No description provided for @shipName.
  ///
  /// In fr, this message translates to:
  /// **'Navire'**
  String get shipName;

  /// No description provided for @name.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get name;

  /// No description provided for @currentBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde actuel'**
  String get currentBalance;

  /// No description provided for @balanceStatus.
  ///
  /// In fr, this message translates to:
  /// **'Situation'**
  String get balanceStatus;

  /// No description provided for @clientOwesUs.
  ///
  /// In fr, this message translates to:
  /// **'Le client nous doit'**
  String get clientOwesUs;

  /// No description provided for @clientCredit.
  ///
  /// In fr, this message translates to:
  /// **'Solde en faveur du client'**
  String get clientCredit;

  /// No description provided for @partnerOwesUs.
  ///
  /// In fr, this message translates to:
  /// **'Le partenaire nous doit'**
  String get partnerOwesUs;

  /// No description provided for @weOwePartner.
  ///
  /// In fr, this message translates to:
  /// **'Nous devons au partenaire'**
  String get weOwePartner;

  /// No description provided for @balanced.
  ///
  /// In fr, this message translates to:
  /// **'Solde nul'**
  String get balanced;

  /// No description provided for @noShips.
  ///
  /// In fr, this message translates to:
  /// **'Aucun navire à afficher.'**
  String get noShips;

  /// No description provided for @noClients.
  ///
  /// In fr, this message translates to:
  /// **'Aucun client à afficher.'**
  String get noClients;

  /// No description provided for @noPartners.
  ///
  /// In fr, this message translates to:
  /// **'Aucun partenaire à afficher.'**
  String get noPartners;

  /// No description provided for @dashboardError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger le tableau de bord.'**
  String get dashboardError;

  /// No description provided for @refresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get refresh;

  /// No description provided for @addShip.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un navire'**
  String get addShip;

  /// No description provided for @editShip.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le navire'**
  String get editShip;

  /// No description provided for @deleteShip.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le navire'**
  String get deleteShip;

  /// No description provided for @searchShips.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher par nom du navire'**
  String get searchShips;

  /// No description provided for @noSearchResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun navire ne correspond à la recherche.'**
  String get noSearchResults;

  /// No description provided for @registrationNumber.
  ///
  /// In fr, this message translates to:
  /// **'Numéro d’immatriculation'**
  String get registrationNumber;

  /// No description provided for @owner.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire'**
  String get owner;

  /// No description provided for @actions.
  ///
  /// In fr, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @deleteConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Cette suppression est définitive. Voulez-vous continuer ?'**
  String get deleteConfirmation;

  /// No description provided for @shipsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les navires.'**
  String get shipsLoadError;

  /// No description provided for @shipDetailsError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les détails du navire.'**
  String get shipDetailsError;

  /// No description provided for @trips.
  ///
  /// In fr, this message translates to:
  /// **'Voyages'**
  String get trips;

  /// No description provided for @addTrip.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un voyage'**
  String get addTrip;

  /// No description provided for @editTrip.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le voyage'**
  String get editTrip;

  /// No description provided for @noTrips.
  ///
  /// In fr, this message translates to:
  /// **'Aucun voyage pour ce navire.'**
  String get noTrips;

  /// No description provided for @ongoing.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get ongoing;

  /// No description provided for @departureDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de départ'**
  String get departureDate;

  /// No description provided for @departureTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure de départ'**
  String get departureTime;

  /// No description provided for @arrivalTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure d’arrivée'**
  String get arrivalTime;

  /// No description provided for @openingExpenses.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses du voyage'**
  String get openingExpenses;

  /// No description provided for @openingRevenues.
  ///
  /// In fr, this message translates to:
  /// **'Revenus du voyage'**
  String get openingRevenues;

  /// No description provided for @addExpenseLine.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une dépense'**
  String get addExpenseLine;

  /// No description provided for @addRevenueLine.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un revenu'**
  String get addRevenueLine;

  /// No description provided for @expenseDetailsRequired.
  ///
  /// In fr, this message translates to:
  /// **'Les détails sont obligatoires pour chaque dépense'**
  String get expenseDetailsRequired;

  /// No description provided for @invalidAmount.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un montant valide supérieur à zéro'**
  String get invalidAmount;

  /// No description provided for @returnDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de retour'**
  String get returnDate;

  /// No description provided for @origin.
  ///
  /// In fr, this message translates to:
  /// **'Origine'**
  String get origin;

  /// No description provided for @destination.
  ///
  /// In fr, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @notes.
  ///
  /// In fr, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @requiredFields.
  ///
  /// In fr, this message translates to:
  /// **'Renseignez tous les champs obligatoires.'**
  String get requiredFields;

  /// No description provided for @tripDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails du voyage'**
  String get tripDetails;

  /// No description provided for @tripDetailsError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les détails du voyage.'**
  String get tripDetailsError;

  /// No description provided for @tripTransactions.
  ///
  /// In fr, this message translates to:
  /// **'Transactions du voyage'**
  String get tripTransactions;

  /// No description provided for @noTripTransactions.
  ///
  /// In fr, this message translates to:
  /// **'Aucune transaction pour ce voyage.'**
  String get noTripTransactions;

  /// No description provided for @addRevenue.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un revenu'**
  String get addRevenue;

  /// No description provided for @addExpense.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une dépense'**
  String get addExpense;

  /// No description provided for @addClientPurchase.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un achat client'**
  String get addClientPurchase;

  /// No description provided for @revenue.
  ///
  /// In fr, this message translates to:
  /// **'Revenu'**
  String get revenue;

  /// No description provided for @expense.
  ///
  /// In fr, this message translates to:
  /// **'Dépense'**
  String get expense;

  /// No description provided for @clientPurchase.
  ///
  /// In fr, this message translates to:
  /// **'Achat client'**
  String get clientPurchase;

  /// No description provided for @client.
  ///
  /// In fr, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @description.
  ///
  /// In fr, this message translates to:
  /// **'Description / motif'**
  String get description;

  /// No description provided for @amountMru.
  ///
  /// In fr, this message translates to:
  /// **'Montant (MRU)'**
  String get amountMru;

  /// No description provided for @validAmountRequired.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un montant positif et les champs obligatoires.'**
  String get validAmountRequired;

  /// No description provided for @addClient.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un client'**
  String get addClient;

  /// No description provided for @editClient.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le client'**
  String get editClient;

  /// No description provided for @deleteClient.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le client'**
  String get deleteClient;

  /// No description provided for @searchClients.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher par nom du client'**
  String get searchClients;

  /// No description provided for @noClientSearchResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun client ne correspond à la recherche.'**
  String get noClientSearchResults;

  /// No description provided for @clientsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les clients.'**
  String get clientsLoadError;

  /// No description provided for @clientDetailsError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les détails du client.'**
  String get clientDetailsError;

  /// No description provided for @phone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get phone;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'E-mail'**
  String get email;

  /// No description provided for @clientValidationError.
  ///
  /// In fr, this message translates to:
  /// **'Le nom est obligatoire.'**
  String get clientValidationError;

  /// No description provided for @addPurchase.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un achat'**
  String get addPurchase;

  /// No description provided for @addPayment.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un paiement'**
  String get addPayment;

  /// No description provided for @purchase.
  ///
  /// In fr, this message translates to:
  /// **'Achat'**
  String get purchase;

  /// No description provided for @payment.
  ///
  /// In fr, this message translates to:
  /// **'Paiement'**
  String get payment;

  /// No description provided for @filters.
  ///
  /// In fr, this message translates to:
  /// **'Filtres'**
  String get filters;

  /// No description provided for @clientTransactions.
  ///
  /// In fr, this message translates to:
  /// **'Transactions du client'**
  String get clientTransactions;

  /// No description provided for @noClientTransactions.
  ///
  /// In fr, this message translates to:
  /// **'Aucun achat ou paiement pour ce client.'**
  String get noClientTransactions;

  /// No description provided for @recordedBy.
  ///
  /// In fr, this message translates to:
  /// **'Enregistré par'**
  String get recordedBy;

  /// No description provided for @dateTime.
  ///
  /// In fr, this message translates to:
  /// **'Date et heure'**
  String get dateTime;

  /// No description provided for @transactionType.
  ///
  /// In fr, this message translates to:
  /// **'Type de transaction'**
  String get transactionType;

  /// No description provided for @trip.
  ///
  /// In fr, this message translates to:
  /// **'Voyage'**
  String get trip;

  /// No description provided for @date.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @theyOweUs.
  ///
  /// In fr, this message translates to:
  /// **'Il nous doit'**
  String get theyOweUs;

  /// No description provided for @weOweThem.
  ///
  /// In fr, this message translates to:
  /// **'Nous lui devons'**
  String get weOweThem;

  /// No description provided for @shipOptional.
  ///
  /// In fr, this message translates to:
  /// **'Navire (facultatif)'**
  String get shipOptional;

  /// No description provided for @tripOptional.
  ///
  /// In fr, this message translates to:
  /// **'Voyage (facultatif)'**
  String get tripOptional;

  /// No description provided for @none.
  ///
  /// In fr, this message translates to:
  /// **'Aucun'**
  String get none;

  /// No description provided for @all.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get all;

  /// No description provided for @allDates.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les dates'**
  String get allDates;

  /// No description provided for @startDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de début'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de fin'**
  String get endDate;

  /// No description provided for @clearFilters.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get clearFilters;

  /// No description provided for @apply.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get apply;

  /// No description provided for @downloadSharePdf.
  ///
  /// In fr, this message translates to:
  /// **'PDF / Partager'**
  String get downloadSharePdf;

  /// No description provided for @clientStatement.
  ///
  /// In fr, this message translates to:
  /// **'Relevé client'**
  String get clientStatement;

  /// No description provided for @pdfError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de générer ou partager le relevé PDF.'**
  String get pdfError;

  /// No description provided for @saveError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’enregistrer la transaction.'**
  String get saveError;

  /// No description provided for @addPartner.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un partenaire'**
  String get addPartner;

  /// No description provided for @editPartner.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le partenaire'**
  String get editPartner;

  /// No description provided for @deletePartner.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le partenaire'**
  String get deletePartner;

  /// No description provided for @searchPartners.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher par nom du partenaire'**
  String get searchPartners;

  /// No description provided for @noPartnerSearchResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun partenaire ne correspond à la recherche.'**
  String get noPartnerSearchResults;

  /// No description provided for @partnersLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les partenaires.'**
  String get partnersLoadError;

  /// No description provided for @partnerDetailsError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les détails du partenaire.'**
  String get partnerDetailsError;

  /// No description provided for @partnerValidationError.
  ///
  /// In fr, this message translates to:
  /// **'Le nom est obligatoire.'**
  String get partnerValidationError;

  /// No description provided for @partnerTransactions.
  ///
  /// In fr, this message translates to:
  /// **'Transactions du partenaire'**
  String get partnerTransactions;

  /// No description provided for @noPartnerTransactions.
  ///
  /// In fr, this message translates to:
  /// **'Aucun prêt ou remboursement pour ce partenaire.'**
  String get noPartnerTransactions;

  /// No description provided for @borrowFromPartner.
  ///
  /// In fr, this message translates to:
  /// **'Emprunter au partenaire'**
  String get borrowFromPartner;

  /// No description provided for @lendToPartner.
  ///
  /// In fr, this message translates to:
  /// **'Prêter au partenaire'**
  String get lendToPartner;

  /// No description provided for @repayPartner.
  ///
  /// In fr, this message translates to:
  /// **'Rembourser le partenaire'**
  String get repayPartner;

  /// No description provided for @receiveRepayment.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir un remboursement'**
  String get receiveRepayment;

  /// No description provided for @loanReceived.
  ///
  /// In fr, this message translates to:
  /// **'Prêt reçu'**
  String get loanReceived;

  /// No description provided for @loanGiven.
  ///
  /// In fr, this message translates to:
  /// **'Prêt accordé'**
  String get loanGiven;

  /// No description provided for @repaymentPaid.
  ///
  /// In fr, this message translates to:
  /// **'Remboursement payé'**
  String get repaymentPaid;

  /// No description provided for @repaymentReceived.
  ///
  /// In fr, this message translates to:
  /// **'Remboursement reçu'**
  String get repaymentReceived;

  /// No description provided for @addOwner.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un propriétaire'**
  String get addOwner;

  /// No description provided for @editOwner.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le propriétaire'**
  String get editOwner;

  /// No description provided for @deleteOwner.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le propriétaire'**
  String get deleteOwner;

  /// No description provided for @searchOwners.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher par nom du propriétaire'**
  String get searchOwners;

  /// No description provided for @noOwners.
  ///
  /// In fr, this message translates to:
  /// **'Aucun propriétaire enregistré.'**
  String get noOwners;

  /// No description provided for @noOwnerSearchResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun propriétaire ne correspond à la recherche.'**
  String get noOwnerSearchResults;

  /// No description provided for @ownersLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les propriétaires.'**
  String get ownersLoadError;

  /// No description provided for @ownerDetailsError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les détails du propriétaire.'**
  String get ownerDetailsError;

  /// No description provided for @ownerValidationError.
  ///
  /// In fr, this message translates to:
  /// **'Le nom est obligatoire.'**
  String get ownerValidationError;

  /// No description provided for @ownerShips.
  ///
  /// In fr, this message translates to:
  /// **'Navires du propriétaire'**
  String get ownerShips;

  /// No description provided for @noOwnerShips.
  ///
  /// In fr, this message translates to:
  /// **'Aucun navire pour ce propriétaire.'**
  String get noOwnerShips;

  /// No description provided for @ownerTransactions.
  ///
  /// In fr, this message translates to:
  /// **'Transactions du compte propriétaire'**
  String get ownerTransactions;

  /// No description provided for @noOwnerTransactions.
  ///
  /// In fr, this message translates to:
  /// **'Aucun dépôt ou retrait pour ce propriétaire.'**
  String get noOwnerTransactions;

  /// No description provided for @addDeposit.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un dépôt'**
  String get addDeposit;

  /// No description provided for @addWithdrawal.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un retrait'**
  String get addWithdrawal;

  /// No description provided for @deposit.
  ///
  /// In fr, this message translates to:
  /// **'Dépôt'**
  String get deposit;

  /// No description provided for @withdrawal.
  ///
  /// In fr, this message translates to:
  /// **'Retrait'**
  String get withdrawal;

  /// No description provided for @businessOwesOwner.
  ///
  /// In fr, this message translates to:
  /// **'L’entreprise doit au propriétaire'**
  String get businessOwesOwner;

  /// No description provided for @ownerOwesBusiness.
  ///
  /// In fr, this message translates to:
  /// **'Le propriétaire doit à l’entreprise'**
  String get ownerOwesBusiness;

  /// No description provided for @shipRevenue.
  ///
  /// In fr, this message translates to:
  /// **'Revenu du navire'**
  String get shipRevenue;

  /// No description provided for @shipExpense.
  ///
  /// In fr, this message translates to:
  /// **'Dépense du navire'**
  String get shipExpense;

  /// No description provided for @clientPayment.
  ///
  /// In fr, this message translates to:
  /// **'Paiement client'**
  String get clientPayment;

  /// No description provided for @ownerDeposit.
  ///
  /// In fr, this message translates to:
  /// **'Dépôt du propriétaire'**
  String get ownerDeposit;

  /// No description provided for @ownerWithdrawal.
  ///
  /// In fr, this message translates to:
  /// **'Retrait du propriétaire'**
  String get ownerWithdrawal;

  /// No description provided for @relatedTo.
  ///
  /// In fr, this message translates to:
  /// **'Éléments liés'**
  String get relatedTo;

  /// No description provided for @reference.
  ///
  /// In fr, this message translates to:
  /// **'Référence'**
  String get reference;

  /// No description provided for @searchTransactions.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher par description, référence ou personne liée'**
  String get searchTransactions;

  /// No description provided for @noTransactionsFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucune transaction ne correspond aux critères.'**
  String get noTransactionsFound;

  /// No description provided for @transactionsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les transactions.'**
  String get transactionsLoadError;

  /// No description provided for @loadMore.
  ///
  /// In fr, this message translates to:
  /// **'Charger plus'**
  String get loadMore;

  /// No description provided for @editTransaction.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la transaction'**
  String get editTransaction;

  /// No description provided for @deleteTransaction.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la transaction'**
  String get deleteTransaction;

  /// No description provided for @deleteTransactionConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Cette transaction sera supprimée et conservée dans l’historique d’audit. Continuer ?'**
  String get deleteTransactionConfirmation;

  /// No description provided for @transactionSaveError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de modifier la transaction.'**
  String get transactionSaveError;

  /// No description provided for @transactionDeleteError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer la transaction.'**
  String get transactionDeleteError;

  /// No description provided for @shipStatement.
  ///
  /// In fr, this message translates to:
  /// **'Relevé du navire'**
  String get shipStatement;

  /// No description provided for @partnerStatement.
  ///
  /// In fr, this message translates to:
  /// **'Relevé du partenaire'**
  String get partnerStatement;

  /// No description provided for @ownerStatement.
  ///
  /// In fr, this message translates to:
  /// **'Relevé du propriétaire'**
  String get ownerStatement;

  /// No description provided for @dailySummary.
  ///
  /// In fr, this message translates to:
  /// **'Résumé journalier'**
  String get dailySummary;

  /// No description provided for @customDateReport.
  ///
  /// In fr, this message translates to:
  /// **'Rapport par période'**
  String get customDateReport;

  /// No description provided for @reportsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les données des rapports.'**
  String get reportsLoadError;

  /// No description provided for @selectTrips.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner un ou plusieurs voyages'**
  String get selectTrips;

  /// No description provided for @reportSelectionError.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez une entité et vérifiez la période.'**
  String get reportSelectionError;

  /// No description provided for @previewReport.
  ///
  /// In fr, this message translates to:
  /// **'Prévisualiser le rapport'**
  String get previewReport;

  /// No description provided for @reportPreview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu du rapport'**
  String get reportPreview;

  /// No description provided for @reportPreviewError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger le rapport.'**
  String get reportPreviewError;

  /// No description provided for @tripResults.
  ///
  /// In fr, this message translates to:
  /// **'Résultats par voyage'**
  String get tripResults;

  /// No description provided for @remainingResult.
  ///
  /// In fr, this message translates to:
  /// **'Résultat restant'**
  String get remainingResult;

  /// No description provided for @openingBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde d’ouverture'**
  String get openingBalance;

  /// No description provided for @closingBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde de clôture'**
  String get closingBalance;

  /// No description provided for @totalClientPurchases.
  ///
  /// In fr, this message translates to:
  /// **'Total des achats clients'**
  String get totalClientPurchases;

  /// No description provided for @totalPurchases.
  ///
  /// In fr, this message translates to:
  /// **'Total des achats'**
  String get totalPurchases;

  /// No description provided for @totalPayments.
  ///
  /// In fr, this message translates to:
  /// **'Total des paiements'**
  String get totalPayments;

  /// No description provided for @totalDeposits.
  ///
  /// In fr, this message translates to:
  /// **'Total des dépôts'**
  String get totalDeposits;

  /// No description provided for @totalWithdrawals.
  ///
  /// In fr, this message translates to:
  /// **'Total des retraits'**
  String get totalWithdrawals;

  /// No description provided for @periodMovement.
  ///
  /// In fr, this message translates to:
  /// **'Mouvement de la période'**
  String get periodMovement;

  /// No description provided for @administration.
  ///
  /// In fr, this message translates to:
  /// **'Administration'**
  String get administration;

  /// No description provided for @userManagement.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des utilisateurs'**
  String get userManagement;

  /// No description provided for @auditLogs.
  ///
  /// In fr, this message translates to:
  /// **'Journaux d’audit'**
  String get auditLogs;

  /// No description provided for @createUser.
  ///
  /// In fr, this message translates to:
  /// **'Créer un utilisateur'**
  String get createUser;

  /// No description provided for @firstName.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get lastName;

  /// No description provided for @role.
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get role;

  /// No description provided for @status.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get status;

  /// No description provided for @administrator.
  ///
  /// In fr, this message translates to:
  /// **'Administrateur'**
  String get administrator;

  /// No description provided for @normalUser.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur'**
  String get normalUser;

  /// No description provided for @active.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In fr, this message translates to:
  /// **'Désactivé'**
  String get inactive;

  /// No description provided for @activate.
  ///
  /// In fr, this message translates to:
  /// **'Activer'**
  String get activate;

  /// No description provided for @deactivate.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver'**
  String get deactivate;

  /// No description provided for @resetPassword.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser le mot de passe'**
  String get resetPassword;

  /// No description provided for @newPassword.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get confirmPassword;

  /// No description provided for @userValidationError.
  ///
  /// In fr, this message translates to:
  /// **'Le nom d’utilisateur est obligatoire et le mot de passe doit contenir au moins 6 caractères.'**
  String get userValidationError;

  /// No description provided for @passwordValidationError.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe doivent correspondre et contenir au moins 6 caractères.'**
  String get passwordValidationError;

  /// No description provided for @usersLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les utilisateurs.'**
  String get usersLoadError;

  /// No description provided for @noUsers.
  ///
  /// In fr, this message translates to:
  /// **'Aucun utilisateur.'**
  String get noUsers;

  /// No description provided for @userSaveError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’enregistrer l’utilisateur.'**
  String get userSaveError;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe réinitialisé.'**
  String get passwordResetSuccess;

  /// No description provided for @passwordResetError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de réinitialiser le mot de passe.'**
  String get passwordResetError;

  /// No description provided for @auditLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les journaux d’audit.'**
  String get auditLoadError;

  /// No description provided for @noAuditLogs.
  ///
  /// In fr, this message translates to:
  /// **'Aucun journal d’audit.'**
  String get noAuditLogs;

  /// No description provided for @user.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur'**
  String get user;

  /// No description provided for @action.
  ///
  /// In fr, this message translates to:
  /// **'Action'**
  String get action;

  /// No description provided for @entity.
  ///
  /// In fr, this message translates to:
  /// **'Entité / modèle'**
  String get entity;

  /// No description provided for @entityId.
  ///
  /// In fr, this message translates to:
  /// **'ID de l’entité'**
  String get entityId;

  /// No description provided for @oldValues.
  ///
  /// In fr, this message translates to:
  /// **'Anciennes valeurs'**
  String get oldValues;

  /// No description provided for @newValues.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelles valeurs'**
  String get newValues;

  /// No description provided for @systemUser.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get systemUser;

  /// No description provided for @createAction.
  ///
  /// In fr, this message translates to:
  /// **'Création'**
  String get createAction;

  /// No description provided for @updateAction.
  ///
  /// In fr, this message translates to:
  /// **'Modification'**
  String get updateAction;

  /// No description provided for @deleteAction.
  ///
  /// In fr, this message translates to:
  /// **'Suppression'**
  String get deleteAction;

  /// No description provided for @companyInformation.
  ///
  /// In fr, this message translates to:
  /// **'Informations de l’entreprise'**
  String get companyInformation;

  /// No description provided for @companyName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l’entreprise'**
  String get companyName;

  /// No description provided for @address.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get address;

  /// No description provided for @companySettingsError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les informations de l’entreprise.'**
  String get companySettingsError;

  /// No description provided for @welcomeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vue financière maritime'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Suivez les indicateurs essentiels depuis un espace sécurisé.'**
  String get welcomeSubtitle;

  /// No description provided for @showPassword.
  ///
  /// In fr, this message translates to:
  /// **'Afficher le mot de passe'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In fr, this message translates to:
  /// **'Masquer le mot de passe'**
  String get hidePassword;

  /// No description provided for @menu.
  ///
  /// In fr, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
