import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tiler_app/components/onBoarding/videoPlayer.dart';
import 'package:tiler_app/routes/authentication/AuthorizedRoute.dart';
import 'package:tiler_app/services/onBoardingHelper.dart';
import 'package:tiler_app/util.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

enum SlideType {
  toggleButton,
  image,
  textWithIcon,
}

class IntroSlideData {
  final String title;
  final SlideType slideType;
  final List<String> description;
  final String? imagePath;
  final String? videoPath;

  IntroSlideData(
      {required this.title,
      required this.slideType,
      required this.description,
      this.imagePath,
      this.videoPath});
}

class OnBoardingDescriptionSlider extends StatefulWidget {
  const OnBoardingDescriptionSlider({Key? key}) : super(key: key);

  @override
  _OnBoardingDescriptionSliderState createState() =>
      _OnBoardingDescriptionSliderState();
}

class _OnBoardingDescriptionSliderState
    extends State<OnBoardingDescriptionSlider> {
  PageController _pageController = PageController();
  int _currentPage = 0;
  late String _selectedOption;
  late AppLocalizations localizations;
  late List<IntroSlideData> _slides;
  @override
  void didChangeDependencies() {
    localizations = AppLocalizations.of(context)!;
    _slides = [
      IntroSlideData(
        title: localizations.tilesVsBlocks,
        slideType: SlideType.toggleButton,
        videoPath: "assets/videos/tiles_vs_blocks.mov",
        description: [
          localizations.vsTilesDescription,
          localizations.vsBlocksDescription
        ],
      ),
      IntroSlideData(
          title: localizations.swipeRight,
          slideType: SlideType.image,
          imagePath: "assets/images/tilerAd.png",
          description: [localizations.swipeRightDescription]),
      IntroSlideData(
        title: localizations.googleCalendarAndMore,
        slideType: SlideType.textWithIcon,
        description: [localizations.googleCalendarAndMoreDescription],
      ),
    ];
    _selectedOption = "Tile";
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            _buildDotsIndicator(colorScheme),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return _buildSlide(_slides[index], colorScheme);
                },
              ),
            ),
            _buildBottomNavigation(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildDotsIndicator(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_slides.length, (index) {
        bool selected = _currentPage == index;
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 4),
          padding: selected ? EdgeInsets.all(4) : EdgeInsets.zero,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: selected
                ? Border.all(color: colorScheme.onPrimary, width: 1)
                : null,
          ),
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.onPrimary,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSlide(IntroSlideData slide, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (slide.slideType == SlideType.textWithIcon)
            Text.rich(
              TextSpan(
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: Baseline(
                      baseline: 32,
                      baselineType: TextBaseline.alphabetic,
                      child: SvgPicture.asset(
                        'assets/images/Component.svg',
                        height: 22,
                        width: 22,
                      ),
                    ),
                  ),
                  TextSpan(
                    text: " ${slide.title}",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            )
          else
            Text(
              slide.title,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          SizedBox(
            height: 20,
          ),
          _buildSlideBody(slide, colorScheme),
          SizedBox(
            height: 20,
          ),
          Text(
            slide.slideType == SlideType.toggleButton
                ? (_selectedOption == "Tile"
                    ? slide.description[0]
                    : slide.description[1])
                : slide.description[0],
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          if (slide.videoPath != null) ...[
            SizedBox(height: 20),
            VideoPlayerWidget(videoPath: slide.videoPath!),
          ],
        ],
      ),
    );
  }

  Widget _buildSlideBody(IntroSlideData slide, ColorScheme colorScheme) {
    switch (slide.slideType) {
      case SlideType.toggleButton:
        return _buildToggleButton(colorScheme, slide);
      case SlideType.image:
        return _buildImageContent(slide.imagePath!);
      case SlideType.textWithIcon:
        return SizedBox();
      default:
        return SizedBox();
    }
  }

  Widget _buildToggleButton(ColorScheme colorScheme, IntroSlideData slide) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedOption = "Tile";
                });
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                height: 24,
                decoration: BoxDecoration(
                  color: _selectedOption == "Tile"
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedOption == "Tile"
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    localizations.tile,
                    style: TextStyle(
                      color: _selectedOption == "Tile"
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedOption = "Block";
                });
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                height: 24,
                decoration: BoxDecoration(
                  color: _selectedOption == "Block"
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedOption == "Block"
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    localizations.appointment,
                    style: TextStyle(
                      color: _selectedOption == "Block"
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent(String imagePath) {
    return Container(
        height: 450,
        width: 450,
        child: Image.asset(
          imagePath,
          fit: BoxFit.contain,
        ));
  }

  Widget _buildBottomNavigation(ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.primary.withLightness(0.62),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 1,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () {
              if (_currentPage < _slides.length - 1) {
                _pageController.nextPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => AuthorizedRoute()));
              }
            },
            icon: Icon(
              Icons.arrow_forward,
              color: colorScheme.onPrimary,
              size: 30,
            ),
          ),
        ),
        SizedBox(height: 20),
        GestureDetector(
          onTap: () async {
            await OnBoardingSharedPreferencesHelper.setSkipOnboarding(true);
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => AuthorizedRoute()));
          },
          child: Text(
            localizations.skip,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
