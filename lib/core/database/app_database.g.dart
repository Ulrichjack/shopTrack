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
          ..write('photoUrl: $photoUrl')
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
          other.photoUrl == this.photoUrl);
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
  const LocalSaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.sellPrice,
    required this.buyPrice,
    required this.profit,
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
  }) => LocalSaleItem(
    id: id ?? this.id,
    saleId: saleId ?? this.saleId,
    productId: productId ?? this.productId,
    productName: productName ?? this.productName,
    quantity: quantity ?? this.quantity,
    sellPrice: sellPrice ?? this.sellPrice,
    buyPrice: buyPrice ?? this.buyPrice,
    profit: profit ?? this.profit,
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
          ..write('profit: $profit')
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
          other.profit == this.profit);
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
  $$SyncQueueItemsTableTableManager get syncQueueItems =>
      $$SyncQueueItemsTableTableManager(_db, _db.syncQueueItems);
}
