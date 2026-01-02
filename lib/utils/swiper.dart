import 'package:flutter/material.dart';
import 'dart:async';

class Swiper extends StatefulWidget {
  final double? height;
  final double? width;
  final List<Widget> pages;

  const Swiper({
    super.key,
    this.height = double.infinity,
    this.width = double.infinity,
    required this.pages,
  });

  @override
  State<Swiper> createState() => _SwiperState();
}

class _SwiperState extends State<Swiper> {
  int _currentIndex = 0;
  Timer? _timer;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    // Only start timer if there are pages to swipe
    if (widget.pages.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (!mounted) return;

        _currentIndex = (_currentIndex + 1) % widget.pages.length;

        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Handle empty pages
    if (widget.pages.isEmpty) {
      return const SizedBox.shrink();
    }

    // Single page - no need for PageView
    if (widget.pages.length == 1) {
      return SizedBox(
        height: widget.height,
        width: widget.width,
        child: widget.pages.first,
      );
    }

    // Multiple pages - use PageView with indicators
    return Stack(
      children: [
        SizedBox(
          height: widget.height,
          width: widget.width,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemCount: widget.pages.length,
            itemBuilder: (context, index) => widget.pages[index],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.pages.length, (index) {
              return Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(left: 5),
                decoration: BoxDecoration(
                  color: _currentIndex == index ? Colors.white : Colors.grey,
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}