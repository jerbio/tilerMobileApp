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
    'descriptions': ['House renovation project'],
    'relevance': 5,
    'durations': [
      Utility.thirtyMin,
      Utility.oneHour,
      Duration(hours: 2),
      Duration(hours: 4),
      Duration(hours: 6),
    ],
    'assets': [
      'assets/images/regenerativeArt/pictimely_design_a_photo_of_someone_renovating_their_home_699323d1-6938-4a45-9ec9-01ae9bbef757.png',
      'assets/images/regenerativeArt/pictimely_design_a_photo_of_someone_working_on_their_home_89d45464-6ce9-4623-b0c4-dcbe9bee8a96.png'
    ]
  },
  {
    'id': Utility.getUuid,
    'descriptions': [
      'Dance party',
      'Flash mob',
    ],
    'durations': [
      Utility.fifteenMin,
      Utility.thirtyMin,
      Utility.oneHour,
    ],
    'relevance': 4,
    'assets': [
      'assets/images/regenerativeArt/pictimely_design_a_photo_of_someone_taking_dance_lessons_with_d_d3c2a283-1c7a-4391-b960-de2f5087d487.png'
    ]
  },
  {
    'id': Utility.getUuid,
    'descriptions': ['Watch a movie marathon', 'Binge Watch'],
    'durations': [
      Duration(hours: 2),
      Duration(hours: 4),
    ],
    'relevance': 4,
    'assets': [
      'assets/images/regenerativeArt/pictimely_design_a_photo_of_diverse_people_watching_movie_with__2aca0b05-74a4-49ea-a7c3-07b8542cd627.png'
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
      'assets/images/regenerativeArt/pictimely_image_of_someone_creating_or_making_something_or_a_ma_2a50defa-b851-4671-9cfd-41eaa5636130.png',
      'assets/images/regenerativeArt/pictimely_design_a_photo_of_someone_working_on_their_home_89d45464-6ce9-4623-b0c4-dcbe9bee8a96.png'
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
      Duration(hours: 1),
    ],
    'assets': [
      'assets/images/regenerativeArt/pictimely_plant_indoor_garden_fb195907-8fd8-4c03-b998-61eb0d000f5f.png'
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
      'assets/images/regenerativeArt/pictimely_design_a_photo_of_someone_going_on_relaxing_walk_b08a6746-c6f7-4937-86fa-445978011119.png'
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
  },
  {
    'id': Utility.getUuid,
    'descriptions': ['Laundry'],
    'relevance': 2,
    'durations': [
      Duration(minutes: 30),
      Duration(hours: 1),
    ],
    'assets': [
      'assets/images/regenerativeArt/pictimely_design_a_photo_of_diverse_people_doing_laundry_f83ffa56-27d2-4556-9bbb-175a92ec9b85.png'
    ]
  },
  {
    'id': Utility.getUuid,
    'descriptions': ['Dinner', 'Coffee with a friend'],
    'relevance': 2,
    'durations': [
      Duration(minutes: 30),
      Duration(hours: 1),
    ],
    'assets': [
      'assets/images/regenerativeArt/pictimely_design_a_photo_of_someone_meeting_up_with_friends_fcf525d6-df39-4b54-887d-fc5afd8c1caa.png'
    ]
  }
];
