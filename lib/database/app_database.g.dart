// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passwordMeta = const VerificationMeta(
    'password',
  );
  @override
  late final GeneratedColumn<String> password = GeneratedColumn<String>(
    'password',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, username, password, role];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<User> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('password')) {
      context.handle(
        _passwordMeta,
        password.isAcceptableOrUnknown(data['password']!, _passwordMeta),
      );
    } else if (isInserting) {
      context.missing(_passwordMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      password: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final int id;
  final String username;
  final String password;
  final String role;
  const User({
    required this.id,
    required this.username,
    required this.password,
    required this.role,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['username'] = Variable<String>(username);
    map['password'] = Variable<String>(password);
    map['role'] = Variable<String>(role);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      username: Value(username),
      password: Value(password),
      role: Value(role),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<int>(json['id']),
      username: serializer.fromJson<String>(json['username']),
      password: serializer.fromJson<String>(json['password']),
      role: serializer.fromJson<String>(json['role']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'username': serializer.toJson<String>(username),
      'password': serializer.toJson<String>(password),
      'role': serializer.toJson<String>(role),
    };
  }

  User copyWith({int? id, String? username, String? password, String? role}) =>
      User(
        id: id ?? this.id,
        username: username ?? this.username,
        password: password ?? this.password,
        role: role ?? this.role,
      );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      username: data.username.present ? data.username.value : this.username,
      password: data.password.present ? data.password.value : this.password,
      role: data.role.present ? data.role.value : this.role,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('role: $role')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, username, password, role);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.username == this.username &&
          other.password == this.password &&
          other.role == this.role);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<int> id;
  final Value<String> username;
  final Value<String> password;
  final Value<String> role;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.username = const Value.absent(),
    this.password = const Value.absent(),
    this.role = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    required String username,
    required String password,
    required String role,
  }) : username = Value(username),
       password = Value(password),
       role = Value(role);
  static Insertable<User> custom({
    Expression<int>? id,
    Expression<String>? username,
    Expression<String>? password,
    Expression<String>? role,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (password != null) 'password': password,
      if (role != null) 'role': role,
    });
  }

  UsersCompanion copyWith({
    Value<int>? id,
    Value<String>? username,
    Value<String>? password,
    Value<String>? role,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (password.present) {
      map['password'] = Variable<String>(password.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('role: $role')
          ..write(')'))
        .toString();
  }
}

class $BranchesTable extends Branches with TableInfo<$BranchesTable, Branch> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BranchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weeklyOrderOfftakeMeta =
      const VerificationMeta('weeklyOrderOfftake');
  @override
  late final GeneratedColumn<String> weeklyOrderOfftake =
      GeneratedColumn<String>(
        'weekly_order_offtake',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _weeklyReorderPointMeta =
      const VerificationMeta('weeklyReorderPoint');
  @override
  late final GeneratedColumn<String> weeklyReorderPoint =
      GeneratedColumn<String>(
        'weekly_reorder_point',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _maintainingInventoryMeta =
      const VerificationMeta('maintainingInventory');
  @override
  late final GeneratedColumn<String> maintainingInventory =
      GeneratedColumn<String>(
        'maintaining_inventory',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    location,
    code,
    weeklyOrderOfftake,
    weeklyReorderPoint,
    maintainingInventory,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'branches';
  @override
  VerificationContext validateIntegrity(
    Insertable<Branch> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    } else if (isInserting) {
      context.missing(_locationMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    }
    if (data.containsKey('weekly_order_offtake')) {
      context.handle(
        _weeklyOrderOfftakeMeta,
        weeklyOrderOfftake.isAcceptableOrUnknown(
          data['weekly_order_offtake']!,
          _weeklyOrderOfftakeMeta,
        ),
      );
    }
    if (data.containsKey('weekly_reorder_point')) {
      context.handle(
        _weeklyReorderPointMeta,
        weeklyReorderPoint.isAcceptableOrUnknown(
          data['weekly_reorder_point']!,
          _weeklyReorderPointMeta,
        ),
      );
    }
    if (data.containsKey('maintaining_inventory')) {
      context.handle(
        _maintainingInventoryMeta,
        maintainingInventory.isAcceptableOrUnknown(
          data['maintaining_inventory']!,
          _maintainingInventoryMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Branch map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Branch(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      ),
      weeklyOrderOfftake: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weekly_order_offtake'],
      ),
      weeklyReorderPoint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weekly_reorder_point'],
      ),
      maintainingInventory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}maintaining_inventory'],
      ),
    );
  }

  @override
  $BranchesTable createAlias(String alias) {
    return $BranchesTable(attachedDatabase, alias);
  }
}

class Branch extends DataClass implements Insertable<Branch> {
  final int id;
  final String name;
  final String location;
  final String? code;
  final String? weeklyOrderOfftake;
  final String? weeklyReorderPoint;
  final String? maintainingInventory;
  const Branch({
    required this.id,
    required this.name,
    required this.location,
    this.code,
    this.weeklyOrderOfftake,
    this.weeklyReorderPoint,
    this.maintainingInventory,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['location'] = Variable<String>(location);
    if (!nullToAbsent || code != null) {
      map['code'] = Variable<String>(code);
    }
    if (!nullToAbsent || weeklyOrderOfftake != null) {
      map['weekly_order_offtake'] = Variable<String>(weeklyOrderOfftake);
    }
    if (!nullToAbsent || weeklyReorderPoint != null) {
      map['weekly_reorder_point'] = Variable<String>(weeklyReorderPoint);
    }
    if (!nullToAbsent || maintainingInventory != null) {
      map['maintaining_inventory'] = Variable<String>(maintainingInventory);
    }
    return map;
  }

  BranchesCompanion toCompanion(bool nullToAbsent) {
    return BranchesCompanion(
      id: Value(id),
      name: Value(name),
      location: Value(location),
      code: code == null && nullToAbsent ? const Value.absent() : Value(code),
      weeklyOrderOfftake: weeklyOrderOfftake == null && nullToAbsent
          ? const Value.absent()
          : Value(weeklyOrderOfftake),
      weeklyReorderPoint: weeklyReorderPoint == null && nullToAbsent
          ? const Value.absent()
          : Value(weeklyReorderPoint),
      maintainingInventory: maintainingInventory == null && nullToAbsent
          ? const Value.absent()
          : Value(maintainingInventory),
    );
  }

  factory Branch.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Branch(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      location: serializer.fromJson<String>(json['location']),
      code: serializer.fromJson<String?>(json['code']),
      weeklyOrderOfftake: serializer.fromJson<String?>(
        json['weeklyOrderOfftake'],
      ),
      weeklyReorderPoint: serializer.fromJson<String?>(
        json['weeklyReorderPoint'],
      ),
      maintainingInventory: serializer.fromJson<String?>(
        json['maintainingInventory'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'location': serializer.toJson<String>(location),
      'code': serializer.toJson<String?>(code),
      'weeklyOrderOfftake': serializer.toJson<String?>(weeklyOrderOfftake),
      'weeklyReorderPoint': serializer.toJson<String?>(weeklyReorderPoint),
      'maintainingInventory': serializer.toJson<String?>(maintainingInventory),
    };
  }

  Branch copyWith({
    int? id,
    String? name,
    String? location,
    Value<String?> code = const Value.absent(),
    Value<String?> weeklyOrderOfftake = const Value.absent(),
    Value<String?> weeklyReorderPoint = const Value.absent(),
    Value<String?> maintainingInventory = const Value.absent(),
  }) => Branch(
    id: id ?? this.id,
    name: name ?? this.name,
    location: location ?? this.location,
    code: code.present ? code.value : this.code,
    weeklyOrderOfftake: weeklyOrderOfftake.present
        ? weeklyOrderOfftake.value
        : this.weeklyOrderOfftake,
    weeklyReorderPoint: weeklyReorderPoint.present
        ? weeklyReorderPoint.value
        : this.weeklyReorderPoint,
    maintainingInventory: maintainingInventory.present
        ? maintainingInventory.value
        : this.maintainingInventory,
  );
  Branch copyWithCompanion(BranchesCompanion data) {
    return Branch(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      location: data.location.present ? data.location.value : this.location,
      code: data.code.present ? data.code.value : this.code,
      weeklyOrderOfftake: data.weeklyOrderOfftake.present
          ? data.weeklyOrderOfftake.value
          : this.weeklyOrderOfftake,
      weeklyReorderPoint: data.weeklyReorderPoint.present
          ? data.weeklyReorderPoint.value
          : this.weeklyReorderPoint,
      maintainingInventory: data.maintainingInventory.present
          ? data.maintainingInventory.value
          : this.maintainingInventory,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Branch(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('location: $location, ')
          ..write('code: $code, ')
          ..write('weeklyOrderOfftake: $weeklyOrderOfftake, ')
          ..write('weeklyReorderPoint: $weeklyReorderPoint, ')
          ..write('maintainingInventory: $maintainingInventory')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    location,
    code,
    weeklyOrderOfftake,
    weeklyReorderPoint,
    maintainingInventory,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Branch &&
          other.id == this.id &&
          other.name == this.name &&
          other.location == this.location &&
          other.code == this.code &&
          other.weeklyOrderOfftake == this.weeklyOrderOfftake &&
          other.weeklyReorderPoint == this.weeklyReorderPoint &&
          other.maintainingInventory == this.maintainingInventory);
}

class BranchesCompanion extends UpdateCompanion<Branch> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> location;
  final Value<String?> code;
  final Value<String?> weeklyOrderOfftake;
  final Value<String?> weeklyReorderPoint;
  final Value<String?> maintainingInventory;
  const BranchesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.location = const Value.absent(),
    this.code = const Value.absent(),
    this.weeklyOrderOfftake = const Value.absent(),
    this.weeklyReorderPoint = const Value.absent(),
    this.maintainingInventory = const Value.absent(),
  });
  BranchesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String location,
    this.code = const Value.absent(),
    this.weeklyOrderOfftake = const Value.absent(),
    this.weeklyReorderPoint = const Value.absent(),
    this.maintainingInventory = const Value.absent(),
  }) : name = Value(name),
       location = Value(location);
  static Insertable<Branch> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? location,
    Expression<String>? code,
    Expression<String>? weeklyOrderOfftake,
    Expression<String>? weeklyReorderPoint,
    Expression<String>? maintainingInventory,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (location != null) 'location': location,
      if (code != null) 'code': code,
      if (weeklyOrderOfftake != null)
        'weekly_order_offtake': weeklyOrderOfftake,
      if (weeklyReorderPoint != null)
        'weekly_reorder_point': weeklyReorderPoint,
      if (maintainingInventory != null)
        'maintaining_inventory': maintainingInventory,
    });
  }

  BranchesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? location,
    Value<String?>? code,
    Value<String?>? weeklyOrderOfftake,
    Value<String?>? weeklyReorderPoint,
    Value<String?>? maintainingInventory,
  }) {
    return BranchesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      code: code ?? this.code,
      weeklyOrderOfftake: weeklyOrderOfftake ?? this.weeklyOrderOfftake,
      weeklyReorderPoint: weeklyReorderPoint ?? this.weeklyReorderPoint,
      maintainingInventory: maintainingInventory ?? this.maintainingInventory,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (weeklyOrderOfftake.present) {
      map['weekly_order_offtake'] = Variable<String>(weeklyOrderOfftake.value);
    }
    if (weeklyReorderPoint.present) {
      map['weekly_reorder_point'] = Variable<String>(weeklyReorderPoint.value);
    }
    if (maintainingInventory.present) {
      map['maintaining_inventory'] = Variable<String>(
        maintainingInventory.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BranchesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('location: $location, ')
          ..write('code: $code, ')
          ..write('weeklyOrderOfftake: $weeklyOrderOfftake, ')
          ..write('weeklyReorderPoint: $weeklyReorderPoint, ')
          ..write('maintainingInventory: $maintainingInventory')
          ..write(')'))
        .toString();
  }
}

