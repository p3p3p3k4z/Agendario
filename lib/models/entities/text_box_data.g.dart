// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'text_box_data.dart';

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const TextBoxDataSchema = Schema(
  name: r'TextBoxData',
  id: 5471231240745787392,
  properties: {
    r'colorValue': PropertySchema(
      id: 0,
      name: r'colorValue',
      type: IsarType.long,
    ),
    r'content': PropertySchema(
      id: 1,
      name: r'content',
      type: IsarType.string,
    ),
    r'fontSize': PropertySchema(
      id: 2,
      name: r'fontSize',
      type: IsarType.double,
    ),
    r'rotation': PropertySchema(
      id: 3,
      name: r'rotation',
      type: IsarType.double,
    ),
    r'scale': PropertySchema(
      id: 4,
      name: r'scale',
      type: IsarType.double,
    ),
    r'webFix': PropertySchema(
      id: 5,
      name: r'webFix',
      type: IsarType.string,
    ),
    r'xPct': PropertySchema(
      id: 6,
      name: r'xPct',
      type: IsarType.double,
    ),
    r'yPct': PropertySchema(
      id: 7,
      name: r'yPct',
      type: IsarType.double,
    )
  },
  estimateSize: _textBoxDataEstimateSize,
  serialize: _textBoxDataSerialize,
  deserialize: _textBoxDataDeserialize,
  deserializeProp: _textBoxDataDeserializeProp,
);

int _textBoxDataEstimateSize(
  TextBoxData object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.content;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.webFix;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _textBoxDataSerialize(
  TextBoxData object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.colorValue);
  writer.writeString(offsets[1], object.content);
  writer.writeDouble(offsets[2], object.fontSize);
  writer.writeDouble(offsets[3], object.rotation);
  writer.writeDouble(offsets[4], object.scale);
  writer.writeString(offsets[5], object.webFix);
  writer.writeDouble(offsets[6], object.xPct);
  writer.writeDouble(offsets[7], object.yPct);
}

TextBoxData _textBoxDataDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TextBoxData(
    colorValue: reader.readLongOrNull(offsets[0]),
    content: reader.readStringOrNull(offsets[1]),
    fontSize: reader.readDoubleOrNull(offsets[2]),
    rotation: reader.readDoubleOrNull(offsets[3]),
    scale: reader.readDoubleOrNull(offsets[4]),
    xPct: reader.readDoubleOrNull(offsets[6]),
    yPct: reader.readDoubleOrNull(offsets[7]),
  );
  object.webFix = reader.readStringOrNull(offsets[5]);
  return object;
}

P _textBoxDataDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDoubleOrNull(offset)) as P;
    case 3:
      return (reader.readDoubleOrNull(offset)) as P;
    case 4:
      return (reader.readDoubleOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    case 7:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension TextBoxDataQueryFilter
    on QueryBuilder<TextBoxData, TextBoxData, QFilterCondition> {
  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition>
      colorValueIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'colorValue',
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition>
      colorValueIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'colorValue',
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition>
      colorValueEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'colorValue',
        value: value,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition>
      colorValueGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'colorValue',
        value: value,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition>
      colorValueLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'colorValue',
        value: value,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition>
      colorValueBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'colorValue',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition>
      contentIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'content',
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition>
      contentIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'content',
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition> contentEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition>
      contentGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition> contentLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition> contentBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'content',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition>
      contentStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition> contentEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition> contentContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition> contentMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'content',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition>
      contentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'content',
        value: '',
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition>
      contentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'content',
        value: '',
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition>
      fontSizeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fontSize',
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition>
      fontSizeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fontSize',
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition> fontSizeEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fontSize',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition>
      fontSizeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fontSize',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition>
      fontSizeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fontSize',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition> fontSizeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fontSize',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition>
      rotationIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'rotation',
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition>
      rotationIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'rotation',
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition> rotationEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rotation',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition>
      rotationGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rotation',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition>
      rotationLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rotation',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition> rotationBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rotation',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition> scaleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'scale',
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition>
      scaleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'scale',
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition> scaleEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scale',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition>
      scaleGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scale',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition> scaleLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scale',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition> scaleBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scale',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition> webFixIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'webFix',
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition>
      webFixIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'webFix',
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition> webFixEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'webFix',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition>
      webFixGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'webFix',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition> webFixLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'webFix',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition> webFixBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'webFix',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition>
      webFixStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'webFix',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition> webFixEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'webFix',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition> webFixContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'webFix',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition> webFixMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'webFix',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition>
      webFixIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'webFix',
        value: '',
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition>
      webFixIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'webFix',
        value: '',
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition> xPctIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'xPct',
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition>
      xPctIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'xPct',
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition> xPctEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'xPct',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition> xPctGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'xPct',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition> xPctLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'xPct',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition> xPctBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'xPct',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition> yPctIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'yPct',
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition>
      yPctIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'yPct',
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition> yPctEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'yPct',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition> yPctGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'yPct',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition> yPctLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'yPct',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TextBoxData, TextBoxData, QAfterFilterCondition> yPctBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'yPct',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension TextBoxDataQueryObject
    on QueryBuilder<TextBoxData, TextBoxData, QFilterCondition> {}
