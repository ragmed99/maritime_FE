class AccountPosition {
  const AccountPosition({
    required this.theyOweUs,
    required this.weOweThem,
    required this.balance,
  });

  factory AccountPosition.fromJson(Map<String, dynamic> json) =>
      AccountPosition(
        theyOweUs: double.parse(json['they_owe_us'].toString()),
        weOweThem: double.parse(json['we_owe_them'].toString()),
        balance: double.parse(json['balance'].toString()),
      );

  final double theyOweUs;
  final double weOweThem;
  final double balance;
}
