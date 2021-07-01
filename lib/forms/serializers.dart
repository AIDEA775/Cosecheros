import 'package:cosecheros/forms/info/info.dart';
import 'package:cosecheros/forms/multichoice/multichoice_group.dart';
import 'package:cosecheros/forms/picture/pic.dart';
import 'package:cosecheros/forms/singlechoice/singlechoice_group.dart';
import 'package:cosecheros/shared/helpers.dart';
import 'package:dynamic_forms/dynamic_forms.dart';
import 'package:flutter_dynamic_forms_components/flutter_dynamic_forms_components.dart'
    as model;
import 'package:cosecheros/forms/map/map.dart' as mapModel;
import 'package:flutter_dynamic_forms_components/flutter_dynamic_forms_components.dart';

class ResponseItem {
  final String id;
  final String type;
  final String label;
  final dynamic value;

  ResponseItem({this.id, this.type, this.label, this.value});

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        if (label != null) 'label': label,
        if (value != null) 'value': value,
      };
}

abstract class Serializer<T extends FormElement> {
  ResponseItem serialize(T element);
}

class NopeSerializer implements Serializer<FormElement> {
  @override
  ResponseItem serialize(FormElement element) {
    return null;
  }
}

class BasicSerializer implements Serializer<FormElement> {
  @override
  ResponseItem serialize(FormElement element) {
    var valueProperty = element.getProperties()['value'];
    if (valueProperty == null) return null;
    return ResponseItem(
      id: element.id,
      type: element.runtimeType.toString(),
      label: element.getProperties()['label'].value,
      value: valueProperty.value,
    );
  }
}

class SingleChoiceSerializer implements Serializer<SingleChoiceGroup> {
  @override
  ResponseItem serialize(SingleChoiceGroup element) {
    var selected = element.choices.singleWhere(
      (choice) => choice.value == element.value,
      orElse: () => null,
    );
    if (selected == null) return null;
    return ResponseItem(
      id: element.id,
      type: 'single_choice',
      label: element.label,
      value: {
        'id': selected.value,
        'label': selected.label,
      },
    );
  }
}

class MultiChoiceSerializer implements Serializer<MultiChoiceGroup> {
  @override
  ResponseItem serialize(MultiChoiceGroup element) {
    var selected = element.choices.where((element) => element.isSelected).map(
          (e) => {
            'id': e.id,
            'label': e.label,
          },
        );
    if (selected == null) return null;
    return ResponseItem(
      id: element.id,
      type: 'multi_choice',
      label: element.label,
      value: selected,
    );
  }
}

class MapSerializer implements Serializer<mapModel.Map> {
  @override
  ResponseItem serialize(mapModel.Map element) {
    return ResponseItem(
      id: element.id,
      type: 'geo_point',
      // label: element.label, TODO: guardar el "cerca de" acá?
      value: geoPoinFromGeoPos(element.point),
    );
  }
}

class DateSerializer implements Serializer<model.Date> {
  @override
  ResponseItem serialize(model.Date element) {
    return ResponseItem(
      id: element.id,
      type: 'date',
      label: element.label,
      value: element.value,
    );
  }
}

class TextSerializer implements Serializer<TextField> {
  @override
  ResponseItem serialize(TextField element) {
    if (element.value.isEmpty) return null;
    return ResponseItem(
      id: element.id,
      type: 'text',
      label: element.label,
      value: element.value,
    );
  }
}

class PictureSerializer implements Serializer<Picture> {
  @override
  ResponseItem serialize(Picture element) {
    if (element.url == null) return null;
    return ResponseItem(
      id: element.id,
      type: 'picture',
      // label: element.label,
      value: element.url,
    );
  }
}

final Map<Type, Serializer> serializers = {
  Picture: PictureSerializer(),
  SingleChoiceGroup: SingleChoiceSerializer(),
  MultiChoiceGroup: MultiChoiceSerializer(),
  model.CheckBox: null,
  mapModel.Map: MapSerializer(),
  model.TextField: TextSerializer(),
  model.Date: DateSerializer(),
  // Ignore
  model.SingleSelectChoice: NopeSerializer(),
  model.MultiSelectChoice: NopeSerializer(),
  model.Label: NopeSerializer(),
  model.FormGroup: NopeSerializer(),
  model.Form: NopeSerializer(),
  Info: NopeSerializer(),
};
