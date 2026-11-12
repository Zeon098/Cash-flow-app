import '../../core/utils/formatters.dart';

class AccountModel {
  const AccountModel({
    required this.id,
    required this.name,
    this.type = 'cash',
    this.icon = 'account_balance_wallet',
    this.color = '#10B981',
  });

  final String id;
  final String name;
  final String type;
  final String icon;
  final String color;

  factory AccountModel.fromJson(Map<String, dynamic> j) => AccountModel(
        id: Json.str(j['id']),
        name: Json.str(j['name']),
        type: Json.str(j['type']),
        icon: Json.str(j['icon']),
        color: Json.str(j['color']),
      );
}
