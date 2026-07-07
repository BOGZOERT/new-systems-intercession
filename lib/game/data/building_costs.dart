import '../models/building_type.dart';

const Map<BuildingType, Map<String, int>> buildingCosts = {
  BuildingType.house: {'wood': 5, 'stone': 3, 'food': 0},
  BuildingType.sawmill: {'wood': 3, 'stone': 5, 'food': 0},
  BuildingType.storage: {'wood': 8, 'stone': 5, 'food': 0},
  BuildingType.castle: {'wood': 20, 'stone': 20, 'food': 10},
};

String buildingName(BuildingType b) {
  switch (b) {
    case BuildingType.house: return 'Дом';
    case BuildingType.sawmill: return 'Лесопилка';
    case BuildingType.storage: return 'Хранилище';
    case BuildingType.castle: return 'Замок';
    default: return '';
  }
}