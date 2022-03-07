extension Filter<T> on Stream<List<T>> {
  // Stream has a builtin function called where in the documentation. This extension
  // is built upon that function

  // Extending Stream that has a list of value of T in order to grab hold of
  // all data existing in the Stream which is then filtered
  // We use this to filter Stream containing a List of DBNote with their respective owners
  Stream<List<T>> filter(bool Function(T) where) =>
      map((items) => items.where(where).toList());
  // Stream returns a List, map returns a iterable so we need to convert toList
}
