import 'package:flutter/material.dart';

class ListModel<E> {
  ListModel({
    required this.listKey,
    required this.removedItemBuilder,
    Iterable<E>? initialItems,
  }) : _items = List<E>.from(initialItems ?? <E>[]);

  final GlobalKey<AnimatedListState> listKey;
  final RemovedItemBuilder<E> removedItemBuilder;
  final List<E> _items;

  AnimatedListState? get _animatedList => listKey.currentState;

  void insert(int index, E item, {bool animate = true}) {
    _items.insert(index, item);
    if (_animatedList != null) {
      if (animate) {
        _animatedList!.insertItem(index);
      } else {
        _animatedList!.insertItem(index, duration: Duration.zero);
      }
    }
  }

  E removeAt(int index, {bool animate = true}) {
    final E removedItem = _items.removeAt(index);
    if (removedItem != null) {
      if (_animatedList != null) {
        if (animate) {
          _animatedList!.removeItem(
            index,
            (BuildContext context, Animation<double> animation) {
              return removedItemBuilder(removedItem, context, animation);
            },
          );
        } else {
          _animatedList!.removeItem(index,
              (BuildContext context, Animation<double> animation) {
            return removedItemBuilder(removedItem, context, animation);
          }, duration: Duration.zero);
        }
      }
    }
    return removedItem;
  }

  E move(int from, int to) {
    E item = this[from];
    removeAt(from);
    insert(to, item);
    return item;
  }

  removeAndUpdate(int from, int to, E item, {bool animate = true}) {
    E removedItem = removeAt(from, animate: animate);
    insert(to, item, animate: animate);
  }

  int get length => _items.length;

  E operator [](int index) => _items[index];

  int indexOf(E item) => _items.indexOf(item);
  List<E> toList() => _items.toList();
}

typedef RemovedItemBuilder<T> = Widget Function(
    T item, BuildContext context, Animation<double> animation);