class $MasterItemsTable extends MasterItems
    with TableInfo<$MasterItemsTable, MasterItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MasterItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<int> branchId = GeneratedColumn<int>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sku,
    description,
    location,
    brand,
    branchId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'master_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<MasterItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    } else if (isInserting) {
      context.missing(_skuMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    } else if (isInserting) {
      context.missing(_locationMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MasterItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MasterItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}branch_id'],
      )!,
    );
  }

  @override
  $MasterItemsTable createAlias(String alias) {
    return $MasterItemsTable(attachedDatabase, alias);
  }
}

class MasterItem extends DataClass implements Insertable<MasterItem> {
  final int id;
  final String sku;
  final String description;
  final String location;
  final String? brand;
  final int branchId;
  const MasterItem({
    required this.id,
    required this.sku,
    required this.description,
    required this.location,
    this.brand,
    required this.branchId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sku'] = Variable<String>(sku);
    map['description'] = Variable<String>(description);
    map['location'] = Variable<String>(location);
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    map['branch_id'] = Variable<int>(branchId);
    return map;
  }

  MasterItemsCompanion toCompanion(bool nullToAbsent) {
    return MasterItemsCompanion(
      id: Value(id),
      sku: Value(sku),
      description: Value(description),
      location: Value(location),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      branchId: Value(branchId),
    );
  }

  factory MasterItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MasterItem(
      id: serializer.fromJson<int>(json['id']),
      sku: serializer.fromJson<String>(json['sku']),
      description: serializer.fromJson<String>(json['description']),
      location: serializer.fromJson<String>(json['location']),
      brand: serializer.fromJson<String?>(json['brand']),
      branchId: serializer.fromJson<int>(json['branchId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sku': serializer.toJson<String>(sku),
      'description': serializer.toJson<String>(description),
      'location': serializer.toJson<String>(location),
      'brand': serializer.toJson<String?>(brand),
      'branchId': serializer.toJson<int>(branchId),
    };
  }

  MasterItem copyWith({
    int? id,
    String? sku,
    String? description,
    String? location,
    Value<String?> brand = const Value.absent(),
    int? branchId,
  }) => MasterItem(
    id: id ?? this.id,
    sku: sku ?? this.sku,
    description: description ?? this.description,
    location: location ?? this.location,
    brand: brand.present ? brand.value : this.brand,
    branchId: branchId ?? this.branchId,
  );
  MasterItem copyWithCompanion(MasterItemsCompanion data) {
    return MasterItem(
      id: data.id.present ? data.id.value : this.id,
      sku: data.sku.present ? data.sku.value : this.sku,
      description: data.description.present
          ? data.description.value
          : this.description,
      location: data.location.present ? data.location.value : this.location,
      brand: data.brand.present ? data.brand.value : this.brand,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MasterItem(')
          ..write('id: $id, ')
          ..write('sku: $sku, ')
          ..write('description: $description, ')
          ..write('location: $location, ')
          ..write('brand: $brand, ')
          ..write('branchId: $branchId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sku, description, location, brand, branchId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MasterItem &&
          other.id == this.id &&
          other.sku == this.sku &&
          other.description == this.description &&
          other.location == this.location &&
          other.brand == this.brand &&
          other.branchId == this.branchId);
}

class MasterItemsCompanion extends UpdateCompanion<MasterItem> {
  final Value<int> id;
  final Value<String> sku;
  final Value<String> description;
  final Value<String> location;
  final Value<String?> brand;
  final Value<int> branchId;
  const MasterItemsCompanion({
    this.id = const Value.absent(),
    this.sku = const Value.absent(),
    this.description = const Value.absent(),
    this.location = const Value.absent(),
    this.brand = const Value.absent(),
    this.branchId = const Value.absent(),
  });
  MasterItemsCompanion.insert({
    this.id = const Value.absent(),
    required String sku,
    required String description,
    required String location,
    this.brand = const Value.absent(),
    required int branchId,
  }) : sku = Value(sku),
       description = Value(description),
       location = Value(location),
       branchId = Value(branchId);
  static Insertable<MasterItem> custom({
    Expression<int>? id,
    Expression<String>? sku,
    Expression<String>? description,
    Expression<String>? location,
    Expression<String>? brand,
    Expression<int>? branchId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sku != null) 'sku': sku,
      if (description != null) 'description': description,
      if (location != null) 'location': location,
      if (brand != null) 'brand': brand,
      if (branchId != null) 'branch_id': branchId,
    });
  }

  MasterItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? sku,
    Value<String>? description,
    Value<String>? location,
    Value<String?>? brand,
    Value<int>? branchId,
  }) {
    return MasterItemsCompanion(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      description: description ?? this.description,
      location: location ?? this.location,
      brand: brand ?? this.brand,
      branchId: branchId ?? this.branchId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<int>(branchId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MasterItemsCompanion(')
          ..write('id: $id, ')
          ..write('sku: $sku, ')
          ..write('description: $description, ')
          ..write('location: $location, ')
          ..write('brand: $brand, ')
          ..write('branchId: $branchId')
          ..write(')'))
        .toString();
  }
}

class $InventoryItemsTable extends InventoryItems
    with TableInfo<$InventoryItemsTable, InventoryItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMeta = const VerificationMeta('end');
  @override
  late final GeneratedColumn<int> end = GeneratedColumn<int>(
    'end',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateAddedMeta = const VerificationMeta(
    'dateAdded',
  );
  @override
  late final GeneratedColumn<String> dateAdded = GeneratedColumn<String>(
    'date_added',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastUpdatedMeta = const VerificationMeta(
    'lastUpdated',
  );
  @override
  late final GeneratedColumn<String> lastUpdated = GeneratedColumn<String>(
    'last_updated',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<int> branchId = GeneratedColumn<int>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _begMeta = const VerificationMeta('beg');
  @override
  late final GeneratedColumn<int> beg = GeneratedColumn<int>(
    'beg',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _prevMeta = const VerificationMeta('prev');
  @override
  late final GeneratedColumn<int> prev = GeneratedColumn<int>(
    'prev',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _salesMeta = const VerificationMeta('sales');
  @override
  late final GeneratedColumn<int> sales = GeneratedColumn<int>(
    'sales',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sku,
    description,
    end,
    location,
    brand,
    dateAdded,
    lastUpdated,
    branchId,
    beg,
    prev,
    sales,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<InventoryItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    } else if (isInserting) {
      context.missing(_skuMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('end')) {
      context.handle(
        _endMeta,
        end.isAcceptableOrUnknown(data['end']!, _endMeta),
      );
    } else if (isInserting) {
      context.missing(_endMeta);
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    } else if (isInserting) {
      context.missing(_locationMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('date_added')) {
      context.handle(
        _dateAddedMeta,
        dateAdded.isAcceptableOrUnknown(data['date_added']!, _dateAddedMeta),
      );
    } else if (isInserting) {
      context.missing(_dateAddedMeta);
    }
    if (data.containsKey('last_updated')) {
      context.handle(
        _lastUpdatedMeta,
        lastUpdated.isAcceptableOrUnknown(
          data['last_updated']!,
          _lastUpdatedMeta,
        ),
      );
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('beg')) {
      context.handle(
        _begMeta,
        beg.isAcceptableOrUnknown(data['beg']!, _begMeta),
      );
    }
    if (data.containsKey('prev')) {
      context.handle(
        _prevMeta,
        prev.isAcceptableOrUnknown(data['prev']!, _prevMeta),
      );
    }
    if (data.containsKey('sales')) {
      context.handle(
        _salesMeta,
        sales.isAcceptableOrUnknown(data['sales']!, _salesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventoryItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      end: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      dateAdded: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_added'],
      )!,
      lastUpdated: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_updated'],
      ),
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}branch_id'],
      )!,
      beg: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}beg'],
      ),
      prev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prev'],
      ),
      sales: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sales'],
      ),
    );
  }

  @override
  $InventoryItemsTable createAlias(String alias) {
    return $InventoryItemsTable(attachedDatabase, alias);
  }
}

class InventoryItem extends DataClass implements Insertable<InventoryItem> {
  final int id;
  final String sku;
  final String description;
  final int end;
  final String location;
  final String? brand;
  final String dateAdded;
  final String? lastUpdated;
  final int branchId;
  final int? beg;
  final int? prev;
  final int? sales;
  const InventoryItem({
    required this.id,
    required this.sku,
    required this.description,
    required this.end,
    required this.location,
    this.brand,
    required this.dateAdded,
    this.lastUpdated,
    required this.branchId,
    this.beg,
    this.prev,
    this.sales,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sku'] = Variable<String>(sku);
    map['description'] = Variable<String>(description);
    map['end'] = Variable<int>(end);
    map['location'] = Variable<String>(location);
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    map['date_added'] = Variable<String>(dateAdded);
    if (!nullToAbsent || lastUpdated != null) {
      map['last_updated'] = Variable<String>(lastUpdated);
    }
    map['branch_id'] = Variable<int>(branchId);
    if (!nullToAbsent || beg != null) {
      map['beg'] = Variable<int>(beg);
    }
    if (!nullToAbsent || prev != null) {
      map['prev'] = Variable<int>(prev);
    }
    if (!nullToAbsent || sales != null) {
      map['sales'] = Variable<int>(sales);
    }
    return map;
  }

  InventoryItemsCompanion toCompanion(bool nullToAbsent) {
    return InventoryItemsCompanion(
      id: Value(id),
      sku: Value(sku),
      description: Value(description),
      end: Value(end),
      location: Value(location),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      dateAdded: Value(dateAdded),
      lastUpdated: lastUpdated == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdated),
      branchId: Value(branchId),
      beg: beg == null && nullToAbsent ? const Value.absent() : Value(beg),
      prev: prev == null && nullToAbsent ? const Value.absent() : Value(prev),
      sales: sales == null && nullToAbsent
          ? const Value.absent()
          : Value(sales),
    );
  }

  factory InventoryItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryItem(
      id: serializer.fromJson<int>(json['id']),
      sku: serializer.fromJson<String>(json['sku']),
      description: serializer.fromJson<String>(json['description']),
      end: serializer.fromJson<int>(json['end']),
      location: serializer.fromJson<String>(json['location']),
      brand: serializer.fromJson<String?>(json['brand']),
      dateAdded: serializer.fromJson<String>(json['dateAdded']),
      lastUpdated: serializer.fromJson<String?>(json['lastUpdated']),
      branchId: serializer.fromJson<int>(json['branchId']),
      beg: serializer.fromJson<int?>(json['beg']),
      prev: serializer.fromJson<int?>(json['prev']),
      sales: serializer.fromJson<int?>(json['sales']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sku': serializer.toJson<String>(sku),
      'description': serializer.toJson<String>(description),
      'end': serializer.toJson<int>(end),
      'location': serializer.toJson<String>(location),
      'brand': serializer.toJson<String?>(brand),
      'dateAdded': serializer.toJson<String>(dateAdded),
      'lastUpdated': serializer.toJson<String?>(lastUpdated),
      'branchId': serializer.toJson<int>(branchId),
      'beg': serializer.toJson<int?>(beg),
      'prev': serializer.toJson<int?>(prev),
      'sales': serializer.toJson<int?>(sales),
    };
  }

  InventoryItem copyWith({
    int? id,
    String? sku,
    String? description,
    int? end,
    String? location,
    Value<String?> brand = const Value.absent(),
    String? dateAdded,
    Value<String?> lastUpdated = const Value.absent(),
    int? branchId,
    Value<int?> beg = const Value.absent(),
    Value<int?> prev = const Value.absent(),
    Value<int?> sales = const Value.absent(),
  }) => InventoryItem(
    id: id ?? this.id,
    sku: sku ?? this.sku,
    description: description ?? this.description,
    end: end ?? this.end,
    location: location ?? this.location,
    brand: brand.present ? brand.value : this.brand,
    dateAdded: dateAdded ?? this.dateAdded,
    lastUpdated: lastUpdated.present ? lastUpdated.value : this.lastUpdated,
    branchId: branchId ?? this.branchId,
    beg: beg.present ? beg.value : this.beg,
    prev: prev.present ? prev.value : this.prev,
    sales: sales.present ? sales.value : this.sales,
  );
  InventoryItem copyWithCompanion(InventoryItemsCompanion data) {
    return InventoryItem(
      id: data.id.present ? data.id.value : this.id,
      sku: data.sku.present ? data.sku.value : this.sku,
      description: data.description.present
          ? data.description.value
          : this.description,
      end: data.end.present ? data.end.value : this.end,
      location: data.location.present ? data.location.value : this.location,
      brand: data.brand.present ? data.brand.value : this.brand,
      dateAdded: data.dateAdded.present ? data.dateAdded.value : this.dateAdded,
      lastUpdated: data.lastUpdated.present
          ? data.lastUpdated.value
          : this.lastUpdated,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      beg: data.beg.present ? data.beg.value : this.beg,
      prev: data.prev.present ? data.prev.value : this.prev,
      sales: data.sales.present ? data.sales.value : this.sales,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryItem(')
          ..write('id: $id, ')
          ..write('sku: $sku, ')
          ..write('description: $description, ')
          ..write('end: $end, ')
          ..write('location: $location, ')
          ..write('brand: $brand, ')
          ..write('dateAdded: $dateAdded, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('branchId: $branchId, ')
          ..write('beg: $beg, ')
          ..write('prev: $prev, ')
          ..write('sales: $sales')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sku,
    description,
    end,
    location,
    brand,
    dateAdded,
    lastUpdated,
    branchId,
    beg,
    prev,
    sales,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryItem &&
          other.id == this.id &&
          other.sku == this.sku &&
          other.description == this.description &&
          other.end == this.end &&
          other.location == this.location &&
          other.brand == this.brand &&
          other.dateAdded == this.dateAdded &&
          other.lastUpdated == this.lastUpdated &&
          other.branchId == this.branchId &&
          other.beg == this.beg &&
          other.prev == this.prev &&
          other.sales == this.sales);
}

class InventoryItemsCompanion extends UpdateCompanion<InventoryItem> {
  final Value<int> id;
  final Value<String> sku;
  final Value<String> description;
  final Value<int> end;
  final Value<String> location;
  final Value<String?> brand;
  final Value<String> dateAdded;
  final Value<String?> lastUpdated;
  final Value<int> branchId;
  final Value<int?> beg;
  final Value<int?> prev;
  final Value<int?> sales;
  const InventoryItemsCompanion({
    this.id = const Value.absent(),
    this.sku = const Value.absent(),
    this.description = const Value.absent(),
    this.end = const Value.absent(),
    this.location = const Value.absent(),
    this.brand = const Value.absent(),
    this.dateAdded = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.branchId = const Value.absent(),
    this.beg = const Value.absent(),
    this.prev = const Value.absent(),
    this.sales = const Value.absent(),
  });
  InventoryItemsCompanion.insert({
    this.id = const Value.absent(),
    required String sku,
    required String description,
    required int end,
    required String location,
    this.brand = const Value.absent(),
    required String dateAdded,
    this.lastUpdated = const Value.absent(),
    required int branchId,
    this.beg = const Value.absent(),
    this.prev = const Value.absent(),
    this.sales = const Value.absent(),
  }) : sku = Value(sku),
       description = Value(description),
       end = Value(end),
       location = Value(location),
       dateAdded = Value(dateAdded),
       branchId = Value(branchId);
  static Insertable<InventoryItem> custom({
    Expression<int>? id,
    Expression<String>? sku,
    Expression<String>? description,
    Expression<int>? end,
    Expression<String>? location,
    Expression<String>? brand,
    Expression<String>? dateAdded,
    Expression<String>? lastUpdated,
    Expression<int>? branchId,
    Expression<int>? beg,
    Expression<int>? prev,
    Expression<int>? sales,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sku != null) 'sku': sku,
      if (description != null) 'description': description,
      if (end != null) 'end': end,
      if (location != null) 'location': location,
      if (brand != null) 'brand': brand,
      if (dateAdded != null) 'date_added': dateAdded,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (branchId != null) 'branch_id': branchId,
      if (beg != null) 'beg': beg,
      if (prev != null) 'prev': prev,
      if (sales != null) 'sales': sales,
    });
  }

  InventoryItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? sku,
    Value<String>? description,
    Value<int>? end,
    Value<String>? location,
    Value<String?>? brand,
    Value<String>? dateAdded,
    Value<String?>? lastUpdated,
    Value<int>? branchId,
    Value<int?>? beg,
    Value<int?>? prev,
    Value<int?>? sales,
  }) {
    return InventoryItemsCompanion(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      description: description ?? this.description,
      end: end ?? this.end,
      location: location ?? this.location,
      brand: brand ?? this.brand,
      dateAdded: dateAdded ?? this.dateAdded,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      branchId: branchId ?? this.branchId,
      beg: beg ?? this.beg,
      prev: prev ?? this.prev,
      sales: sales ?? this.sales,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (end.present) {
      map['end'] = Variable<int>(end.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (dateAdded.present) {
      map['date_added'] = Variable<String>(dateAdded.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<String>(lastUpdated.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<int>(branchId.value);
    }
    if (beg.present) {
      map['beg'] = Variable<int>(beg.value);
    }
    if (prev.present) {
      map['prev'] = Variable<int>(prev.value);
    }
    if (sales.present) {
      map['sales'] = Variable<int>(sales.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryItemsCompanion(')
          ..write('id: $id, ')
          ..write('sku: $sku, ')
          ..write('description: $description, ')
          ..write('end: $end, ')
          ..write('location: $location, ')
          ..write('brand: $brand, ')
          ..write('dateAdded: $dateAdded, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('branchId: $branchId, ')
          ..write('beg: $beg, ')
          ..write('prev: $prev, ')
          ..write('sales: $sales')
          ..write(')'))
        .toString();
  }
}

class $OrdersTable extends Orders with TableInfo<$OrdersTable, Order> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<int> branchId = GeneratedColumn<int>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _dateOrderedMeta = const VerificationMeta(
    'dateOrdered',
  );
  @override
  late final GeneratedColumn<String> dateOrdered = GeneratedColumn<String>(
    'date_ordered',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    branchId,
    location,
    brand,
    itemId,
    quantity,
    dateOrdered,
    status,
    batchId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Order> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    } else if (isInserting) {
      context.missing(_locationMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    } else if (isInserting) {
      context.missing(_brandMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('date_ordered')) {
      context.handle(
        _dateOrderedMeta,
        dateOrdered.isAcceptableOrUnknown(
          data['date_ordered']!,
          _dateOrderedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dateOrderedMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Order map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Order(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}branch_id'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      dateOrdered: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_ordered'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      ),
    );
  }

  @override
  $OrdersTable createAlias(String alias) {
    return $OrdersTable(attachedDatabase, alias);
  }
}

class Order extends DataClass implements Insertable<Order> {
  final int id;
  final int branchId;
  final String location;
  final String brand;
  final int itemId;
  final int quantity;
  final String dateOrdered;
  final String status;
  final String? batchId;
  const Order({
    required this.id,
    required this.branchId,
    required this.location,
    required this.brand,
    required this.itemId,
    required this.quantity,
    required this.dateOrdered,
    required this.status,
    this.batchId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['branch_id'] = Variable<int>(branchId);
    map['location'] = Variable<String>(location);
    map['brand'] = Variable<String>(brand);
    map['item_id'] = Variable<int>(itemId);
    map['quantity'] = Variable<int>(quantity);
    map['date_ordered'] = Variable<String>(dateOrdered);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || batchId != null) {
      map['batch_id'] = Variable<String>(batchId);
    }
    return map;
  }

  OrdersCompanion toCompanion(bool nullToAbsent) {
    return OrdersCompanion(
      id: Value(id),
      branchId: Value(branchId),
      location: Value(location),
      brand: Value(brand),
      itemId: Value(itemId),
      quantity: Value(quantity),
      dateOrdered: Value(dateOrdered),
      status: Value(status),
      batchId: batchId == null && nullToAbsent
          ? const Value.absent()
          : Value(batchId),
    );
  }

  factory Order.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Order(
      id: serializer.fromJson<int>(json['id']),
      branchId: serializer.fromJson<int>(json['branchId']),
      location: serializer.fromJson<String>(json['location']),
      brand: serializer.fromJson<String>(json['brand']),
      itemId: serializer.fromJson<int>(json['itemId']),
      quantity: serializer.fromJson<int>(json['quantity']),
      dateOrdered: serializer.fromJson<String>(json['dateOrdered']),
      status: serializer.fromJson<String>(json['status']),
      batchId: serializer.fromJson<String?>(json['batchId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'branchId': serializer.toJson<int>(branchId),
      'location': serializer.toJson<String>(location),
      'brand': serializer.toJson<String>(brand),
      'itemId': serializer.toJson<int>(itemId),
      'quantity': serializer.toJson<int>(quantity),
      'dateOrdered': serializer.toJson<String>(dateOrdered),
      'status': serializer.toJson<String>(status),
      'batchId': serializer.toJson<String?>(batchId),
    };
  }

  Order copyWith({
    int? id,
    int? branchId,
    String? location,
    String? brand,
    int? itemId,
    int? quantity,
    String? dateOrdered,
    String? status,
    Value<String?> batchId = const Value.absent(),
  }) => Order(
    id: id ?? this.id,
    branchId: branchId ?? this.branchId,
    location: location ?? this.location,
    brand: brand ?? this.brand,
    itemId: itemId ?? this.itemId,
    quantity: quantity ?? this.quantity,
    dateOrdered: dateOrdered ?? this.dateOrdered,
    status: status ?? this.status,
    batchId: batchId.present ? batchId.value : this.batchId,
  );
  Order copyWithCompanion(OrdersCompanion data) {
    return Order(
      id: data.id.present ? data.id.value : this.id,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      location: data.location.present ? data.location.value : this.location,
      brand: data.brand.present ? data.brand.value : this.brand,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      dateOrdered: data.dateOrdered.present
          ? data.dateOrdered.value
          : this.dateOrdered,
      status: data.status.present ? data.status.value : this.status,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Order(')
          ..write('id: $id, ')
          ..write('branchId: $branchId, ')
          ..write('location: $location, ')
          ..write('brand: $brand, ')
          ..write('itemId: $itemId, ')
          ..write('quantity: $quantity, ')
          ..write('dateOrdered: $dateOrdered, ')
          ..write('status: $status, ')
          ..write('batchId: $batchId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    branchId,
    location,
    brand,
    itemId,
    quantity,
    dateOrdered,
    status,
    batchId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Order &&
          other.id == this.id &&
          other.branchId == this.branchId &&
          other.location == this.location &&
          other.brand == this.brand &&
          other.itemId == this.itemId &&
          other.quantity == this.quantity &&
          other.dateOrdered == this.dateOrdered &&
          other.status == this.status &&
          other.batchId == this.batchId);
}

class OrdersCompanion extends UpdateCompanion<Order> {
  final Value<int> id;
  final Value<int> branchId;
  final Value<String> location;
  final Value<String> brand;
  final Value<int> itemId;
  final Value<int> quantity;
  final Value<String> dateOrdered;
  final Value<String> status;
  final Value<String?> batchId;
  const OrdersCompanion({
    this.id = const Value.absent(),
    this.branchId = const Value.absent(),
    this.location = const Value.absent(),
    this.brand = const Value.absent(),
    this.itemId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.dateOrdered = const Value.absent(),
    this.status = const Value.absent(),
    this.batchId = const Value.absent(),
  });
  OrdersCompanion.insert({
    this.id = const Value.absent(),
    required int branchId,
    required String location,
    required String brand,
    required int itemId,
    required int quantity,
    required String dateOrdered,
    this.status = const Value.absent(),
    this.batchId = const Value.absent(),
  }) : branchId = Value(branchId),
       location = Value(location),
       brand = Value(brand),
       itemId = Value(itemId),
       quantity = Value(quantity),
       dateOrdered = Value(dateOrdered);
  static Insertable<Order> custom({
    Expression<int>? id,
    Expression<int>? branchId,
    Expression<String>? location,
    Expression<String>? brand,
    Expression<int>? itemId,
    Expression<int>? quantity,
    Expression<String>? dateOrdered,
    Expression<String>? status,
    Expression<String>? batchId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (branchId != null) 'branch_id': branchId,
      if (location != null) 'location': location,
      if (brand != null) 'brand': brand,
      if (itemId != null) 'item_id': itemId,
      if (quantity != null) 'quantity': quantity,
      if (dateOrdered != null) 'date_ordered': dateOrdered,
      if (status != null) 'status': status,
      if (batchId != null) 'batch_id': batchId,
    });
  }

  OrdersCompanion copyWith({
    Value<int>? id,
    Value<int>? branchId,
    Value<String>? location,
    Value<String>? brand,
    Value<int>? itemId,
    Value<int>? quantity,
    Value<String>? dateOrdered,
    Value<String>? status,
    Value<String?>? batchId,
  }) {
    return OrdersCompanion(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      location: location ?? this.location,
      brand: brand ?? this.brand,
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
      dateOrdered: dateOrdered ?? this.dateOrdered,
      status: status ?? this.status,
      batchId: batchId ?? this.batchId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<int>(branchId.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (dateOrdered.present) {
      map['date_ordered'] = Variable<String>(dateOrdered.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrdersCompanion(')
          ..write('id: $id, ')
          ..write('branchId: $branchId, ')
          ..write('location: $location, ')
          ..write('brand: $brand, ')
          ..write('itemId: $itemId, ')
          ..write('quantity: $quantity, ')
          ..write('dateOrdered: $dateOrdered, ')
          ..write('status: $status, ')
          ..write('batchId: $batchId')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $BranchesTable branches = $BranchesTable(this);
  late final $MasterItemsTable masterItems = $MasterItemsTable(this);
  late final $InventoryItemsTable inventoryItems = $InventoryItemsTable(this);
  late final $OrdersTable orders = $OrdersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    users,
    branches,
    masterItems,
    inventoryItems,
    orders,
  ];
}

typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      required String username,
      required String password,
      required String role,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      Value<String> username,
      Value<String> password,
      Value<String> role,
    });

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
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

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get password => $composableBuilder(
    column: $table.password,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
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

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get password => $composableBuilder(
    column: $table.password,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get password =>
      $composableBuilder(column: $table.password, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          User,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
          User,
          PrefetchHooks Function()
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> password = const Value.absent(),
                Value<String> role = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                username: username,
                password: password,
                role: role,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String username,
                required String password,
                required String role,
              }) => UsersCompanion.insert(
                id: id,
                username: username,
                password: password,
                role: role,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      User,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
      User,
      PrefetchHooks Function()
    >;
typedef $$BranchesTableCreateCompanionBuilder =
    BranchesCompanion Function({
      Value<int> id,
      required String name,
      required String location,
      Value<String?> code,
      Value<String?> weeklyOrderOfftake,
      Value<String?> weeklyReorderPoint,
      Value<String?> maintainingInventory,
    });
typedef $$BranchesTableUpdateCompanionBuilder =
    BranchesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> location,
      Value<String?> code,
      Value<String?> weeklyOrderOfftake,
      Value<String?> weeklyReorderPoint,
      Value<String?> maintainingInventory,
    });

class $$BranchesTableFilterComposer
    extends Composer<_$AppDatabase, $BranchesTable> {
  $$BranchesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weeklyOrderOfftake => $composableBuilder(
    column: $table.weeklyOrderOfftake,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weeklyReorderPoint => $composableBuilder(
    column: $table.weeklyReorderPoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get maintainingInventory => $composableBuilder(
    column: $table.maintainingInventory,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BranchesTableOrderingComposer
    extends Composer<_$AppDatabase, $BranchesTable> {
  $$BranchesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weeklyOrderOfftake => $composableBuilder(
    column: $table.weeklyOrderOfftake,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weeklyReorderPoint => $composableBuilder(
    column: $table.weeklyReorderPoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get maintainingInventory => $composableBuilder(
    column: $table.maintainingInventory,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BranchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BranchesTable> {
  $$BranchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get weeklyOrderOfftake => $composableBuilder(
    column: $table.weeklyOrderOfftake,
    builder: (column) => column,
  );

  GeneratedColumn<String> get weeklyReorderPoint => $composableBuilder(
    column: $table.weeklyReorderPoint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get maintainingInventory => $composableBuilder(
    column: $table.maintainingInventory,
    builder: (column) => column,
  );
}

class $$BranchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BranchesTable,
          Branch,
          $$BranchesTableFilterComposer,
          $$BranchesTableOrderingComposer,
          $$BranchesTableAnnotationComposer,
          $$BranchesTableCreateCompanionBuilder,
          $$BranchesTableUpdateCompanionBuilder,
          (Branch, BaseReferences<_$AppDatabase, $BranchesTable, Branch>),
          Branch,
          PrefetchHooks Function()
        > {
  $$BranchesTableTableManager(_$AppDatabase db, $BranchesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BranchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BranchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BranchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<String?> code = const Value.absent(),
                Value<String?> weeklyOrderOfftake = const Value.absent(),
                Value<String?> weeklyReorderPoint = const Value.absent(),
                Value<String?> maintainingInventory = const Value.absent(),
              }) => BranchesCompanion(
                id: id,
                name: name,
                location: location,
                code: code,
                weeklyOrderOfftake: weeklyOrderOfftake,
                weeklyReorderPoint: weeklyReorderPoint,
                maintainingInventory: maintainingInventory,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String location,
                Value<String?> code = const Value.absent(),
                Value<String?> weeklyOrderOfftake = const Value.absent(),
                Value<String?> weeklyReorderPoint = const Value.absent(),
                Value<String?> maintainingInventory = const Value.absent(),
              }) => BranchesCompanion.insert(
                id: id,
                name: name,
                location: location,
                code: code,
                weeklyOrderOfftake: weeklyOrderOfftake,
                weeklyReorderPoint: weeklyReorderPoint,
                maintainingInventory: maintainingInventory,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BranchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BranchesTable,
      Branch,
      $$BranchesTableFilterComposer,
      $$BranchesTableOrderingComposer,
      $$BranchesTableAnnotationComposer,
      $$BranchesTableCreateCompanionBuilder,
      $$BranchesTableUpdateCompanionBuilder,
      (Branch, BaseReferences<_$AppDatabase, $BranchesTable, Branch>),
      Branch,
      PrefetchHooks Function()
    >;
typedef $$MasterItemsTableCreateCompanionBuilder =
    MasterItemsCompanion Function({
      Value<int> id,
      required String sku,
      required String description,
      required String location,
      Value<String?> brand,
      required int branchId,
    });
typedef $$MasterItemsTableUpdateCompanionBuilder =
    MasterItemsCompanion Function({
      Value<int> id,
      Value<String> sku,
      Value<String> description,
      Value<String> location,
      Value<String?> brand,
      Value<int> branchId,
    });

class $$MasterItemsTableFilterComposer
    extends Composer<_$AppDatabase, $MasterItemsTable> {
  $$MasterItemsTableFilterComposer({
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

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MasterItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $MasterItemsTable> {
  $$MasterItemsTableOrderingComposer({
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

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MasterItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MasterItemsTable> {
  $$MasterItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<int> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);
}

class $$MasterItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MasterItemsTable,
          MasterItem,
          $$MasterItemsTableFilterComposer,
          $$MasterItemsTableOrderingComposer,
          $$MasterItemsTableAnnotationComposer,
          $$MasterItemsTableCreateCompanionBuilder,
          $$MasterItemsTableUpdateCompanionBuilder,
          (
            MasterItem,
            BaseReferences<_$AppDatabase, $MasterItemsTable, MasterItem>,
          ),
          MasterItem,
          PrefetchHooks Function()
        > {
  $$MasterItemsTableTableManager(_$AppDatabase db, $MasterItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MasterItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MasterItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MasterItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sku = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<int> branchId = const Value.absent(),
              }) => MasterItemsCompanion(
                id: id,
                sku: sku,
                description: description,
                location: location,
                brand: brand,
                branchId: branchId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sku,
                required String description,
                required String location,
                Value<String?> brand = const Value.absent(),
                required int branchId,
              }) => MasterItemsCompanion.insert(
                id: id,
                sku: sku,
                description: description,
                location: location,
                brand: brand,
                branchId: branchId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MasterItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MasterItemsTable,
      MasterItem,
      $$MasterItemsTableFilterComposer,
      $$MasterItemsTableOrderingComposer,
      $$MasterItemsTableAnnotationComposer,
      $$MasterItemsTableCreateCompanionBuilder,
      $$MasterItemsTableUpdateCompanionBuilder,
      (
        MasterItem,
        BaseReferences<_$AppDatabase, $MasterItemsTable, MasterItem>,
      ),
      MasterItem,
      PrefetchHooks Function()
    >;
typedef $$InventoryItemsTableCreateCompanionBuilder =
    InventoryItemsCompanion Function({
      Value<int> id,
      required String sku,
      required String description,
      required int end,
      required String location,
      Value<String?> brand,
      required String dateAdded,
      Value<String?> lastUpdated,
      required int branchId,
      Value<int?> beg,
      Value<int?> prev,
      Value<int?> sales,
    });
typedef $$InventoryItemsTableUpdateCompanionBuilder =
    InventoryItemsCompanion Function({
      Value<int> id,
      Value<String> sku,
      Value<String> description,
      Value<int> end,
      Value<String> location,
      Value<String?> brand,
      Value<String> dateAdded,
      Value<String?> lastUpdated,
      Value<int> branchId,
      Value<int?> beg,
      Value<int?> prev,
      Value<int?> sales,
    });

class $$InventoryItemsTableFilterComposer
    extends Composer<_$AppDatabase, $InventoryItemsTable> {
  $$InventoryItemsTableFilterComposer({
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

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get end => $composableBuilder(
    column: $table.end,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get beg => $composableBuilder(
    column: $table.beg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get prev => $composableBuilder(
    column: $table.prev,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sales => $composableBuilder(
    column: $table.sales,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InventoryItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $InventoryItemsTable> {
  $$InventoryItemsTableOrderingComposer({
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

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get end => $composableBuilder(
    column: $table.end,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get beg => $composableBuilder(
    column: $table.beg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get prev => $composableBuilder(
    column: $table.prev,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sales => $composableBuilder(
    column: $table.sales,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InventoryItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventoryItemsTable> {
  $$InventoryItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get end =>
      $composableBuilder(column: $table.end, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get dateAdded =>
      $composableBuilder(column: $table.dateAdded, builder: (column) => column);

  GeneratedColumn<String> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => column,
  );

  GeneratedColumn<int> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<int> get beg =>
      $composableBuilder(column: $table.beg, builder: (column) => column);

  GeneratedColumn<int> get prev =>
      $composableBuilder(column: $table.prev, builder: (column) => column);

  GeneratedColumn<int> get sales =>
      $composableBuilder(column: $table.sales, builder: (column) => column);
}

class $$InventoryItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InventoryItemsTable,
          InventoryItem,
          $$InventoryItemsTableFilterComposer,
          $$InventoryItemsTableOrderingComposer,
          $$InventoryItemsTableAnnotationComposer,
          $$InventoryItemsTableCreateCompanionBuilder,
          $$InventoryItemsTableUpdateCompanionBuilder,
          (
            InventoryItem,
            BaseReferences<_$AppDatabase, $InventoryItemsTable, InventoryItem>,
          ),
          InventoryItem,
          PrefetchHooks Function()
        > {
  $$InventoryItemsTableTableManager(
    _$AppDatabase db,
    $InventoryItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventoryItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sku = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> end = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<String> dateAdded = const Value.absent(),
                Value<String?> lastUpdated = const Value.absent(),
                Value<int> branchId = const Value.absent(),
                Value<int?> beg = const Value.absent(),
                Value<int?> prev = const Value.absent(),
                Value<int?> sales = const Value.absent(),
              }) => InventoryItemsCompanion(
                id: id,
                sku: sku,
                description: description,
                end: end,
                location: location,
                brand: brand,
                dateAdded: dateAdded,
                lastUpdated: lastUpdated,
                branchId: branchId,
                beg: beg,
                prev: prev,
                sales: sales,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sku,
                required String description,
                required int end,
                required String location,
                Value<String?> brand = const Value.absent(),
                required String dateAdded,
                Value<String?> lastUpdated = const Value.absent(),
                required int branchId,
                Value<int?> beg = const Value.absent(),
                Value<int?> prev = const Value.absent(),
                Value<int?> sales = const Value.absent(),
              }) => InventoryItemsCompanion.insert(
                id: id,
                sku: sku,
                description: description,
                end: end,
                location: location,
                brand: brand,
                dateAdded: dateAdded,
                lastUpdated: lastUpdated,
                branchId: branchId,
                beg: beg,
                prev: prev,
                sales: sales,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InventoryItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InventoryItemsTable,
      InventoryItem,
      $$InventoryItemsTableFilterComposer,
      $$InventoryItemsTableOrderingComposer,
      $$InventoryItemsTableAnnotationComposer,
      $$InventoryItemsTableCreateCompanionBuilder,
      $$InventoryItemsTableUpdateCompanionBuilder,
      (
        InventoryItem,
        BaseReferences<_$AppDatabase, $InventoryItemsTable, InventoryItem>,
      ),
      InventoryItem,
      PrefetchHooks Function()
    >;
typedef $$OrdersTableCreateCompanionBuilder =
    OrdersCompanion Function({
      Value<int> id,
      required int branchId,
      required String location,
      required String brand,
      required int itemId,
      required int quantity,
      required String dateOrdered,
      Value<String> status,
      Value<String?> batchId,
    });
typedef $$OrdersTableUpdateCompanionBuilder =
    OrdersCompanion Function({
      Value<int> id,
      Value<int> branchId,
      Value<String> location,
      Value<String> brand,
      Value<int> itemId,
      Value<int> quantity,
      Value<String> dateOrdered,
      Value<String> status,
      Value<String?> batchId,
    });

class $$OrdersTableFilterComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableFilterComposer({
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

  ColumnFilters<int> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dateOrdered => $composableBuilder(
    column: $table.dateOrdered,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OrdersTableOrderingComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableOrderingComposer({
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

  ColumnOrderings<int> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dateOrdered => $composableBuilder(
    column: $table.dateOrdered,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OrdersTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<int> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get dateOrdered => $composableBuilder(
    column: $table.dateOrdered,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get batchId =>
      $composableBuilder(column: $table.batchId, builder: (column) => column);
}

class $$OrdersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OrdersTable,
          Order,
          $$OrdersTableFilterComposer,
          $$OrdersTableOrderingComposer,
          $$OrdersTableAnnotationComposer,
          $$OrdersTableCreateCompanionBuilder,
          $$OrdersTableUpdateCompanionBuilder,
          (Order, BaseReferences<_$AppDatabase, $OrdersTable, Order>),
          Order,
          PrefetchHooks Function()
        > {
  $$OrdersTableTableManager(_$AppDatabase db, $OrdersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> branchId = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<String> brand = const Value.absent(),
                Value<int> itemId = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<String> dateOrdered = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> batchId = const Value.absent(),
              }) => OrdersCompanion(
                id: id,
                branchId: branchId,
                location: location,
                brand: brand,
                itemId: itemId,
                quantity: quantity,
                dateOrdered: dateOrdered,
                status: status,
                batchId: batchId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int branchId,
                required String location,
                required String brand,
                required int itemId,
                required int quantity,
                required String dateOrdered,
                Value<String> status = const Value.absent(),
                Value<String?> batchId = const Value.absent(),
              }) => OrdersCompanion.insert(
                id: id,
                branchId: branchId,
                location: location,
                brand: brand,
                itemId: itemId,
                quantity: quantity,
                dateOrdered: dateOrdered,
                status: status,
                batchId: batchId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OrdersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OrdersTable,
      Order,
      $$OrdersTableFilterComposer,
      $$OrdersTableOrderingComposer,
      $$OrdersTableAnnotationComposer,
      $$OrdersTableCreateCompanionBuilder,
      $$OrdersTableUpdateCompanionBuilder,
      (Order, BaseReferences<_$AppDatabase, $OrdersTable, Order>),
      Order,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$BranchesTableTableManager get branches =>
      $$BranchesTableTableManager(_db, _db.branches);
  $$MasterItemsTableTableManager get masterItems =>
      $$MasterItemsTableTableManager(_db, _db.masterItems);
  $$InventoryItemsTableTableManager get inventoryItems =>
      $$InventoryItemsTableTableManager(_db, _db.inventoryItems);
  $$OrdersTableTableManager get orders =>
      $$OrdersTableTableManager(_db, _db.orders);
}
