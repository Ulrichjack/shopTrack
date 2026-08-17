// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalProductsTable extends LocalProducts
    with TableInfo<$LocalProductsTable, LocalProduct> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shopIdMeta = const VerificationMeta('shopId');
  @override
  late final GeneratedColumn<String> shopId = GeneratedColumn<String>(
    'shop_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _buyPriceMeta = const VerificationMeta(
    'buyPrice',
  );
  @override
  late final GeneratedColumn<double> buyPrice = GeneratedColumn<double>(
    'buy_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sellPriceMeta = const VerificationMeta(
    'sellPrice',
  );
  @override
  late final GeneratedColumn<double> sellPrice = GeneratedColumn<double>(
    'sell_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minQuantityMeta = const VerificationMeta(
    'minQuantity',
  );
  @override
  late final GeneratedColumn<int> minQuantity = GeneratedColumn<int>(
    'min_quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoUrlMeta = const VerificationMeta(
    'photoUrl',
  );
  @override
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
    'photo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    shopId,
    name,
    buyPrice,
    sellPrice,
    quantity,
    minQuantity,
    barcode,
    photoUrl,
    unit,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_products';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalProduct> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('shop_id')) {
      context.handle(
        _shopIdMeta,
        shopId.isAcceptableOrUnknown(data['shop_id']!, _shopIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shopIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('buy_price')) {
      context.handle(
        _buyPriceMeta,
        buyPrice.isAcceptableOrUnknown(data['buy_price']!, _buyPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_buyPriceMeta);
    }
    if (data.containsKey('sell_price')) {
      context.handle(
        _sellPriceMeta,
        sellPrice.isAcceptableOrUnknown(data['sell_price']!, _sellPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_sellPriceMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('min_quantity')) {
      context.handle(
        _minQuantityMeta,
        minQuantity.isAcceptableOrUnknown(
          data['min_quantity']!,
          _minQuantityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_minQuantityMeta);
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('photo_url')) {
      context.handle(
        _photoUrlMeta,
        photoUrl.isAcceptableOrUnknown(data['photo_url']!, _photoUrlMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalProduct map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalProduct(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      shopId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      buyPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}buy_price'],
      )!,
      sellPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sell_price'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      minQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_quantity'],
      )!,
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      photoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_url'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
    );
  }

  @override
  $LocalProductsTable createAlias(String alias) {
    return $LocalProductsTable(attachedDatabase, alias);
  }
}

class LocalProduct extends DataClass implements Insertable<LocalProduct> {
  final String id;
  final String shopId;
  final String name;
  final double buyPrice;
  final double sellPrice;
  final int quantity;
  final int minQuantity;
  final String? barcode;
  final String? photoUrl;

  /// Étiquette d'affichage (sac, bouteille, casier, g, l…). N'entre dans
  /// aucun calcul : le commerçant compte dans une seule unité par produit.
  final String? unit;
  const LocalProduct({
    required this.id,
    required this.shopId,
    required this.name,
    required this.buyPrice,
    required this.sellPrice,
    required this.quantity,
    required this.minQuantity,
    this.barcode,
    this.photoUrl,
    this.unit,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['shop_id'] = Variable<String>(shopId);
    map['name'] = Variable<String>(name);
    map['buy_price'] = Variable<double>(buyPrice);
    map['sell_price'] = Variable<double>(sellPrice);
    map['quantity'] = Variable<int>(quantity);
    map['min_quantity'] = Variable<int>(minQuantity);
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    if (!nullToAbsent || photoUrl != null) {
      map['photo_url'] = Variable<String>(photoUrl);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    return map;
  }

  LocalProductsCompanion toCompanion(bool nullToAbsent) {
    return LocalProductsCompanion(
      id: Value(id),
      shopId: Value(shopId),
      name: Value(name),
      buyPrice: Value(buyPrice),
      sellPrice: Value(sellPrice),
      quantity: Value(quantity),
      minQuantity: Value(minQuantity),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      photoUrl: photoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(photoUrl),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
    );
  }

  factory LocalProduct.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalProduct(
      id: serializer.fromJson<String>(json['id']),
      shopId: serializer.fromJson<String>(json['shopId']),
      name: serializer.fromJson<String>(json['name']),
      buyPrice: serializer.fromJson<double>(json['buyPrice']),
      sellPrice: serializer.fromJson<double>(json['sellPrice']),
      quantity: serializer.fromJson<int>(json['quantity']),
      minQuantity: serializer.fromJson<int>(json['minQuantity']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      photoUrl: serializer.fromJson<String?>(json['photoUrl']),
      unit: serializer.fromJson<String?>(json['unit']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'shopId': serializer.toJson<String>(shopId),
      'name': serializer.toJson<String>(name),
      'buyPrice': serializer.toJson<double>(buyPrice),
      'sellPrice': serializer.toJson<double>(sellPrice),
      'quantity': serializer.toJson<int>(quantity),
      'minQuantity': serializer.toJson<int>(minQuantity),
      'barcode': serializer.toJson<String?>(barcode),
      'photoUrl': serializer.toJson<String?>(photoUrl),
      'unit': serializer.toJson<String?>(unit),
    };
  }

  LocalProduct copyWith({
    String? id,
    String? shopId,
    String? name,
    double? buyPrice,
    double? sellPrice,
    int? quantity,
    int? minQuantity,
    Value<String?> barcode = const Value.absent(),
    Value<String?> photoUrl = const Value.absent(),
    Value<String?> unit = const Value.absent(),
  }) => LocalProduct(
    id: id ?? this.id,
    shopId: shopId ?? this.shopId,
    name: name ?? this.name,
    buyPrice: buyPrice ?? this.buyPrice,
    sellPrice: sellPrice ?? this.sellPrice,
    quantity: quantity ?? this.quantity,
    minQuantity: minQuantity ?? this.minQuantity,
    barcode: barcode.present ? barcode.value : this.barcode,
    photoUrl: photoUrl.present ? photoUrl.value : this.photoUrl,
    unit: unit.present ? unit.value : this.unit,
  );
  LocalProduct copyWithCompanion(LocalProductsCompanion data) {
    return LocalProduct(
      id: data.id.present ? data.id.value : this.id,
      shopId: data.shopId.present ? data.shopId.value : this.shopId,
      name: data.name.present ? data.name.value : this.name,
      buyPrice: data.buyPrice.present ? data.buyPrice.value : this.buyPrice,
      sellPrice: data.sellPrice.present ? data.sellPrice.value : this.sellPrice,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      minQuantity: data.minQuantity.present
          ? data.minQuantity.value
          : this.minQuantity,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      photoUrl: data.photoUrl.present ? data.photoUrl.value : this.photoUrl,
      unit: data.unit.present ? data.unit.value : this.unit,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalProduct(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('name: $name, ')
          ..write('buyPrice: $buyPrice, ')
          ..write('sellPrice: $sellPrice, ')
          ..write('quantity: $quantity, ')
          ..write('minQuantity: $minQuantity, ')
          ..write('barcode: $barcode, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('unit: $unit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    shopId,
    name,
    buyPrice,
    sellPrice,
    quantity,
    minQuantity,
    barcode,
    photoUrl,
    unit,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalProduct &&
          other.id == this.id &&
          other.shopId == this.shopId &&
          other.name == this.name &&
          other.buyPrice == this.buyPrice &&
          other.sellPrice == this.sellPrice &&
          other.quantity == this.quantity &&
          other.minQuantity == this.minQuantity &&
          other.barcode == this.barcode &&
          other.photoUrl == this.photoUrl &&
          other.unit == this.unit);
}

class LocalProductsCompanion extends UpdateCompanion<LocalProduct> {
  final Value<String> id;
  final Value<String> shopId;
  final Value<String> name;
  final Value<double> buyPrice;
  final Value<double> sellPrice;
  final Value<int> quantity;
  final Value<int> minQuantity;
  final Value<String?> barcode;
  final Value<String?> photoUrl;
  final Value<String?> unit;
  final Value<int> rowid;
  const LocalProductsCompanion({
    this.id = const Value.absent(),
    this.shopId = const Value.absent(),
    this.name = const Value.absent(),
    this.buyPrice = const Value.absent(),
    this.sellPrice = const Value.absent(),
    this.quantity = const Value.absent(),
    this.minQuantity = const Value.absent(),
    this.barcode = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.unit = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalProductsCompanion.insert({
    required String id,
    required String shopId,
    required String name,
    required double buyPrice,
    required double sellPrice,
    required int quantity,
    required int minQuantity,
    this.barcode = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.unit = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       shopId = Value(shopId),
       name = Value(name),
       buyPrice = Value(buyPrice),
       sellPrice = Value(sellPrice),
       quantity = Value(quantity),
       minQuantity = Value(minQuantity);
  static Insertable<LocalProduct> custom({
    Expression<String>? id,
    Expression<String>? shopId,
    Expression<String>? name,
    Expression<double>? buyPrice,
    Expression<double>? sellPrice,
    Expression<int>? quantity,
    Expression<int>? minQuantity,
    Expression<String>? barcode,
    Expression<String>? photoUrl,
    Expression<String>? unit,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shopId != null) 'shop_id': shopId,
      if (name != null) 'name': name,
      if (buyPrice != null) 'buy_price': buyPrice,
      if (sellPrice != null) 'sell_price': sellPrice,
      if (quantity != null) 'quantity': quantity,
      if (minQuantity != null) 'min_quantity': minQuantity,
      if (barcode != null) 'barcode': barcode,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (unit != null) 'unit': unit,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalProductsCompanion copyWith({
    Value<String>? id,
    Value<String>? shopId,
    Value<String>? name,
    Value<double>? buyPrice,
    Value<double>? sellPrice,
    Value<int>? quantity,
    Value<int>? minQuantity,
    Value<String?>? barcode,
    Value<String?>? photoUrl,
    Value<String?>? unit,
    Value<int>? rowid,
  }) {
    return LocalProductsCompanion(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      buyPrice: buyPrice ?? this.buyPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      quantity: quantity ?? this.quantity,
      minQuantity: minQuantity ?? this.minQuantity,
      barcode: barcode ?? this.barcode,
      photoUrl: photoUrl ?? this.photoUrl,
      unit: unit ?? this.unit,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (shopId.present) {
      map['shop_id'] = Variable<String>(shopId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (buyPrice.present) {
      map['buy_price'] = Variable<double>(buyPrice.value);
    }
    if (sellPrice.present) {
      map['sell_price'] = Variable<double>(sellPrice.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (minQuantity.present) {
      map['min_quantity'] = Variable<int>(minQuantity.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (photoUrl.present) {
      map['photo_url'] = Variable<String>(photoUrl.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalProductsCompanion(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('name: $name, ')
          ..write('buyPrice: $buyPrice, ')
          ..write('sellPrice: $sellPrice, ')
          ..write('quantity: $quantity, ')
          ..write('minQuantity: $minQuantity, ')
          ..write('barcode: $barcode, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('unit: $unit, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSalesTable extends LocalSales
    with TableInfo<$LocalSalesTable, LocalSale> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shopIdMeta = const VerificationMeta('shopId');
  @override
  late final GeneratedColumn<String> shopId = GeneratedColumn<String>(
    'shop_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalProfitMeta = const VerificationMeta(
    'totalProfit',
  );
  @override
  late final GeneratedColumn<double> totalProfit = GeneratedColumn<double>(
    'total_profit',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    shopId,
    userId,
    totalAmount,
    totalProfit,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_sales';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSale> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('shop_id')) {
      context.handle(
        _shopIdMeta,
        shopId.isAcceptableOrUnknown(data['shop_id']!, _shopIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shopIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalAmountMeta);
    }
    if (data.containsKey('total_profit')) {
      context.handle(
        _totalProfitMeta,
        totalProfit.isAcceptableOrUnknown(
          data['total_profit']!,
          _totalProfitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalProfitMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSale map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSale(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      shopId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      )!,
      totalProfit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_profit'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalSalesTable createAlias(String alias) {
    return $LocalSalesTable(attachedDatabase, alias);
  }
}

class LocalSale extends DataClass implements Insertable<LocalSale> {
  final String id;
  final String shopId;
  final String userId;
  final double totalAmount;
  final double totalProfit;
  final DateTime createdAt;
  const LocalSale({
    required this.id,
    required this.shopId,
    required this.userId,
    required this.totalAmount,
    required this.totalProfit,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['shop_id'] = Variable<String>(shopId);
    map['user_id'] = Variable<String>(userId);
    map['total_amount'] = Variable<double>(totalAmount);
    map['total_profit'] = Variable<double>(totalProfit);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalSalesCompanion toCompanion(bool nullToAbsent) {
    return LocalSalesCompanion(
      id: Value(id),
      shopId: Value(shopId),
      userId: Value(userId),
      totalAmount: Value(totalAmount),
      totalProfit: Value(totalProfit),
      createdAt: Value(createdAt),
    );
  }

  factory LocalSale.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSale(
      id: serializer.fromJson<String>(json['id']),
      shopId: serializer.fromJson<String>(json['shopId']),
      userId: serializer.fromJson<String>(json['userId']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      totalProfit: serializer.fromJson<double>(json['totalProfit']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'shopId': serializer.toJson<String>(shopId),
      'userId': serializer.toJson<String>(userId),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'totalProfit': serializer.toJson<double>(totalProfit),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalSale copyWith({
    String? id,
    String? shopId,
    String? userId,
    double? totalAmount,
    double? totalProfit,
    DateTime? createdAt,
  }) => LocalSale(
    id: id ?? this.id,
    shopId: shopId ?? this.shopId,
    userId: userId ?? this.userId,
    totalAmount: totalAmount ?? this.totalAmount,
    totalProfit: totalProfit ?? this.totalProfit,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalSale copyWithCompanion(LocalSalesCompanion data) {
    return LocalSale(
      id: data.id.present ? data.id.value : this.id,
      shopId: data.shopId.present ? data.shopId.value : this.shopId,
      userId: data.userId.present ? data.userId.value : this.userId,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      totalProfit: data.totalProfit.present
          ? data.totalProfit.value
          : this.totalProfit,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSale(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('userId: $userId, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('totalProfit: $totalProfit, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, shopId, userId, totalAmount, totalProfit, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSale &&
          other.id == this.id &&
          other.shopId == this.shopId &&
          other.userId == this.userId &&
          other.totalAmount == this.totalAmount &&
          other.totalProfit == this.totalProfit &&
          other.createdAt == this.createdAt);
}

class LocalSalesCompanion extends UpdateCompanion<LocalSale> {
  final Value<String> id;
  final Value<String> shopId;
  final Value<String> userId;
  final Value<double> totalAmount;
  final Value<double> totalProfit;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalSalesCompanion({
    this.id = const Value.absent(),
    this.shopId = const Value.absent(),
    this.userId = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.totalProfit = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSalesCompanion.insert({
    required String id,
    required String shopId,
    required String userId,
    required double totalAmount,
    required double totalProfit,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       shopId = Value(shopId),
       userId = Value(userId),
       totalAmount = Value(totalAmount),
       totalProfit = Value(totalProfit),
       createdAt = Value(createdAt);
  static Insertable<LocalSale> custom({
    Expression<String>? id,
    Expression<String>? shopId,
    Expression<String>? userId,
    Expression<double>? totalAmount,
    Expression<double>? totalProfit,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shopId != null) 'shop_id': shopId,
      if (userId != null) 'user_id': userId,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (totalProfit != null) 'total_profit': totalProfit,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSalesCompanion copyWith({
    Value<String>? id,
    Value<String>? shopId,
    Value<String>? userId,
    Value<double>? totalAmount,
    Value<double>? totalProfit,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LocalSalesCompanion(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      userId: userId ?? this.userId,
      totalAmount: totalAmount ?? this.totalAmount,
      totalProfit: totalProfit ?? this.totalProfit,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (shopId.present) {
      map['shop_id'] = Variable<String>(shopId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (totalProfit.present) {
      map['total_profit'] = Variable<double>(totalProfit.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSalesCompanion(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('userId: $userId, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('totalProfit: $totalProfit, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSaleItemsTable extends LocalSaleItems
    with TableInfo<$LocalSaleItemsTable, LocalSaleItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSaleItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<String> saleId = GeneratedColumn<String>(
    'sale_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sellPriceMeta = const VerificationMeta(
    'sellPrice',
  );
  @override
  late final GeneratedColumn<double> sellPrice = GeneratedColumn<double>(
    'sell_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _buyPriceMeta = const VerificationMeta(
    'buyPrice',
  );
  @override
  late final GeneratedColumn<double> buyPrice = GeneratedColumn<double>(
    'buy_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profitMeta = const VerificationMeta('profit');
  @override
  late final GeneratedColumn<double> profit = GeneratedColumn<double>(
    'profit',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cycleIdMeta = const VerificationMeta(
    'cycleId',
  );
  @override
  late final GeneratedColumn<String> cycleId = GeneratedColumn<String>(
    'cycle_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitIdMeta = const VerificationMeta('unitId');
  @override
  late final GeneratedColumn<String> unitId = GeneratedColumn<String>(
    'unit_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityInBaseMeta = const VerificationMeta(
    'quantityInBase',
  );
  @override
  late final GeneratedColumn<int> quantityInBase = GeneratedColumn<int>(
    'quantity_in_base',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitSellPriceMeta = const VerificationMeta(
    'unitSellPrice',
  );
  @override
  late final GeneratedColumn<double> unitSellPrice = GeneratedColumn<double>(
    'unit_sell_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    saleId,
    productId,
    productName,
    quantity,
    sellPrice,
    buyPrice,
    profit,
    cycleId,
    unitId,
    quantityInBase,
    unitSellPrice,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_sale_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSaleItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sale_id')) {
      context.handle(
        _saleIdMeta,
        saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_saleIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('sell_price')) {
      context.handle(
        _sellPriceMeta,
        sellPrice.isAcceptableOrUnknown(data['sell_price']!, _sellPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_sellPriceMeta);
    }
    if (data.containsKey('buy_price')) {
      context.handle(
        _buyPriceMeta,
        buyPrice.isAcceptableOrUnknown(data['buy_price']!, _buyPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_buyPriceMeta);
    }
    if (data.containsKey('profit')) {
      context.handle(
        _profitMeta,
        profit.isAcceptableOrUnknown(data['profit']!, _profitMeta),
      );
    } else if (isInserting) {
      context.missing(_profitMeta);
    }
    if (data.containsKey('cycle_id')) {
      context.handle(
        _cycleIdMeta,
        cycleId.isAcceptableOrUnknown(data['cycle_id']!, _cycleIdMeta),
      );
    }
    if (data.containsKey('unit_id')) {
      context.handle(
        _unitIdMeta,
        unitId.isAcceptableOrUnknown(data['unit_id']!, _unitIdMeta),
      );
    }
    if (data.containsKey('quantity_in_base')) {
      context.handle(
        _quantityInBaseMeta,
        quantityInBase.isAcceptableOrUnknown(
          data['quantity_in_base']!,
          _quantityInBaseMeta,
        ),
      );
    }
    if (data.containsKey('unit_sell_price')) {
      context.handle(
        _unitSellPriceMeta,
        unitSellPrice.isAcceptableOrUnknown(
          data['unit_sell_price']!,
          _unitSellPriceMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSaleItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSaleItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      saleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      sellPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sell_price'],
      )!,
      buyPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}buy_price'],
      )!,
      profit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}profit'],
      )!,
      cycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cycle_id'],
      ),
      unitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_id'],
      ),
      quantityInBase: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity_in_base'],
      ),
      unitSellPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_sell_price'],
      ),
    );
  }

  @override
  $LocalSaleItemsTable createAlias(String alias) {
    return $LocalSaleItemsTable(attachedDatabase, alias);
  }
}

class LocalSaleItem extends DataClass implements Insertable<LocalSaleItem> {
  final String id;
  final String saleId;
  final String productId;
  final String productName;
  final int quantity;
  final double sellPrice;
  final double buyPrice;
  final double profit;
  final String? cycleId;
  final String? unitId;
  final int? quantityInBase;
  final double? unitSellPrice;
  const LocalSaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.sellPrice,
    required this.buyPrice,
    required this.profit,
    this.cycleId,
    this.unitId,
    this.quantityInBase,
    this.unitSellPrice,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sale_id'] = Variable<String>(saleId);
    map['product_id'] = Variable<String>(productId);
    map['product_name'] = Variable<String>(productName);
    map['quantity'] = Variable<int>(quantity);
    map['sell_price'] = Variable<double>(sellPrice);
    map['buy_price'] = Variable<double>(buyPrice);
    map['profit'] = Variable<double>(profit);
    if (!nullToAbsent || cycleId != null) {
      map['cycle_id'] = Variable<String>(cycleId);
    }
    if (!nullToAbsent || unitId != null) {
      map['unit_id'] = Variable<String>(unitId);
    }
    if (!nullToAbsent || quantityInBase != null) {
      map['quantity_in_base'] = Variable<int>(quantityInBase);
    }
    if (!nullToAbsent || unitSellPrice != null) {
      map['unit_sell_price'] = Variable<double>(unitSellPrice);
    }
    return map;
  }

  LocalSaleItemsCompanion toCompanion(bool nullToAbsent) {
    return LocalSaleItemsCompanion(
      id: Value(id),
      saleId: Value(saleId),
      productId: Value(productId),
      productName: Value(productName),
      quantity: Value(quantity),
      sellPrice: Value(sellPrice),
      buyPrice: Value(buyPrice),
      profit: Value(profit),
      cycleId: cycleId == null && nullToAbsent
          ? const Value.absent()
          : Value(cycleId),
      unitId: unitId == null && nullToAbsent
          ? const Value.absent()
          : Value(unitId),
      quantityInBase: quantityInBase == null && nullToAbsent
          ? const Value.absent()
          : Value(quantityInBase),
      unitSellPrice: unitSellPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(unitSellPrice),
    );
  }

  factory LocalSaleItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSaleItem(
      id: serializer.fromJson<String>(json['id']),
      saleId: serializer.fromJson<String>(json['saleId']),
      productId: serializer.fromJson<String>(json['productId']),
      productName: serializer.fromJson<String>(json['productName']),
      quantity: serializer.fromJson<int>(json['quantity']),
      sellPrice: serializer.fromJson<double>(json['sellPrice']),
      buyPrice: serializer.fromJson<double>(json['buyPrice']),
      profit: serializer.fromJson<double>(json['profit']),
      cycleId: serializer.fromJson<String?>(json['cycleId']),
      unitId: serializer.fromJson<String?>(json['unitId']),
      quantityInBase: serializer.fromJson<int?>(json['quantityInBase']),
      unitSellPrice: serializer.fromJson<double?>(json['unitSellPrice']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'saleId': serializer.toJson<String>(saleId),
      'productId': serializer.toJson<String>(productId),
      'productName': serializer.toJson<String>(productName),
      'quantity': serializer.toJson<int>(quantity),
      'sellPrice': serializer.toJson<double>(sellPrice),
      'buyPrice': serializer.toJson<double>(buyPrice),
      'profit': serializer.toJson<double>(profit),
      'cycleId': serializer.toJson<String?>(cycleId),
      'unitId': serializer.toJson<String?>(unitId),
      'quantityInBase': serializer.toJson<int?>(quantityInBase),
      'unitSellPrice': serializer.toJson<double?>(unitSellPrice),
    };
  }

  LocalSaleItem copyWith({
    String? id,
    String? saleId,
    String? productId,
    String? productName,
    int? quantity,
    double? sellPrice,
    double? buyPrice,
    double? profit,
    Value<String?> cycleId = const Value.absent(),
    Value<String?> unitId = const Value.absent(),
    Value<int?> quantityInBase = const Value.absent(),
    Value<double?> unitSellPrice = const Value.absent(),
  }) => LocalSaleItem(
    id: id ?? this.id,
    saleId: saleId ?? this.saleId,
    productId: productId ?? this.productId,
    productName: productName ?? this.productName,
    quantity: quantity ?? this.quantity,
    sellPrice: sellPrice ?? this.sellPrice,
    buyPrice: buyPrice ?? this.buyPrice,
    profit: profit ?? this.profit,
    cycleId: cycleId.present ? cycleId.value : this.cycleId,
    unitId: unitId.present ? unitId.value : this.unitId,
    quantityInBase: quantityInBase.present
        ? quantityInBase.value
        : this.quantityInBase,
    unitSellPrice: unitSellPrice.present
        ? unitSellPrice.value
        : this.unitSellPrice,
  );
  LocalSaleItem copyWithCompanion(LocalSaleItemsCompanion data) {
    return LocalSaleItem(
      id: data.id.present ? data.id.value : this.id,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      sellPrice: data.sellPrice.present ? data.sellPrice.value : this.sellPrice,
      buyPrice: data.buyPrice.present ? data.buyPrice.value : this.buyPrice,
      profit: data.profit.present ? data.profit.value : this.profit,
      cycleId: data.cycleId.present ? data.cycleId.value : this.cycleId,
      unitId: data.unitId.present ? data.unitId.value : this.unitId,
      quantityInBase: data.quantityInBase.present
          ? data.quantityInBase.value
          : this.quantityInBase,
      unitSellPrice: data.unitSellPrice.present
          ? data.unitSellPrice.value
          : this.unitSellPrice,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSaleItem(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('quantity: $quantity, ')
          ..write('sellPrice: $sellPrice, ')
          ..write('buyPrice: $buyPrice, ')
          ..write('profit: $profit, ')
          ..write('cycleId: $cycleId, ')
          ..write('unitId: $unitId, ')
          ..write('quantityInBase: $quantityInBase, ')
          ..write('unitSellPrice: $unitSellPrice')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    saleId,
    productId,
    productName,
    quantity,
    sellPrice,
    buyPrice,
    profit,
    cycleId,
    unitId,
    quantityInBase,
    unitSellPrice,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSaleItem &&
          other.id == this.id &&
          other.saleId == this.saleId &&
          other.productId == this.productId &&
          other.productName == this.productName &&
          other.quantity == this.quantity &&
          other.sellPrice == this.sellPrice &&
          other.buyPrice == this.buyPrice &&
          other.profit == this.profit &&
          other.cycleId == this.cycleId &&
          other.unitId == this.unitId &&
          other.quantityInBase == this.quantityInBase &&
          other.unitSellPrice == this.unitSellPrice);
}

class LocalSaleItemsCompanion extends UpdateCompanion<LocalSaleItem> {
  final Value<String> id;
  final Value<String> saleId;
  final Value<String> productId;
  final Value<String> productName;
  final Value<int> quantity;
  final Value<double> sellPrice;
  final Value<double> buyPrice;
  final Value<double> profit;
  final Value<String?> cycleId;
  final Value<String?> unitId;
  final Value<int?> quantityInBase;
  final Value<double?> unitSellPrice;
  final Value<int> rowid;
  const LocalSaleItemsCompanion({
    this.id = const Value.absent(),
    this.saleId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productName = const Value.absent(),
    this.quantity = const Value.absent(),
    this.sellPrice = const Value.absent(),
    this.buyPrice = const Value.absent(),
    this.profit = const Value.absent(),
    this.cycleId = const Value.absent(),
    this.unitId = const Value.absent(),
    this.quantityInBase = const Value.absent(),
    this.unitSellPrice = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSaleItemsCompanion.insert({
    required String id,
    required String saleId,
    required String productId,
    required String productName,
    required int quantity,
    required double sellPrice,
    required double buyPrice,
    required double profit,
    this.cycleId = const Value.absent(),
    this.unitId = const Value.absent(),
    this.quantityInBase = const Value.absent(),
    this.unitSellPrice = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       saleId = Value(saleId),
       productId = Value(productId),
       productName = Value(productName),
       quantity = Value(quantity),
       sellPrice = Value(sellPrice),
       buyPrice = Value(buyPrice),
       profit = Value(profit);
  static Insertable<LocalSaleItem> custom({
    Expression<String>? id,
    Expression<String>? saleId,
    Expression<String>? productId,
    Expression<String>? productName,
    Expression<int>? quantity,
    Expression<double>? sellPrice,
    Expression<double>? buyPrice,
    Expression<double>? profit,
    Expression<String>? cycleId,
    Expression<String>? unitId,
    Expression<int>? quantityInBase,
    Expression<double>? unitSellPrice,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (saleId != null) 'sale_id': saleId,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (quantity != null) 'quantity': quantity,
      if (sellPrice != null) 'sell_price': sellPrice,
      if (buyPrice != null) 'buy_price': buyPrice,
      if (profit != null) 'profit': profit,
      if (cycleId != null) 'cycle_id': cycleId,
      if (unitId != null) 'unit_id': unitId,
      if (quantityInBase != null) 'quantity_in_base': quantityInBase,
      if (unitSellPrice != null) 'unit_sell_price': unitSellPrice,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSaleItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? saleId,
    Value<String>? productId,
    Value<String>? productName,
    Value<int>? quantity,
    Value<double>? sellPrice,
    Value<double>? buyPrice,
    Value<double>? profit,
    Value<String?>? cycleId,
    Value<String?>? unitId,
    Value<int?>? quantityInBase,
    Value<double?>? unitSellPrice,
    Value<int>? rowid,
  }) {
    return LocalSaleItemsCompanion(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      sellPrice: sellPrice ?? this.sellPrice,
      buyPrice: buyPrice ?? this.buyPrice,
      profit: profit ?? this.profit,
      cycleId: cycleId ?? this.cycleId,
      unitId: unitId ?? this.unitId,
      quantityInBase: quantityInBase ?? this.quantityInBase,
      unitSellPrice: unitSellPrice ?? this.unitSellPrice,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<String>(saleId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (sellPrice.present) {
      map['sell_price'] = Variable<double>(sellPrice.value);
    }
    if (buyPrice.present) {
      map['buy_price'] = Variable<double>(buyPrice.value);
    }
    if (profit.present) {
      map['profit'] = Variable<double>(profit.value);
    }
    if (cycleId.present) {
      map['cycle_id'] = Variable<String>(cycleId.value);
    }
    if (unitId.present) {
      map['unit_id'] = Variable<String>(unitId.value);
    }
    if (quantityInBase.present) {
      map['quantity_in_base'] = Variable<int>(quantityInBase.value);
    }
    if (unitSellPrice.present) {
      map['unit_sell_price'] = Variable<double>(unitSellPrice.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSaleItemsCompanion(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('quantity: $quantity, ')
          ..write('sellPrice: $sellPrice, ')
          ..write('buyPrice: $buyPrice, ')
          ..write('profit: $profit, ')
          ..write('cycleId: $cycleId, ')
          ..write('unitId: $unitId, ')
          ..write('quantityInBase: $quantityInBase, ')
          ..write('unitSellPrice: $unitSellPrice, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalCashMovementsTable extends LocalCashMovements
    with TableInfo<$LocalCashMovementsTable, LocalCashMovement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCashMovementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shopIdMeta = const VerificationMeta('shopId');
  @override
  late final GeneratedColumn<String> shopId = GeneratedColumn<String>(
    'shop_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    shopId,
    userId,
    amount,
    type,
    category,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_cash_movements';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalCashMovement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('shop_id')) {
      context.handle(
        _shopIdMeta,
        shopId.isAcceptableOrUnknown(data['shop_id']!, _shopIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shopIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalCashMovement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCashMovement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      shopId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalCashMovementsTable createAlias(String alias) {
    return $LocalCashMovementsTable(attachedDatabase, alias);
  }
}

class LocalCashMovement extends DataClass
    implements Insertable<LocalCashMovement> {
  final String id;
  final String shopId;
  final String userId;
  final double amount;
  final String type;
  final String? category;
  final String? note;
  final DateTime createdAt;
  const LocalCashMovement({
    required this.id,
    required this.shopId,
    required this.userId,
    required this.amount,
    required this.type,
    this.category,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['shop_id'] = Variable<String>(shopId);
    map['user_id'] = Variable<String>(userId);
    map['amount'] = Variable<double>(amount);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalCashMovementsCompanion toCompanion(bool nullToAbsent) {
    return LocalCashMovementsCompanion(
      id: Value(id),
      shopId: Value(shopId),
      userId: Value(userId),
      amount: Value(amount),
      type: Value(type),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory LocalCashMovement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCashMovement(
      id: serializer.fromJson<String>(json['id']),
      shopId: serializer.fromJson<String>(json['shopId']),
      userId: serializer.fromJson<String>(json['userId']),
      amount: serializer.fromJson<double>(json['amount']),
      type: serializer.fromJson<String>(json['type']),
      category: serializer.fromJson<String?>(json['category']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'shopId': serializer.toJson<String>(shopId),
      'userId': serializer.toJson<String>(userId),
      'amount': serializer.toJson<double>(amount),
      'type': serializer.toJson<String>(type),
      'category': serializer.toJson<String?>(category),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalCashMovement copyWith({
    String? id,
    String? shopId,
    String? userId,
    double? amount,
    String? type,
    Value<String?> category = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
  }) => LocalCashMovement(
    id: id ?? this.id,
    shopId: shopId ?? this.shopId,
    userId: userId ?? this.userId,
    amount: amount ?? this.amount,
    type: type ?? this.type,
    category: category.present ? category.value : this.category,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalCashMovement copyWithCompanion(LocalCashMovementsCompanion data) {
    return LocalCashMovement(
      id: data.id.present ? data.id.value : this.id,
      shopId: data.shopId.present ? data.shopId.value : this.shopId,
      userId: data.userId.present ? data.userId.value : this.userId,
      amount: data.amount.present ? data.amount.value : this.amount,
      type: data.type.present ? data.type.value : this.type,
      category: data.category.present ? data.category.value : this.category,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCashMovement(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('userId: $userId, ')
          ..write('amount: $amount, ')
          ..write('type: $type, ')
          ..write('category: $category, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, shopId, userId, amount, type, category, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCashMovement &&
          other.id == this.id &&
          other.shopId == this.shopId &&
          other.userId == this.userId &&
          other.amount == this.amount &&
          other.type == this.type &&
          other.category == this.category &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class LocalCashMovementsCompanion extends UpdateCompanion<LocalCashMovement> {
  final Value<String> id;
  final Value<String> shopId;
  final Value<String> userId;
  final Value<double> amount;
  final Value<String> type;
  final Value<String?> category;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalCashMovementsCompanion({
    this.id = const Value.absent(),
    this.shopId = const Value.absent(),
    this.userId = const Value.absent(),
    this.amount = const Value.absent(),
    this.type = const Value.absent(),
    this.category = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalCashMovementsCompanion.insert({
    required String id,
    required String shopId,
    required String userId,
    required double amount,
    required String type,
    this.category = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       shopId = Value(shopId),
       userId = Value(userId),
       amount = Value(amount),
       type = Value(type),
       createdAt = Value(createdAt);
  static Insertable<LocalCashMovement> custom({
    Expression<String>? id,
    Expression<String>? shopId,
    Expression<String>? userId,
    Expression<double>? amount,
    Expression<String>? type,
    Expression<String>? category,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shopId != null) 'shop_id': shopId,
      if (userId != null) 'user_id': userId,
      if (amount != null) 'amount': amount,
      if (type != null) 'type': type,
      if (category != null) 'category': category,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalCashMovementsCompanion copyWith({
    Value<String>? id,
    Value<String>? shopId,
    Value<String>? userId,
    Value<double>? amount,
    Value<String>? type,
    Value<String?>? category,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LocalCashMovementsCompanion(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (shopId.present) {
      map['shop_id'] = Variable<String>(shopId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCashMovementsCompanion(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('userId: $userId, ')
          ..write('amount: $amount, ')
          ..write('type: $type, ')
          ..write('category: $category, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalStockMovementsTable extends LocalStockMovements
    with TableInfo<$LocalStockMovementsTable, LocalStockMovement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalStockMovementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shopIdMeta = const VerificationMeta('shopId');
  @override
  late final GeneratedColumn<String> shopId = GeneratedColumn<String>(
    'shop_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    shopId,
    productId,
    quantity,
    type,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_stock_movements';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalStockMovement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('shop_id')) {
      context.handle(
        _shopIdMeta,
        shopId.isAcceptableOrUnknown(data['shop_id']!, _shopIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shopIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalStockMovement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalStockMovement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      shopId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalStockMovementsTable createAlias(String alias) {
    return $LocalStockMovementsTable(attachedDatabase, alias);
  }
}

class LocalStockMovement extends DataClass
    implements Insertable<LocalStockMovement> {
  final String id;
  final String shopId;
  final String productId;
  final int quantity;
  final String type;
  final DateTime createdAt;
  const LocalStockMovement({
    required this.id,
    required this.shopId,
    required this.productId,
    required this.quantity,
    required this.type,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['shop_id'] = Variable<String>(shopId);
    map['product_id'] = Variable<String>(productId);
    map['quantity'] = Variable<int>(quantity);
    map['type'] = Variable<String>(type);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalStockMovementsCompanion toCompanion(bool nullToAbsent) {
    return LocalStockMovementsCompanion(
      id: Value(id),
      shopId: Value(shopId),
      productId: Value(productId),
      quantity: Value(quantity),
      type: Value(type),
      createdAt: Value(createdAt),
    );
  }

  factory LocalStockMovement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalStockMovement(
      id: serializer.fromJson<String>(json['id']),
      shopId: serializer.fromJson<String>(json['shopId']),
      productId: serializer.fromJson<String>(json['productId']),
      quantity: serializer.fromJson<int>(json['quantity']),
      type: serializer.fromJson<String>(json['type']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'shopId': serializer.toJson<String>(shopId),
      'productId': serializer.toJson<String>(productId),
      'quantity': serializer.toJson<int>(quantity),
      'type': serializer.toJson<String>(type),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalStockMovement copyWith({
    String? id,
    String? shopId,
    String? productId,
    int? quantity,
    String? type,
    DateTime? createdAt,
  }) => LocalStockMovement(
    id: id ?? this.id,
    shopId: shopId ?? this.shopId,
    productId: productId ?? this.productId,
    quantity: quantity ?? this.quantity,
    type: type ?? this.type,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalStockMovement copyWithCompanion(LocalStockMovementsCompanion data) {
    return LocalStockMovement(
      id: data.id.present ? data.id.value : this.id,
      shopId: data.shopId.present ? data.shopId.value : this.shopId,
      productId: data.productId.present ? data.productId.value : this.productId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      type: data.type.present ? data.type.value : this.type,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalStockMovement(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('productId: $productId, ')
          ..write('quantity: $quantity, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, shopId, productId, quantity, type, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalStockMovement &&
          other.id == this.id &&
          other.shopId == this.shopId &&
          other.productId == this.productId &&
          other.quantity == this.quantity &&
          other.type == this.type &&
          other.createdAt == this.createdAt);
}

class LocalStockMovementsCompanion extends UpdateCompanion<LocalStockMovement> {
  final Value<String> id;
  final Value<String> shopId;
  final Value<String> productId;
  final Value<int> quantity;
  final Value<String> type;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalStockMovementsCompanion({
    this.id = const Value.absent(),
    this.shopId = const Value.absent(),
    this.productId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.type = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalStockMovementsCompanion.insert({
    required String id,
    required String shopId,
    required String productId,
    required int quantity,
    required String type,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       shopId = Value(shopId),
       productId = Value(productId),
       quantity = Value(quantity),
       type = Value(type),
       createdAt = Value(createdAt);
  static Insertable<LocalStockMovement> custom({
    Expression<String>? id,
    Expression<String>? shopId,
    Expression<String>? productId,
    Expression<int>? quantity,
    Expression<String>? type,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shopId != null) 'shop_id': shopId,
      if (productId != null) 'product_id': productId,
      if (quantity != null) 'quantity': quantity,
      if (type != null) 'type': type,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalStockMovementsCompanion copyWith({
    Value<String>? id,
    Value<String>? shopId,
    Value<String>? productId,
    Value<int>? quantity,
    Value<String>? type,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LocalStockMovementsCompanion(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (shopId.present) {
      map['shop_id'] = Variable<String>(shopId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalStockMovementsCompanion(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('productId: $productId, ')
          ..write('quantity: $quantity, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalDailyClosingsTable extends LocalDailyClosings
    with TableInfo<$LocalDailyClosingsTable, LocalDailyClosing> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalDailyClosingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shopIdMeta = const VerificationMeta('shopId');
  @override
  late final GeneratedColumn<String> shopId = GeneratedColumn<String>(
    'shop_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _closingDateMeta = const VerificationMeta(
    'closingDate',
  );
  @override
  late final GeneratedColumn<DateTime> closingDate = GeneratedColumn<DateTime>(
    'closing_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _morningBalanceMeta = const VerificationMeta(
    'morningBalance',
  );
  @override
  late final GeneratedColumn<double> morningBalance = GeneratedColumn<double>(
    'morning_balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalSalesMeta = const VerificationMeta(
    'totalSales',
  );
  @override
  late final GeneratedColumn<double> totalSales = GeneratedColumn<double>(
    'total_sales',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalWithdrawalsMeta = const VerificationMeta(
    'totalWithdrawals',
  );
  @override
  late final GeneratedColumn<double> totalWithdrawals = GeneratedColumn<double>(
    'total_withdrawals',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _calculatedCashMeta = const VerificationMeta(
    'calculatedCash',
  );
  @override
  late final GeneratedColumn<double> calculatedCash = GeneratedColumn<double>(
    'calculated_cash',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _grossProfitMeta = const VerificationMeta(
    'grossProfit',
  );
  @override
  late final GeneratedColumn<double> grossProfit = GeneratedColumn<double>(
    'gross_profit',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _netProfitMeta = const VerificationMeta(
    'netProfit',
  );
  @override
  late final GeneratedColumn<double> netProfit = GeneratedColumn<double>(
    'net_profit',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _physicalCashMeta = const VerificationMeta(
    'physicalCash',
  );
  @override
  late final GeneratedColumn<double> physicalCash = GeneratedColumn<double>(
    'physical_cash',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cashGapMeta = const VerificationMeta(
    'cashGap',
  );
  @override
  late final GeneratedColumn<double> cashGap = GeneratedColumn<double>(
    'cash_gap',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isClosedMeta = const VerificationMeta(
    'isClosed',
  );
  @override
  late final GeneratedColumn<bool> isClosed = GeneratedColumn<bool>(
    'is_closed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_closed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    shopId,
    userId,
    closingDate,
    morningBalance,
    totalSales,
    totalWithdrawals,
    calculatedCash,
    grossProfit,
    netProfit,
    physicalCash,
    cashGap,
    isClosed,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_daily_closings';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalDailyClosing> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('shop_id')) {
      context.handle(
        _shopIdMeta,
        shopId.isAcceptableOrUnknown(data['shop_id']!, _shopIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shopIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('closing_date')) {
      context.handle(
        _closingDateMeta,
        closingDate.isAcceptableOrUnknown(
          data['closing_date']!,
          _closingDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_closingDateMeta);
    }
    if (data.containsKey('morning_balance')) {
      context.handle(
        _morningBalanceMeta,
        morningBalance.isAcceptableOrUnknown(
          data['morning_balance']!,
          _morningBalanceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_morningBalanceMeta);
    }
    if (data.containsKey('total_sales')) {
      context.handle(
        _totalSalesMeta,
        totalSales.isAcceptableOrUnknown(data['total_sales']!, _totalSalesMeta),
      );
    } else if (isInserting) {
      context.missing(_totalSalesMeta);
    }
    if (data.containsKey('total_withdrawals')) {
      context.handle(
        _totalWithdrawalsMeta,
        totalWithdrawals.isAcceptableOrUnknown(
          data['total_withdrawals']!,
          _totalWithdrawalsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalWithdrawalsMeta);
    }
    if (data.containsKey('calculated_cash')) {
      context.handle(
        _calculatedCashMeta,
        calculatedCash.isAcceptableOrUnknown(
          data['calculated_cash']!,
          _calculatedCashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_calculatedCashMeta);
    }
    if (data.containsKey('gross_profit')) {
      context.handle(
        _grossProfitMeta,
        grossProfit.isAcceptableOrUnknown(
          data['gross_profit']!,
          _grossProfitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_grossProfitMeta);
    }
    if (data.containsKey('net_profit')) {
      context.handle(
        _netProfitMeta,
        netProfit.isAcceptableOrUnknown(data['net_profit']!, _netProfitMeta),
      );
    } else if (isInserting) {
      context.missing(_netProfitMeta);
    }
    if (data.containsKey('physical_cash')) {
      context.handle(
        _physicalCashMeta,
        physicalCash.isAcceptableOrUnknown(
          data['physical_cash']!,
          _physicalCashMeta,
        ),
      );
    }
    if (data.containsKey('cash_gap')) {
      context.handle(
        _cashGapMeta,
        cashGap.isAcceptableOrUnknown(data['cash_gap']!, _cashGapMeta),
      );
    }
    if (data.containsKey('is_closed')) {
      context.handle(
        _isClosedMeta,
        isClosed.isAcceptableOrUnknown(data['is_closed']!, _isClosedMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalDailyClosing map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDailyClosing(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      shopId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      closingDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}closing_date'],
      )!,
      morningBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}morning_balance'],
      )!,
      totalSales: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_sales'],
      )!,
      totalWithdrawals: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_withdrawals'],
      )!,
      calculatedCash: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}calculated_cash'],
      )!,
      grossProfit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}gross_profit'],
      )!,
      netProfit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}net_profit'],
      )!,
      physicalCash: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}physical_cash'],
      ),
      cashGap: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cash_gap'],
      ),
      isClosed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_closed'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $LocalDailyClosingsTable createAlias(String alias) {
    return $LocalDailyClosingsTable(attachedDatabase, alias);
  }
}

class LocalDailyClosing extends DataClass
    implements Insertable<LocalDailyClosing> {
  final String id;
  final String shopId;
  final String userId;
  final DateTime closingDate;
  final double morningBalance;
  final double totalSales;
  final double totalWithdrawals;
  final double calculatedCash;
  final double grossProfit;
  final double netProfit;
  final double? physicalCash;
  final double? cashGap;
  final bool isClosed;
  final String? note;
  const LocalDailyClosing({
    required this.id,
    required this.shopId,
    required this.userId,
    required this.closingDate,
    required this.morningBalance,
    required this.totalSales,
    required this.totalWithdrawals,
    required this.calculatedCash,
    required this.grossProfit,
    required this.netProfit,
    this.physicalCash,
    this.cashGap,
    required this.isClosed,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['shop_id'] = Variable<String>(shopId);
    map['user_id'] = Variable<String>(userId);
    map['closing_date'] = Variable<DateTime>(closingDate);
    map['morning_balance'] = Variable<double>(morningBalance);
    map['total_sales'] = Variable<double>(totalSales);
    map['total_withdrawals'] = Variable<double>(totalWithdrawals);
    map['calculated_cash'] = Variable<double>(calculatedCash);
    map['gross_profit'] = Variable<double>(grossProfit);
    map['net_profit'] = Variable<double>(netProfit);
    if (!nullToAbsent || physicalCash != null) {
      map['physical_cash'] = Variable<double>(physicalCash);
    }
    if (!nullToAbsent || cashGap != null) {
      map['cash_gap'] = Variable<double>(cashGap);
    }
    map['is_closed'] = Variable<bool>(isClosed);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  LocalDailyClosingsCompanion toCompanion(bool nullToAbsent) {
    return LocalDailyClosingsCompanion(
      id: Value(id),
      shopId: Value(shopId),
      userId: Value(userId),
      closingDate: Value(closingDate),
      morningBalance: Value(morningBalance),
      totalSales: Value(totalSales),
      totalWithdrawals: Value(totalWithdrawals),
      calculatedCash: Value(calculatedCash),
      grossProfit: Value(grossProfit),
      netProfit: Value(netProfit),
      physicalCash: physicalCash == null && nullToAbsent
          ? const Value.absent()
          : Value(physicalCash),
      cashGap: cashGap == null && nullToAbsent
          ? const Value.absent()
          : Value(cashGap),
      isClosed: Value(isClosed),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory LocalDailyClosing.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDailyClosing(
      id: serializer.fromJson<String>(json['id']),
      shopId: serializer.fromJson<String>(json['shopId']),
      userId: serializer.fromJson<String>(json['userId']),
      closingDate: serializer.fromJson<DateTime>(json['closingDate']),
      morningBalance: serializer.fromJson<double>(json['morningBalance']),
      totalSales: serializer.fromJson<double>(json['totalSales']),
      totalWithdrawals: serializer.fromJson<double>(json['totalWithdrawals']),
      calculatedCash: serializer.fromJson<double>(json['calculatedCash']),
      grossProfit: serializer.fromJson<double>(json['grossProfit']),
      netProfit: serializer.fromJson<double>(json['netProfit']),
      physicalCash: serializer.fromJson<double?>(json['physicalCash']),
      cashGap: serializer.fromJson<double?>(json['cashGap']),
      isClosed: serializer.fromJson<bool>(json['isClosed']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'shopId': serializer.toJson<String>(shopId),
      'userId': serializer.toJson<String>(userId),
      'closingDate': serializer.toJson<DateTime>(closingDate),
      'morningBalance': serializer.toJson<double>(morningBalance),
      'totalSales': serializer.toJson<double>(totalSales),
      'totalWithdrawals': serializer.toJson<double>(totalWithdrawals),
      'calculatedCash': serializer.toJson<double>(calculatedCash),
      'grossProfit': serializer.toJson<double>(grossProfit),
      'netProfit': serializer.toJson<double>(netProfit),
      'physicalCash': serializer.toJson<double?>(physicalCash),
      'cashGap': serializer.toJson<double?>(cashGap),
      'isClosed': serializer.toJson<bool>(isClosed),
      'note': serializer.toJson<String?>(note),
    };
  }

  LocalDailyClosing copyWith({
    String? id,
    String? shopId,
    String? userId,
    DateTime? closingDate,
    double? morningBalance,
    double? totalSales,
    double? totalWithdrawals,
    double? calculatedCash,
    double? grossProfit,
    double? netProfit,
    Value<double?> physicalCash = const Value.absent(),
    Value<double?> cashGap = const Value.absent(),
    bool? isClosed,
    Value<String?> note = const Value.absent(),
  }) => LocalDailyClosing(
    id: id ?? this.id,
    shopId: shopId ?? this.shopId,
    userId: userId ?? this.userId,
    closingDate: closingDate ?? this.closingDate,
    morningBalance: morningBalance ?? this.morningBalance,
    totalSales: totalSales ?? this.totalSales,
    totalWithdrawals: totalWithdrawals ?? this.totalWithdrawals,
    calculatedCash: calculatedCash ?? this.calculatedCash,
    grossProfit: grossProfit ?? this.grossProfit,
    netProfit: netProfit ?? this.netProfit,
    physicalCash: physicalCash.present ? physicalCash.value : this.physicalCash,
    cashGap: cashGap.present ? cashGap.value : this.cashGap,
    isClosed: isClosed ?? this.isClosed,
    note: note.present ? note.value : this.note,
  );
  LocalDailyClosing copyWithCompanion(LocalDailyClosingsCompanion data) {
    return LocalDailyClosing(
      id: data.id.present ? data.id.value : this.id,
      shopId: data.shopId.present ? data.shopId.value : this.shopId,
      userId: data.userId.present ? data.userId.value : this.userId,
      closingDate: data.closingDate.present
          ? data.closingDate.value
          : this.closingDate,
      morningBalance: data.morningBalance.present
          ? data.morningBalance.value
          : this.morningBalance,
      totalSales: data.totalSales.present
          ? data.totalSales.value
          : this.totalSales,
      totalWithdrawals: data.totalWithdrawals.present
          ? data.totalWithdrawals.value
          : this.totalWithdrawals,
      calculatedCash: data.calculatedCash.present
          ? data.calculatedCash.value
          : this.calculatedCash,
      grossProfit: data.grossProfit.present
          ? data.grossProfit.value
          : this.grossProfit,
      netProfit: data.netProfit.present ? data.netProfit.value : this.netProfit,
      physicalCash: data.physicalCash.present
          ? data.physicalCash.value
          : this.physicalCash,
      cashGap: data.cashGap.present ? data.cashGap.value : this.cashGap,
      isClosed: data.isClosed.present ? data.isClosed.value : this.isClosed,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDailyClosing(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('userId: $userId, ')
          ..write('closingDate: $closingDate, ')
          ..write('morningBalance: $morningBalance, ')
          ..write('totalSales: $totalSales, ')
          ..write('totalWithdrawals: $totalWithdrawals, ')
          ..write('calculatedCash: $calculatedCash, ')
          ..write('grossProfit: $grossProfit, ')
          ..write('netProfit: $netProfit, ')
          ..write('physicalCash: $physicalCash, ')
          ..write('cashGap: $cashGap, ')
          ..write('isClosed: $isClosed, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    shopId,
    userId,
    closingDate,
    morningBalance,
    totalSales,
    totalWithdrawals,
    calculatedCash,
    grossProfit,
    netProfit,
    physicalCash,
    cashGap,
    isClosed,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDailyClosing &&
          other.id == this.id &&
          other.shopId == this.shopId &&
          other.userId == this.userId &&
          other.closingDate == this.closingDate &&
          other.morningBalance == this.morningBalance &&
          other.totalSales == this.totalSales &&
          other.totalWithdrawals == this.totalWithdrawals &&
          other.calculatedCash == this.calculatedCash &&
          other.grossProfit == this.grossProfit &&
          other.netProfit == this.netProfit &&
          other.physicalCash == this.physicalCash &&
          other.cashGap == this.cashGap &&
          other.isClosed == this.isClosed &&
          other.note == this.note);
}

class LocalDailyClosingsCompanion extends UpdateCompanion<LocalDailyClosing> {
  final Value<String> id;
  final Value<String> shopId;
  final Value<String> userId;
  final Value<DateTime> closingDate;
  final Value<double> morningBalance;
  final Value<double> totalSales;
  final Value<double> totalWithdrawals;
  final Value<double> calculatedCash;
  final Value<double> grossProfit;
  final Value<double> netProfit;
  final Value<double?> physicalCash;
  final Value<double?> cashGap;
  final Value<bool> isClosed;
  final Value<String?> note;
  final Value<int> rowid;
  const LocalDailyClosingsCompanion({
    this.id = const Value.absent(),
    this.shopId = const Value.absent(),
    this.userId = const Value.absent(),
    this.closingDate = const Value.absent(),
    this.morningBalance = const Value.absent(),
    this.totalSales = const Value.absent(),
    this.totalWithdrawals = const Value.absent(),
    this.calculatedCash = const Value.absent(),
    this.grossProfit = const Value.absent(),
    this.netProfit = const Value.absent(),
    this.physicalCash = const Value.absent(),
    this.cashGap = const Value.absent(),
    this.isClosed = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalDailyClosingsCompanion.insert({
    required String id,
    required String shopId,
    required String userId,
    required DateTime closingDate,
    required double morningBalance,
    required double totalSales,
    required double totalWithdrawals,
    required double calculatedCash,
    required double grossProfit,
    required double netProfit,
    this.physicalCash = const Value.absent(),
    this.cashGap = const Value.absent(),
    this.isClosed = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       shopId = Value(shopId),
       userId = Value(userId),
       closingDate = Value(closingDate),
       morningBalance = Value(morningBalance),
       totalSales = Value(totalSales),
       totalWithdrawals = Value(totalWithdrawals),
       calculatedCash = Value(calculatedCash),
       grossProfit = Value(grossProfit),
       netProfit = Value(netProfit);
  static Insertable<LocalDailyClosing> custom({
    Expression<String>? id,
    Expression<String>? shopId,
    Expression<String>? userId,
    Expression<DateTime>? closingDate,
    Expression<double>? morningBalance,
    Expression<double>? totalSales,
    Expression<double>? totalWithdrawals,
    Expression<double>? calculatedCash,
    Expression<double>? grossProfit,
    Expression<double>? netProfit,
    Expression<double>? physicalCash,
    Expression<double>? cashGap,
    Expression<bool>? isClosed,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shopId != null) 'shop_id': shopId,
      if (userId != null) 'user_id': userId,
      if (closingDate != null) 'closing_date': closingDate,
      if (morningBalance != null) 'morning_balance': morningBalance,
      if (totalSales != null) 'total_sales': totalSales,
      if (totalWithdrawals != null) 'total_withdrawals': totalWithdrawals,
      if (calculatedCash != null) 'calculated_cash': calculatedCash,
      if (grossProfit != null) 'gross_profit': grossProfit,
      if (netProfit != null) 'net_profit': netProfit,
      if (physicalCash != null) 'physical_cash': physicalCash,
      if (cashGap != null) 'cash_gap': cashGap,
      if (isClosed != null) 'is_closed': isClosed,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalDailyClosingsCompanion copyWith({
    Value<String>? id,
    Value<String>? shopId,
    Value<String>? userId,
    Value<DateTime>? closingDate,
    Value<double>? morningBalance,
    Value<double>? totalSales,
    Value<double>? totalWithdrawals,
    Value<double>? calculatedCash,
    Value<double>? grossProfit,
    Value<double>? netProfit,
    Value<double?>? physicalCash,
    Value<double?>? cashGap,
    Value<bool>? isClosed,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return LocalDailyClosingsCompanion(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      userId: userId ?? this.userId,
      closingDate: closingDate ?? this.closingDate,
      morningBalance: morningBalance ?? this.morningBalance,
      totalSales: totalSales ?? this.totalSales,
      totalWithdrawals: totalWithdrawals ?? this.totalWithdrawals,
      calculatedCash: calculatedCash ?? this.calculatedCash,
      grossProfit: grossProfit ?? this.grossProfit,
      netProfit: netProfit ?? this.netProfit,
      physicalCash: physicalCash ?? this.physicalCash,
      cashGap: cashGap ?? this.cashGap,
      isClosed: isClosed ?? this.isClosed,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (shopId.present) {
      map['shop_id'] = Variable<String>(shopId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (closingDate.present) {
      map['closing_date'] = Variable<DateTime>(closingDate.value);
    }
    if (morningBalance.present) {
      map['morning_balance'] = Variable<double>(morningBalance.value);
    }
    if (totalSales.present) {
      map['total_sales'] = Variable<double>(totalSales.value);
    }
    if (totalWithdrawals.present) {
      map['total_withdrawals'] = Variable<double>(totalWithdrawals.value);
    }
    if (calculatedCash.present) {
      map['calculated_cash'] = Variable<double>(calculatedCash.value);
    }
    if (grossProfit.present) {
      map['gross_profit'] = Variable<double>(grossProfit.value);
    }
    if (netProfit.present) {
      map['net_profit'] = Variable<double>(netProfit.value);
    }
    if (physicalCash.present) {
      map['physical_cash'] = Variable<double>(physicalCash.value);
    }
    if (cashGap.present) {
      map['cash_gap'] = Variable<double>(cashGap.value);
    }
    if (isClosed.present) {
      map['is_closed'] = Variable<bool>(isClosed.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalDailyClosingsCompanion(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('userId: $userId, ')
          ..write('closingDate: $closingDate, ')
          ..write('morningBalance: $morningBalance, ')
          ..write('totalSales: $totalSales, ')
          ..write('totalWithdrawals: $totalWithdrawals, ')
          ..write('calculatedCash: $calculatedCash, ')
          ..write('grossProfit: $grossProfit, ')
          ..write('netProfit: $netProfit, ')
          ..write('physicalCash: $physicalCash, ')
          ..write('cashGap: $cashGap, ')
          ..write('isClosed: $isClosed, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalShopSettingsTable extends LocalShopSettings
    with TableInfo<$LocalShopSettingsTable, LocalShopSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalShopSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _shopIdMeta = const VerificationMeta('shopId');
  @override
  late final GeneratedColumn<String> shopId = GeneratedColumn<String>(
    'shop_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitModeMeta = const VerificationMeta(
    'unitMode',
  );
  @override
  late final GeneratedColumn<String> unitMode = GeneratedColumn<String>(
    'unit_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('simple'),
  );
  static const VerificationMeta _saleCaptureModeMeta = const VerificationMeta(
    'saleCaptureMode',
  );
  @override
  late final GeneratedColumn<String> saleCaptureMode = GeneratedColumn<String>(
    'sale_capture_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('realtime'),
  );
  static const VerificationMeta _multiPointEnabledMeta = const VerificationMeta(
    'multiPointEnabled',
  );
  @override
  late final GeneratedColumn<bool> multiPointEnabled = GeneratedColumn<bool>(
    'multi_point_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("multi_point_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    shopId,
    unitMode,
    saleCaptureMode,
    multiPointEnabled,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_shop_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalShopSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('shop_id')) {
      context.handle(
        _shopIdMeta,
        shopId.isAcceptableOrUnknown(data['shop_id']!, _shopIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shopIdMeta);
    }
    if (data.containsKey('unit_mode')) {
      context.handle(
        _unitModeMeta,
        unitMode.isAcceptableOrUnknown(data['unit_mode']!, _unitModeMeta),
      );
    }
    if (data.containsKey('sale_capture_mode')) {
      context.handle(
        _saleCaptureModeMeta,
        saleCaptureMode.isAcceptableOrUnknown(
          data['sale_capture_mode']!,
          _saleCaptureModeMeta,
        ),
      );
    }
    if (data.containsKey('multi_point_enabled')) {
      context.handle(
        _multiPointEnabledMeta,
        multiPointEnabled.isAcceptableOrUnknown(
          data['multi_point_enabled']!,
          _multiPointEnabledMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {shopId};
  @override
  LocalShopSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalShopSetting(
      shopId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_id'],
      )!,
      unitMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_mode'],
      )!,
      saleCaptureMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_capture_mode'],
      )!,
      multiPointEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}multi_point_enabled'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalShopSettingsTable createAlias(String alias) {
    return $LocalShopSettingsTable(attachedDatabase, alias);
  }
}

class LocalShopSetting extends DataClass
    implements Insertable<LocalShopSetting> {
  final String shopId;
  final String unitMode;
  final String saleCaptureMode;
  final bool multiPointEnabled;
  final DateTime updatedAt;
  const LocalShopSetting({
    required this.shopId,
    required this.unitMode,
    required this.saleCaptureMode,
    required this.multiPointEnabled,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['shop_id'] = Variable<String>(shopId);
    map['unit_mode'] = Variable<String>(unitMode);
    map['sale_capture_mode'] = Variable<String>(saleCaptureMode);
    map['multi_point_enabled'] = Variable<bool>(multiPointEnabled);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalShopSettingsCompanion toCompanion(bool nullToAbsent) {
    return LocalShopSettingsCompanion(
      shopId: Value(shopId),
      unitMode: Value(unitMode),
      saleCaptureMode: Value(saleCaptureMode),
      multiPointEnabled: Value(multiPointEnabled),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalShopSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalShopSetting(
      shopId: serializer.fromJson<String>(json['shopId']),
      unitMode: serializer.fromJson<String>(json['unitMode']),
      saleCaptureMode: serializer.fromJson<String>(json['saleCaptureMode']),
      multiPointEnabled: serializer.fromJson<bool>(json['multiPointEnabled']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'shopId': serializer.toJson<String>(shopId),
      'unitMode': serializer.toJson<String>(unitMode),
      'saleCaptureMode': serializer.toJson<String>(saleCaptureMode),
      'multiPointEnabled': serializer.toJson<bool>(multiPointEnabled),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalShopSetting copyWith({
    String? shopId,
    String? unitMode,
    String? saleCaptureMode,
    bool? multiPointEnabled,
    DateTime? updatedAt,
  }) => LocalShopSetting(
    shopId: shopId ?? this.shopId,
    unitMode: unitMode ?? this.unitMode,
    saleCaptureMode: saleCaptureMode ?? this.saleCaptureMode,
    multiPointEnabled: multiPointEnabled ?? this.multiPointEnabled,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalShopSetting copyWithCompanion(LocalShopSettingsCompanion data) {
    return LocalShopSetting(
      shopId: data.shopId.present ? data.shopId.value : this.shopId,
      unitMode: data.unitMode.present ? data.unitMode.value : this.unitMode,
      saleCaptureMode: data.saleCaptureMode.present
          ? data.saleCaptureMode.value
          : this.saleCaptureMode,
      multiPointEnabled: data.multiPointEnabled.present
          ? data.multiPointEnabled.value
          : this.multiPointEnabled,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalShopSetting(')
          ..write('shopId: $shopId, ')
          ..write('unitMode: $unitMode, ')
          ..write('saleCaptureMode: $saleCaptureMode, ')
          ..write('multiPointEnabled: $multiPointEnabled, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    shopId,
    unitMode,
    saleCaptureMode,
    multiPointEnabled,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalShopSetting &&
          other.shopId == this.shopId &&
          other.unitMode == this.unitMode &&
          other.saleCaptureMode == this.saleCaptureMode &&
          other.multiPointEnabled == this.multiPointEnabled &&
          other.updatedAt == this.updatedAt);
}

class LocalShopSettingsCompanion extends UpdateCompanion<LocalShopSetting> {
  final Value<String> shopId;
  final Value<String> unitMode;
  final Value<String> saleCaptureMode;
  final Value<bool> multiPointEnabled;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalShopSettingsCompanion({
    this.shopId = const Value.absent(),
    this.unitMode = const Value.absent(),
    this.saleCaptureMode = const Value.absent(),
    this.multiPointEnabled = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalShopSettingsCompanion.insert({
    required String shopId,
    this.unitMode = const Value.absent(),
    this.saleCaptureMode = const Value.absent(),
    this.multiPointEnabled = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : shopId = Value(shopId);
  static Insertable<LocalShopSetting> custom({
    Expression<String>? shopId,
    Expression<String>? unitMode,
    Expression<String>? saleCaptureMode,
    Expression<bool>? multiPointEnabled,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (shopId != null) 'shop_id': shopId,
      if (unitMode != null) 'unit_mode': unitMode,
      if (saleCaptureMode != null) 'sale_capture_mode': saleCaptureMode,
      if (multiPointEnabled != null) 'multi_point_enabled': multiPointEnabled,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalShopSettingsCompanion copyWith({
    Value<String>? shopId,
    Value<String>? unitMode,
    Value<String>? saleCaptureMode,
    Value<bool>? multiPointEnabled,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalShopSettingsCompanion(
      shopId: shopId ?? this.shopId,
      unitMode: unitMode ?? this.unitMode,
      saleCaptureMode: saleCaptureMode ?? this.saleCaptureMode,
      multiPointEnabled: multiPointEnabled ?? this.multiPointEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (shopId.present) {
      map['shop_id'] = Variable<String>(shopId.value);
    }
    if (unitMode.present) {
      map['unit_mode'] = Variable<String>(unitMode.value);
    }
    if (saleCaptureMode.present) {
      map['sale_capture_mode'] = Variable<String>(saleCaptureMode.value);
    }
    if (multiPointEnabled.present) {
      map['multi_point_enabled'] = Variable<bool>(multiPointEnabled.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalShopSettingsCompanion(')
          ..write('shopId: $shopId, ')
          ..write('unitMode: $unitMode, ')
          ..write('saleCaptureMode: $saleCaptureMode, ')
          ..write('multiPointEnabled: $multiPointEnabled, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalProductUnitsTable extends LocalProductUnits
    with TableInfo<$LocalProductUnitsTable, LocalProductUnit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalProductUnitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitNameMeta = const VerificationMeta(
    'unitName',
  );
  @override
  late final GeneratedColumn<String> unitName = GeneratedColumn<String>(
    'unit_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratioToBaseMeta = const VerificationMeta(
    'ratioToBase',
  );
  @override
  late final GeneratedColumn<int> ratioToBase = GeneratedColumn<int>(
    'ratio_to_base',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    unitName,
    ratioToBase,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_product_units';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalProductUnit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('unit_name')) {
      context.handle(
        _unitNameMeta,
        unitName.isAcceptableOrUnknown(data['unit_name']!, _unitNameMeta),
      );
    } else if (isInserting) {
      context.missing(_unitNameMeta);
    }
    if (data.containsKey('ratio_to_base')) {
      context.handle(
        _ratioToBaseMeta,
        ratioToBase.isAcceptableOrUnknown(
          data['ratio_to_base']!,
          _ratioToBaseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ratioToBaseMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalProductUnit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalProductUnit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      unitName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_name'],
      )!,
      ratioToBase: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ratio_to_base'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $LocalProductUnitsTable createAlias(String alias) {
    return $LocalProductUnitsTable(attachedDatabase, alias);
  }
}

class LocalProductUnit extends DataClass
    implements Insertable<LocalProductUnit> {
  final String id;
  final String productId;
  final String unitName;
  final int ratioToBase;
  final int sortOrder;
  const LocalProductUnit({
    required this.id,
    required this.productId,
    required this.unitName,
    required this.ratioToBase,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['product_id'] = Variable<String>(productId);
    map['unit_name'] = Variable<String>(unitName);
    map['ratio_to_base'] = Variable<int>(ratioToBase);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  LocalProductUnitsCompanion toCompanion(bool nullToAbsent) {
    return LocalProductUnitsCompanion(
      id: Value(id),
      productId: Value(productId),
      unitName: Value(unitName),
      ratioToBase: Value(ratioToBase),
      sortOrder: Value(sortOrder),
    );
  }

  factory LocalProductUnit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalProductUnit(
      id: serializer.fromJson<String>(json['id']),
      productId: serializer.fromJson<String>(json['productId']),
      unitName: serializer.fromJson<String>(json['unitName']),
      ratioToBase: serializer.fromJson<int>(json['ratioToBase']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productId': serializer.toJson<String>(productId),
      'unitName': serializer.toJson<String>(unitName),
      'ratioToBase': serializer.toJson<int>(ratioToBase),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  LocalProductUnit copyWith({
    String? id,
    String? productId,
    String? unitName,
    int? ratioToBase,
    int? sortOrder,
  }) => LocalProductUnit(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    unitName: unitName ?? this.unitName,
    ratioToBase: ratioToBase ?? this.ratioToBase,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  LocalProductUnit copyWithCompanion(LocalProductUnitsCompanion data) {
    return LocalProductUnit(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      unitName: data.unitName.present ? data.unitName.value : this.unitName,
      ratioToBase: data.ratioToBase.present
          ? data.ratioToBase.value
          : this.ratioToBase,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalProductUnit(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('unitName: $unitName, ')
          ..write('ratioToBase: $ratioToBase, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, productId, unitName, ratioToBase, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalProductUnit &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.unitName == this.unitName &&
          other.ratioToBase == this.ratioToBase &&
          other.sortOrder == this.sortOrder);
}

class LocalProductUnitsCompanion extends UpdateCompanion<LocalProductUnit> {
  final Value<String> id;
  final Value<String> productId;
  final Value<String> unitName;
  final Value<int> ratioToBase;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const LocalProductUnitsCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.unitName = const Value.absent(),
    this.ratioToBase = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalProductUnitsCompanion.insert({
    required String id,
    required String productId,
    required String unitName,
    required int ratioToBase,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       productId = Value(productId),
       unitName = Value(unitName),
       ratioToBase = Value(ratioToBase);
  static Insertable<LocalProductUnit> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<String>? unitName,
    Expression<int>? ratioToBase,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (unitName != null) 'unit_name': unitName,
      if (ratioToBase != null) 'ratio_to_base': ratioToBase,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalProductUnitsCompanion copyWith({
    Value<String>? id,
    Value<String>? productId,
    Value<String>? unitName,
    Value<int>? ratioToBase,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return LocalProductUnitsCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      unitName: unitName ?? this.unitName,
      ratioToBase: ratioToBase ?? this.ratioToBase,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (unitName.present) {
      map['unit_name'] = Variable<String>(unitName.value);
    }
    if (ratioToBase.present) {
      map['ratio_to_base'] = Variable<int>(ratioToBase.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalProductUnitsCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('unitName: $unitName, ')
          ..write('ratioToBase: $ratioToBase, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSupplyCyclesTable extends LocalSupplyCycles
    with TableInfo<$LocalSupplyCyclesTable, LocalSupplyCycle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSupplyCyclesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shopIdMeta = const VerificationMeta('shopId');
  @override
  late final GeneratedColumn<String> shopId = GeneratedColumn<String>(
    'shop_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openedAtMeta = const VerificationMeta(
    'openedAt',
  );
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
    'opened_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _closedAtMeta = const VerificationMeta(
    'closedAt',
  );
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
    'closed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityReceivedMeta = const VerificationMeta(
    'quantityReceived',
  );
  @override
  late final GeneratedColumn<int> quantityReceived = GeneratedColumn<int>(
    'quantity_received',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _purchaseCostMeta = const VerificationMeta(
    'purchaseCost',
  );
  @override
  late final GeneratedColumn<double> purchaseCost = GeneratedColumn<double>(
    'purchase_cost',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceMarginPerUnitMeta =
      const VerificationMeta('referenceMarginPerUnit');
  @override
  late final GeneratedColumn<double> referenceMarginPerUnit =
      GeneratedColumn<double>(
        'reference_margin_per_unit',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('open'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    shopId,
    productId,
    openedAt,
    closedAt,
    quantityReceived,
    purchaseCost,
    referenceMarginPerUnit,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_supply_cycles';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSupplyCycle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('shop_id')) {
      context.handle(
        _shopIdMeta,
        shopId.isAcceptableOrUnknown(data['shop_id']!, _shopIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shopIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('opened_at')) {
      context.handle(
        _openedAtMeta,
        openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_openedAtMeta);
    }
    if (data.containsKey('closed_at')) {
      context.handle(
        _closedAtMeta,
        closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta),
      );
    }
    if (data.containsKey('quantity_received')) {
      context.handle(
        _quantityReceivedMeta,
        quantityReceived.isAcceptableOrUnknown(
          data['quantity_received']!,
          _quantityReceivedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quantityReceivedMeta);
    }
    if (data.containsKey('purchase_cost')) {
      context.handle(
        _purchaseCostMeta,
        purchaseCost.isAcceptableOrUnknown(
          data['purchase_cost']!,
          _purchaseCostMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_purchaseCostMeta);
    }
    if (data.containsKey('reference_margin_per_unit')) {
      context.handle(
        _referenceMarginPerUnitMeta,
        referenceMarginPerUnit.isAcceptableOrUnknown(
          data['reference_margin_per_unit']!,
          _referenceMarginPerUnitMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSupplyCycle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSupplyCycle(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      shopId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      openedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}opened_at'],
      )!,
      closedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}closed_at'],
      ),
      quantityReceived: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity_received'],
      )!,
      purchaseCost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}purchase_cost'],
      )!,
      referenceMarginPerUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}reference_margin_per_unit'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $LocalSupplyCyclesTable createAlias(String alias) {
    return $LocalSupplyCyclesTable(attachedDatabase, alias);
  }
}

class LocalSupplyCycle extends DataClass
    implements Insertable<LocalSupplyCycle> {
  final String id;
  final String shopId;
  final String productId;
  final DateTime openedAt;
  final DateTime? closedAt;
  final int quantityReceived;
  final double purchaseCost;
  final double? referenceMarginPerUnit;
  final String status;
  const LocalSupplyCycle({
    required this.id,
    required this.shopId,
    required this.productId,
    required this.openedAt,
    this.closedAt,
    required this.quantityReceived,
    required this.purchaseCost,
    this.referenceMarginPerUnit,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['shop_id'] = Variable<String>(shopId);
    map['product_id'] = Variable<String>(productId);
    map['opened_at'] = Variable<DateTime>(openedAt);
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<DateTime>(closedAt);
    }
    map['quantity_received'] = Variable<int>(quantityReceived);
    map['purchase_cost'] = Variable<double>(purchaseCost);
    if (!nullToAbsent || referenceMarginPerUnit != null) {
      map['reference_margin_per_unit'] = Variable<double>(
        referenceMarginPerUnit,
      );
    }
    map['status'] = Variable<String>(status);
    return map;
  }

  LocalSupplyCyclesCompanion toCompanion(bool nullToAbsent) {
    return LocalSupplyCyclesCompanion(
      id: Value(id),
      shopId: Value(shopId),
      productId: Value(productId),
      openedAt: Value(openedAt),
      closedAt: closedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAt),
      quantityReceived: Value(quantityReceived),
      purchaseCost: Value(purchaseCost),
      referenceMarginPerUnit: referenceMarginPerUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(referenceMarginPerUnit),
      status: Value(status),
    );
  }

  factory LocalSupplyCycle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSupplyCycle(
      id: serializer.fromJson<String>(json['id']),
      shopId: serializer.fromJson<String>(json['shopId']),
      productId: serializer.fromJson<String>(json['productId']),
      openedAt: serializer.fromJson<DateTime>(json['openedAt']),
      closedAt: serializer.fromJson<DateTime?>(json['closedAt']),
      quantityReceived: serializer.fromJson<int>(json['quantityReceived']),
      purchaseCost: serializer.fromJson<double>(json['purchaseCost']),
      referenceMarginPerUnit: serializer.fromJson<double?>(
        json['referenceMarginPerUnit'],
      ),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'shopId': serializer.toJson<String>(shopId),
      'productId': serializer.toJson<String>(productId),
      'openedAt': serializer.toJson<DateTime>(openedAt),
      'closedAt': serializer.toJson<DateTime?>(closedAt),
      'quantityReceived': serializer.toJson<int>(quantityReceived),
      'purchaseCost': serializer.toJson<double>(purchaseCost),
      'referenceMarginPerUnit': serializer.toJson<double?>(
        referenceMarginPerUnit,
      ),
      'status': serializer.toJson<String>(status),
    };
  }

  LocalSupplyCycle copyWith({
    String? id,
    String? shopId,
    String? productId,
    DateTime? openedAt,
    Value<DateTime?> closedAt = const Value.absent(),
    int? quantityReceived,
    double? purchaseCost,
    Value<double?> referenceMarginPerUnit = const Value.absent(),
    String? status,
  }) => LocalSupplyCycle(
    id: id ?? this.id,
    shopId: shopId ?? this.shopId,
    productId: productId ?? this.productId,
    openedAt: openedAt ?? this.openedAt,
    closedAt: closedAt.present ? closedAt.value : this.closedAt,
    quantityReceived: quantityReceived ?? this.quantityReceived,
    purchaseCost: purchaseCost ?? this.purchaseCost,
    referenceMarginPerUnit: referenceMarginPerUnit.present
        ? referenceMarginPerUnit.value
        : this.referenceMarginPerUnit,
    status: status ?? this.status,
  );
  LocalSupplyCycle copyWithCompanion(LocalSupplyCyclesCompanion data) {
    return LocalSupplyCycle(
      id: data.id.present ? data.id.value : this.id,
      shopId: data.shopId.present ? data.shopId.value : this.shopId,
      productId: data.productId.present ? data.productId.value : this.productId,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
      quantityReceived: data.quantityReceived.present
          ? data.quantityReceived.value
          : this.quantityReceived,
      purchaseCost: data.purchaseCost.present
          ? data.purchaseCost.value
          : this.purchaseCost,
      referenceMarginPerUnit: data.referenceMarginPerUnit.present
          ? data.referenceMarginPerUnit.value
          : this.referenceMarginPerUnit,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSupplyCycle(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('productId: $productId, ')
          ..write('openedAt: $openedAt, ')
          ..write('closedAt: $closedAt, ')
          ..write('quantityReceived: $quantityReceived, ')
          ..write('purchaseCost: $purchaseCost, ')
          ..write('referenceMarginPerUnit: $referenceMarginPerUnit, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    shopId,
    productId,
    openedAt,
    closedAt,
    quantityReceived,
    purchaseCost,
    referenceMarginPerUnit,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSupplyCycle &&
          other.id == this.id &&
          other.shopId == this.shopId &&
          other.productId == this.productId &&
          other.openedAt == this.openedAt &&
          other.closedAt == this.closedAt &&
          other.quantityReceived == this.quantityReceived &&
          other.purchaseCost == this.purchaseCost &&
          other.referenceMarginPerUnit == this.referenceMarginPerUnit &&
          other.status == this.status);
}

class LocalSupplyCyclesCompanion extends UpdateCompanion<LocalSupplyCycle> {
  final Value<String> id;
  final Value<String> shopId;
  final Value<String> productId;
  final Value<DateTime> openedAt;
  final Value<DateTime?> closedAt;
  final Value<int> quantityReceived;
  final Value<double> purchaseCost;
  final Value<double?> referenceMarginPerUnit;
  final Value<String> status;
  final Value<int> rowid;
  const LocalSupplyCyclesCompanion({
    this.id = const Value.absent(),
    this.shopId = const Value.absent(),
    this.productId = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.quantityReceived = const Value.absent(),
    this.purchaseCost = const Value.absent(),
    this.referenceMarginPerUnit = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSupplyCyclesCompanion.insert({
    required String id,
    required String shopId,
    required String productId,
    required DateTime openedAt,
    this.closedAt = const Value.absent(),
    required int quantityReceived,
    required double purchaseCost,
    this.referenceMarginPerUnit = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       shopId = Value(shopId),
       productId = Value(productId),
       openedAt = Value(openedAt),
       quantityReceived = Value(quantityReceived),
       purchaseCost = Value(purchaseCost);
  static Insertable<LocalSupplyCycle> custom({
    Expression<String>? id,
    Expression<String>? shopId,
    Expression<String>? productId,
    Expression<DateTime>? openedAt,
    Expression<DateTime>? closedAt,
    Expression<int>? quantityReceived,
    Expression<double>? purchaseCost,
    Expression<double>? referenceMarginPerUnit,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shopId != null) 'shop_id': shopId,
      if (productId != null) 'product_id': productId,
      if (openedAt != null) 'opened_at': openedAt,
      if (closedAt != null) 'closed_at': closedAt,
      if (quantityReceived != null) 'quantity_received': quantityReceived,
      if (purchaseCost != null) 'purchase_cost': purchaseCost,
      if (referenceMarginPerUnit != null)
        'reference_margin_per_unit': referenceMarginPerUnit,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSupplyCyclesCompanion copyWith({
    Value<String>? id,
    Value<String>? shopId,
    Value<String>? productId,
    Value<DateTime>? openedAt,
    Value<DateTime?>? closedAt,
    Value<int>? quantityReceived,
    Value<double>? purchaseCost,
    Value<double?>? referenceMarginPerUnit,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return LocalSupplyCyclesCompanion(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      productId: productId ?? this.productId,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      quantityReceived: quantityReceived ?? this.quantityReceived,
      purchaseCost: purchaseCost ?? this.purchaseCost,
      referenceMarginPerUnit:
          referenceMarginPerUnit ?? this.referenceMarginPerUnit,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (shopId.present) {
      map['shop_id'] = Variable<String>(shopId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    if (quantityReceived.present) {
      map['quantity_received'] = Variable<int>(quantityReceived.value);
    }
    if (purchaseCost.present) {
      map['purchase_cost'] = Variable<double>(purchaseCost.value);
    }
    if (referenceMarginPerUnit.present) {
      map['reference_margin_per_unit'] = Variable<double>(
        referenceMarginPerUnit.value,
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSupplyCyclesCompanion(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('productId: $productId, ')
          ..write('openedAt: $openedAt, ')
          ..write('closedAt: $closedAt, ')
          ..write('quantityReceived: $quantityReceived, ')
          ..write('purchaseCost: $purchaseCost, ')
          ..write('referenceMarginPerUnit: $referenceMarginPerUnit, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalCycleLossesTable extends LocalCycleLosses
    with TableInfo<$LocalCycleLossesTable, LocalCycleLossesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCycleLossesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cycleIdMeta = const VerificationMeta(
    'cycleId',
  );
  @override
  late final GeneratedColumn<String> cycleId = GeneratedColumn<String>(
    'cycle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cycleId,
    quantity,
    reason,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_cycle_losses';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalCycleLossesData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('cycle_id')) {
      context.handle(
        _cycleIdMeta,
        cycleId.isAcceptableOrUnknown(data['cycle_id']!, _cycleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cycleIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalCycleLossesData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCycleLossesData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      cycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cycle_id'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalCycleLossesTable createAlias(String alias) {
    return $LocalCycleLossesTable(attachedDatabase, alias);
  }
}

class LocalCycleLossesData extends DataClass
    implements Insertable<LocalCycleLossesData> {
  final String id;
  final String cycleId;
  final int quantity;
  final String reason;
  final String? note;
  final DateTime createdAt;
  const LocalCycleLossesData({
    required this.id,
    required this.cycleId,
    required this.quantity,
    required this.reason,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['cycle_id'] = Variable<String>(cycleId);
    map['quantity'] = Variable<int>(quantity);
    map['reason'] = Variable<String>(reason);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalCycleLossesCompanion toCompanion(bool nullToAbsent) {
    return LocalCycleLossesCompanion(
      id: Value(id),
      cycleId: Value(cycleId),
      quantity: Value(quantity),
      reason: Value(reason),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory LocalCycleLossesData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCycleLossesData(
      id: serializer.fromJson<String>(json['id']),
      cycleId: serializer.fromJson<String>(json['cycleId']),
      quantity: serializer.fromJson<int>(json['quantity']),
      reason: serializer.fromJson<String>(json['reason']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'cycleId': serializer.toJson<String>(cycleId),
      'quantity': serializer.toJson<int>(quantity),
      'reason': serializer.toJson<String>(reason),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalCycleLossesData copyWith({
    String? id,
    String? cycleId,
    int? quantity,
    String? reason,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
  }) => LocalCycleLossesData(
    id: id ?? this.id,
    cycleId: cycleId ?? this.cycleId,
    quantity: quantity ?? this.quantity,
    reason: reason ?? this.reason,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalCycleLossesData copyWithCompanion(LocalCycleLossesCompanion data) {
    return LocalCycleLossesData(
      id: data.id.present ? data.id.value : this.id,
      cycleId: data.cycleId.present ? data.cycleId.value : this.cycleId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      reason: data.reason.present ? data.reason.value : this.reason,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCycleLossesData(')
          ..write('id: $id, ')
          ..write('cycleId: $cycleId, ')
          ..write('quantity: $quantity, ')
          ..write('reason: $reason, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, cycleId, quantity, reason, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCycleLossesData &&
          other.id == this.id &&
          other.cycleId == this.cycleId &&
          other.quantity == this.quantity &&
          other.reason == this.reason &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class LocalCycleLossesCompanion extends UpdateCompanion<LocalCycleLossesData> {
  final Value<String> id;
  final Value<String> cycleId;
  final Value<int> quantity;
  final Value<String> reason;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalCycleLossesCompanion({
    this.id = const Value.absent(),
    this.cycleId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.reason = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalCycleLossesCompanion.insert({
    required String id,
    required String cycleId,
    required int quantity,
    required String reason,
    this.note = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       cycleId = Value(cycleId),
       quantity = Value(quantity),
       reason = Value(reason),
       createdAt = Value(createdAt);
  static Insertable<LocalCycleLossesData> custom({
    Expression<String>? id,
    Expression<String>? cycleId,
    Expression<int>? quantity,
    Expression<String>? reason,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cycleId != null) 'cycle_id': cycleId,
      if (quantity != null) 'quantity': quantity,
      if (reason != null) 'reason': reason,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalCycleLossesCompanion copyWith({
    Value<String>? id,
    Value<String>? cycleId,
    Value<int>? quantity,
    Value<String>? reason,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LocalCycleLossesCompanion(
      id: id ?? this.id,
      cycleId: cycleId ?? this.cycleId,
      quantity: quantity ?? this.quantity,
      reason: reason ?? this.reason,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (cycleId.present) {
      map['cycle_id'] = Variable<String>(cycleId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCycleLossesCompanion(')
          ..write('id: $id, ')
          ..write('cycleId: $cycleId, ')
          ..write('quantity: $quantity, ')
          ..write('reason: $reason, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalShopTakingsTable extends LocalShopTakings
    with TableInfo<$LocalShopTakingsTable, LocalShopTaking> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalShopTakingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _shopIdMeta = const VerificationMeta('shopId');
  @override
  late final GeneratedColumn<String> shopId = GeneratedColumn<String>(
    'shop_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [shopId, date, amount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_shop_takings';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalShopTaking> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('shop_id')) {
      context.handle(
        _shopIdMeta,
        shopId.isAcceptableOrUnknown(data['shop_id']!, _shopIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shopIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {shopId, date};
  @override
  LocalShopTaking map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalShopTaking(
      shopId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
    );
  }

  @override
  $LocalShopTakingsTable createAlias(String alias) {
    return $LocalShopTakingsTable(attachedDatabase, alias);
  }
}

class LocalShopTaking extends DataClass implements Insertable<LocalShopTaking> {
  final String shopId;
  final DateTime date;
  final double amount;
  const LocalShopTaking({
    required this.shopId,
    required this.date,
    required this.amount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['shop_id'] = Variable<String>(shopId);
    map['date'] = Variable<DateTime>(date);
    map['amount'] = Variable<double>(amount);
    return map;
  }

  LocalShopTakingsCompanion toCompanion(bool nullToAbsent) {
    return LocalShopTakingsCompanion(
      shopId: Value(shopId),
      date: Value(date),
      amount: Value(amount),
    );
  }

  factory LocalShopTaking.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalShopTaking(
      shopId: serializer.fromJson<String>(json['shopId']),
      date: serializer.fromJson<DateTime>(json['date']),
      amount: serializer.fromJson<double>(json['amount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'shopId': serializer.toJson<String>(shopId),
      'date': serializer.toJson<DateTime>(date),
      'amount': serializer.toJson<double>(amount),
    };
  }

  LocalShopTaking copyWith({String? shopId, DateTime? date, double? amount}) =>
      LocalShopTaking(
        shopId: shopId ?? this.shopId,
        date: date ?? this.date,
        amount: amount ?? this.amount,
      );
  LocalShopTaking copyWithCompanion(LocalShopTakingsCompanion data) {
    return LocalShopTaking(
      shopId: data.shopId.present ? data.shopId.value : this.shopId,
      date: data.date.present ? data.date.value : this.date,
      amount: data.amount.present ? data.amount.value : this.amount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalShopTaking(')
          ..write('shopId: $shopId, ')
          ..write('date: $date, ')
          ..write('amount: $amount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(shopId, date, amount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalShopTaking &&
          other.shopId == this.shopId &&
          other.date == this.date &&
          other.amount == this.amount);
}

class LocalShopTakingsCompanion extends UpdateCompanion<LocalShopTaking> {
  final Value<String> shopId;
  final Value<DateTime> date;
  final Value<double> amount;
  final Value<int> rowid;
  const LocalShopTakingsCompanion({
    this.shopId = const Value.absent(),
    this.date = const Value.absent(),
    this.amount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalShopTakingsCompanion.insert({
    required String shopId,
    required DateTime date,
    required double amount,
    this.rowid = const Value.absent(),
  }) : shopId = Value(shopId),
       date = Value(date),
       amount = Value(amount);
  static Insertable<LocalShopTaking> custom({
    Expression<String>? shopId,
    Expression<DateTime>? date,
    Expression<double>? amount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (shopId != null) 'shop_id': shopId,
      if (date != null) 'date': date,
      if (amount != null) 'amount': amount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalShopTakingsCompanion copyWith({
    Value<String>? shopId,
    Value<DateTime>? date,
    Value<double>? amount,
    Value<int>? rowid,
  }) {
    return LocalShopTakingsCompanion(
      shopId: shopId ?? this.shopId,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (shopId.present) {
      map['shop_id'] = Variable<String>(shopId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalShopTakingsCompanion(')
          ..write('shopId: $shopId, ')
          ..write('date: $date, ')
          ..write('amount: $amount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalInventoryCountsTable extends LocalInventoryCounts
    with TableInfo<$LocalInventoryCountsTable, LocalInventoryCount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalInventoryCountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shopIdMeta = const VerificationMeta('shopId');
  @override
  late final GeneratedColumn<String> shopId = GeneratedColumn<String>(
    'shop_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countedAtMeta = const VerificationMeta(
    'countedAt',
  );
  @override
  late final GeneratedColumn<DateTime> countedAt = GeneratedColumn<DateTime>(
    'counted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countedQuantityMeta = const VerificationMeta(
    'countedQuantity',
  );
  @override
  late final GeneratedColumn<int> countedQuantity = GeneratedColumn<int>(
    'counted_quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _previousCountedAtMeta = const VerificationMeta(
    'previousCountedAt',
  );
  @override
  late final GeneratedColumn<DateTime> previousCountedAt =
      GeneratedColumn<DateTime>(
        'previous_counted_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _previousQuantityMeta = const VerificationMeta(
    'previousQuantity',
  );
  @override
  late final GeneratedColumn<int> previousQuantity = GeneratedColumn<int>(
    'previous_quantity',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    shopId,
    productId,
    countedAt,
    countedQuantity,
    previousCountedAt,
    previousQuantity,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_inventory_counts';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalInventoryCount> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('shop_id')) {
      context.handle(
        _shopIdMeta,
        shopId.isAcceptableOrUnknown(data['shop_id']!, _shopIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shopIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('counted_at')) {
      context.handle(
        _countedAtMeta,
        countedAt.isAcceptableOrUnknown(data['counted_at']!, _countedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_countedAtMeta);
    }
    if (data.containsKey('counted_quantity')) {
      context.handle(
        _countedQuantityMeta,
        countedQuantity.isAcceptableOrUnknown(
          data['counted_quantity']!,
          _countedQuantityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_countedQuantityMeta);
    }
    if (data.containsKey('previous_counted_at')) {
      context.handle(
        _previousCountedAtMeta,
        previousCountedAt.isAcceptableOrUnknown(
          data['previous_counted_at']!,
          _previousCountedAtMeta,
        ),
      );
    }
    if (data.containsKey('previous_quantity')) {
      context.handle(
        _previousQuantityMeta,
        previousQuantity.isAcceptableOrUnknown(
          data['previous_quantity']!,
          _previousQuantityMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalInventoryCount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalInventoryCount(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      shopId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      countedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}counted_at'],
      )!,
      countedQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}counted_quantity'],
      )!,
      previousCountedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}previous_counted_at'],
      ),
      previousQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}previous_quantity'],
      ),
    );
  }

  @override
  $LocalInventoryCountsTable createAlias(String alias) {
    return $LocalInventoryCountsTable(attachedDatabase, alias);
  }
}

class LocalInventoryCount extends DataClass
    implements Insertable<LocalInventoryCount> {
  final String id;
  final String shopId;
  final String productId;
  final DateTime countedAt;
  final int countedQuantity;
  final DateTime? previousCountedAt;
  final int? previousQuantity;
  const LocalInventoryCount({
    required this.id,
    required this.shopId,
    required this.productId,
    required this.countedAt,
    required this.countedQuantity,
    this.previousCountedAt,
    this.previousQuantity,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['shop_id'] = Variable<String>(shopId);
    map['product_id'] = Variable<String>(productId);
    map['counted_at'] = Variable<DateTime>(countedAt);
    map['counted_quantity'] = Variable<int>(countedQuantity);
    if (!nullToAbsent || previousCountedAt != null) {
      map['previous_counted_at'] = Variable<DateTime>(previousCountedAt);
    }
    if (!nullToAbsent || previousQuantity != null) {
      map['previous_quantity'] = Variable<int>(previousQuantity);
    }
    return map;
  }

  LocalInventoryCountsCompanion toCompanion(bool nullToAbsent) {
    return LocalInventoryCountsCompanion(
      id: Value(id),
      shopId: Value(shopId),
      productId: Value(productId),
      countedAt: Value(countedAt),
      countedQuantity: Value(countedQuantity),
      previousCountedAt: previousCountedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(previousCountedAt),
      previousQuantity: previousQuantity == null && nullToAbsent
          ? const Value.absent()
          : Value(previousQuantity),
    );
  }

  factory LocalInventoryCount.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalInventoryCount(
      id: serializer.fromJson<String>(json['id']),
      shopId: serializer.fromJson<String>(json['shopId']),
      productId: serializer.fromJson<String>(json['productId']),
      countedAt: serializer.fromJson<DateTime>(json['countedAt']),
      countedQuantity: serializer.fromJson<int>(json['countedQuantity']),
      previousCountedAt: serializer.fromJson<DateTime?>(
        json['previousCountedAt'],
      ),
      previousQuantity: serializer.fromJson<int?>(json['previousQuantity']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'shopId': serializer.toJson<String>(shopId),
      'productId': serializer.toJson<String>(productId),
      'countedAt': serializer.toJson<DateTime>(countedAt),
      'countedQuantity': serializer.toJson<int>(countedQuantity),
      'previousCountedAt': serializer.toJson<DateTime?>(previousCountedAt),
      'previousQuantity': serializer.toJson<int?>(previousQuantity),
    };
  }

  LocalInventoryCount copyWith({
    String? id,
    String? shopId,
    String? productId,
    DateTime? countedAt,
    int? countedQuantity,
    Value<DateTime?> previousCountedAt = const Value.absent(),
    Value<int?> previousQuantity = const Value.absent(),
  }) => LocalInventoryCount(
    id: id ?? this.id,
    shopId: shopId ?? this.shopId,
    productId: productId ?? this.productId,
    countedAt: countedAt ?? this.countedAt,
    countedQuantity: countedQuantity ?? this.countedQuantity,
    previousCountedAt: previousCountedAt.present
        ? previousCountedAt.value
        : this.previousCountedAt,
    previousQuantity: previousQuantity.present
        ? previousQuantity.value
        : this.previousQuantity,
  );
  LocalInventoryCount copyWithCompanion(LocalInventoryCountsCompanion data) {
    return LocalInventoryCount(
      id: data.id.present ? data.id.value : this.id,
      shopId: data.shopId.present ? data.shopId.value : this.shopId,
      productId: data.productId.present ? data.productId.value : this.productId,
      countedAt: data.countedAt.present ? data.countedAt.value : this.countedAt,
      countedQuantity: data.countedQuantity.present
          ? data.countedQuantity.value
          : this.countedQuantity,
      previousCountedAt: data.previousCountedAt.present
          ? data.previousCountedAt.value
          : this.previousCountedAt,
      previousQuantity: data.previousQuantity.present
          ? data.previousQuantity.value
          : this.previousQuantity,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalInventoryCount(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('productId: $productId, ')
          ..write('countedAt: $countedAt, ')
          ..write('countedQuantity: $countedQuantity, ')
          ..write('previousCountedAt: $previousCountedAt, ')
          ..write('previousQuantity: $previousQuantity')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    shopId,
    productId,
    countedAt,
    countedQuantity,
    previousCountedAt,
    previousQuantity,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalInventoryCount &&
          other.id == this.id &&
          other.shopId == this.shopId &&
          other.productId == this.productId &&
          other.countedAt == this.countedAt &&
          other.countedQuantity == this.countedQuantity &&
          other.previousCountedAt == this.previousCountedAt &&
          other.previousQuantity == this.previousQuantity);
}

class LocalInventoryCountsCompanion
    extends UpdateCompanion<LocalInventoryCount> {
  final Value<String> id;
  final Value<String> shopId;
  final Value<String> productId;
  final Value<DateTime> countedAt;
  final Value<int> countedQuantity;
  final Value<DateTime?> previousCountedAt;
  final Value<int?> previousQuantity;
  final Value<int> rowid;
  const LocalInventoryCountsCompanion({
    this.id = const Value.absent(),
    this.shopId = const Value.absent(),
    this.productId = const Value.absent(),
    this.countedAt = const Value.absent(),
    this.countedQuantity = const Value.absent(),
    this.previousCountedAt = const Value.absent(),
    this.previousQuantity = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalInventoryCountsCompanion.insert({
    required String id,
    required String shopId,
    required String productId,
    required DateTime countedAt,
    required int countedQuantity,
    this.previousCountedAt = const Value.absent(),
    this.previousQuantity = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       shopId = Value(shopId),
       productId = Value(productId),
       countedAt = Value(countedAt),
       countedQuantity = Value(countedQuantity);
  static Insertable<LocalInventoryCount> custom({
    Expression<String>? id,
    Expression<String>? shopId,
    Expression<String>? productId,
    Expression<DateTime>? countedAt,
    Expression<int>? countedQuantity,
    Expression<DateTime>? previousCountedAt,
    Expression<int>? previousQuantity,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shopId != null) 'shop_id': shopId,
      if (productId != null) 'product_id': productId,
      if (countedAt != null) 'counted_at': countedAt,
      if (countedQuantity != null) 'counted_quantity': countedQuantity,
      if (previousCountedAt != null) 'previous_counted_at': previousCountedAt,
      if (previousQuantity != null) 'previous_quantity': previousQuantity,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalInventoryCountsCompanion copyWith({
    Value<String>? id,
    Value<String>? shopId,
    Value<String>? productId,
    Value<DateTime>? countedAt,
    Value<int>? countedQuantity,
    Value<DateTime?>? previousCountedAt,
    Value<int?>? previousQuantity,
    Value<int>? rowid,
  }) {
    return LocalInventoryCountsCompanion(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      productId: productId ?? this.productId,
      countedAt: countedAt ?? this.countedAt,
      countedQuantity: countedQuantity ?? this.countedQuantity,
      previousCountedAt: previousCountedAt ?? this.previousCountedAt,
      previousQuantity: previousQuantity ?? this.previousQuantity,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (shopId.present) {
      map['shop_id'] = Variable<String>(shopId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (countedAt.present) {
      map['counted_at'] = Variable<DateTime>(countedAt.value);
    }
    if (countedQuantity.present) {
      map['counted_quantity'] = Variable<int>(countedQuantity.value);
    }
    if (previousCountedAt.present) {
      map['previous_counted_at'] = Variable<DateTime>(previousCountedAt.value);
    }
    if (previousQuantity.present) {
      map['previous_quantity'] = Variable<int>(previousQuantity.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalInventoryCountsCompanion(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('productId: $productId, ')
          ..write('countedAt: $countedAt, ')
          ..write('countedQuantity: $countedQuantity, ')
          ..write('previousCountedAt: $previousCountedAt, ')
          ..write('previousQuantity: $previousQuantity, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalInventoryLossesTable extends LocalInventoryLosses
    with TableInfo<$LocalInventoryLossesTable, LocalInventoryLoss> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalInventoryLossesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shopIdMeta = const VerificationMeta('shopId');
  @override
  late final GeneratedColumn<String> shopId = GeneratedColumn<String>(
    'shop_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    shopId,
    productId,
    quantity,
    reason,
    note,
    occurredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_inventory_losses';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalInventoryLoss> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('shop_id')) {
      context.handle(
        _shopIdMeta,
        shopId.isAcceptableOrUnknown(data['shop_id']!, _shopIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shopIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalInventoryLoss map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalInventoryLoss(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      shopId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
    );
  }

  @override
  $LocalInventoryLossesTable createAlias(String alias) {
    return $LocalInventoryLossesTable(attachedDatabase, alias);
  }
}

class LocalInventoryLoss extends DataClass
    implements Insertable<LocalInventoryLoss> {
  final String id;
  final String shopId;
  final String productId;
  final int quantity;

  /// casse · peremption · invendu · vol · autre — mêmes valeurs que la
  /// contrainte SQL de `inventory_losses`, sinon le push est rejeté.
  final String reason;
  final String? note;
  final DateTime occurredAt;
  const LocalInventoryLoss({
    required this.id,
    required this.shopId,
    required this.productId,
    required this.quantity,
    required this.reason,
    this.note,
    required this.occurredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['shop_id'] = Variable<String>(shopId);
    map['product_id'] = Variable<String>(productId);
    map['quantity'] = Variable<int>(quantity);
    map['reason'] = Variable<String>(reason);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    return map;
  }

  LocalInventoryLossesCompanion toCompanion(bool nullToAbsent) {
    return LocalInventoryLossesCompanion(
      id: Value(id),
      shopId: Value(shopId),
      productId: Value(productId),
      quantity: Value(quantity),
      reason: Value(reason),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      occurredAt: Value(occurredAt),
    );
  }

  factory LocalInventoryLoss.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalInventoryLoss(
      id: serializer.fromJson<String>(json['id']),
      shopId: serializer.fromJson<String>(json['shopId']),
      productId: serializer.fromJson<String>(json['productId']),
      quantity: serializer.fromJson<int>(json['quantity']),
      reason: serializer.fromJson<String>(json['reason']),
      note: serializer.fromJson<String?>(json['note']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'shopId': serializer.toJson<String>(shopId),
      'productId': serializer.toJson<String>(productId),
      'quantity': serializer.toJson<int>(quantity),
      'reason': serializer.toJson<String>(reason),
      'note': serializer.toJson<String?>(note),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
    };
  }

  LocalInventoryLoss copyWith({
    String? id,
    String? shopId,
    String? productId,
    int? quantity,
    String? reason,
    Value<String?> note = const Value.absent(),
    DateTime? occurredAt,
  }) => LocalInventoryLoss(
    id: id ?? this.id,
    shopId: shopId ?? this.shopId,
    productId: productId ?? this.productId,
    quantity: quantity ?? this.quantity,
    reason: reason ?? this.reason,
    note: note.present ? note.value : this.note,
    occurredAt: occurredAt ?? this.occurredAt,
  );
  LocalInventoryLoss copyWithCompanion(LocalInventoryLossesCompanion data) {
    return LocalInventoryLoss(
      id: data.id.present ? data.id.value : this.id,
      shopId: data.shopId.present ? data.shopId.value : this.shopId,
      productId: data.productId.present ? data.productId.value : this.productId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      reason: data.reason.present ? data.reason.value : this.reason,
      note: data.note.present ? data.note.value : this.note,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalInventoryLoss(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('productId: $productId, ')
          ..write('quantity: $quantity, ')
          ..write('reason: $reason, ')
          ..write('note: $note, ')
          ..write('occurredAt: $occurredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, shopId, productId, quantity, reason, note, occurredAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalInventoryLoss &&
          other.id == this.id &&
          other.shopId == this.shopId &&
          other.productId == this.productId &&
          other.quantity == this.quantity &&
          other.reason == this.reason &&
          other.note == this.note &&
          other.occurredAt == this.occurredAt);
}

class LocalInventoryLossesCompanion
    extends UpdateCompanion<LocalInventoryLoss> {
  final Value<String> id;
  final Value<String> shopId;
  final Value<String> productId;
  final Value<int> quantity;
  final Value<String> reason;
  final Value<String?> note;
  final Value<DateTime> occurredAt;
  final Value<int> rowid;
  const LocalInventoryLossesCompanion({
    this.id = const Value.absent(),
    this.shopId = const Value.absent(),
    this.productId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.reason = const Value.absent(),
    this.note = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalInventoryLossesCompanion.insert({
    required String id,
    required String shopId,
    required String productId,
    required int quantity,
    required String reason,
    this.note = const Value.absent(),
    required DateTime occurredAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       shopId = Value(shopId),
       productId = Value(productId),
       quantity = Value(quantity),
       reason = Value(reason),
       occurredAt = Value(occurredAt);
  static Insertable<LocalInventoryLoss> custom({
    Expression<String>? id,
    Expression<String>? shopId,
    Expression<String>? productId,
    Expression<int>? quantity,
    Expression<String>? reason,
    Expression<String>? note,
    Expression<DateTime>? occurredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shopId != null) 'shop_id': shopId,
      if (productId != null) 'product_id': productId,
      if (quantity != null) 'quantity': quantity,
      if (reason != null) 'reason': reason,
      if (note != null) 'note': note,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalInventoryLossesCompanion copyWith({
    Value<String>? id,
    Value<String>? shopId,
    Value<String>? productId,
    Value<int>? quantity,
    Value<String>? reason,
    Value<String?>? note,
    Value<DateTime>? occurredAt,
    Value<int>? rowid,
  }) {
    return LocalInventoryLossesCompanion(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      reason: reason ?? this.reason,
      note: note ?? this.note,
      occurredAt: occurredAt ?? this.occurredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (shopId.present) {
      map['shop_id'] = Variable<String>(shopId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalInventoryLossesCompanion(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('productId: $productId, ')
          ..write('quantity: $quantity, ')
          ..write('reason: $reason, ')
          ..write('note: $note, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalStockPurchasesTable extends LocalStockPurchases
    with TableInfo<$LocalStockPurchasesTable, LocalStockPurchase> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalStockPurchasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shopIdMeta = const VerificationMeta('shopId');
  @override
  late final GeneratedColumn<String> shopId = GeneratedColumn<String>(
    'shop_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitCostMeta = const VerificationMeta(
    'unitCost',
  );
  @override
  late final GeneratedColumn<double> unitCost = GeneratedColumn<double>(
    'unit_cost',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _purchasedAtMeta = const VerificationMeta(
    'purchasedAt',
  );
  @override
  late final GeneratedColumn<DateTime> purchasedAt = GeneratedColumn<DateTime>(
    'purchased_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    shopId,
    productId,
    quantity,
    unitCost,
    purchasedAt,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_stock_purchases';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalStockPurchase> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('shop_id')) {
      context.handle(
        _shopIdMeta,
        shopId.isAcceptableOrUnknown(data['shop_id']!, _shopIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shopIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit_cost')) {
      context.handle(
        _unitCostMeta,
        unitCost.isAcceptableOrUnknown(data['unit_cost']!, _unitCostMeta),
      );
    } else if (isInserting) {
      context.missing(_unitCostMeta);
    }
    if (data.containsKey('purchased_at')) {
      context.handle(
        _purchasedAtMeta,
        purchasedAt.isAcceptableOrUnknown(
          data['purchased_at']!,
          _purchasedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_purchasedAtMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalStockPurchase map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalStockPurchase(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      shopId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      unitCost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_cost'],
      )!,
      purchasedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}purchased_at'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $LocalStockPurchasesTable createAlias(String alias) {
    return $LocalStockPurchasesTable(attachedDatabase, alias);
  }
}

class LocalStockPurchase extends DataClass
    implements Insertable<LocalStockPurchase> {
  final String id;
  final String shopId;
  final String productId;
  final int quantity;
  final double unitCost;
  final DateTime purchasedAt;
  final String? note;
  const LocalStockPurchase({
    required this.id,
    required this.shopId,
    required this.productId,
    required this.quantity,
    required this.unitCost,
    required this.purchasedAt,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['shop_id'] = Variable<String>(shopId);
    map['product_id'] = Variable<String>(productId);
    map['quantity'] = Variable<int>(quantity);
    map['unit_cost'] = Variable<double>(unitCost);
    map['purchased_at'] = Variable<DateTime>(purchasedAt);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  LocalStockPurchasesCompanion toCompanion(bool nullToAbsent) {
    return LocalStockPurchasesCompanion(
      id: Value(id),
      shopId: Value(shopId),
      productId: Value(productId),
      quantity: Value(quantity),
      unitCost: Value(unitCost),
      purchasedAt: Value(purchasedAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory LocalStockPurchase.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalStockPurchase(
      id: serializer.fromJson<String>(json['id']),
      shopId: serializer.fromJson<String>(json['shopId']),
      productId: serializer.fromJson<String>(json['productId']),
      quantity: serializer.fromJson<int>(json['quantity']),
      unitCost: serializer.fromJson<double>(json['unitCost']),
      purchasedAt: serializer.fromJson<DateTime>(json['purchasedAt']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'shopId': serializer.toJson<String>(shopId),
      'productId': serializer.toJson<String>(productId),
      'quantity': serializer.toJson<int>(quantity),
      'unitCost': serializer.toJson<double>(unitCost),
      'purchasedAt': serializer.toJson<DateTime>(purchasedAt),
      'note': serializer.toJson<String?>(note),
    };
  }

  LocalStockPurchase copyWith({
    String? id,
    String? shopId,
    String? productId,
    int? quantity,
    double? unitCost,
    DateTime? purchasedAt,
    Value<String?> note = const Value.absent(),
  }) => LocalStockPurchase(
    id: id ?? this.id,
    shopId: shopId ?? this.shopId,
    productId: productId ?? this.productId,
    quantity: quantity ?? this.quantity,
    unitCost: unitCost ?? this.unitCost,
    purchasedAt: purchasedAt ?? this.purchasedAt,
    note: note.present ? note.value : this.note,
  );
  LocalStockPurchase copyWithCompanion(LocalStockPurchasesCompanion data) {
    return LocalStockPurchase(
      id: data.id.present ? data.id.value : this.id,
      shopId: data.shopId.present ? data.shopId.value : this.shopId,
      productId: data.productId.present ? data.productId.value : this.productId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitCost: data.unitCost.present ? data.unitCost.value : this.unitCost,
      purchasedAt: data.purchasedAt.present
          ? data.purchasedAt.value
          : this.purchasedAt,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalStockPurchase(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('productId: $productId, ')
          ..write('quantity: $quantity, ')
          ..write('unitCost: $unitCost, ')
          ..write('purchasedAt: $purchasedAt, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, shopId, productId, quantity, unitCost, purchasedAt, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalStockPurchase &&
          other.id == this.id &&
          other.shopId == this.shopId &&
          other.productId == this.productId &&
          other.quantity == this.quantity &&
          other.unitCost == this.unitCost &&
          other.purchasedAt == this.purchasedAt &&
          other.note == this.note);
}

class LocalStockPurchasesCompanion extends UpdateCompanion<LocalStockPurchase> {
  final Value<String> id;
  final Value<String> shopId;
  final Value<String> productId;
  final Value<int> quantity;
  final Value<double> unitCost;
  final Value<DateTime> purchasedAt;
  final Value<String?> note;
  final Value<int> rowid;
  const LocalStockPurchasesCompanion({
    this.id = const Value.absent(),
    this.shopId = const Value.absent(),
    this.productId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitCost = const Value.absent(),
    this.purchasedAt = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalStockPurchasesCompanion.insert({
    required String id,
    required String shopId,
    required String productId,
    required int quantity,
    required double unitCost,
    required DateTime purchasedAt,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       shopId = Value(shopId),
       productId = Value(productId),
       quantity = Value(quantity),
       unitCost = Value(unitCost),
       purchasedAt = Value(purchasedAt);
  static Insertable<LocalStockPurchase> custom({
    Expression<String>? id,
    Expression<String>? shopId,
    Expression<String>? productId,
    Expression<int>? quantity,
    Expression<double>? unitCost,
    Expression<DateTime>? purchasedAt,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shopId != null) 'shop_id': shopId,
      if (productId != null) 'product_id': productId,
      if (quantity != null) 'quantity': quantity,
      if (unitCost != null) 'unit_cost': unitCost,
      if (purchasedAt != null) 'purchased_at': purchasedAt,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalStockPurchasesCompanion copyWith({
    Value<String>? id,
    Value<String>? shopId,
    Value<String>? productId,
    Value<int>? quantity,
    Value<double>? unitCost,
    Value<DateTime>? purchasedAt,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return LocalStockPurchasesCompanion(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (shopId.present) {
      map['shop_id'] = Variable<String>(shopId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (unitCost.present) {
      map['unit_cost'] = Variable<double>(unitCost.value);
    }
    if (purchasedAt.present) {
      map['purchased_at'] = Variable<DateTime>(purchasedAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalStockPurchasesCompanion(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('productId: $productId, ')
          ..write('quantity: $quantity, ')
          ..write('unitCost: $unitCost, ')
          ..write('purchasedAt: $purchasedAt, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalProductPricesTable extends LocalProductPrices
    with TableInfo<$LocalProductPricesTable, LocalProductPrice> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalProductPricesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shopIdMeta = const VerificationMeta('shopId');
  @override
  late final GeneratedColumn<String> shopId = GeneratedColumn<String>(
    'shop_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _buyPriceMeta = const VerificationMeta(
    'buyPrice',
  );
  @override
  late final GeneratedColumn<double> buyPrice = GeneratedColumn<double>(
    'buy_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sellPriceMeta = const VerificationMeta(
    'sellPrice',
  );
  @override
  late final GeneratedColumn<double> sellPrice = GeneratedColumn<double>(
    'sell_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _effectiveAtMeta = const VerificationMeta(
    'effectiveAt',
  );
  @override
  late final GeneratedColumn<DateTime> effectiveAt = GeneratedColumn<DateTime>(
    'effective_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    shopId,
    productId,
    buyPrice,
    sellPrice,
    effectiveAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_product_prices';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalProductPrice> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('shop_id')) {
      context.handle(
        _shopIdMeta,
        shopId.isAcceptableOrUnknown(data['shop_id']!, _shopIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shopIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('buy_price')) {
      context.handle(
        _buyPriceMeta,
        buyPrice.isAcceptableOrUnknown(data['buy_price']!, _buyPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_buyPriceMeta);
    }
    if (data.containsKey('sell_price')) {
      context.handle(
        _sellPriceMeta,
        sellPrice.isAcceptableOrUnknown(data['sell_price']!, _sellPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_sellPriceMeta);
    }
    if (data.containsKey('effective_at')) {
      context.handle(
        _effectiveAtMeta,
        effectiveAt.isAcceptableOrUnknown(
          data['effective_at']!,
          _effectiveAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_effectiveAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalProductPrice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalProductPrice(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      shopId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      buyPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}buy_price'],
      )!,
      sellPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sell_price'],
      )!,
      effectiveAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}effective_at'],
      )!,
    );
  }

  @override
  $LocalProductPricesTable createAlias(String alias) {
    return $LocalProductPricesTable(attachedDatabase, alias);
  }
}

class LocalProductPrice extends DataClass
    implements Insertable<LocalProductPrice> {
  final String id;
  final String shopId;
  final String productId;
  final double buyPrice;
  final double sellPrice;
  final DateTime effectiveAt;
  const LocalProductPrice({
    required this.id,
    required this.shopId,
    required this.productId,
    required this.buyPrice,
    required this.sellPrice,
    required this.effectiveAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['shop_id'] = Variable<String>(shopId);
    map['product_id'] = Variable<String>(productId);
    map['buy_price'] = Variable<double>(buyPrice);
    map['sell_price'] = Variable<double>(sellPrice);
    map['effective_at'] = Variable<DateTime>(effectiveAt);
    return map;
  }

  LocalProductPricesCompanion toCompanion(bool nullToAbsent) {
    return LocalProductPricesCompanion(
      id: Value(id),
      shopId: Value(shopId),
      productId: Value(productId),
      buyPrice: Value(buyPrice),
      sellPrice: Value(sellPrice),
      effectiveAt: Value(effectiveAt),
    );
  }

  factory LocalProductPrice.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalProductPrice(
      id: serializer.fromJson<String>(json['id']),
      shopId: serializer.fromJson<String>(json['shopId']),
      productId: serializer.fromJson<String>(json['productId']),
      buyPrice: serializer.fromJson<double>(json['buyPrice']),
      sellPrice: serializer.fromJson<double>(json['sellPrice']),
      effectiveAt: serializer.fromJson<DateTime>(json['effectiveAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'shopId': serializer.toJson<String>(shopId),
      'productId': serializer.toJson<String>(productId),
      'buyPrice': serializer.toJson<double>(buyPrice),
      'sellPrice': serializer.toJson<double>(sellPrice),
      'effectiveAt': serializer.toJson<DateTime>(effectiveAt),
    };
  }

  LocalProductPrice copyWith({
    String? id,
    String? shopId,
    String? productId,
    double? buyPrice,
    double? sellPrice,
    DateTime? effectiveAt,
  }) => LocalProductPrice(
    id: id ?? this.id,
    shopId: shopId ?? this.shopId,
    productId: productId ?? this.productId,
    buyPrice: buyPrice ?? this.buyPrice,
    sellPrice: sellPrice ?? this.sellPrice,
    effectiveAt: effectiveAt ?? this.effectiveAt,
  );
  LocalProductPrice copyWithCompanion(LocalProductPricesCompanion data) {
    return LocalProductPrice(
      id: data.id.present ? data.id.value : this.id,
      shopId: data.shopId.present ? data.shopId.value : this.shopId,
      productId: data.productId.present ? data.productId.value : this.productId,
      buyPrice: data.buyPrice.present ? data.buyPrice.value : this.buyPrice,
      sellPrice: data.sellPrice.present ? data.sellPrice.value : this.sellPrice,
      effectiveAt: data.effectiveAt.present
          ? data.effectiveAt.value
          : this.effectiveAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalProductPrice(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('productId: $productId, ')
          ..write('buyPrice: $buyPrice, ')
          ..write('sellPrice: $sellPrice, ')
          ..write('effectiveAt: $effectiveAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, shopId, productId, buyPrice, sellPrice, effectiveAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalProductPrice &&
          other.id == this.id &&
          other.shopId == this.shopId &&
          other.productId == this.productId &&
          other.buyPrice == this.buyPrice &&
          other.sellPrice == this.sellPrice &&
          other.effectiveAt == this.effectiveAt);
}

class LocalProductPricesCompanion extends UpdateCompanion<LocalProductPrice> {
  final Value<String> id;
  final Value<String> shopId;
  final Value<String> productId;
  final Value<double> buyPrice;
  final Value<double> sellPrice;
  final Value<DateTime> effectiveAt;
  final Value<int> rowid;
  const LocalProductPricesCompanion({
    this.id = const Value.absent(),
    this.shopId = const Value.absent(),
    this.productId = const Value.absent(),
    this.buyPrice = const Value.absent(),
    this.sellPrice = const Value.absent(),
    this.effectiveAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalProductPricesCompanion.insert({
    required String id,
    required String shopId,
    required String productId,
    required double buyPrice,
    required double sellPrice,
    required DateTime effectiveAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       shopId = Value(shopId),
       productId = Value(productId),
       buyPrice = Value(buyPrice),
       sellPrice = Value(sellPrice),
       effectiveAt = Value(effectiveAt);
  static Insertable<LocalProductPrice> custom({
    Expression<String>? id,
    Expression<String>? shopId,
    Expression<String>? productId,
    Expression<double>? buyPrice,
    Expression<double>? sellPrice,
    Expression<DateTime>? effectiveAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shopId != null) 'shop_id': shopId,
      if (productId != null) 'product_id': productId,
      if (buyPrice != null) 'buy_price': buyPrice,
      if (sellPrice != null) 'sell_price': sellPrice,
      if (effectiveAt != null) 'effective_at': effectiveAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalProductPricesCompanion copyWith({
    Value<String>? id,
    Value<String>? shopId,
    Value<String>? productId,
    Value<double>? buyPrice,
    Value<double>? sellPrice,
    Value<DateTime>? effectiveAt,
    Value<int>? rowid,
  }) {
    return LocalProductPricesCompanion(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      productId: productId ?? this.productId,
      buyPrice: buyPrice ?? this.buyPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      effectiveAt: effectiveAt ?? this.effectiveAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (shopId.present) {
      map['shop_id'] = Variable<String>(shopId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (buyPrice.present) {
      map['buy_price'] = Variable<double>(buyPrice.value);
    }
    if (sellPrice.present) {
      map['sell_price'] = Variable<double>(sellPrice.value);
    }
    if (effectiveAt.present) {
      map['effective_at'] = Variable<DateTime>(effectiveAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalProductPricesCompanion(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('productId: $productId, ')
          ..write('buyPrice: $buyPrice, ')
          ..write('sellPrice: $sellPrice, ')
          ..write('effectiveAt: $effectiveAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalStockTransfersTable extends LocalStockTransfers
    with TableInfo<$LocalStockTransfersTable, LocalStockTransfer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalStockTransfersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromShopIdMeta = const VerificationMeta(
    'fromShopId',
  );
  @override
  late final GeneratedColumn<String> fromShopId = GeneratedColumn<String>(
    'from_shop_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toShopIdMeta = const VerificationMeta(
    'toShopId',
  );
  @override
  late final GeneratedColumn<String> toShopId = GeneratedColumn<String>(
    'to_shop_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivedQuantityMeta = const VerificationMeta(
    'receivedQuantity',
  );
  @override
  late final GeneratedColumn<int> receivedQuantity = GeneratedColumn<int>(
    'received_quantity',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receivedAtMeta = const VerificationMeta(
    'receivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
    'received_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transferredAtMeta = const VerificationMeta(
    'transferredAt',
  );
  @override
  late final GeneratedColumn<DateTime> transferredAt =
      GeneratedColumn<DateTime>(
        'transferred_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fromShopId,
    toShopId,
    productId,
    quantity,
    receivedQuantity,
    receivedAt,
    transferredAt,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_stock_transfers';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalStockTransfer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('from_shop_id')) {
      context.handle(
        _fromShopIdMeta,
        fromShopId.isAcceptableOrUnknown(
          data['from_shop_id']!,
          _fromShopIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromShopIdMeta);
    }
    if (data.containsKey('to_shop_id')) {
      context.handle(
        _toShopIdMeta,
        toShopId.isAcceptableOrUnknown(data['to_shop_id']!, _toShopIdMeta),
      );
    } else if (isInserting) {
      context.missing(_toShopIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('received_quantity')) {
      context.handle(
        _receivedQuantityMeta,
        receivedQuantity.isAcceptableOrUnknown(
          data['received_quantity']!,
          _receivedQuantityMeta,
        ),
      );
    }
    if (data.containsKey('received_at')) {
      context.handle(
        _receivedAtMeta,
        receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta),
      );
    }
    if (data.containsKey('transferred_at')) {
      context.handle(
        _transferredAtMeta,
        transferredAt.isAcceptableOrUnknown(
          data['transferred_at']!,
          _transferredAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transferredAtMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalStockTransfer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalStockTransfer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      fromShopId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_shop_id'],
      )!,
      toShopId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_shop_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      receivedQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}received_quantity'],
      ),
      receivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}received_at'],
      ),
      transferredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}transferred_at'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $LocalStockTransfersTable createAlias(String alias) {
    return $LocalStockTransfersTable(attachedDatabase, alias);
  }
}

class LocalStockTransfer extends DataClass
    implements Insertable<LocalStockTransfer> {
  final String id;
  final String fromShopId;
  final String toShopId;
  final String productId;
  final int quantity;
  final int? receivedQuantity;
  final DateTime? receivedAt;
  final DateTime transferredAt;
  final String? note;
  const LocalStockTransfer({
    required this.id,
    required this.fromShopId,
    required this.toShopId,
    required this.productId,
    required this.quantity,
    this.receivedQuantity,
    this.receivedAt,
    required this.transferredAt,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['from_shop_id'] = Variable<String>(fromShopId);
    map['to_shop_id'] = Variable<String>(toShopId);
    map['product_id'] = Variable<String>(productId);
    map['quantity'] = Variable<int>(quantity);
    if (!nullToAbsent || receivedQuantity != null) {
      map['received_quantity'] = Variable<int>(receivedQuantity);
    }
    if (!nullToAbsent || receivedAt != null) {
      map['received_at'] = Variable<DateTime>(receivedAt);
    }
    map['transferred_at'] = Variable<DateTime>(transferredAt);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  LocalStockTransfersCompanion toCompanion(bool nullToAbsent) {
    return LocalStockTransfersCompanion(
      id: Value(id),
      fromShopId: Value(fromShopId),
      toShopId: Value(toShopId),
      productId: Value(productId),
      quantity: Value(quantity),
      receivedQuantity: receivedQuantity == null && nullToAbsent
          ? const Value.absent()
          : Value(receivedQuantity),
      receivedAt: receivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(receivedAt),
      transferredAt: Value(transferredAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory LocalStockTransfer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalStockTransfer(
      id: serializer.fromJson<String>(json['id']),
      fromShopId: serializer.fromJson<String>(json['fromShopId']),
      toShopId: serializer.fromJson<String>(json['toShopId']),
      productId: serializer.fromJson<String>(json['productId']),
      quantity: serializer.fromJson<int>(json['quantity']),
      receivedQuantity: serializer.fromJson<int?>(json['receivedQuantity']),
      receivedAt: serializer.fromJson<DateTime?>(json['receivedAt']),
      transferredAt: serializer.fromJson<DateTime>(json['transferredAt']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fromShopId': serializer.toJson<String>(fromShopId),
      'toShopId': serializer.toJson<String>(toShopId),
      'productId': serializer.toJson<String>(productId),
      'quantity': serializer.toJson<int>(quantity),
      'receivedQuantity': serializer.toJson<int?>(receivedQuantity),
      'receivedAt': serializer.toJson<DateTime?>(receivedAt),
      'transferredAt': serializer.toJson<DateTime>(transferredAt),
      'note': serializer.toJson<String?>(note),
    };
  }

  LocalStockTransfer copyWith({
    String? id,
    String? fromShopId,
    String? toShopId,
    String? productId,
    int? quantity,
    Value<int?> receivedQuantity = const Value.absent(),
    Value<DateTime?> receivedAt = const Value.absent(),
    DateTime? transferredAt,
    Value<String?> note = const Value.absent(),
  }) => LocalStockTransfer(
    id: id ?? this.id,
    fromShopId: fromShopId ?? this.fromShopId,
    toShopId: toShopId ?? this.toShopId,
    productId: productId ?? this.productId,
    quantity: quantity ?? this.quantity,
    receivedQuantity: receivedQuantity.present
        ? receivedQuantity.value
        : this.receivedQuantity,
    receivedAt: receivedAt.present ? receivedAt.value : this.receivedAt,
    transferredAt: transferredAt ?? this.transferredAt,
    note: note.present ? note.value : this.note,
  );
  LocalStockTransfer copyWithCompanion(LocalStockTransfersCompanion data) {
    return LocalStockTransfer(
      id: data.id.present ? data.id.value : this.id,
      fromShopId: data.fromShopId.present
          ? data.fromShopId.value
          : this.fromShopId,
      toShopId: data.toShopId.present ? data.toShopId.value : this.toShopId,
      productId: data.productId.present ? data.productId.value : this.productId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      receivedQuantity: data.receivedQuantity.present
          ? data.receivedQuantity.value
          : this.receivedQuantity,
      receivedAt: data.receivedAt.present
          ? data.receivedAt.value
          : this.receivedAt,
      transferredAt: data.transferredAt.present
          ? data.transferredAt.value
          : this.transferredAt,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalStockTransfer(')
          ..write('id: $id, ')
          ..write('fromShopId: $fromShopId, ')
          ..write('toShopId: $toShopId, ')
          ..write('productId: $productId, ')
          ..write('quantity: $quantity, ')
          ..write('receivedQuantity: $receivedQuantity, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('transferredAt: $transferredAt, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    fromShopId,
    toShopId,
    productId,
    quantity,
    receivedQuantity,
    receivedAt,
    transferredAt,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalStockTransfer &&
          other.id == this.id &&
          other.fromShopId == this.fromShopId &&
          other.toShopId == this.toShopId &&
          other.productId == this.productId &&
          other.quantity == this.quantity &&
          other.receivedQuantity == this.receivedQuantity &&
          other.receivedAt == this.receivedAt &&
          other.transferredAt == this.transferredAt &&
          other.note == this.note);
}

class LocalStockTransfersCompanion extends UpdateCompanion<LocalStockTransfer> {
  final Value<String> id;
  final Value<String> fromShopId;
  final Value<String> toShopId;
  final Value<String> productId;
  final Value<int> quantity;
  final Value<int?> receivedQuantity;
  final Value<DateTime?> receivedAt;
  final Value<DateTime> transferredAt;
  final Value<String?> note;
  final Value<int> rowid;
  const LocalStockTransfersCompanion({
    this.id = const Value.absent(),
    this.fromShopId = const Value.absent(),
    this.toShopId = const Value.absent(),
    this.productId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.receivedQuantity = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.transferredAt = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalStockTransfersCompanion.insert({
    required String id,
    required String fromShopId,
    required String toShopId,
    required String productId,
    required int quantity,
    this.receivedQuantity = const Value.absent(),
    this.receivedAt = const Value.absent(),
    required DateTime transferredAt,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       fromShopId = Value(fromShopId),
       toShopId = Value(toShopId),
       productId = Value(productId),
       quantity = Value(quantity),
       transferredAt = Value(transferredAt);
  static Insertable<LocalStockTransfer> custom({
    Expression<String>? id,
    Expression<String>? fromShopId,
    Expression<String>? toShopId,
    Expression<String>? productId,
    Expression<int>? quantity,
    Expression<int>? receivedQuantity,
    Expression<DateTime>? receivedAt,
    Expression<DateTime>? transferredAt,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fromShopId != null) 'from_shop_id': fromShopId,
      if (toShopId != null) 'to_shop_id': toShopId,
      if (productId != null) 'product_id': productId,
      if (quantity != null) 'quantity': quantity,
      if (receivedQuantity != null) 'received_quantity': receivedQuantity,
      if (receivedAt != null) 'received_at': receivedAt,
      if (transferredAt != null) 'transferred_at': transferredAt,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalStockTransfersCompanion copyWith({
    Value<String>? id,
    Value<String>? fromShopId,
    Value<String>? toShopId,
    Value<String>? productId,
    Value<int>? quantity,
    Value<int?>? receivedQuantity,
    Value<DateTime?>? receivedAt,
    Value<DateTime>? transferredAt,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return LocalStockTransfersCompanion(
      id: id ?? this.id,
      fromShopId: fromShopId ?? this.fromShopId,
      toShopId: toShopId ?? this.toShopId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      receivedQuantity: receivedQuantity ?? this.receivedQuantity,
      receivedAt: receivedAt ?? this.receivedAt,
      transferredAt: transferredAt ?? this.transferredAt,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fromShopId.present) {
      map['from_shop_id'] = Variable<String>(fromShopId.value);
    }
    if (toShopId.present) {
      map['to_shop_id'] = Variable<String>(toShopId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (receivedQuantity.present) {
      map['received_quantity'] = Variable<int>(receivedQuantity.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    if (transferredAt.present) {
      map['transferred_at'] = Variable<DateTime>(transferredAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalStockTransfersCompanion(')
          ..write('id: $id, ')
          ..write('fromShopId: $fromShopId, ')
          ..write('toShopId: $toShopId, ')
          ..write('productId: $productId, ')
          ..write('quantity: $quantity, ')
          ..write('receivedQuantity: $receivedQuantity, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('transferredAt: $transferredAt, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueItemsTable extends SyncQueueItems
    with TableInfo<$SyncQueueItemsTable, SyncQueueItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, action, payload, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SyncQueueItemsTable createAlias(String alias) {
    return $SyncQueueItemsTable(attachedDatabase, alias);
  }
}

class SyncQueueItem extends DataClass implements Insertable<SyncQueueItem> {
  final int id;
  final String action;
  final String payload;
  final DateTime createdAt;
  const SyncQueueItem({
    required this.id,
    required this.action,
    required this.payload,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['action'] = Variable<String>(action);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SyncQueueItemsCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueItemsCompanion(
      id: Value(id),
      action: Value(action),
      payload: Value(payload),
      createdAt: Value(createdAt),
    );
  }

  factory SyncQueueItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueItem(
      id: serializer.fromJson<int>(json['id']),
      action: serializer.fromJson<String>(json['action']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'action': serializer.toJson<String>(action),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SyncQueueItem copyWith({
    int? id,
    String? action,
    String? payload,
    DateTime? createdAt,
  }) => SyncQueueItem(
    id: id ?? this.id,
    action: action ?? this.action,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
  );
  SyncQueueItem copyWithCompanion(SyncQueueItemsCompanion data) {
    return SyncQueueItem(
      id: data.id.present ? data.id.value : this.id,
      action: data.action.present ? data.action.value : this.action,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueItem(')
          ..write('id: $id, ')
          ..write('action: $action, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, action, payload, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueItem &&
          other.id == this.id &&
          other.action == this.action &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt);
}

class SyncQueueItemsCompanion extends UpdateCompanion<SyncQueueItem> {
  final Value<int> id;
  final Value<String> action;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  const SyncQueueItemsCompanion({
    this.id = const Value.absent(),
    this.action = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SyncQueueItemsCompanion.insert({
    this.id = const Value.absent(),
    required String action,
    required String payload,
    this.createdAt = const Value.absent(),
  }) : action = Value(action),
       payload = Value(payload);
  static Insertable<SyncQueueItem> custom({
    Expression<int>? id,
    Expression<String>? action,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (action != null) 'action': action,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SyncQueueItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? action,
    Value<String>? payload,
    Value<DateTime>? createdAt,
  }) {
    return SyncQueueItemsCompanion(
      id: id ?? this.id,
      action: action ?? this.action,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueItemsCompanion(')
          ..write('id: $id, ')
          ..write('action: $action, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalProductsTable localProducts = $LocalProductsTable(this);
  late final $LocalSalesTable localSales = $LocalSalesTable(this);
  late final $LocalSaleItemsTable localSaleItems = $LocalSaleItemsTable(this);
  late final $LocalCashMovementsTable localCashMovements =
      $LocalCashMovementsTable(this);
  late final $LocalStockMovementsTable localStockMovements =
      $LocalStockMovementsTable(this);
  late final $LocalDailyClosingsTable localDailyClosings =
      $LocalDailyClosingsTable(this);
  late final $LocalShopSettingsTable localShopSettings =
      $LocalShopSettingsTable(this);
  late final $LocalProductUnitsTable localProductUnits =
      $LocalProductUnitsTable(this);
  late final $LocalSupplyCyclesTable localSupplyCycles =
      $LocalSupplyCyclesTable(this);
  late final $LocalCycleLossesTable localCycleLosses = $LocalCycleLossesTable(
    this,
  );
  late final $LocalShopTakingsTable localShopTakings = $LocalShopTakingsTable(
    this,
  );
  late final $LocalInventoryCountsTable localInventoryCounts =
      $LocalInventoryCountsTable(this);
  late final $LocalInventoryLossesTable localInventoryLosses =
      $LocalInventoryLossesTable(this);
  late final $LocalStockPurchasesTable localStockPurchases =
      $LocalStockPurchasesTable(this);
  late final $LocalProductPricesTable localProductPrices =
      $LocalProductPricesTable(this);
  late final $LocalStockTransfersTable localStockTransfers =
      $LocalStockTransfersTable(this);
  late final $SyncQueueItemsTable syncQueueItems = $SyncQueueItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localProducts,
    localSales,
    localSaleItems,
    localCashMovements,
    localStockMovements,
    localDailyClosings,
    localShopSettings,
    localProductUnits,
    localSupplyCycles,
    localCycleLosses,
    localShopTakings,
    localInventoryCounts,
    localInventoryLosses,
    localStockPurchases,
    localProductPrices,
    localStockTransfers,
    syncQueueItems,
  ];
}

typedef $$LocalProductsTableCreateCompanionBuilder =
    LocalProductsCompanion Function({
      required String id,
      required String shopId,
      required String name,
      required double buyPrice,
      required double sellPrice,
      required int quantity,
      required int minQuantity,
      Value<String?> barcode,
      Value<String?> photoUrl,
      Value<String?> unit,
      Value<int> rowid,
    });
typedef $$LocalProductsTableUpdateCompanionBuilder =
    LocalProductsCompanion Function({
      Value<String> id,
      Value<String> shopId,
      Value<String> name,
      Value<double> buyPrice,
      Value<double> sellPrice,
      Value<int> quantity,
      Value<int> minQuantity,
      Value<String?> barcode,
      Value<String?> photoUrl,
      Value<String?> unit,
      Value<int> rowid,
    });

class $$LocalProductsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalProductsTable> {
  $$LocalProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get buyPrice => $composableBuilder(
    column: $table.buyPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sellPrice => $composableBuilder(
    column: $table.sellPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minQuantity => $composableBuilder(
    column: $table.minQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalProductsTable> {
  $$LocalProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get buyPrice => $composableBuilder(
    column: $table.buyPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sellPrice => $composableBuilder(
    column: $table.sellPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minQuantity => $composableBuilder(
    column: $table.minQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalProductsTable> {
  $$LocalProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get shopId =>
      $composableBuilder(column: $table.shopId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get buyPrice =>
      $composableBuilder(column: $table.buyPrice, builder: (column) => column);

  GeneratedColumn<double> get sellPrice =>
      $composableBuilder(column: $table.sellPrice, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<int> get minQuantity => $composableBuilder(
    column: $table.minQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get photoUrl =>
      $composableBuilder(column: $table.photoUrl, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);
}

class $$LocalProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalProductsTable,
          LocalProduct,
          $$LocalProductsTableFilterComposer,
          $$LocalProductsTableOrderingComposer,
          $$LocalProductsTableAnnotationComposer,
          $$LocalProductsTableCreateCompanionBuilder,
          $$LocalProductsTableUpdateCompanionBuilder,
          (
            LocalProduct,
            BaseReferences<_$AppDatabase, $LocalProductsTable, LocalProduct>,
          ),
          LocalProduct,
          PrefetchHooks Function()
        > {
  $$LocalProductsTableTableManager(_$AppDatabase db, $LocalProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> shopId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> buyPrice = const Value.absent(),
                Value<double> sellPrice = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<int> minQuantity = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String?> photoUrl = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalProductsCompanion(
                id: id,
                shopId: shopId,
                name: name,
                buyPrice: buyPrice,
                sellPrice: sellPrice,
                quantity: quantity,
                minQuantity: minQuantity,
                barcode: barcode,
                photoUrl: photoUrl,
                unit: unit,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String shopId,
                required String name,
                required double buyPrice,
                required double sellPrice,
                required int quantity,
                required int minQuantity,
                Value<String?> barcode = const Value.absent(),
                Value<String?> photoUrl = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalProductsCompanion.insert(
                id: id,
                shopId: shopId,
                name: name,
                buyPrice: buyPrice,
                sellPrice: sellPrice,
                quantity: quantity,
                minQuantity: minQuantity,
                barcode: barcode,
                photoUrl: photoUrl,
                unit: unit,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalProductsTable,
      LocalProduct,
      $$LocalProductsTableFilterComposer,
      $$LocalProductsTableOrderingComposer,
      $$LocalProductsTableAnnotationComposer,
      $$LocalProductsTableCreateCompanionBuilder,
      $$LocalProductsTableUpdateCompanionBuilder,
      (
        LocalProduct,
        BaseReferences<_$AppDatabase, $LocalProductsTable, LocalProduct>,
      ),
      LocalProduct,
      PrefetchHooks Function()
    >;
typedef $$LocalSalesTableCreateCompanionBuilder =
    LocalSalesCompanion Function({
      required String id,
      required String shopId,
      required String userId,
      required double totalAmount,
      required double totalProfit,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$LocalSalesTableUpdateCompanionBuilder =
    LocalSalesCompanion Function({
      Value<String> id,
      Value<String> shopId,
      Value<String> userId,
      Value<double> totalAmount,
      Value<double> totalProfit,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$LocalSalesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSalesTable> {
  $$LocalSalesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalProfit => $composableBuilder(
    column: $table.totalProfit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSalesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSalesTable> {
  $$LocalSalesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalProfit => $composableBuilder(
    column: $table.totalProfit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSalesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSalesTable> {
  $$LocalSalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get shopId =>
      $composableBuilder(column: $table.shopId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalProfit => $composableBuilder(
    column: $table.totalProfit,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalSalesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSalesTable,
          LocalSale,
          $$LocalSalesTableFilterComposer,
          $$LocalSalesTableOrderingComposer,
          $$LocalSalesTableAnnotationComposer,
          $$LocalSalesTableCreateCompanionBuilder,
          $$LocalSalesTableUpdateCompanionBuilder,
          (
            LocalSale,
            BaseReferences<_$AppDatabase, $LocalSalesTable, LocalSale>,
          ),
          LocalSale,
          PrefetchHooks Function()
        > {
  $$LocalSalesTableTableManager(_$AppDatabase db, $LocalSalesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> shopId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<double> totalProfit = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSalesCompanion(
                id: id,
                shopId: shopId,
                userId: userId,
                totalAmount: totalAmount,
                totalProfit: totalProfit,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String shopId,
                required String userId,
                required double totalAmount,
                required double totalProfit,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalSalesCompanion.insert(
                id: id,
                shopId: shopId,
                userId: userId,
                totalAmount: totalAmount,
                totalProfit: totalProfit,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSalesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSalesTable,
      LocalSale,
      $$LocalSalesTableFilterComposer,
      $$LocalSalesTableOrderingComposer,
      $$LocalSalesTableAnnotationComposer,
      $$LocalSalesTableCreateCompanionBuilder,
      $$LocalSalesTableUpdateCompanionBuilder,
      (LocalSale, BaseReferences<_$AppDatabase, $LocalSalesTable, LocalSale>),
      LocalSale,
      PrefetchHooks Function()
    >;
typedef $$LocalSaleItemsTableCreateCompanionBuilder =
    LocalSaleItemsCompanion Function({
      required String id,
      required String saleId,
      required String productId,
      required String productName,
      required int quantity,
      required double sellPrice,
      required double buyPrice,
      required double profit,
      Value<String?> cycleId,
      Value<String?> unitId,
      Value<int?> quantityInBase,
      Value<double?> unitSellPrice,
      Value<int> rowid,
    });
typedef $$LocalSaleItemsTableUpdateCompanionBuilder =
    LocalSaleItemsCompanion Function({
      Value<String> id,
      Value<String> saleId,
      Value<String> productId,
      Value<String> productName,
      Value<int> quantity,
      Value<double> sellPrice,
      Value<double> buyPrice,
      Value<double> profit,
      Value<String?> cycleId,
      Value<String?> unitId,
      Value<int?> quantityInBase,
      Value<double?> unitSellPrice,
      Value<int> rowid,
    });

class $$LocalSaleItemsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSaleItemsTable> {
  $$LocalSaleItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get saleId => $composableBuilder(
    column: $table.saleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sellPrice => $composableBuilder(
    column: $table.sellPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get buyPrice => $composableBuilder(
    column: $table.buyPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get profit => $composableBuilder(
    column: $table.profit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cycleId => $composableBuilder(
    column: $table.cycleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitId => $composableBuilder(
    column: $table.unitId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantityInBase => $composableBuilder(
    column: $table.quantityInBase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitSellPrice => $composableBuilder(
    column: $table.unitSellPrice,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSaleItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSaleItemsTable> {
  $$LocalSaleItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get saleId => $composableBuilder(
    column: $table.saleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sellPrice => $composableBuilder(
    column: $table.sellPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get buyPrice => $composableBuilder(
    column: $table.buyPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get profit => $composableBuilder(
    column: $table.profit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cycleId => $composableBuilder(
    column: $table.cycleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitId => $composableBuilder(
    column: $table.unitId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantityInBase => $composableBuilder(
    column: $table.quantityInBase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitSellPrice => $composableBuilder(
    column: $table.unitSellPrice,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSaleItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSaleItemsTable> {
  $$LocalSaleItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get saleId =>
      $composableBuilder(column: $table.saleId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get sellPrice =>
      $composableBuilder(column: $table.sellPrice, builder: (column) => column);

  GeneratedColumn<double> get buyPrice =>
      $composableBuilder(column: $table.buyPrice, builder: (column) => column);

  GeneratedColumn<double> get profit =>
      $composableBuilder(column: $table.profit, builder: (column) => column);

  GeneratedColumn<String> get cycleId =>
      $composableBuilder(column: $table.cycleId, builder: (column) => column);

  GeneratedColumn<String> get unitId =>
      $composableBuilder(column: $table.unitId, builder: (column) => column);

  GeneratedColumn<int> get quantityInBase => $composableBuilder(
    column: $table.quantityInBase,
    builder: (column) => column,
  );

  GeneratedColumn<double> get unitSellPrice => $composableBuilder(
    column: $table.unitSellPrice,
    builder: (column) => column,
  );
}

class $$LocalSaleItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSaleItemsTable,
          LocalSaleItem,
          $$LocalSaleItemsTableFilterComposer,
          $$LocalSaleItemsTableOrderingComposer,
          $$LocalSaleItemsTableAnnotationComposer,
          $$LocalSaleItemsTableCreateCompanionBuilder,
          $$LocalSaleItemsTableUpdateCompanionBuilder,
          (
            LocalSaleItem,
            BaseReferences<_$AppDatabase, $LocalSaleItemsTable, LocalSaleItem>,
          ),
          LocalSaleItem,
          PrefetchHooks Function()
        > {
  $$LocalSaleItemsTableTableManager(
    _$AppDatabase db,
    $LocalSaleItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSaleItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSaleItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSaleItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> saleId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<double> sellPrice = const Value.absent(),
                Value<double> buyPrice = const Value.absent(),
                Value<double> profit = const Value.absent(),
                Value<String?> cycleId = const Value.absent(),
                Value<String?> unitId = const Value.absent(),
                Value<int?> quantityInBase = const Value.absent(),
                Value<double?> unitSellPrice = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSaleItemsCompanion(
                id: id,
                saleId: saleId,
                productId: productId,
                productName: productName,
                quantity: quantity,
                sellPrice: sellPrice,
                buyPrice: buyPrice,
                profit: profit,
                cycleId: cycleId,
                unitId: unitId,
                quantityInBase: quantityInBase,
                unitSellPrice: unitSellPrice,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String saleId,
                required String productId,
                required String productName,
                required int quantity,
                required double sellPrice,
                required double buyPrice,
                required double profit,
                Value<String?> cycleId = const Value.absent(),
                Value<String?> unitId = const Value.absent(),
                Value<int?> quantityInBase = const Value.absent(),
                Value<double?> unitSellPrice = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSaleItemsCompanion.insert(
                id: id,
                saleId: saleId,
                productId: productId,
                productName: productName,
                quantity: quantity,
                sellPrice: sellPrice,
                buyPrice: buyPrice,
                profit: profit,
                cycleId: cycleId,
                unitId: unitId,
                quantityInBase: quantityInBase,
                unitSellPrice: unitSellPrice,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSaleItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSaleItemsTable,
      LocalSaleItem,
      $$LocalSaleItemsTableFilterComposer,
      $$LocalSaleItemsTableOrderingComposer,
      $$LocalSaleItemsTableAnnotationComposer,
      $$LocalSaleItemsTableCreateCompanionBuilder,
      $$LocalSaleItemsTableUpdateCompanionBuilder,
      (
        LocalSaleItem,
        BaseReferences<_$AppDatabase, $LocalSaleItemsTable, LocalSaleItem>,
      ),
      LocalSaleItem,
      PrefetchHooks Function()
    >;
typedef $$LocalCashMovementsTableCreateCompanionBuilder =
    LocalCashMovementsCompanion Function({
      required String id,
      required String shopId,
      required String userId,
      required double amount,
      required String type,
      Value<String?> category,
      Value<String?> note,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$LocalCashMovementsTableUpdateCompanionBuilder =
    LocalCashMovementsCompanion Function({
      Value<String> id,
      Value<String> shopId,
      Value<String> userId,
      Value<double> amount,
      Value<String> type,
      Value<String?> category,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$LocalCashMovementsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalCashMovementsTable> {
  $$LocalCashMovementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalCashMovementsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalCashMovementsTable> {
  $$LocalCashMovementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalCashMovementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalCashMovementsTable> {
  $$LocalCashMovementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get shopId =>
      $composableBuilder(column: $table.shopId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalCashMovementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalCashMovementsTable,
          LocalCashMovement,
          $$LocalCashMovementsTableFilterComposer,
          $$LocalCashMovementsTableOrderingComposer,
          $$LocalCashMovementsTableAnnotationComposer,
          $$LocalCashMovementsTableCreateCompanionBuilder,
          $$LocalCashMovementsTableUpdateCompanionBuilder,
          (
            LocalCashMovement,
            BaseReferences<
              _$AppDatabase,
              $LocalCashMovementsTable,
              LocalCashMovement
            >,
          ),
          LocalCashMovement,
          PrefetchHooks Function()
        > {
  $$LocalCashMovementsTableTableManager(
    _$AppDatabase db,
    $LocalCashMovementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCashMovementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalCashMovementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalCashMovementsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> shopId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCashMovementsCompanion(
                id: id,
                shopId: shopId,
                userId: userId,
                amount: amount,
                type: type,
                category: category,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String shopId,
                required String userId,
                required double amount,
                required String type,
                Value<String?> category = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalCashMovementsCompanion.insert(
                id: id,
                shopId: shopId,
                userId: userId,
                amount: amount,
                type: type,
                category: category,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalCashMovementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalCashMovementsTable,
      LocalCashMovement,
      $$LocalCashMovementsTableFilterComposer,
      $$LocalCashMovementsTableOrderingComposer,
      $$LocalCashMovementsTableAnnotationComposer,
      $$LocalCashMovementsTableCreateCompanionBuilder,
      $$LocalCashMovementsTableUpdateCompanionBuilder,
      (
        LocalCashMovement,
        BaseReferences<
          _$AppDatabase,
          $LocalCashMovementsTable,
          LocalCashMovement
        >,
      ),
      LocalCashMovement,
      PrefetchHooks Function()
    >;
typedef $$LocalStockMovementsTableCreateCompanionBuilder =
    LocalStockMovementsCompanion Function({
      required String id,
      required String shopId,
      required String productId,
      required int quantity,
      required String type,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$LocalStockMovementsTableUpdateCompanionBuilder =
    LocalStockMovementsCompanion Function({
      Value<String> id,
      Value<String> shopId,
      Value<String> productId,
      Value<int> quantity,
      Value<String> type,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$LocalStockMovementsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalStockMovementsTable> {
  $$LocalStockMovementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalStockMovementsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalStockMovementsTable> {
  $$LocalStockMovementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalStockMovementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalStockMovementsTable> {
  $$LocalStockMovementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get shopId =>
      $composableBuilder(column: $table.shopId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalStockMovementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalStockMovementsTable,
          LocalStockMovement,
          $$LocalStockMovementsTableFilterComposer,
          $$LocalStockMovementsTableOrderingComposer,
          $$LocalStockMovementsTableAnnotationComposer,
          $$LocalStockMovementsTableCreateCompanionBuilder,
          $$LocalStockMovementsTableUpdateCompanionBuilder,
          (
            LocalStockMovement,
            BaseReferences<
              _$AppDatabase,
              $LocalStockMovementsTable,
              LocalStockMovement
            >,
          ),
          LocalStockMovement,
          PrefetchHooks Function()
        > {
  $$LocalStockMovementsTableTableManager(
    _$AppDatabase db,
    $LocalStockMovementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalStockMovementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalStockMovementsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalStockMovementsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> shopId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalStockMovementsCompanion(
                id: id,
                shopId: shopId,
                productId: productId,
                quantity: quantity,
                type: type,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String shopId,
                required String productId,
                required int quantity,
                required String type,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalStockMovementsCompanion.insert(
                id: id,
                shopId: shopId,
                productId: productId,
                quantity: quantity,
                type: type,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalStockMovementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalStockMovementsTable,
      LocalStockMovement,
      $$LocalStockMovementsTableFilterComposer,
      $$LocalStockMovementsTableOrderingComposer,
      $$LocalStockMovementsTableAnnotationComposer,
      $$LocalStockMovementsTableCreateCompanionBuilder,
      $$LocalStockMovementsTableUpdateCompanionBuilder,
      (
        LocalStockMovement,
        BaseReferences<
          _$AppDatabase,
          $LocalStockMovementsTable,
          LocalStockMovement
        >,
      ),
      LocalStockMovement,
      PrefetchHooks Function()
    >;
typedef $$LocalDailyClosingsTableCreateCompanionBuilder =
    LocalDailyClosingsCompanion Function({
      required String id,
      required String shopId,
      required String userId,
      required DateTime closingDate,
      required double morningBalance,
      required double totalSales,
      required double totalWithdrawals,
      required double calculatedCash,
      required double grossProfit,
      required double netProfit,
      Value<double?> physicalCash,
      Value<double?> cashGap,
      Value<bool> isClosed,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$LocalDailyClosingsTableUpdateCompanionBuilder =
    LocalDailyClosingsCompanion Function({
      Value<String> id,
      Value<String> shopId,
      Value<String> userId,
      Value<DateTime> closingDate,
      Value<double> morningBalance,
      Value<double> totalSales,
      Value<double> totalWithdrawals,
      Value<double> calculatedCash,
      Value<double> grossProfit,
      Value<double> netProfit,
      Value<double?> physicalCash,
      Value<double?> cashGap,
      Value<bool> isClosed,
      Value<String?> note,
      Value<int> rowid,
    });

class $$LocalDailyClosingsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalDailyClosingsTable> {
  $$LocalDailyClosingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get closingDate => $composableBuilder(
    column: $table.closingDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get morningBalance => $composableBuilder(
    column: $table.morningBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalSales => $composableBuilder(
    column: $table.totalSales,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalWithdrawals => $composableBuilder(
    column: $table.totalWithdrawals,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get calculatedCash => $composableBuilder(
    column: $table.calculatedCash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grossProfit => $composableBuilder(
    column: $table.grossProfit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get netProfit => $composableBuilder(
    column: $table.netProfit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get physicalCash => $composableBuilder(
    column: $table.physicalCash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cashGap => $composableBuilder(
    column: $table.cashGap,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isClosed => $composableBuilder(
    column: $table.isClosed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalDailyClosingsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalDailyClosingsTable> {
  $$LocalDailyClosingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get closingDate => $composableBuilder(
    column: $table.closingDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get morningBalance => $composableBuilder(
    column: $table.morningBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalSales => $composableBuilder(
    column: $table.totalSales,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalWithdrawals => $composableBuilder(
    column: $table.totalWithdrawals,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get calculatedCash => $composableBuilder(
    column: $table.calculatedCash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grossProfit => $composableBuilder(
    column: $table.grossProfit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get netProfit => $composableBuilder(
    column: $table.netProfit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get physicalCash => $composableBuilder(
    column: $table.physicalCash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cashGap => $composableBuilder(
    column: $table.cashGap,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isClosed => $composableBuilder(
    column: $table.isClosed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalDailyClosingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalDailyClosingsTable> {
  $$LocalDailyClosingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get shopId =>
      $composableBuilder(column: $table.shopId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get closingDate => $composableBuilder(
    column: $table.closingDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get morningBalance => $composableBuilder(
    column: $table.morningBalance,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalSales => $composableBuilder(
    column: $table.totalSales,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalWithdrawals => $composableBuilder(
    column: $table.totalWithdrawals,
    builder: (column) => column,
  );

  GeneratedColumn<double> get calculatedCash => $composableBuilder(
    column: $table.calculatedCash,
    builder: (column) => column,
  );

  GeneratedColumn<double> get grossProfit => $composableBuilder(
    column: $table.grossProfit,
    builder: (column) => column,
  );

  GeneratedColumn<double> get netProfit =>
      $composableBuilder(column: $table.netProfit, builder: (column) => column);

  GeneratedColumn<double> get physicalCash => $composableBuilder(
    column: $table.physicalCash,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cashGap =>
      $composableBuilder(column: $table.cashGap, builder: (column) => column);

  GeneratedColumn<bool> get isClosed =>
      $composableBuilder(column: $table.isClosed, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$LocalDailyClosingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalDailyClosingsTable,
          LocalDailyClosing,
          $$LocalDailyClosingsTableFilterComposer,
          $$LocalDailyClosingsTableOrderingComposer,
          $$LocalDailyClosingsTableAnnotationComposer,
          $$LocalDailyClosingsTableCreateCompanionBuilder,
          $$LocalDailyClosingsTableUpdateCompanionBuilder,
          (
            LocalDailyClosing,
            BaseReferences<
              _$AppDatabase,
              $LocalDailyClosingsTable,
              LocalDailyClosing
            >,
          ),
          LocalDailyClosing,
          PrefetchHooks Function()
        > {
  $$LocalDailyClosingsTableTableManager(
    _$AppDatabase db,
    $LocalDailyClosingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalDailyClosingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalDailyClosingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalDailyClosingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> shopId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> closingDate = const Value.absent(),
                Value<double> morningBalance = const Value.absent(),
                Value<double> totalSales = const Value.absent(),
                Value<double> totalWithdrawals = const Value.absent(),
                Value<double> calculatedCash = const Value.absent(),
                Value<double> grossProfit = const Value.absent(),
                Value<double> netProfit = const Value.absent(),
                Value<double?> physicalCash = const Value.absent(),
                Value<double?> cashGap = const Value.absent(),
                Value<bool> isClosed = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDailyClosingsCompanion(
                id: id,
                shopId: shopId,
                userId: userId,
                closingDate: closingDate,
                morningBalance: morningBalance,
                totalSales: totalSales,
                totalWithdrawals: totalWithdrawals,
                calculatedCash: calculatedCash,
                grossProfit: grossProfit,
                netProfit: netProfit,
                physicalCash: physicalCash,
                cashGap: cashGap,
                isClosed: isClosed,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String shopId,
                required String userId,
                required DateTime closingDate,
                required double morningBalance,
                required double totalSales,
                required double totalWithdrawals,
                required double calculatedCash,
                required double grossProfit,
                required double netProfit,
                Value<double?> physicalCash = const Value.absent(),
                Value<double?> cashGap = const Value.absent(),
                Value<bool> isClosed = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDailyClosingsCompanion.insert(
                id: id,
                shopId: shopId,
                userId: userId,
                closingDate: closingDate,
                morningBalance: morningBalance,
                totalSales: totalSales,
                totalWithdrawals: totalWithdrawals,
                calculatedCash: calculatedCash,
                grossProfit: grossProfit,
                netProfit: netProfit,
                physicalCash: physicalCash,
                cashGap: cashGap,
                isClosed: isClosed,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalDailyClosingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalDailyClosingsTable,
      LocalDailyClosing,
      $$LocalDailyClosingsTableFilterComposer,
      $$LocalDailyClosingsTableOrderingComposer,
      $$LocalDailyClosingsTableAnnotationComposer,
      $$LocalDailyClosingsTableCreateCompanionBuilder,
      $$LocalDailyClosingsTableUpdateCompanionBuilder,
      (
        LocalDailyClosing,
        BaseReferences<
          _$AppDatabase,
          $LocalDailyClosingsTable,
          LocalDailyClosing
        >,
      ),
      LocalDailyClosing,
      PrefetchHooks Function()
    >;
typedef $$LocalShopSettingsTableCreateCompanionBuilder =
    LocalShopSettingsCompanion Function({
      required String shopId,
      Value<String> unitMode,
      Value<String> saleCaptureMode,
      Value<bool> multiPointEnabled,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalShopSettingsTableUpdateCompanionBuilder =
    LocalShopSettingsCompanion Function({
      Value<String> shopId,
      Value<String> unitMode,
      Value<String> saleCaptureMode,
      Value<bool> multiPointEnabled,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalShopSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalShopSettingsTable> {
  $$LocalShopSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitMode => $composableBuilder(
    column: $table.unitMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get saleCaptureMode => $composableBuilder(
    column: $table.saleCaptureMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get multiPointEnabled => $composableBuilder(
    column: $table.multiPointEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalShopSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalShopSettingsTable> {
  $$LocalShopSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitMode => $composableBuilder(
    column: $table.unitMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get saleCaptureMode => $composableBuilder(
    column: $table.saleCaptureMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get multiPointEnabled => $composableBuilder(
    column: $table.multiPointEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalShopSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalShopSettingsTable> {
  $$LocalShopSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get shopId =>
      $composableBuilder(column: $table.shopId, builder: (column) => column);

  GeneratedColumn<String> get unitMode =>
      $composableBuilder(column: $table.unitMode, builder: (column) => column);

  GeneratedColumn<String> get saleCaptureMode => $composableBuilder(
    column: $table.saleCaptureMode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get multiPointEnabled => $composableBuilder(
    column: $table.multiPointEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalShopSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalShopSettingsTable,
          LocalShopSetting,
          $$LocalShopSettingsTableFilterComposer,
          $$LocalShopSettingsTableOrderingComposer,
          $$LocalShopSettingsTableAnnotationComposer,
          $$LocalShopSettingsTableCreateCompanionBuilder,
          $$LocalShopSettingsTableUpdateCompanionBuilder,
          (
            LocalShopSetting,
            BaseReferences<
              _$AppDatabase,
              $LocalShopSettingsTable,
              LocalShopSetting
            >,
          ),
          LocalShopSetting,
          PrefetchHooks Function()
        > {
  $$LocalShopSettingsTableTableManager(
    _$AppDatabase db,
    $LocalShopSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalShopSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalShopSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalShopSettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> shopId = const Value.absent(),
                Value<String> unitMode = const Value.absent(),
                Value<String> saleCaptureMode = const Value.absent(),
                Value<bool> multiPointEnabled = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalShopSettingsCompanion(
                shopId: shopId,
                unitMode: unitMode,
                saleCaptureMode: saleCaptureMode,
                multiPointEnabled: multiPointEnabled,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String shopId,
                Value<String> unitMode = const Value.absent(),
                Value<String> saleCaptureMode = const Value.absent(),
                Value<bool> multiPointEnabled = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalShopSettingsCompanion.insert(
                shopId: shopId,
                unitMode: unitMode,
                saleCaptureMode: saleCaptureMode,
                multiPointEnabled: multiPointEnabled,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalShopSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalShopSettingsTable,
      LocalShopSetting,
      $$LocalShopSettingsTableFilterComposer,
      $$LocalShopSettingsTableOrderingComposer,
      $$LocalShopSettingsTableAnnotationComposer,
      $$LocalShopSettingsTableCreateCompanionBuilder,
      $$LocalShopSettingsTableUpdateCompanionBuilder,
      (
        LocalShopSetting,
        BaseReferences<
          _$AppDatabase,
          $LocalShopSettingsTable,
          LocalShopSetting
        >,
      ),
      LocalShopSetting,
      PrefetchHooks Function()
    >;
typedef $$LocalProductUnitsTableCreateCompanionBuilder =
    LocalProductUnitsCompanion Function({
      required String id,
      required String productId,
      required String unitName,
      required int ratioToBase,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$LocalProductUnitsTableUpdateCompanionBuilder =
    LocalProductUnitsCompanion Function({
      Value<String> id,
      Value<String> productId,
      Value<String> unitName,
      Value<int> ratioToBase,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$LocalProductUnitsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalProductUnitsTable> {
  $$LocalProductUnitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitName => $composableBuilder(
    column: $table.unitName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ratioToBase => $composableBuilder(
    column: $table.ratioToBase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalProductUnitsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalProductUnitsTable> {
  $$LocalProductUnitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitName => $composableBuilder(
    column: $table.unitName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ratioToBase => $composableBuilder(
    column: $table.ratioToBase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalProductUnitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalProductUnitsTable> {
  $$LocalProductUnitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get unitName =>
      $composableBuilder(column: $table.unitName, builder: (column) => column);

  GeneratedColumn<int> get ratioToBase => $composableBuilder(
    column: $table.ratioToBase,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$LocalProductUnitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalProductUnitsTable,
          LocalProductUnit,
          $$LocalProductUnitsTableFilterComposer,
          $$LocalProductUnitsTableOrderingComposer,
          $$LocalProductUnitsTableAnnotationComposer,
          $$LocalProductUnitsTableCreateCompanionBuilder,
          $$LocalProductUnitsTableUpdateCompanionBuilder,
          (
            LocalProductUnit,
            BaseReferences<
              _$AppDatabase,
              $LocalProductUnitsTable,
              LocalProductUnit
            >,
          ),
          LocalProductUnit,
          PrefetchHooks Function()
        > {
  $$LocalProductUnitsTableTableManager(
    _$AppDatabase db,
    $LocalProductUnitsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalProductUnitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalProductUnitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalProductUnitsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> unitName = const Value.absent(),
                Value<int> ratioToBase = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalProductUnitsCompanion(
                id: id,
                productId: productId,
                unitName: unitName,
                ratioToBase: ratioToBase,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String productId,
                required String unitName,
                required int ratioToBase,
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalProductUnitsCompanion.insert(
                id: id,
                productId: productId,
                unitName: unitName,
                ratioToBase: ratioToBase,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalProductUnitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalProductUnitsTable,
      LocalProductUnit,
      $$LocalProductUnitsTableFilterComposer,
      $$LocalProductUnitsTableOrderingComposer,
      $$LocalProductUnitsTableAnnotationComposer,
      $$LocalProductUnitsTableCreateCompanionBuilder,
      $$LocalProductUnitsTableUpdateCompanionBuilder,
      (
        LocalProductUnit,
        BaseReferences<
          _$AppDatabase,
          $LocalProductUnitsTable,
          LocalProductUnit
        >,
      ),
      LocalProductUnit,
      PrefetchHooks Function()
    >;
typedef $$LocalSupplyCyclesTableCreateCompanionBuilder =
    LocalSupplyCyclesCompanion Function({
      required String id,
      required String shopId,
      required String productId,
      required DateTime openedAt,
      Value<DateTime?> closedAt,
      required int quantityReceived,
      required double purchaseCost,
      Value<double?> referenceMarginPerUnit,
      Value<String> status,
      Value<int> rowid,
    });
typedef $$LocalSupplyCyclesTableUpdateCompanionBuilder =
    LocalSupplyCyclesCompanion Function({
      Value<String> id,
      Value<String> shopId,
      Value<String> productId,
      Value<DateTime> openedAt,
      Value<DateTime?> closedAt,
      Value<int> quantityReceived,
      Value<double> purchaseCost,
      Value<double?> referenceMarginPerUnit,
      Value<String> status,
      Value<int> rowid,
    });

class $$LocalSupplyCyclesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSupplyCyclesTable> {
  $$LocalSupplyCyclesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantityReceived => $composableBuilder(
    column: $table.quantityReceived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get purchaseCost => $composableBuilder(
    column: $table.purchaseCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get referenceMarginPerUnit => $composableBuilder(
    column: $table.referenceMarginPerUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSupplyCyclesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSupplyCyclesTable> {
  $$LocalSupplyCyclesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantityReceived => $composableBuilder(
    column: $table.quantityReceived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get purchaseCost => $composableBuilder(
    column: $table.purchaseCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get referenceMarginPerUnit => $composableBuilder(
    column: $table.referenceMarginPerUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSupplyCyclesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSupplyCyclesTable> {
  $$LocalSupplyCyclesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get shopId =>
      $composableBuilder(column: $table.shopId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);

  GeneratedColumn<int> get quantityReceived => $composableBuilder(
    column: $table.quantityReceived,
    builder: (column) => column,
  );

  GeneratedColumn<double> get purchaseCost => $composableBuilder(
    column: $table.purchaseCost,
    builder: (column) => column,
  );

  GeneratedColumn<double> get referenceMarginPerUnit => $composableBuilder(
    column: $table.referenceMarginPerUnit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$LocalSupplyCyclesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSupplyCyclesTable,
          LocalSupplyCycle,
          $$LocalSupplyCyclesTableFilterComposer,
          $$LocalSupplyCyclesTableOrderingComposer,
          $$LocalSupplyCyclesTableAnnotationComposer,
          $$LocalSupplyCyclesTableCreateCompanionBuilder,
          $$LocalSupplyCyclesTableUpdateCompanionBuilder,
          (
            LocalSupplyCycle,
            BaseReferences<
              _$AppDatabase,
              $LocalSupplyCyclesTable,
              LocalSupplyCycle
            >,
          ),
          LocalSupplyCycle,
          PrefetchHooks Function()
        > {
  $$LocalSupplyCyclesTableTableManager(
    _$AppDatabase db,
    $LocalSupplyCyclesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSupplyCyclesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSupplyCyclesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSupplyCyclesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> shopId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<DateTime> openedAt = const Value.absent(),
                Value<DateTime?> closedAt = const Value.absent(),
                Value<int> quantityReceived = const Value.absent(),
                Value<double> purchaseCost = const Value.absent(),
                Value<double?> referenceMarginPerUnit = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSupplyCyclesCompanion(
                id: id,
                shopId: shopId,
                productId: productId,
                openedAt: openedAt,
                closedAt: closedAt,
                quantityReceived: quantityReceived,
                purchaseCost: purchaseCost,
                referenceMarginPerUnit: referenceMarginPerUnit,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String shopId,
                required String productId,
                required DateTime openedAt,
                Value<DateTime?> closedAt = const Value.absent(),
                required int quantityReceived,
                required double purchaseCost,
                Value<double?> referenceMarginPerUnit = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSupplyCyclesCompanion.insert(
                id: id,
                shopId: shopId,
                productId: productId,
                openedAt: openedAt,
                closedAt: closedAt,
                quantityReceived: quantityReceived,
                purchaseCost: purchaseCost,
                referenceMarginPerUnit: referenceMarginPerUnit,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSupplyCyclesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSupplyCyclesTable,
      LocalSupplyCycle,
      $$LocalSupplyCyclesTableFilterComposer,
      $$LocalSupplyCyclesTableOrderingComposer,
      $$LocalSupplyCyclesTableAnnotationComposer,
      $$LocalSupplyCyclesTableCreateCompanionBuilder,
      $$LocalSupplyCyclesTableUpdateCompanionBuilder,
      (
        LocalSupplyCycle,
        BaseReferences<
          _$AppDatabase,
          $LocalSupplyCyclesTable,
          LocalSupplyCycle
        >,
      ),
      LocalSupplyCycle,
      PrefetchHooks Function()
    >;
typedef $$LocalCycleLossesTableCreateCompanionBuilder =
    LocalCycleLossesCompanion Function({
      required String id,
      required String cycleId,
      required int quantity,
      required String reason,
      Value<String?> note,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$LocalCycleLossesTableUpdateCompanionBuilder =
    LocalCycleLossesCompanion Function({
      Value<String> id,
      Value<String> cycleId,
      Value<int> quantity,
      Value<String> reason,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$LocalCycleLossesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalCycleLossesTable> {
  $$LocalCycleLossesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cycleId => $composableBuilder(
    column: $table.cycleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalCycleLossesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalCycleLossesTable> {
  $$LocalCycleLossesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cycleId => $composableBuilder(
    column: $table.cycleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalCycleLossesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalCycleLossesTable> {
  $$LocalCycleLossesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cycleId =>
      $composableBuilder(column: $table.cycleId, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalCycleLossesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalCycleLossesTable,
          LocalCycleLossesData,
          $$LocalCycleLossesTableFilterComposer,
          $$LocalCycleLossesTableOrderingComposer,
          $$LocalCycleLossesTableAnnotationComposer,
          $$LocalCycleLossesTableCreateCompanionBuilder,
          $$LocalCycleLossesTableUpdateCompanionBuilder,
          (
            LocalCycleLossesData,
            BaseReferences<
              _$AppDatabase,
              $LocalCycleLossesTable,
              LocalCycleLossesData
            >,
          ),
          LocalCycleLossesData,
          PrefetchHooks Function()
        > {
  $$LocalCycleLossesTableTableManager(
    _$AppDatabase db,
    $LocalCycleLossesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCycleLossesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalCycleLossesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalCycleLossesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> cycleId = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCycleLossesCompanion(
                id: id,
                cycleId: cycleId,
                quantity: quantity,
                reason: reason,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String cycleId,
                required int quantity,
                required String reason,
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalCycleLossesCompanion.insert(
                id: id,
                cycleId: cycleId,
                quantity: quantity,
                reason: reason,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalCycleLossesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalCycleLossesTable,
      LocalCycleLossesData,
      $$LocalCycleLossesTableFilterComposer,
      $$LocalCycleLossesTableOrderingComposer,
      $$LocalCycleLossesTableAnnotationComposer,
      $$LocalCycleLossesTableCreateCompanionBuilder,
      $$LocalCycleLossesTableUpdateCompanionBuilder,
      (
        LocalCycleLossesData,
        BaseReferences<
          _$AppDatabase,
          $LocalCycleLossesTable,
          LocalCycleLossesData
        >,
      ),
      LocalCycleLossesData,
      PrefetchHooks Function()
    >;
typedef $$LocalShopTakingsTableCreateCompanionBuilder =
    LocalShopTakingsCompanion Function({
      required String shopId,
      required DateTime date,
      required double amount,
      Value<int> rowid,
    });
typedef $$LocalShopTakingsTableUpdateCompanionBuilder =
    LocalShopTakingsCompanion Function({
      Value<String> shopId,
      Value<DateTime> date,
      Value<double> amount,
      Value<int> rowid,
    });

class $$LocalShopTakingsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalShopTakingsTable> {
  $$LocalShopTakingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalShopTakingsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalShopTakingsTable> {
  $$LocalShopTakingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalShopTakingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalShopTakingsTable> {
  $$LocalShopTakingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get shopId =>
      $composableBuilder(column: $table.shopId, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);
}

class $$LocalShopTakingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalShopTakingsTable,
          LocalShopTaking,
          $$LocalShopTakingsTableFilterComposer,
          $$LocalShopTakingsTableOrderingComposer,
          $$LocalShopTakingsTableAnnotationComposer,
          $$LocalShopTakingsTableCreateCompanionBuilder,
          $$LocalShopTakingsTableUpdateCompanionBuilder,
          (
            LocalShopTaking,
            BaseReferences<
              _$AppDatabase,
              $LocalShopTakingsTable,
              LocalShopTaking
            >,
          ),
          LocalShopTaking,
          PrefetchHooks Function()
        > {
  $$LocalShopTakingsTableTableManager(
    _$AppDatabase db,
    $LocalShopTakingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalShopTakingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalShopTakingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalShopTakingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> shopId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalShopTakingsCompanion(
                shopId: shopId,
                date: date,
                amount: amount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String shopId,
                required DateTime date,
                required double amount,
                Value<int> rowid = const Value.absent(),
              }) => LocalShopTakingsCompanion.insert(
                shopId: shopId,
                date: date,
                amount: amount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalShopTakingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalShopTakingsTable,
      LocalShopTaking,
      $$LocalShopTakingsTableFilterComposer,
      $$LocalShopTakingsTableOrderingComposer,
      $$LocalShopTakingsTableAnnotationComposer,
      $$LocalShopTakingsTableCreateCompanionBuilder,
      $$LocalShopTakingsTableUpdateCompanionBuilder,
      (
        LocalShopTaking,
        BaseReferences<_$AppDatabase, $LocalShopTakingsTable, LocalShopTaking>,
      ),
      LocalShopTaking,
      PrefetchHooks Function()
    >;
typedef $$LocalInventoryCountsTableCreateCompanionBuilder =
    LocalInventoryCountsCompanion Function({
      required String id,
      required String shopId,
      required String productId,
      required DateTime countedAt,
      required int countedQuantity,
      Value<DateTime?> previousCountedAt,
      Value<int?> previousQuantity,
      Value<int> rowid,
    });
typedef $$LocalInventoryCountsTableUpdateCompanionBuilder =
    LocalInventoryCountsCompanion Function({
      Value<String> id,
      Value<String> shopId,
      Value<String> productId,
      Value<DateTime> countedAt,
      Value<int> countedQuantity,
      Value<DateTime?> previousCountedAt,
      Value<int?> previousQuantity,
      Value<int> rowid,
    });

class $$LocalInventoryCountsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalInventoryCountsTable> {
  $$LocalInventoryCountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get countedAt => $composableBuilder(
    column: $table.countedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get countedQuantity => $composableBuilder(
    column: $table.countedQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get previousCountedAt => $composableBuilder(
    column: $table.previousCountedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get previousQuantity => $composableBuilder(
    column: $table.previousQuantity,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalInventoryCountsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalInventoryCountsTable> {
  $$LocalInventoryCountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get countedAt => $composableBuilder(
    column: $table.countedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get countedQuantity => $composableBuilder(
    column: $table.countedQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get previousCountedAt => $composableBuilder(
    column: $table.previousCountedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get previousQuantity => $composableBuilder(
    column: $table.previousQuantity,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalInventoryCountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalInventoryCountsTable> {
  $$LocalInventoryCountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get shopId =>
      $composableBuilder(column: $table.shopId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<DateTime> get countedAt =>
      $composableBuilder(column: $table.countedAt, builder: (column) => column);

  GeneratedColumn<int> get countedQuantity => $composableBuilder(
    column: $table.countedQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get previousCountedAt => $composableBuilder(
    column: $table.previousCountedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get previousQuantity => $composableBuilder(
    column: $table.previousQuantity,
    builder: (column) => column,
  );
}

class $$LocalInventoryCountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalInventoryCountsTable,
          LocalInventoryCount,
          $$LocalInventoryCountsTableFilterComposer,
          $$LocalInventoryCountsTableOrderingComposer,
          $$LocalInventoryCountsTableAnnotationComposer,
          $$LocalInventoryCountsTableCreateCompanionBuilder,
          $$LocalInventoryCountsTableUpdateCompanionBuilder,
          (
            LocalInventoryCount,
            BaseReferences<
              _$AppDatabase,
              $LocalInventoryCountsTable,
              LocalInventoryCount
            >,
          ),
          LocalInventoryCount,
          PrefetchHooks Function()
        > {
  $$LocalInventoryCountsTableTableManager(
    _$AppDatabase db,
    $LocalInventoryCountsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalInventoryCountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalInventoryCountsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalInventoryCountsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> shopId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<DateTime> countedAt = const Value.absent(),
                Value<int> countedQuantity = const Value.absent(),
                Value<DateTime?> previousCountedAt = const Value.absent(),
                Value<int?> previousQuantity = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalInventoryCountsCompanion(
                id: id,
                shopId: shopId,
                productId: productId,
                countedAt: countedAt,
                countedQuantity: countedQuantity,
                previousCountedAt: previousCountedAt,
                previousQuantity: previousQuantity,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String shopId,
                required String productId,
                required DateTime countedAt,
                required int countedQuantity,
                Value<DateTime?> previousCountedAt = const Value.absent(),
                Value<int?> previousQuantity = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalInventoryCountsCompanion.insert(
                id: id,
                shopId: shopId,
                productId: productId,
                countedAt: countedAt,
                countedQuantity: countedQuantity,
                previousCountedAt: previousCountedAt,
                previousQuantity: previousQuantity,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalInventoryCountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalInventoryCountsTable,
      LocalInventoryCount,
      $$LocalInventoryCountsTableFilterComposer,
      $$LocalInventoryCountsTableOrderingComposer,
      $$LocalInventoryCountsTableAnnotationComposer,
      $$LocalInventoryCountsTableCreateCompanionBuilder,
      $$LocalInventoryCountsTableUpdateCompanionBuilder,
      (
        LocalInventoryCount,
        BaseReferences<
          _$AppDatabase,
          $LocalInventoryCountsTable,
          LocalInventoryCount
        >,
      ),
      LocalInventoryCount,
      PrefetchHooks Function()
    >;
typedef $$LocalInventoryLossesTableCreateCompanionBuilder =
    LocalInventoryLossesCompanion Function({
      required String id,
      required String shopId,
      required String productId,
      required int quantity,
      required String reason,
      Value<String?> note,
      required DateTime occurredAt,
      Value<int> rowid,
    });
typedef $$LocalInventoryLossesTableUpdateCompanionBuilder =
    LocalInventoryLossesCompanion Function({
      Value<String> id,
      Value<String> shopId,
      Value<String> productId,
      Value<int> quantity,
      Value<String> reason,
      Value<String?> note,
      Value<DateTime> occurredAt,
      Value<int> rowid,
    });

class $$LocalInventoryLossesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalInventoryLossesTable> {
  $$LocalInventoryLossesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalInventoryLossesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalInventoryLossesTable> {
  $$LocalInventoryLossesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalInventoryLossesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalInventoryLossesTable> {
  $$LocalInventoryLossesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get shopId =>
      $composableBuilder(column: $table.shopId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );
}

class $$LocalInventoryLossesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalInventoryLossesTable,
          LocalInventoryLoss,
          $$LocalInventoryLossesTableFilterComposer,
          $$LocalInventoryLossesTableOrderingComposer,
          $$LocalInventoryLossesTableAnnotationComposer,
          $$LocalInventoryLossesTableCreateCompanionBuilder,
          $$LocalInventoryLossesTableUpdateCompanionBuilder,
          (
            LocalInventoryLoss,
            BaseReferences<
              _$AppDatabase,
              $LocalInventoryLossesTable,
              LocalInventoryLoss
            >,
          ),
          LocalInventoryLoss,
          PrefetchHooks Function()
        > {
  $$LocalInventoryLossesTableTableManager(
    _$AppDatabase db,
    $LocalInventoryLossesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalInventoryLossesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalInventoryLossesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalInventoryLossesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> shopId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalInventoryLossesCompanion(
                id: id,
                shopId: shopId,
                productId: productId,
                quantity: quantity,
                reason: reason,
                note: note,
                occurredAt: occurredAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String shopId,
                required String productId,
                required int quantity,
                required String reason,
                Value<String?> note = const Value.absent(),
                required DateTime occurredAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalInventoryLossesCompanion.insert(
                id: id,
                shopId: shopId,
                productId: productId,
                quantity: quantity,
                reason: reason,
                note: note,
                occurredAt: occurredAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalInventoryLossesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalInventoryLossesTable,
      LocalInventoryLoss,
      $$LocalInventoryLossesTableFilterComposer,
      $$LocalInventoryLossesTableOrderingComposer,
      $$LocalInventoryLossesTableAnnotationComposer,
      $$LocalInventoryLossesTableCreateCompanionBuilder,
      $$LocalInventoryLossesTableUpdateCompanionBuilder,
      (
        LocalInventoryLoss,
        BaseReferences<
          _$AppDatabase,
          $LocalInventoryLossesTable,
          LocalInventoryLoss
        >,
      ),
      LocalInventoryLoss,
      PrefetchHooks Function()
    >;
typedef $$LocalStockPurchasesTableCreateCompanionBuilder =
    LocalStockPurchasesCompanion Function({
      required String id,
      required String shopId,
      required String productId,
      required int quantity,
      required double unitCost,
      required DateTime purchasedAt,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$LocalStockPurchasesTableUpdateCompanionBuilder =
    LocalStockPurchasesCompanion Function({
      Value<String> id,
      Value<String> shopId,
      Value<String> productId,
      Value<int> quantity,
      Value<double> unitCost,
      Value<DateTime> purchasedAt,
      Value<String?> note,
      Value<int> rowid,
    });

class $$LocalStockPurchasesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalStockPurchasesTable> {
  $$LocalStockPurchasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitCost => $composableBuilder(
    column: $table.unitCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get purchasedAt => $composableBuilder(
    column: $table.purchasedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalStockPurchasesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalStockPurchasesTable> {
  $$LocalStockPurchasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitCost => $composableBuilder(
    column: $table.unitCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get purchasedAt => $composableBuilder(
    column: $table.purchasedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalStockPurchasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalStockPurchasesTable> {
  $$LocalStockPurchasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get shopId =>
      $composableBuilder(column: $table.shopId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get unitCost =>
      $composableBuilder(column: $table.unitCost, builder: (column) => column);

  GeneratedColumn<DateTime> get purchasedAt => $composableBuilder(
    column: $table.purchasedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$LocalStockPurchasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalStockPurchasesTable,
          LocalStockPurchase,
          $$LocalStockPurchasesTableFilterComposer,
          $$LocalStockPurchasesTableOrderingComposer,
          $$LocalStockPurchasesTableAnnotationComposer,
          $$LocalStockPurchasesTableCreateCompanionBuilder,
          $$LocalStockPurchasesTableUpdateCompanionBuilder,
          (
            LocalStockPurchase,
            BaseReferences<
              _$AppDatabase,
              $LocalStockPurchasesTable,
              LocalStockPurchase
            >,
          ),
          LocalStockPurchase,
          PrefetchHooks Function()
        > {
  $$LocalStockPurchasesTableTableManager(
    _$AppDatabase db,
    $LocalStockPurchasesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalStockPurchasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalStockPurchasesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalStockPurchasesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> shopId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<double> unitCost = const Value.absent(),
                Value<DateTime> purchasedAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalStockPurchasesCompanion(
                id: id,
                shopId: shopId,
                productId: productId,
                quantity: quantity,
                unitCost: unitCost,
                purchasedAt: purchasedAt,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String shopId,
                required String productId,
                required int quantity,
                required double unitCost,
                required DateTime purchasedAt,
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalStockPurchasesCompanion.insert(
                id: id,
                shopId: shopId,
                productId: productId,
                quantity: quantity,
                unitCost: unitCost,
                purchasedAt: purchasedAt,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalStockPurchasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalStockPurchasesTable,
      LocalStockPurchase,
      $$LocalStockPurchasesTableFilterComposer,
      $$LocalStockPurchasesTableOrderingComposer,
      $$LocalStockPurchasesTableAnnotationComposer,
      $$LocalStockPurchasesTableCreateCompanionBuilder,
      $$LocalStockPurchasesTableUpdateCompanionBuilder,
      (
        LocalStockPurchase,
        BaseReferences<
          _$AppDatabase,
          $LocalStockPurchasesTable,
          LocalStockPurchase
        >,
      ),
      LocalStockPurchase,
      PrefetchHooks Function()
    >;
typedef $$LocalProductPricesTableCreateCompanionBuilder =
    LocalProductPricesCompanion Function({
      required String id,
      required String shopId,
      required String productId,
      required double buyPrice,
      required double sellPrice,
      required DateTime effectiveAt,
      Value<int> rowid,
    });
typedef $$LocalProductPricesTableUpdateCompanionBuilder =
    LocalProductPricesCompanion Function({
      Value<String> id,
      Value<String> shopId,
      Value<String> productId,
      Value<double> buyPrice,
      Value<double> sellPrice,
      Value<DateTime> effectiveAt,
      Value<int> rowid,
    });

class $$LocalProductPricesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalProductPricesTable> {
  $$LocalProductPricesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get buyPrice => $composableBuilder(
    column: $table.buyPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sellPrice => $composableBuilder(
    column: $table.sellPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get effectiveAt => $composableBuilder(
    column: $table.effectiveAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalProductPricesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalProductPricesTable> {
  $$LocalProductPricesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get buyPrice => $composableBuilder(
    column: $table.buyPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sellPrice => $composableBuilder(
    column: $table.sellPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get effectiveAt => $composableBuilder(
    column: $table.effectiveAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalProductPricesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalProductPricesTable> {
  $$LocalProductPricesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get shopId =>
      $composableBuilder(column: $table.shopId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<double> get buyPrice =>
      $composableBuilder(column: $table.buyPrice, builder: (column) => column);

  GeneratedColumn<double> get sellPrice =>
      $composableBuilder(column: $table.sellPrice, builder: (column) => column);

  GeneratedColumn<DateTime> get effectiveAt => $composableBuilder(
    column: $table.effectiveAt,
    builder: (column) => column,
  );
}

class $$LocalProductPricesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalProductPricesTable,
          LocalProductPrice,
          $$LocalProductPricesTableFilterComposer,
          $$LocalProductPricesTableOrderingComposer,
          $$LocalProductPricesTableAnnotationComposer,
          $$LocalProductPricesTableCreateCompanionBuilder,
          $$LocalProductPricesTableUpdateCompanionBuilder,
          (
            LocalProductPrice,
            BaseReferences<
              _$AppDatabase,
              $LocalProductPricesTable,
              LocalProductPrice
            >,
          ),
          LocalProductPrice,
          PrefetchHooks Function()
        > {
  $$LocalProductPricesTableTableManager(
    _$AppDatabase db,
    $LocalProductPricesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalProductPricesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalProductPricesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalProductPricesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> shopId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<double> buyPrice = const Value.absent(),
                Value<double> sellPrice = const Value.absent(),
                Value<DateTime> effectiveAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalProductPricesCompanion(
                id: id,
                shopId: shopId,
                productId: productId,
                buyPrice: buyPrice,
                sellPrice: sellPrice,
                effectiveAt: effectiveAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String shopId,
                required String productId,
                required double buyPrice,
                required double sellPrice,
                required DateTime effectiveAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalProductPricesCompanion.insert(
                id: id,
                shopId: shopId,
                productId: productId,
                buyPrice: buyPrice,
                sellPrice: sellPrice,
                effectiveAt: effectiveAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalProductPricesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalProductPricesTable,
      LocalProductPrice,
      $$LocalProductPricesTableFilterComposer,
      $$LocalProductPricesTableOrderingComposer,
      $$LocalProductPricesTableAnnotationComposer,
      $$LocalProductPricesTableCreateCompanionBuilder,
      $$LocalProductPricesTableUpdateCompanionBuilder,
      (
        LocalProductPrice,
        BaseReferences<
          _$AppDatabase,
          $LocalProductPricesTable,
          LocalProductPrice
        >,
      ),
      LocalProductPrice,
      PrefetchHooks Function()
    >;
typedef $$LocalStockTransfersTableCreateCompanionBuilder =
    LocalStockTransfersCompanion Function({
      required String id,
      required String fromShopId,
      required String toShopId,
      required String productId,
      required int quantity,
      Value<int?> receivedQuantity,
      Value<DateTime?> receivedAt,
      required DateTime transferredAt,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$LocalStockTransfersTableUpdateCompanionBuilder =
    LocalStockTransfersCompanion Function({
      Value<String> id,
      Value<String> fromShopId,
      Value<String> toShopId,
      Value<String> productId,
      Value<int> quantity,
      Value<int?> receivedQuantity,
      Value<DateTime?> receivedAt,
      Value<DateTime> transferredAt,
      Value<String?> note,
      Value<int> rowid,
    });

class $$LocalStockTransfersTableFilterComposer
    extends Composer<_$AppDatabase, $LocalStockTransfersTable> {
  $$LocalStockTransfersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromShopId => $composableBuilder(
    column: $table.fromShopId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toShopId => $composableBuilder(
    column: $table.toShopId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get receivedQuantity => $composableBuilder(
    column: $table.receivedQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get transferredAt => $composableBuilder(
    column: $table.transferredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalStockTransfersTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalStockTransfersTable> {
  $$LocalStockTransfersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromShopId => $composableBuilder(
    column: $table.fromShopId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toShopId => $composableBuilder(
    column: $table.toShopId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get receivedQuantity => $composableBuilder(
    column: $table.receivedQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get transferredAt => $composableBuilder(
    column: $table.transferredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalStockTransfersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalStockTransfersTable> {
  $$LocalStockTransfersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fromShopId => $composableBuilder(
    column: $table.fromShopId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get toShopId =>
      $composableBuilder(column: $table.toShopId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<int> get receivedQuantity => $composableBuilder(
    column: $table.receivedQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get transferredAt => $composableBuilder(
    column: $table.transferredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$LocalStockTransfersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalStockTransfersTable,
          LocalStockTransfer,
          $$LocalStockTransfersTableFilterComposer,
          $$LocalStockTransfersTableOrderingComposer,
          $$LocalStockTransfersTableAnnotationComposer,
          $$LocalStockTransfersTableCreateCompanionBuilder,
          $$LocalStockTransfersTableUpdateCompanionBuilder,
          (
            LocalStockTransfer,
            BaseReferences<
              _$AppDatabase,
              $LocalStockTransfersTable,
              LocalStockTransfer
            >,
          ),
          LocalStockTransfer,
          PrefetchHooks Function()
        > {
  $$LocalStockTransfersTableTableManager(
    _$AppDatabase db,
    $LocalStockTransfersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalStockTransfersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalStockTransfersTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalStockTransfersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> fromShopId = const Value.absent(),
                Value<String> toShopId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<int?> receivedQuantity = const Value.absent(),
                Value<DateTime?> receivedAt = const Value.absent(),
                Value<DateTime> transferredAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalStockTransfersCompanion(
                id: id,
                fromShopId: fromShopId,
                toShopId: toShopId,
                productId: productId,
                quantity: quantity,
                receivedQuantity: receivedQuantity,
                receivedAt: receivedAt,
                transferredAt: transferredAt,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String fromShopId,
                required String toShopId,
                required String productId,
                required int quantity,
                Value<int?> receivedQuantity = const Value.absent(),
                Value<DateTime?> receivedAt = const Value.absent(),
                required DateTime transferredAt,
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalStockTransfersCompanion.insert(
                id: id,
                fromShopId: fromShopId,
                toShopId: toShopId,
                productId: productId,
                quantity: quantity,
                receivedQuantity: receivedQuantity,
                receivedAt: receivedAt,
                transferredAt: transferredAt,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalStockTransfersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalStockTransfersTable,
      LocalStockTransfer,
      $$LocalStockTransfersTableFilterComposer,
      $$LocalStockTransfersTableOrderingComposer,
      $$LocalStockTransfersTableAnnotationComposer,
      $$LocalStockTransfersTableCreateCompanionBuilder,
      $$LocalStockTransfersTableUpdateCompanionBuilder,
      (
        LocalStockTransfer,
        BaseReferences<
          _$AppDatabase,
          $LocalStockTransfersTable,
          LocalStockTransfer
        >,
      ),
      LocalStockTransfer,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueItemsTableCreateCompanionBuilder =
    SyncQueueItemsCompanion Function({
      Value<int> id,
      required String action,
      required String payload,
      Value<DateTime> createdAt,
    });
typedef $$SyncQueueItemsTableUpdateCompanionBuilder =
    SyncQueueItemsCompanion Function({
      Value<int> id,
      Value<String> action,
      Value<String> payload,
      Value<DateTime> createdAt,
    });

class $$SyncQueueItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueItemsTable> {
  $$SyncQueueItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueItemsTable> {
  $$SyncQueueItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueItemsTable> {
  $$SyncQueueItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncQueueItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueItemsTable,
          SyncQueueItem,
          $$SyncQueueItemsTableFilterComposer,
          $$SyncQueueItemsTableOrderingComposer,
          $$SyncQueueItemsTableAnnotationComposer,
          $$SyncQueueItemsTableCreateCompanionBuilder,
          $$SyncQueueItemsTableUpdateCompanionBuilder,
          (
            SyncQueueItem,
            BaseReferences<_$AppDatabase, $SyncQueueItemsTable, SyncQueueItem>,
          ),
          SyncQueueItem,
          PrefetchHooks Function()
        > {
  $$SyncQueueItemsTableTableManager(
    _$AppDatabase db,
    $SyncQueueItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SyncQueueItemsCompanion(
                id: id,
                action: action,
                payload: payload,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String action,
                required String payload,
                Value<DateTime> createdAt = const Value.absent(),
              }) => SyncQueueItemsCompanion.insert(
                id: id,
                action: action,
                payload: payload,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueItemsTable,
      SyncQueueItem,
      $$SyncQueueItemsTableFilterComposer,
      $$SyncQueueItemsTableOrderingComposer,
      $$SyncQueueItemsTableAnnotationComposer,
      $$SyncQueueItemsTableCreateCompanionBuilder,
      $$SyncQueueItemsTableUpdateCompanionBuilder,
      (
        SyncQueueItem,
        BaseReferences<_$AppDatabase, $SyncQueueItemsTable, SyncQueueItem>,
      ),
      SyncQueueItem,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalProductsTableTableManager get localProducts =>
      $$LocalProductsTableTableManager(_db, _db.localProducts);
  $$LocalSalesTableTableManager get localSales =>
      $$LocalSalesTableTableManager(_db, _db.localSales);
  $$LocalSaleItemsTableTableManager get localSaleItems =>
      $$LocalSaleItemsTableTableManager(_db, _db.localSaleItems);
  $$LocalCashMovementsTableTableManager get localCashMovements =>
      $$LocalCashMovementsTableTableManager(_db, _db.localCashMovements);
  $$LocalStockMovementsTableTableManager get localStockMovements =>
      $$LocalStockMovementsTableTableManager(_db, _db.localStockMovements);
  $$LocalDailyClosingsTableTableManager get localDailyClosings =>
      $$LocalDailyClosingsTableTableManager(_db, _db.localDailyClosings);
  $$LocalShopSettingsTableTableManager get localShopSettings =>
      $$LocalShopSettingsTableTableManager(_db, _db.localShopSettings);
  $$LocalProductUnitsTableTableManager get localProductUnits =>
      $$LocalProductUnitsTableTableManager(_db, _db.localProductUnits);
  $$LocalSupplyCyclesTableTableManager get localSupplyCycles =>
      $$LocalSupplyCyclesTableTableManager(_db, _db.localSupplyCycles);
  $$LocalCycleLossesTableTableManager get localCycleLosses =>
      $$LocalCycleLossesTableTableManager(_db, _db.localCycleLosses);
  $$LocalShopTakingsTableTableManager get localShopTakings =>
      $$LocalShopTakingsTableTableManager(_db, _db.localShopTakings);
  $$LocalInventoryCountsTableTableManager get localInventoryCounts =>
      $$LocalInventoryCountsTableTableManager(_db, _db.localInventoryCounts);
  $$LocalInventoryLossesTableTableManager get localInventoryLosses =>
      $$LocalInventoryLossesTableTableManager(_db, _db.localInventoryLosses);
  $$LocalStockPurchasesTableTableManager get localStockPurchases =>
      $$LocalStockPurchasesTableTableManager(_db, _db.localStockPurchases);
  $$LocalProductPricesTableTableManager get localProductPrices =>
      $$LocalProductPricesTableTableManager(_db, _db.localProductPrices);
  $$LocalStockTransfersTableTableManager get localStockTransfers =>
      $$LocalStockTransfersTableTableManager(_db, _db.localStockTransfers);
  $$SyncQueueItemsTableTableManager get syncQueueItems =>
      $$SyncQueueItemsTableTableManager(_db, _db.syncQueueItems);
}
