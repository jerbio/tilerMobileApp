import 'package:tiler_app/util.dart';

var autoTileParams = [
  {
    'id': Utility.getUuid,
    'isLastCard': true,
    'descriptions': [
      'We only have so much',
      'AI will return next week with more options'
    ],
    'relevance': 0,
    'durations': [Utility.oneMin],
    'assets': [],
  },
  {
    'id': Utility.getUuid,
    'descriptions': [
      'Dance Class',
    ],
    'durations': [
      Utility.fifteenMin,
      Utility.thirtyMin,
      Utility.oneHour,
    ],
    'relevance': 4,
    'assets': []
  },
  {
    'id': Utility.getUuid,
    'descriptions': ['Watch a movie marathon', 'Binge Watch'],
    'durations': [
      Duration(hours: 2),
      Duration(hours: 4),
    ],
    'relevance': 4,
    'assets': []
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
      'assets/images/regenerativeArt/pictimely_design_a_photo_of_someone_working_on_their_home_89d45464-6ce9-4623-b0c4-dcbe9bee8a96.png'
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
    'assets': []
  },
  {
    'id': Utility.getUuid,
    'descriptions': ['Take a nap'],
    'relevance': 3,
    'durations': [
      Duration(hours: 1),
      Duration(hours: 2),
    ],
    'assets': []
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
    'descriptions': ['Chores'],
    'relevance': 2,
    'durations': [
      Duration(minutes: 30),
      Duration(hours: 1),
    ],
    'assets': [
      'assets/images/regenerativeArt/pictimely_design_a_photo_of_diverse_people_doing_laundry_f83ffa56-27d2-4556-9bbb-175a92ec9b85.png',
      'assets/images/regenerativeArt/cleanup_kitchen_prep_7fd5f130-8833-42be-be26-faf4b0110b2f_3.png'
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
  },
  {
    'id': Utility.getUuid,
    'descriptions': ['Meditate', 'Work out'],
    'relevance': 2,
    'durations': [
      Duration(minutes: 30),
      Duration(hours: 1),
      Duration(hours: 2),
    ],
    'assets': [
      'assets/images/regenerativeArt/run_workout_a94bbb89-2f18-47fc-8280-7bf2634259da_2.png',
      'assets/images/regenerativeArt/work_out_run_a94bbb89-2f18-47fc-8280-7bf2634259da_1.png',
      'assets/images/regenerativeArt/workout_meditate_e77fbb2a-88b4-4c65-ac6b-c457145336d6_3.png',
      'assets/images/regenerativeArt/workout_meditate_e77fbb2a-88b4-4c65-ac6b-c457145336d6_1.png'
    ]
  },
  {
    'id': Utility.getUuid,
    'descriptions': ['Deep Work', "Plan Your Day"],
    'relevance': 2,
    'durations': [
      Duration(hours: 2),
      Duration(hours: 4),
    ],
    'assets': [
      'assets/images/regenerativeArt/deep_work_aa3ab045-791b-4d59-be21-546c08bc554f_1.png',
      'assets/images/regenerativeArt/deep_work_81053022-ead4-4edc-b689-a17a294c420d_3.png'
    ]
  },
  {
    'id': Utility.getUuid,
    'descriptions': ['Explore', "Tour City"],
    'relevance': 2,
    'durations': [
      Duration(hours: 2),
      Duration(hours: 4),
    ],
    'assets': [
      'assets/images/regenerativeArt/plan_trip_2dde37b4-6596-42c3-adc0-c8daf853c4ed_0.png',
      'assets/images/regenerativeArt/public_transit_2dde37b4-6596-42c3-adc0-c8daf853c4ed_3.png'
    ]
  },
  {
    'id': Utility.getUuid,
    'descriptions': ['Quiet Time', "Journal"],
    'relevance': 2,
    'durations': [
      Duration(minutes: 30),
      Duration(hours: 1),
    ],
    'assets': [
      'assets/images/regenerativeArt/workout_meditate_e77fbb2a-88b4-4c65-ac6b-c457145336d6_1.png'
    ]
  }
];
