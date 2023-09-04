module Shared {
  module Arrays {
    const TAG = "Arrays";
    function swap(a, i, j) {
      var z = a[i];
      a[i] = a[j];
      a[j] = z;
    }

    function qsort(a, less) {
      qsortImpl(a, 0, a.size()-1, less);
    }

    function qsortImpl(a, b, e, less) {
      if (b >= e || b < 0) {
        return;
      }
      var i = partition(a, b, e, less);
      qsortImpl(a, b, i-1, less);
      qsortImpl(a, i+1, e, less);
    }

    function partition(a, b, e, less) {
      var piv = a[e];
      var i = b - 1;
      for (var j = b; j < e; j++) {
        if (!less.invoke(piv, a[j])) {
	  i = i + 1;
	  swap(a, i, j);
	}
      }
      i = i + 1;
      swap(a, i, e);
      return i;
    }
  }
}

