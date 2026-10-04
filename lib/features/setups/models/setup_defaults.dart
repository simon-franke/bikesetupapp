import 'category.dart';

/// Domain defaults independent of repositories and controller state.
class SetupDefaults {
  static Map<Category, Map<String, String>> forShock(String shockType) => {
        Category.fork: const {
          'Pressure': '90',
          'Rebound': '5',
          'Compression': '8',
          'Tokens': '2'
        },
        Category.shock: {
          if (shockType == 'Coil') ...{
            'Preload': '0',
            'Spring Rate': '450'
          } else ...{
            'Pressure': '180',
            'Tokens': '0'
          },
          'Rebound': '5',
          'Compression': '8',
        },
        Category.frontTire: const {'Pressure': '26'},
        Category.rearTire: const {'Pressure': '26'},
        Category.generalSettings: const {
          'Reach': '450mm',
          'Stack Height': '20mm',
          'Seat Height': '35mm'
        },
      };
}
