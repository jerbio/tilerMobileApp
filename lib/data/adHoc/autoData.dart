import 'package:tiler_app/util.dart';

var autoTileParams = [
  {
    'id': Utility.getUuid,
    'isLastCard': true,
    'descriptions': [
      'We only have so much',
      'AI will return next week more options'
    ],
    'relevance': 0,
    'durations': [Utility.oneMin],
    'assets': [
      'assets/images/regenerativeArt/pictimely_we_are_not_Gods_064eb660-6cca-44bb-b75b-12da4555ef30.png'
    ],
  },
  {
    'id': Utility.getUuid,
    'descriptions': ['Pillow fort', 'Build a fort'],
    'durations': [Utility.thirtyMin, Utility.oneHour],
    'relevance': 4,
    'assets': [
      'assets/images/regenerativeArt/pictimely_build_a_pillow_fort_d77bbb89-2e18-4e70-a547-a78d9b9eee83.png'
    ]
  },
  {
    'id': Utility.getUuid,
    'descriptions': ['House renovation project', 'Learn magic trick'],
    'relevance': 5,
    'durations': [
      Utility.thirtyMin,
      Utility.oneHour,
      Duration(hours: 2),
      Duration(hours: 4),
      Duration(hours: 6),
    ],
    'assets': [
      'assets/images/regenerativeArt/pictimely_cute_photo_of_woman_and_man_working_together_looking__49c9615b-3c01-4914-aa4c-be6aaeba779d.png'
    ]
  },
  {
    'id': Utility.getUuid,
    'descriptions': ['Origami', 'Paper art'],
    'durations': [
      Utility.thirtyMin,
      Utility.oneHour,
      Duration(hours: 2),
    ],
    'relevance': 5,
    'assets': [
      'assets/images/regenerativeArt/pictimely_Do_some_origami_43731a0a-393c-434e-ab3e-1c5bb10143b2.png'
    ]
  },
  {
    'id': Utility.getUuid,
    'descriptions': [
      'Dance party',
      'Flash mob',
      'Bob to some music',
      'Buga buga'
    ],
    'durations': [
      Utility.fifteenMin,
      Utility.thirtyMin,
      Utility.oneHour,
    ],
    'relevance': 4,
    'assets': [
      'assets/images/regenerativeArt/pictimely_feeling_idle_excited_at_a_dance_party_2efb40a6-7b44-49d9-a038-50f197bb506a.png'
    ]
  },
  {
    'id': Utility.getUuid,
    'descriptions': ['Watch a movie marathon', 'Binge Watch'],
    'durations': [
      Duration(hours: 2),
      Duration(hours: 4),
      Duration(hours: 6),
    ],
    'relevance': 4,
    'assets': [
      'assets/images/regenerativeArt/pictimely_Have_a_movie_marathon_e574a17c-3c4a-439b-8c94-7ae1771495f4.png'
    ]
  },
  {
    'id': Utility.getUuid,
    'descriptions': [
      'Work on a project',
      'Work at a shelter',
      'Join a Maker shop'
    ],
    'relevance': 2,
    'durations': [
      Utility.oneHour,
      Duration(hours: 2),
      Duration(hours: 4),
    ],
    'assets': [
      'assets/images/regenerativeArt/pictimely_image_of_someone_creating_or_making_something_or_a_ma_2a50defa-b851-4671-9cfd-41eaa5636130.png'
    ]
  },
  {
    'id': Utility.getUuid,
    'descriptions': ['Make a bird feeder', 'Work at a shelter'],
    'relevance': 5,
    'durations': [
      Utility.thirtyMin,
      Utility.oneHour,
      Duration(hours: 2),
      Duration(hours: 4)
    ],
    'assets': [
      'assets/images/regenerativeArt/pictimely_Make_a_bird_feeder_28f817f4-f638-4730-bf9c-4273f6a6ef33.png'
    ]
  },
  {
    'id': Utility.getUuid,
    'descriptions': ['Reorganize Closet', 'Reorganize room'],
    'relevance': 1,
    'durations': [
      Duration(hours: 2),
      Duration(hours: 4),
    ],
    'assets': [
      'assets/images/regenerativeArt/pictimely_Reorganize_your_closets_abdd967a-9592-444b-b772-0326fa46d8ea.png'
    ]
  },
  {
    'id': Utility.getUuid,
    'descriptions': ['Plant indoor Garden', 'Pick up planting'],
    'relevance': 5,
    'durations': [
      Duration(hours: 2),
      Duration(hours: 4),
    ],
    'assets': [
      'assets/images/regenerativeArt/pictimely_plant_indoor_garden_fb195907-8fd8-4c03-b998-61eb0d000f5f.png'
    ]
  },
  {
    'id': Utility.getUuid,
    'descriptions': ['Make a T-shirt'],
    'relevance': 5,
    'durations': [
      Duration(hours: 2),
      Duration(hours: 4),
    ],
    'assets': [
      'assets/images/regenerativeArt/pictimely_make_a_tshirt_05b6d04b-a565-4683-bbf8-6e208acee019.png'
    ]
  },
  {
    'id': Utility.getUuid,
    'descriptions': ['Take a nap'],
    'relevance': 3,
    'durations': [
      Duration(hours: 1),
      Duration(hours: 2),
    ],
    'assets': [
      'assets/images/regenerativeArt/pictimely_take_a_nap_d7b1437a-eb98-458b-ad54-50ccd9792ea1.png'
    ]
  },
  {
    'id': Utility.getUuid,
    'descriptions': ['Go for a walk'],
    'relevance': 1,
    'durations': [
      Duration(minutes: 30),
      Duration(hours: 1),
    ],
    'assets': [
      'assets/images/regenerativeArt/pictimely_go_for_a_walk_at_different_time_of_the_day_and_differ_e708108b-c576-4e27-a01c-dce2a88c7599.png'
    ]
  },
  {
    'id': Utility.getUuid,
    'descriptions': ['Listen to music', 'Listen to your favorite artist'],
    'relevance': 3,
    'durations': [
      Duration(minutes: 5),
      Duration(minutes: 15),
      Duration(minutes: 30),
      Duration(hours: 1),
    ],
    'assets': [
      'assets/images/regenerativeArt/pictimely_people_trying_to_find_something_to_do_while_listening_7fcfd84e-fde9-44b1-8835-470d9ff7036d.png'
    ]
  },
  {
    'id': Utility.getUuid,
    'descriptions': ['Redesign room', 'Rearrange home'],
    'relevance': 2,
    'durations': [
      Duration(minutes: 30),
      Duration(hours: 1),
      Duration(hours: 2),
      Duration(hours: 4),
    ],
    'assets': [
      'assets/images/regenerativeArt/pictimely_decorate_a_room_05c28f1e-30fb-44f9-9738-30fe5decab93.png'
    ]
  }
];
