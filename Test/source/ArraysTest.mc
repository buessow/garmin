import Toybox.Lang;

using Shared.Arrays;
using Shared.Util;
using TestLib.Assert;
using Toybox.Test;

class ArraysTest {

  (:test)
  function qsortEmpty(l as Test.Logger) as Boolean {
    var a = [];
    Arrays.qsort(a);
    Assert.equal(0, a.size());
    return true;
  }

  (:test)
  function qsort1Element(l as Test.Logger) as Boolean {
    var a = [1];
    Arrays.qsort(a);
    Assert.equal([1], a);
    return true;
  }

  (:test)
  function qsortNElement1(l as Test.Logger) as Boolean {
    var a = [1, 4, 5, 3, 0, 1, -4];
    Arrays.qsort(a);
    Assert.equal([-4, 0, 1, 1, 3, 4, 5], a);
    return true;
  }

  (:test)
  function qsortManyElements(l as Test.Logger) as Boolean {
    var a = [];
    for (var i = 0; i < 100; i++) {
      a.add((120 - i) % 100);
    }
    Arrays.qsort(a);
    Assert.equal(100, a.size());
    for (var i = 0; i < 100; i++) {
      Assert.equal(i, a[i]);
    }
    return true;
  }
}